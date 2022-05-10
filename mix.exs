defmodule Ubuntu.MixProject do
  use Mix.Project

  def project do
    [
      app: :ubuntu,
      version: "20.4.0",
      elixir: "~> 1.12",
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
      {:dialyxir, "~> 1.1.0", [runtime: false]},
      {:doma_witchcraft, "~> 1.0.4-doma"},
      {:doma_algae, "~> 1.3.1-doma"},
      {:doma_quark, "~> 2.3.2-doma2"},
      {:uptight, "~> 0.1.0-pre"}
    ]
  end
end
