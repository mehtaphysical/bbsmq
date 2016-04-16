defmodule Bbsmq.Mixfile do
  use Mix.Project

  def project do
    [app: :bbsmq,
     version: "0.0.5",
     elixir: "~> 1.2",
     description: description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger],
      mod: {BBSMq, []}]
  end

  defp deps do
    [
      {:amqp, "0.1.4"},
      {:exprotobuf, "~> 1.0.0"},
      {:httpoison, "~> 0.8.0"},
      { :uuid, "~> 1.1" },
      {:poison, "~> 2.0"}
    ]
  end

  defp description do
  """
  Translate CloudFoundry BBS events and endpoints into rabbitmq messages.
  """
end

defp package do
  [
   files: ["lib", "mix.exs", "README*"],
   maintainers: ["Ryan Mehta"],
   links: %{"GitHub" => "https://github.com/mehtaphysical/bbsmq"}
  ]
end

end
