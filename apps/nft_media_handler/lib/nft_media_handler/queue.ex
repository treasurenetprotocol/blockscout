defmodule NFTMediaHandler.Queue do
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
  # use Agent

  # def start_link(_) do
  #   Agent.start_link(fn -> %{} end, name: __MODULE__)
  # end

  # def value() do
  #   Agent.get(__MODULE__, & &1)
  # end

  # def add_task({token_address_hash, token_id, media_url}) do
  #   Agent.update(__MODULE__, fn current_map ->
  #     Map.put(current_map, {token_address_hash, token_id}, media_url)
  #   end)
  # end

  # def get_task do
  #   Agent.get_and_update(__MODULE__, fn current_map ->
  #     [key | _] = Map.keys(current_map)
  #     Map.pop(current_map, key)
  #   end)
  # end

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_media_to_fetch({_token_address_hash, _token_id, _media_url} = data_to_fetch) do
    GenServer.cast(__MODULE__, {:add_to_queue, data_to_fetch})
  end

  def init(_) do
    {:ok, table} = :dets.open_file(:queue_storage, type: :bag)
    {:ok, table}
  end

  def handle_cast({:add_to_queue, {token_address_hash, token_id, media_url}}, table) do
    :dets.insert(table, {media_url, {token_address_hash, token_id}})
    {:noreply, table}
  end

  def handle_call({:get_by_url, url}, _from, table) do
    {:reply, :dets.lookup(table, url), table}
  end

  def handle_call({:drop_url, url}) do
  end
end
