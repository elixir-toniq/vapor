defmodule Vapor.Mixfile do
  use Mix.Project

  @version "0.10.0"

  def project do
    [
      app: :vapor,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Vapor",
      source_url: "https://github.com/keathley/vapor",
      docs: docs(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:sasl, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # normal dependencies
      {:jason, "~> 1.1"},
      {:toml, "~> 0.3"},
      {:yaml_elixir, "~> 2.1"},
      {:norm, "~> 0.9"},

      # dev and test dependencies
      {:credo, "~> 1.0", only: [:dev]},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description do
    "Dynamic configuration management"
  end

  defp package do
    [
      name: "vapor",
      maintainers: ["Chris Keathley", "Jeff Weiss", "Ben Marx"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/keathley/vapor"}
    ]
  end

  def docs do
    [
      main: "Vapor",
      source_ref: "v#{@version}",
      source_url: "https://github.com/keathley/vapor",
    ]
  end
end
