defmodule ExAws.SNS.Application do
  use Application
  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ExAws.SNS.PublicKeyCache, [[name: ExAws.SNS.PublicKeyCache]]),
    ]

    opts = [strategy: :one_for_one, name: ExAws.SNS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
