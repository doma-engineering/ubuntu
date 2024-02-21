defmodule Ubuntu.MixProject do
  use Mix.Project

  def project do
    [
      app: :ubuntu,
      version: "20.4.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:uptight, github: "doma-engineering/uptight", branch: "main"},
      {:quark_goo, github: "doma-engineering/quark-goo", branch: "main"},
      {:algae_goo, github: "doma-engineering/algae-goo", branch: "main"},
      {:witchcraft_goo, github: "doma-engineering/witchcraft-goo", branch: "main"}
    ]
  end
end
