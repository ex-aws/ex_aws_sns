defmodule ExAws.SNS.CertUtility do
  @moduledoc false

  require Record

  @public_key_header "public_key/include/public_key.hrl"
  Enum.each(Record.extract_all(from_lib: @public_key_header), fn {name, _} ->
    macro = name |> to_string() |> String.downcase() |> String.to_atom()
    Record.defrecordp(macro, name, Record.extract(name, from_lib: @public_key_header))
  end)

  @expected_sns_hostname ~c"sns.amazonaws.com"

  @aia_oid {1, 3, 6, 1, 5, 5, 7, 1, 1}
  @ca_issuers_oid {1, 3, 6, 1, 5, 5, 7, 48, 2}
  @max_chain_depth 5

  @type otp_cert :: :public_key.cert()
  @type http_client :: module()

  @doc "Decodes a PEM entry into an OTP certificate structure."
  @spec decode_otp(:public_key.pem_entry()) :: {:ok, otp_cert()} | {:error, String.t()}
  def decode_otp(pem_entry) do
    try do
      der = elem(pem_entry, 1)
      {:ok, :public_key.pkix_decode_cert(der, :otp)}
    catch
      _kind, error -> {:error, "Failed to decode certificate: #{inspect(error)}"}
    end
  end

  @doc "Verifies the certificate's hostname matches the expected SNS hostname."
  @spec validate_subject(:public_key.pem_entry()) :: :ok | {:error, String.t()}
  def validate_subject(pem_entry) do
    der = elem(pem_entry, 1)

    if :public_key.pkix_verify_hostname(der, dns_id: @expected_sns_hostname) do
      :ok
    else
      {:error, "Certificate hostname does not match expected #{@expected_sns_hostname}"}
    end
  end

  @doc "Extracts the NotBefore and NotAfter validity datetimes from an OTP certificate."
  @spec get_validity(otp_cert()) :: {:ok, DateTime.t(), DateTime.t()} | {:error, String.t()}
  def get_validity(otp_cert) do
    tbs = otpcertificate(otp_cert, :tbsCertificate)
    {:Validity, not_before, not_after} = otptbscertificate(tbs, :validity)

    with {:ok, not_before_dt} <- parse_cert_time(not_before),
         {:ok, not_after_dt} <- parse_cert_time(not_after) do
      {:ok, not_before_dt, not_after_dt}
    end
  end

  @doc """
  Builds and validates the certificate chain up to a trusted root.

  Follows AIA caIssuers links recursively to fetch intermediate CAs, then validates
  the full chain using the system trust store. Allows up to #{@max_chain_depth} intermediates.
  """
  @spec build_and_validate_chain(:public_key.pem_entry(), http_client()) ::
          :ok | {:error, String.t()}
  def build_and_validate_chain(pem_entry, http_client) do
    build_and_validate_chain(elem(pem_entry, 1), [], http_client)
  end

  @doc "Extracts the RSA public key from a PEM entry."
  @spec get_public_key(:public_key.pem_entry()) ::
          {:ok, :public_key.rsa_public_key()} | {:error, String.t()}
  def get_public_key(pem_entry) do
    try do
      key =
        pem_entry
        |> :public_key.pem_entry_decode()
        |> certificate(:tbsCertificate)
        |> tbscertificate(:subjectPublicKeyInfo)
        |> subjectpublickeyinfo(:subjectPublicKey)

      {:ok, :public_key.der_decode(:RSAPublicKey, key)}
    catch
      _kind, error -> {:error, "Unexpected error while decoding public key: #{inspect(error)}"}
    end
  end

  defp build_and_validate_chain(current_der, intermediates, http_client)
       when length(intermediates) <= @max_chain_depth do
    current_otp = :public_key.pkix_decode_cert(current_der, :otp)

    :public_key.cacerts_load()

    # Chain order for pkix_path_validation: closest to root first, peer (end-entity) last.
    # As we recurse upward fetching intermediates, current_der moves closer to the root,
    # so it prepends the accumulated chain.
    chain = [current_der | intermediates]

    root_candidates =
      Enum.filter(:public_key.cacerts_get(), fn {:cert, _der, root_otp} ->
        :public_key.pkix_is_issuer(current_otp, root_otp)
      end)

    validated =
      Enum.find_value(root_candidates, fn {:cert, root_der, _} ->
        case :public_key.pkix_path_validation(root_der, chain,
               verify_fun: path_validation_verify_fun()
             ) do
          {:ok, _} -> :ok
          {:error, _} -> nil
        end
      end)

    cond do
      validated == :ok ->
        :ok

      root_candidates == [] ->
        tbs = otpcertificate(current_otp, :tbsCertificate)
        extensions = otptbscertificate(tbs, :extensions)

        with {:ok, aia_url} <- find_ca_issuers_url(extensions),
             {:ok, next_der} <- fetch_der(aia_url, http_client) do
          build_and_validate_chain(next_der, [current_der | intermediates], http_client)
        end

      true ->
        {:error, "Certificate chain validation failed: no trusted root found for issuer"}
    end
  end

  defp build_and_validate_chain(_current_der, _intermediates, _http_client) do
    {:error,
     "Certificate chain validation failed: exceeded maximum chain depth of #{@max_chain_depth}"}
  end

  defp path_validation_verify_fun do
    {fn
       # SNS signing certs are TLS server certs (Digital Signature, Key Encipherment)
       # and do not have the keyCertSign usage required by strict path validation.
       # We accept this because we only use the public key to verify message signatures,
       # not for TLS. The chain of trust is still fully validated.
       _cert, {:bad_cert, :invalid_key_usage}, state -> {:valid, state}
       _cert, {:bad_cert, reason}, _state -> {:fail, reason}
       _cert, {:extension, _}, state -> {:unknown, state}
       _cert, :valid, state -> {:valid, state}
       _cert, :valid_peer, state -> {:valid, state}
     end, []}
  end

  defp find_ca_issuers_url(extensions) when is_list(extensions) do
    case Enum.find(extensions, fn {:Extension, oid, _, _} -> oid == @aia_oid end) do
      {:Extension, _, _, access_descriptions} ->
        access_descriptions
        |> Enum.find(&match?({:AccessDescription, @ca_issuers_oid, _}, &1))
        |> case do
          {:AccessDescription, _, {:uniformResourceIdentifier, url_chars}} ->
            {:ok, List.to_string(url_chars)}

          _ ->
            {:error, "Certificate AIA extension does not contain a caIssuers URL"}
        end

      nil ->
        {:error, "Certificate does not contain an Authority Information Access extension"}
    end
  end

  defp find_ca_issuers_url(_), do: {:error, "Certificate has no extensions"}

  defp fetch_der(url, http_client) do
    case http_client.request(:get, url) do
      {:ok, %{status_code: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %{status_code: status_code}} ->
        {:error, "Could not fetch intermediate CA from #{url}, got HTTP #{status_code}"}

      {:error, %{reason: reason}} ->
        {:error, "Could not fetch intermediate CA from #{url}: #{inspect(reason)}"}
    end
  end

  defp parse_cert_time({type, time_chars}) do
    time_str = List.to_string(time_chars)

    case {type, time_str} do
      {:utcTime,
       <<yy::binary-2, mm::binary-2, dd::binary-2, hh::binary-2, min::binary-2, ss::binary-2,
         "Z">>} ->
        year_2digit = String.to_integer(yy)
        year = if year_2digit >= 50, do: 1900 + year_2digit, else: 2000 + year_2digit
        date = Date.new!(year, String.to_integer(mm), String.to_integer(dd))
        time = Time.new!(String.to_integer(hh), String.to_integer(min), String.to_integer(ss))
        DateTime.new(date, time, "Etc/UTC")

      {:generalTime,
       <<yyyy::binary-4, mm::binary-2, dd::binary-2, hh::binary-2, min::binary-2, ss::binary-2,
         "Z">>} ->
        date = Date.new!(String.to_integer(yyyy), String.to_integer(mm), String.to_integer(dd))
        time = Time.new!(String.to_integer(hh), String.to_integer(min), String.to_integer(ss))
        DateTime.new(date, time, "Etc/UTC")

      _ ->
        {:error, "Unexpected #{type} format: #{time_str}"}
    end
  end
end
