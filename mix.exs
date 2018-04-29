defmodule Outkit.Mixfile do
  use Mix.Project

  @description """
    Outkit Elixir client
  """

  def project do
    [
      app: :outkit,
      version: "0.0.2",
      elixir: "~> 1.0",
      name: "Outkit",
      description: @description,
      source_url: "https://github.com/outkit/elixir-client",
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:httpoison, :poison]]
  end

  defp deps do
    [{:httpoison, "~> 0.8"}, {:poison, "~> 3.1"}, {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [
      maintainers: ["Stian Grytøyr"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/outkit/elixir-client"}
    ]
  end
end
