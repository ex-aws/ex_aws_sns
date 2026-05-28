defmodule ExAws.SNS.PublicKeyCache do
  use GenServer

  alias ExAws.SNS.CertUtility

  @valid_sns_hosts_default ~r/^sns\.[a-z0-9-]+\.amazonaws\.com(\.cn)?$|^sns\.[a-z0-9-]+\.api\.aws$/

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get(cert_url) do
    case :ets.lookup(__MODULE__, cert_url) do
      [{_cert_url, entry}] -> {:ok, entry}
      [] -> GenServer.call(__MODULE__, {:get_public_key, cert_url})
    end
  end

  ## Callbacks

  def init(:ok) do
    ets = :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    {:ok, ets}
  end

  def handle_call({:get_public_key, cert_url}, _from, ets) do
    http_client = Application.get_env(:ex_aws, :http_client, ExAws.Request.Hackney)

    with :ok <- validate_cert_url(cert_url),
         {:ok, pem_entry} <- fetch_certificate(cert_url, http_client),
         {:ok, otp_cert} <- CertUtility.decode_otp(pem_entry),
         :ok <- CertUtility.validate_subject(pem_entry),
         {:ok, not_before, not_after} <- CertUtility.get_validity(otp_cert),
         :ok <- CertUtility.build_and_validate_chain(pem_entry, http_client),
         {:ok, public_key} <- CertUtility.get_public_key(pem_entry) do
      entry = {public_key, not_before, not_after}
      :ets.insert(__MODULE__, {cert_url, entry})
      {:reply, {:ok, entry}, ets}
    else
      error -> {:reply, error, ets}
    end
  end

  defp fetch_certificate(cert_url, http_client) do
    with {:ok, %{status_code: 200, body: cert_binary}} <- http_client.request(:get, cert_url) do
      case :public_key.pem_decode(cert_binary) do
        [entry] -> {:ok, entry}
        entries -> {:error, "Invalid PEM entries: #{inspect(entries)}"}
      end
    else
      {:ok, %{status_code: status_code}} ->
        {:error,
         "Could not fetch certificate from #{cert_url}, expected http code 200, got: #{status_code}"}

      {:error, %{reason: reason}} ->
        {:error,
         "Unexpected error, could not fetch certificate from #{cert_url}, got #{inspect(reason)}"}
    end
  end

  defp validate_cert_url(cert_url) do
    allowed_cert_schemes = Application.get_env(:ex_aws_sns, :allowed_cert_schemes, ["https"])
    valid_hosts = Application.get_env(:ex_aws_sns, :valid_hosts, @valid_sns_hosts_default)
    uri = URI.parse(cert_url)

    cond do
      uri.scheme not in allowed_cert_schemes ->
        {:error, "Invalid certificate URL scheme: #{cert_url}"}

      not String.ends_with?(uri.path || "", ".pem") ->
        {:error, "Invalid SNS certificate URL path, expected .pem extension: #{uri.path}"}

      !(uri.host =~ valid_hosts) ->
        {:error, "Invalid SNS certificate URL host: #{uri.host}"}

      true ->
        :ok
    end
  end
end
