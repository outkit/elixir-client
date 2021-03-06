defmodule Outkit do
  @moduledoc """
  Interface to Outkit's API.

  ## Configuration

  A configuration key is expected with a set of working Outkit API credentials.

      config :outkit,
        key: "outkit_api_key",
        secret: "outkit_api_secret",
        passphrase: "outkit_api_passphrase"

  ## Usage

  This library is primarily used to render and/or send messages. Refer to `Outkit.Message` for full
  documentation and usage.
  """

  @doc """
  Assembles configuration data and creates a new Outkit.Client. This is used throughout
  the client library for functions that do not take an Outkit.Client as the first
  argument.

  ## Examples

      client = client_from_config()

  """
  def client_from_config do
    key = api_key()
    secret = api_secret()
    passphrase = api_passphrase()
    auth_config = [key: key, secret: secret, passphrase: passphrase]
    endpoint = Application.get_env(:outkit, :endpoint)

    endpoint_config =
      case is_nil(endpoint) do
        true ->
          auth_config

        false ->
          Keyword.merge(auth_config, endpoint: endpoint)
      end

    opts = Application.get_env(:outkit, :opts)

    config =
      case is_nil(opts) do
        true ->
          endpoint_config

        false ->
          Keyword.merge(endpoint_config, opts: opts)
      end

    Outkit.Client.new(config)
  end

  defp api_key do
    key = Application.get_env(:outkit, :key)

    unless key do
      raise RuntimeError, """
      No API key is configured for Outkit. Update your config before making an API call.
          config :outkit,
            key: "outkit_api_key",
            secret: "outkit_api_secret",
            passphrase: "outkit_api_passphrase"
      """
    end

    key
  end

  defp api_secret do
    secret = Application.get_env(:outkit, :secret)

    unless secret do
      raise RuntimeError, """
      No API secret is configured for Outkit. Update your config before making an API call.
          config :outkit,
            key: "outkit_api_key",
            secret: "outkit_api_secret",
            passphrase: "outkit_api_passphrase"
      """
    end

    secret
  end

  defp api_passphrase do
    passphrase = Application.get_env(:outkit, :passphrase)

    unless passphrase do
      raise RuntimeError, """
      No API passphrase is configured for Outkit. Update your config before making an API call.
          config :outkit,
            key: "outkit_api_key",
            secret: "outkit_api_secret",
            passphrase: "outkit_api_passphrase"
      """
    end

    passphrase
  end

  def to_struct(kind, attrs) do
    struct = struct(kind, attrs)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end

  def format_response(client, result, module) do
    case result do
      {:ok, response} ->
        case Keyword.get(client.opts, :return_response) do
          true ->
            {:ok, response}

          _ ->
            {:ok, module.new(response.body["data"])}
        end

      {:error, err} ->
        {:error, err}
    end
  end
end
