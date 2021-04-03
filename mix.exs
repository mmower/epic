defmodule Epic.MixProject do
  use Mix.Project

  def project do
    [
      app: :epic,
      version: "0.2.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Epic",
      description: description(),
      package: package(),
      source_url: "https://github.com/mmower/epic",
      docs: [main: "README", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "Epic is an Elixir parser combinator library."
  end

  def package do
    [
      name: "epic",
      licenses: ["Apache-2.0"],
      links: %{"Github" => "https://github.com/mmower/epic"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev},
      {:mix_test_watch, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
