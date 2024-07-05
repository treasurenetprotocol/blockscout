defmodule NFTMediaHandler.Results do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch({_token_address_hash, _token_id, media_url}) do
    GenServer.cast(__MODULE__, {:fetch, media_url})
  end

  def init(_) do
    {:ok, table} = :dets.open_file(:results_storage, type: :bag)
    {:ok, table}
  end

  def handle_cast({:fetch, url}) do
    NFTMediaHandler.prepare_and_upload_by_url(url)
  end
end
