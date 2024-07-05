defmodule NFTMediaHandlerDispatcherInterface do
  @moduledoc """
  Documentation for `NftMediaHandlerDispatcherInterface`.
  """

  def get_urls(amount) do
    remote_call([amount], :get_urls_to_fetch, Application.get_env(:nft_media_handler, :remote?))
  end

  def store_result(result) do
    remote_call([result], :store_result, Application.get_env(:nft_media_handler, :remote?))
  end

  def remote_node do
    Application.get_env(:nft_media_handler, :dispatcher_node)
  end

  defp remote_call(args, function, true) do
    :rpc.call(remote_node(), NFTMediaHandlerDispatcher.Queue, function, args)
  end

  defp remote_call(args, function, false) do
    apply(NFTMediaHandlerDispatcher.Queue, function, args)
  end
end
