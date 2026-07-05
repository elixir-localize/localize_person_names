defmodule LocalizePersonNames.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :localize_person_names,
      version: @version,
      name: "Localize Person Names",
      source_url: "https://github.com/elixir-localize/localize_person_names",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore_warnings"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Locale-aware person name formatting built on the Unicode CLDR " <>
      "person names specification."
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  defp links do
    %{
      "GitHub" => "https://github.com/elixir-localize/localize_person_names",
      "Readme" =>
        "https://github.com/elixir-localize/localize_person_names/blob/main/README.md",
      "Changelog" =>
        "https://github.com/elixir-localize/localize_person_names/blob/main/CHANGELOG.md"
    }
  end

  defp docs do
    [
      source_ref: "main",
      main: "readme",
      extras:
        [
          "README.md",
          "LICENSE.md"
        ] ++ Path.wildcard("guides/*.md"),
      formatters: ["html", "markdown"],
      groups_for_modules: groups_for_modules(),
      groups_for_extras: groups_for_extras(),
      skip_undefined_reference_warnings_on: ["conformance.md"] ++ Path.wildcard("guides/*.md")
    ]
  end

  defp groups_for_modules do
    [
      "External Struct Integration": [
        Localize.PersonName.Convertible
      ],
      "Message Formatting": [
        Localize.PersonName.MF2
      ],
      Exceptions: [
        Localize.PersonNameError
      ]
    ]
  end

  defp groups_for_extras do
    [
      Guides: Path.wildcard("guides/*.md")
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:localize, "~> 0.13"},
      {:unicode_string, "~> 2.0"},
      {:ex_doc, "~> 0.34", optional: true, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ] ++ maybe_json_polyfill()
  end

  defp maybe_json_polyfill do
    if Code.ensure_loaded?(:json) do
      []
    else
      [{:json_polyfill, "~> 0.2 or ~> 1.0"}]
    end
  end
end
