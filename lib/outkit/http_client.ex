defmodule Outkit.HttpClient do
  @moduledoc """
  This module fascilitates communication with the HTTP API endpoints.

  It is typically not used directly, but you can if you want.

  ## Example

      # Perform a GET request to retrieve a message
      {:ok, response} = Outkit.HttpClient.do_request(client, :get, "/messages/" <> id)

      # Perform a POST request to create a message
      {:ok, response} = Outkit.HttpClient.do_request(client, :post, "/messages", %{message: message})

  """

  @doc """
  Perform an HTTP request against an Outkit API endpoint. 

  Requires an Outkit.Client as the first argument.

  ## Examples

      do_request(client, :post, "/messages", %{message: message})

  """
  def do_request(client, method, uri_fragment, native_body \\ nil) do
    uri = uri(client, uri_fragment)

    body =
      case is_nil(native_body) do
        true -> ""
        false -> encode_body(native_body)
      end

    headers = headers(client, method, uri, body)

    response =
      case method do
        :get ->
          HTTPoison.get(uri, headers)

        :post ->
          HTTPoison.post(uri, body, headers)
      end

    process_response(response)
  end

  defp uri(client, fragment) do
    client.endpoint <> String.replace(fragment, ~r'^/', "")
  end

  defp encode_body(native_body) do
    Poison.encode!(native_body)
  end

  defp headers(client, method, uri, body) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
    uri_parts = URI.parse(uri)

    path =
      case is_nil(uri_parts.query) do
        true -> uri_parts.path
        false -> uri_parts.path <> "?" <> uri_parts.query
      end

    payload = timestamp <> method_to_string(method) <> path <> body
    signature = compute_signature(client.secret, payload)

    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"User-Agent", "outkit-elixir-client"},
      {"Outkit-Access-Key", client.key},
      {"Outkit-Access-Signature", signature},
      {"Outkit-Access-Timestamp", timestamp},
      {"Outkit-Access-Passphrase", client.passphrase}
    ]
  end

  defp compute_signature(secret, payload) do
    :crypto.hmac(:sha256, secret, payload)
    |> Base.encode64()
  end

  defp method_to_string(method) do
    case method do
      :get -> "GET"
      :post -> "POST"
      :put -> "PUT"
      :patch -> "PATCH"
      :delete -> "DELETE"
    end
  end

  defp process_response(raw_resp) do
    case raw_resp do
      {:ok, raw_response} ->
        response = %{
          status_code: raw_response.status_code,
          raw_body: raw_response.body,
          headers: raw_response.headers
        }

        case String.starts_with?(Integer.to_string(response.status_code), "2") do
          true ->
            {:ok, add_parsed_body(response)}

          false ->
            {:error, :api_error, "Got a #{response.status_code} error", response}
        end

      {:error, _err} ->
        {:error, :network_issue, "There was a network issue when trying to talk to the API."}
    end
  end

  defp add_parsed_body(response) do
    case response.raw_body === "" do
      true ->
        response

      false ->
        Map.merge(response, %{body: Poison.decode!(response.raw_body)})
    end
  end
end
