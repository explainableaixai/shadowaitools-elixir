defmodule ShadowAITools.Client do
  @moduledoc "Client for Shadow AI Tools."
  defstruct [:api_key, :base_url]

  def new(api_key, opts \\ []) when is_binary(api_key) and byte_size(api_key) > 0,
    do: %__MODULE__{
      api_key: api_key,
      base_url:
        Keyword.get(opts, :base_url, "https://www.aitoolsblocklist.com/api")
        |> String.trim_trailing("/")
    }

  defp request(client, value) when is_binary(value) and byte_size(value) > 0 do
    case Req.get(client.base_url <> "/check",
           params: %{"domain" => value},
           headers: [{"x-api-key", client.api_key}]
         ) do
      {:ok, %Req.Response{status: s, body: body}} when s in 200..299 -> {:ok, body}
      {:ok, %Req.Response{status: s, body: body}} -> {:error, {:api_error, s, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def check(client, domain), do: request(client, domain)

  def scan(client, path) do
    path
    |> File.read!()
    |> String.split(~r/[\s,;]+/, trim: true)
    |> Enum.map(fn value ->
      uri = URI.parse(if String.contains?(value, "://"), do: value, else: "https://" <> value)
      uri.host
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.map(&check(client, &1))
  end
end
