defmodule Vapor.Mixfile do
  use Mix.Project

  def project do
    [
      app: :vapor,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Vapor",
      source_url: "https://github.com/keathley/vapor",
      dialyzer: [
        ignore_warnings: "dialyzer.ignore-warnings",
        plt_file: {:no_warn, "priv/plts/vapor.plt"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # normal dependencies
      {:jason, "~> 1.1"},
      {:toml, "~> 0.3"},
      {:yaml_elixir, "~> 2.1"},
      # dev and test dependencies
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description do
    "Dynamic configuration management"
  end

  defp package do
    [
      name: "vapor",
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Chris Keathley", "Jeff Weiss", "Ben Marx"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/keathley/vapor"}
    ]
  end
end
