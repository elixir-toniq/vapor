defmodule Vapor.Mixfile do
  use Mix.Project

  @source_url "https://github.com/keathley/vapor"
  @version "0.10.0"

  def project do
    [
      app: :vapor,
      version: @version,
      name: "Vapor",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix]]
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
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "vapor",
      description: "Dynamic configuration management",
      maintainers: ["Chris Keathley", "Jeff Weiss", "Ben Marx"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  def docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
