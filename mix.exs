defmodule Abex.MixProject do
  use Mix.Project

  def project do
    [
      app: :abex,
      version: "0.2.1",
      elixir: "~> 1.9",
      name: "ABex",
      description: description(),
      package: package(),
      source_url: "https://github.com/valiot/abex",
      start_permanent: Mix.env() == :prod,
      compilers: [:cmake] ++ Mix.compilers(),
      docs: [extras: ["README.md"], main: "readme"],
      build_embedded: true,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "Elixir wrapper for Libplctag, for communication with Allen-Bradley PLC's."
  end

  defp package() do
    [
      files: [
        "lib",
        "src/*.c",
        "src/libplctag/libplctag.pc.in",
        "src/libplctag/src",
        "CMakeLists.txt",
        "test",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      maintainers: ["valiot"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/valiot/abex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # it requires an update to elixir_cmake hex dependency
      {:elixir_cmake, "~> 0.8"},
      {:ex_doc, "~> 0.28", only: :dev},
      {:muontrap, "~> 1.2"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
