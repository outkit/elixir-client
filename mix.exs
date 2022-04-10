defmodule Outkit.Mixfile do
  use Mix.Project

  @source_url "https://github.com/outkit/elixir-client"
  @version "0.0.5"

  @description """
    Outkit Elixir client
  """

  def project do
    [
      app: :outkit,
      version: @version,
      elixir: "~> 1.0",
      name: "Outkit",
      description: @description,
      source_url: "https://github.com/outkit/elixir-client",
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:httpoison, :jason]]
  end

  defp deps do
    [
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      maintainers: ["Stian Grytøyr"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "Outkit",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/outkit",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE"]
    ]
  end
end
