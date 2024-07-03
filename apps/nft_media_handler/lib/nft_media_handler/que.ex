defmodule NFTMediaHandler.Que do
  @moduledoc """
  Queue for fetching media
  """

  # use GenServer

  # def fetch({_token_address_hash, _token_id, media_url}) do
  #   GenServer.cast(__MODULE__, {:fetch, media_url})
  # end

  # def start_link(_) do
  #   GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  # end

  # def init(_) do
  #   {:ok, []}
  # end

  # def handle_cast({:fetch, url}) do
  #   NFTMediaHandler.prepare_and_upload_by_url(url)
  # end
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def value() do
    Agent.get(__MODULE__, & &1)
  end

  def add_task({token_address_hash, token_id, media_url}) do
    Agent.update(__MODULE__, fn current_map ->
      Map.put({token_address_hash, token_id}, media_url)
    end)
  end

  def get_task do
    Agent.get_and_update(__MODULE__, fn current_map ->
      [key | _] = Map.keys(current_map)
      Map.pop(current_map, key)
    end)
  end
end
