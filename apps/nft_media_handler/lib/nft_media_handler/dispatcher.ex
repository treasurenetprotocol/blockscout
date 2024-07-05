defmodule NFTMediaHandler.Dispatcher do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_media_to_fetch({_token_address_hash, _token_id, _media_url} = data_to_fetch) do
    GenServer.cast(__MODULE__, {:add_to_queue, data_to_fetch})
  end

  def init(_) do
    Process.send(self(), :spawn_tasks)
    GenServer.cast(__MODULE__, :spawn_tasks)
    {:ok, %{max_concurrency: 10, current_concurrency: 0, batch_size: 1, waiting_timeout: 100}}
  end

  def handle_info(:spawn_tasks, %{max_concurrency: max_concurrency, current_concurrency: current_concurrency})
      when max_concurrency > current_concurrency do
    to_spawn = max_concurrency - current_concurrency
    batch_size = batch_size()
    # urls =
    (batch_size * to_spawn)
    |> NFTMediaHandlerDispatcherInterface.get_urls()
    |> Enum.chunk_every(batch_size)
    |> Enum.map(&run_task/1)
    |> Task.await_many(:infinity)
  end

  # replace Task.await_many(:infinity) with handle_info(...)

  defp run_task(batch),
    do:
      Task.async(fn ->
        Enum.map(batch, fn url ->
          NFTMediaHandler.prepare_and_upload_by_url(url) |> NFTMediaHandlerDispatcherInterface.store_result()
        end)
      end)

  defp batch_size(), do: 1
end
