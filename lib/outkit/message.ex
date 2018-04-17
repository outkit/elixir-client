defmodule Outkit.Message do

  defstruct [
    :project,
    :template,
    :backend,
    :project_id,
    :template_id,
    :backend_id,
    :type,
    :team_id,
    :team_backend_id,
    :api_key_id,
    :client_id,
    :backend_supplied_id,
    :public_id,
    :subject,
    :text_body,
    :html_body,
    :to,
    :from,
    :data,
    :render_only,
    :sync,
    :no_send,
    :status,
    :status_message,
    :queued_for_rendering_at,
    :queued_for_delivery_at,
    :rendered_at,
    :delivered_at,
    :failed_at,
    :backend_response,
    :test,
    :done,
  ]

  alias __MODULE__
  alias Outkit.Client
  alias Outkit.HttpClient

  @settable_keys [
    :type,
    :template,
    :project,
    :backend,
    :subject,
    :text_body,
    :html_body,
    :client_id,
    :to,
    :from,
    :render_only,
    :sync,
    :no_send,
    :test,
  ]

  def new(message) when is_map(message) do
    Outkit.to_struct(__MODULE__, message)
  end

  def get(%Client{} = client, id) when is_binary(id), do: do_get(client, id)
  def get(id) when is_binary(id), do: do_get(Outkit.client_from_config, id)

  def create(%Client{} = client, %Message{} = message), do: do_create(client, message)
  def create(%Client{} = client, message) when is_map(message), do: do_create(client, new(message))
  def create(%Message{} = message), do: do_create(Outkit.client_from_config(), message)
  def create(message) when is_map(message), do: do_create(Outkit.client_from_config(), new(message))

  defp do_get(client, id) do
    result = HttpClient.do_request(client, :get, "/messages/" <> id)
    Outkit.format_response(client, result, __MODULE__)
  end

  defp do_create(client, message) do
    clean_message = Map.delete(Map.from_struct(message), :__meta__)
    all_keys = Map.keys(%__MODULE__{}) |> List.delete(:__struct__)
    non_settable_keys = all_keys -- @settable_keys
    settable_message = Map.drop(clean_message, non_settable_keys)
    result = HttpClient.do_request(client, :post, "/messages", %{message: settable_message})
    Outkit.format_response(client, result, __MODULE__)
  end

end
