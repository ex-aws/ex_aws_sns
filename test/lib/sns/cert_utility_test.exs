defmodule ExAws.SNS.CertUtilityTest do
  use ExUnit.Case, async: true

  alias ExAws.SNS.CertUtility

  # This cert has TLS key usage (Digital Signature, Key Encipherment) without
  # keyCertSign, which strict PKIX path validation rejects as :invalid_key_usage.
  # Requires network access to fetch the cert and its intermediate CA via AIA.
  @tag :skip
  test "build_and_validate_chain/2 succeeds for SNS cert with TLS-only key usage" do
    url =
      "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-7506a1e35b36ef5a444dd1a8e7cc3ed8.pem"

    {:ok, body} = ExAws.Request.Hackney.request(:get, url)
    [pem_entry] = :public_key.pem_decode(body.body)

    assert :ok == CertUtility.build_and_validate_chain(pem_entry, ExAws.Request.Hackney)
  end
end
