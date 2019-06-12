defmodule Pseudoloc.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :pseudoloc,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:gettext, "~> 0.16"},
      {:cmark, "~> 0.7", only: [:dev, :test]},
      {:credo, "~> 1.1", only: :dev},
      {:ex_doc, "~> 0.20", only: [:dev, :test], runtime: false},
      {:version_tasks, "~> 0.11", only: :dev}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "CODE_OF_CONDUCT.md",
        "CONTRIBUTING.md",
        "README.md": [
          filename: "readme",
          title: "README"
        ],
        "LICENSE.md": [
          filename: "license",
          title: "License"
        ]
      ]
    ]
  end
end
