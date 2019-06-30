defmodule Pseudoloc.MixProject do
  use Mix.Project

  @version "0.2.1"

  def project do
    [
      app: :pseudoloc,
      description: "A library and Mix task for pseudolocalizing Gettext translation files",
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:excoveralls, "~> 0.11", only: :test},
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

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Lee Dohm"],
      links: %{"GitHub" => "https://github.com/lee-dohm/pseudoloc"}
    ]
  end
end
