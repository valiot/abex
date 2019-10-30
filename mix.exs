defmodule Abex.MixProject do
  use Mix.Project

  def project do
    #elixir cmake should put compile as default path.
    System.put_env("MIX_COMPILE_PATH", Mix.Project.compile_path(build_per_environment: true, app: :abex))
    [
      app: :abex,
      version: "0.1.0",
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
        "src",
        "src/libplctag",
        "src/libplctag/src",
        "test",
        "mix.exs",
        "README.md",
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
      {:elixir_cmake, "~> 0.1.0"},
      {:muontrap, "~> 0.5.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
