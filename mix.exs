defmodule SQLite.MixProject do
  use Mix.Project

  def project do
    [
      app: :sqlite,
      version: "0.1.0",
      elixir: "~> 1.15",
      compilers: [:elixir_make | Mix.compilers()],
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
      {:benchee, "~> 1.1", only: [:bench]},
      {:exqlite, "~> 0.14.0", only: [:bench]},
      {:elixir_make, "~> 0.7", runtime: false}
    ]
  end
end
