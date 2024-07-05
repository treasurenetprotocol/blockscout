defmodule NftMediaHandlerInterface do
  @moduledoc """
  Documentation for `NftMediaHandlerInterface`.
  """

  def put_new_url_in_que({_token_address_hash, _token_id, _media_url} = payload) do
    remote_call([payload], :add_media_to_fetch, Application.get_env(:nft_media_handler_interface, :remote?))
  end

  def remote_node do
    Application.get_env(:nft_media_handler_interface, :node)
  end

  defp remote_call(args, function, true) do
    :rpc.call(remote_node(), NFTMediaHandler.Queue, function, args)
  end

  defp remote_call(args, function, false) do
    apply(NFTMediaHandler.Queue, function, args)
  end
end
