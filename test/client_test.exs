defmodule Outkit.ClientTest do
  use ExUnit.Case
  alias Outkit.Client

  doctest Outkit.Client

  test "default endpoint" do
    client = Client.new()
    assert client.endpoint == "https://api.outkit.io/v1"
  end

  test "custom endpoint" do
    expected = "http://localhost:4990/v1/"

    client = Client.new(endpoint: expected)
    assert client.endpoint == expected

    # when tailing '/' is missing
    client = Client.new(endpoint: "http://localhost:4990/v1")
    assert client.endpoint == expected
  end
end
