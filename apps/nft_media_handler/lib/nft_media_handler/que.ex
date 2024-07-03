defmodule NFTMediaHandler.Que do
  @moduledoc """
  Queue for fetching media
  """

  use GenServer

  def fetch(url) do
    GenServer.cast(__MODULE__, {:fetch, url})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def handle_cast({:fetch, url}) do
    NFTMediaHandler.prepare_and_upload_by_url(url)
  end
end
