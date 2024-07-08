defmodule NFTMediaHandler.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Task.Supervisor, name: NFTMediaHandler.TaskSupervisor}, id: NFTMediaHandler.TaskSupervisor),
      NFTMediaHandler.Dispatcher
    ]

    opts = [strategy: :one_for_one, name: NFTMediaHandler.Supervisor, max_restarts: 1_000]

    Supervisor.start_link(children, opts)
  end
end
