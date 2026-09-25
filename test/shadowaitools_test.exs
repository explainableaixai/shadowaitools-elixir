defmodule ShadowAIToolsTest do
  use ExUnit.Case

  test "constructs a client" do
    client = ShadowAITools.Client.new("test")
    assert client.api_key == "test"
  end
end
