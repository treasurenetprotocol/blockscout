defmodule NftMediaHandlerInterface do
  @moduledoc """
  Documentation for `NftMediaHandlerInterface`.
  """

  def put_new_url_in_que({_token_address_hash, _token_id, _media_url} = payload) do
    remote_call(payload, Application.get_env(:nft_media_handler_interface, :remote?))
  end

  def remote_node do
    Application.get_env(:nft_media_handler_interface, :node)
  end

  defp remote_call({_token_address_hash, _token_id, _media_url} = arg, true) do
    :rpc.call(remote_node(), NFTMediaHandler.Que, :fetch, [arg])
  end

  defp remote_call({_token_address_hash, _token_id, _media_url} = arg, false) do
    apply(NFTMediaHandler.Que, :fetch, [arg])
  end
end
