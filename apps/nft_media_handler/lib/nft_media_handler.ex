defmodule NFTMediaHandler do
  @moduledoc """
  Module resizes and uploads images to R2/S3 bucket.
  """

  require Logger

  alias Image.Video
  alias NFTMediaHandler.Media.Fetcher
  alias NFTMediaHandler.Image.Resizer
  alias NFTMediaHandler.R2.Uploader
  alias Vix.Vips.Image, as: VipsImage

  def prepare_and_upload_by_url(url) do
    with {:ok, media_type, body} <- Fetcher.fetch_media(url) do
      prepare_and_upload_inner(media_type, body, url)
    else
      {:error, reason} ->
        Logger.warning("Error on fetching media: #{inspect(reason)}, from url (#{url})")
        :error
    end
  end

  def prepare_and_upload_inner({"image", _} = media_type, body, url) do
    with {:image, {:ok, image}} <- {:image, Image.from_binary(body, pages: -1)} do
      extension = media_type_to_extension(media_type)

      thumbnails = Resizer.resize(image, url, ".#{extension}")

      uploaded_thumbnails =
        Enum.map(thumbnails, fn {size, image, file_name} ->
          with {:ok, _result, uploaded_file_url} <- Uploader.upload_image(image, file_name) do
            {size, uploaded_file_url}
          else
            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.into(%{})

      uploaded_original_url =
        with file_name = Resizer.generate_file_name(url, ".#{extension}", "original"),
             {:ok, binary} <- image_to_binary(image, file_name, ".#{extension}"),
             {:ok, _result, uploaded_file_url} <-
               Uploader.upload_image(binary, Resizer.generate_file_name(url, ".#{extension}", "original")) do
          uploaded_file_url
        else
          _ ->
            nil
        end

      max_size_or_original =
        uploaded_original_url ||
          (
            {_, url} =
              Enum.max_by(uploaded_thumbnails, fn {size, _} ->
                {int_size, _} = Integer.parse(size)
                int_size
              end)

            url
          )

      Enum.reduce(Resizer.sizes(), uploaded_thumbnails, fn {_, size}, acc ->
        if Map.has_key?(acc, size) do
          acc
        else
          Map.put(acc, size, max_size_or_original)
        end
      end)
      |> Map.put("original", uploaded_original_url)
    else
      {:image, {:error, reason}} ->
        Logger.warning("Error on open image from url (#{url}): #{inspect(reason)}")
        :error
    end
  end

  def prepare_and_upload_inner({"video", _} = media_type, body, url) do
    extension = media_type_to_extension(media_type)
    file_name = Resizer.generate_file_name(url, ".#{extension}", "original")
    path = "#{Application.get_env(:nft_media_handler, :tmp_dir)}#{file_name}"

    with {:file, :ok} <- {:file, File.write(path, body)},
         {:ok, image} <-
           Video.with_video(path, fn video ->
             Video.image_from_video(video, frame: 0)
           end) do
      remove_file(path)
      thumbnails = Resizer.resize(image, url, ".jpg")

      Enum.map(thumbnails, fn {size, image, file_name} ->
        with {:ok, _result, uploaded_file_url} <- Uploader.upload_image(image, file_name) do
          {size, uploaded_file_url}
        else
          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})
    else
      {:file, reason} ->
        Logger.error("Error while writing video to file: #{inspect(reason)}, url: #{url}")
        :error

      {:error, reason} ->
        Logger.error("Error while taking zero frame from video: #{inspect(reason)}, url: #{url}")
        File.rm(path)
        :error
    end
  end

  defp media_type_to_extension({type, subtype}) do
    [extension | _] = MIME.extensions("#{type}/#{subtype}")
    extension
  end

  defp generate_file_name(image_name, size \\ "original") do
    "#{image_name}_#{size}.jpg"
  end

  def image_to_binary(resized_image, _file_name, extension) when extension in [".jpg", ".png"] do
    VipsImage.write_to_buffer(resized_image, "#{extension}[Q=75,strip]")
  end

  # workaround, because VipsImage.write_to_buffer/2 does not support .gif
  def image_to_binary(resized_image, file_name, ".gif") do
    path = "#{Application.get_env(:nft_media_handler, :tmp_dir)}#{file_name}.gif"
    VipsImage.write_to_file(resized_image, path)
    result = File.read(path)
    remove_file(path)
    result
  end

  defp remove_file(path) do
    with :ok <- File.rm(path) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Unable to delete file, reason: #{inspect(reason)}, path: #{path}")
        :error
    end
  end
end
