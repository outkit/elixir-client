defmodule Outkit.Client do

  @moduledoc """
  This module encapsulates auth and config data for API requests.

  ## Example

      # Create a client with API credentials manually
      client = Outkit.Client.new(key: "my-key", secret: "my-secret", passphrase: "my-passphrase")

      # Create a client with an config options set
      client = Outkit.Client.new(opts: [return_response: true])

  """
  
  defstruct(
    key: nil, 
    secret: nil,
    passphrase: nil,
    endpoint: "https://api.outkit.io/v1",
    opts: []
  )

  def new(), do: %__MODULE__{}

  def new(endpoint: endpoint) do
    %__MODULE__{endpoint: format_endpoint(endpoint)}
  end

  def new(opts: opts) do
    %__MODULE__{opts: opts}
  end

  def new(endpoint: endpoint, opts: opts) do
    %__MODULE__{endpoint: format_endpoint(endpoint), opts: opts}
  end

  def new(key: k, secret: s, passphrase: p) do
    %__MODULE__{key: k, secret: s, passphrase: p}
  end

  def new(key: k, secret: s, passphrase: p, endpoint: endpoint) do
    %__MODULE__{key: k, secret: s, passphrase: p, endpoint: format_endpoint(endpoint)}
  end

  def new(key: k, secret: s, passphrase: p, opts: opts) do
    %__MODULE__{key: k, secret: s, passphrase: p, opts: opts}
  end

  def new(key: k, secret: s, passphrase: p, endpoint: endpoint, opts: opts) do
    %__MODULE__{key: k, secret: s, passphrase: p, endpoint: format_endpoint(endpoint), opts: opts}
  end

  defp format_endpoint(endpoint) do
    if String.ends_with?(endpoint, "/") do
      endpoint
    else
      endpoint <> "/"
    end
  end

end
