defmodule ExAws.SNS.PublicKeyCache do
  use GenServer

  require Record

  # Import the erlang records for public_key handling
  @public_key_header "public_key/include/public_key.hrl"
  Enum.each(Record.extract_all(from_lib: @public_key_header), fn {name, _} ->
    macro = name |> to_string() |> String.downcase() |> String.to_atom()
    Record.defrecordp(macro, name, Record.extract(name, from_lib: @public_key_header))
  end)

  @valid_sns_hosts_default ~r/^sns.*[amazonaws\.com|api\.aws]$/

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get(cert_url) do
    case :ets.lookup(__MODULE__, cert_url) do
      [{_cert_url, public_key}] -> {:ok, public_key}
      [] -> GenServer.call(__MODULE__, {:get_public_key, cert_url})
    end
  end

  ## Callbacks

  def init(:ok) do
    ets = :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    {:ok, ets}
  end

  def handle_call({:get_public_key, cert_url}, _from, ets) do
    with :ok <- validate_cert_url(cert_url),
         {:ok, pem_entry} <- fetch_certificate(cert_url),
         {:ok, public_key} <- get_public_key(pem_entry) do
      :ets.insert(__MODULE__, {cert_url, public_key})
      {:reply, {:ok, public_key}, ets}
    else
      error -> {:reply, error, ets}
    end
  end

  defp fetch_certificate(cert_url) do
    http_client = Application.get_env(:ex_aws, :http_client, ExAws.Request.Hackney)

    with {:ok, %{status_code: 200, body: cert_binary}} <- http_client.request(:get, cert_url) do
      get_pem_entry(:public_key.pem_decode(cert_binary))
    else
      {:ok, %{status_code: status_code}} ->
        {:error,
         "Could not fetch certificate from #{cert_url}, expected http code 200, got: #{status_code}"}

      {:error, %{reason: reason}} ->
        {:error,
         "Unexpected error, could not fetch certificate from #{cert_url}, got #{inspect(reason)}"}
    end
  end

  defp get_pem_entry(pem_entries) do
    case pem_entries do
      [entry] ->
        {:ok, entry}

      entries ->
        {:error, "Invalid PEM entries: #{inspect(entries)}"}
    end
  end

  defp get_public_key(pem_entry) do
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

  defp validate_cert_url(cert_url) do
    allowed_cert_schemes = Application.get_env(:ex_aws_sns, :allowed_cert_schemes, ["https"])
    valid_hosts = Application.get_env(:ex_aws_sns, :valid_hosts, @valid_sns_hosts_default)
    uri = URI.parse(cert_url)

    if uri.scheme in allowed_cert_schemes do
      if uri.host =~ valid_hosts do
        :ok
      else
        {:error, "Invalid SNS certificate URL host: #{uri.host}"}
      end
    else
      {:error, "Invalid certificate URL scheme: #{cert_url}"}
    end
  end
end
