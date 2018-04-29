defmodule Outkit.Message do
  @moduledoc """
  This module lets you render/send or retrieve a message using
  Outkit’s API.

  ## Example

      # Create a message
      {:ok, message} = Outkit.Message.create(%{
        type: "email",                   # Message type - 'email' and 'sms' currently supported
        project: "my-project",           # Outkit project identifier (managed through our web UI)
        template: "my-template",         # Template identifier (managed through our web UI)
        subject: "Welcome, Jane!",       # Email subject (optional, can also be set in the template or omitted for SMS messages)
        to: "some.name@example.com",     # Recipient address (and optional name)
        from: "other.name@example.com",  # Sender address (and optional name)
        data: %{
            name: "John Doe",
            # ...
            # Add the values for any variables used in the template here
        },
      })

      # Retrieve a message
      {:ok, message} = Outkit.Message.get("some-id")

  """
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
    :id_from_submitter,
    :id_from_backend,
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
    :done
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
    :id_from_submitter,
    :to,
    :from,
    :render_only,
    :sync,
    :no_send,
    :test
  ]

  @doc """
  Creates a new Outkit.Message struct. Mostly used indirectly through the `get` and 
  `create` functions.

  ## Examples

      new(%{
        type: "email",
        project: "acme-project",
        template: "welcome",
      })

  """
  def new(message) when is_map(message) do
    Outkit.to_struct(__MODULE__, message)
  end

  @doc """
  Retrieve a message using an Outkit.Client and an id.

  ## Examples

      client = Outkit.Client.new(key: "my-key", secret: "my-secret", passphrase: "my-passphrase")
      get(client, "some-id")

  """
  def get(%Client{} = client, id) when is_binary(id), do: do_get(client, id)

  @doc """
  Retrieve a message using an id. The client will be derived from your configuration.

  ## Examples

      get("some-id")

  """
  def get(id) when is_binary(id), do: do_get(Outkit.client_from_config(), id)

  @doc """
  Create a message based on an Outkit.Message. Uses an Outkit.Client.

  ## Examples

      client = Outkit.Client.new(key: "my-key", secret: "my-secret", passphrase: "my-passphrase")
      message = Outkit.Message.new(%{
        type: "email",
        project: "acme-project",
        template: "welcome",
      })
      create(client, message)

  """
  def create(%Client{} = client, %Message{} = message), do: do_create(client, message)

  @doc """
  Create a message based on a map. Uses an Outkit.Client.

  ## Examples

      client = Outkit.Client.new(key: "my-key", secret: "my-secret", passphrase: "my-passphrase")
      create(client, %{
        type: "email",
        project: "acme-project",
        template: "welcome",
      })

  """
  def create(%Client{} = client, message) when is_map(message),
    do: do_create(client, new(message))

  @doc """
  Create a message based on an Outkit.Message. The client will be derived from your configuration.

  ## Examples

      message = Outkit.Message.new(%{
        type: "email",
        project: "acme-project",
        template: "welcome",
      })
      create(message)

  """
  def create(%Message{} = message), do: do_create(Outkit.client_from_config(), message)

  @doc """
  Create a message based on a map. The client will be derived from your configuration.

  ## Examples

      create(%{
        type: "email",
        project: "acme-project",
        template: "welcome",
      })

  """
  def create(message) when is_map(message),
    do: do_create(Outkit.client_from_config(), new(message))

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
