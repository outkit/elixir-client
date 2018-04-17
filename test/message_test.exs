defmodule Outkit.MessageTest do

  use ExUnit.Case
  alias Outkit.Message

  doctest Outkit.Message

  setup_all do
    Application.put_env :outkit, :key, "sQngiw9hp5Ag4rL89oqkBBb3Czz4gqb5KW899y3IkblSB-a_"
    Application.put_env :outkit, :secret, "Y29SOVz4L_bD8O8_Ja5-GX-lChrcM0JmxXePD2bflz0fG4_Z-ADfD8UmF2XzEEW8"
    Application.put_env :outkit, :passphrase, "uff0tdcxmhlhts1213dq0n4vmcjl9t"
    Application.put_env :outkit, :endpoint, "http://localhost:4990/v1"
    Application.put_env :outkit, :opts, []
  end
  
  test "getting a message" do
    assert %Message{done: true} = Message.get("78545bb5-fd3c-4566-9d92-02f8e9c4ad03")
  end

  test "creating a message" do
    message = Message.new(%{
      type: "email",
      template: "welcome",
      project: "outkit",
      to: "some.email@example.com",
      no_send: true,
    })
    assert %Message{done: false} = Message.create(message)
  end

end
