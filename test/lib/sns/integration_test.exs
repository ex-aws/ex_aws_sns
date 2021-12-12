defmodule ExAws.SNS.IntegrationTest do
  use ExUnit.Case, async: true

  # Requires AWS access
  @tag :skip
  test "basic sanity check" do
    assert {:error, {:http_error, 400, _}} =
             ExAws.SNS.list_topics(next_token: "foo") |> ExAws.request()
  end
end
