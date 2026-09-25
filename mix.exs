defmodule ShadowAITools.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :shadowaitools,
      version: "1.0.1",
      elixir: "~> 1.14",
      description: "Elixir client for Shadow AI Tools.",
      package: package(),
      deps: deps(),
      docs: [main: "readme", extras: ["README.md"]],
      source_url: "https://github.com/explainableaixai/shadowaitools-elixir",
      homepage_url: "https://www.shadowaitools.com"
    ]

  def application, do: [extra_applications: [:logger]]
  defp deps, do: [{:req, "~> 0.5"}, {:ex_doc, "~> 0.34", only: :dev, runtime: false}]

  defp package,
    do: [
      licenses: ["MIT"],
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE),
      links: %{
        "Homepage" => "https://www.shadowaitools.com",
        "GitHub" => "https://github.com/explainableaixai/shadowaitools-elixir"
      }
    ]
end
