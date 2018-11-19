defmodule Vapor.Config.File do
  defstruct path: nil, format: nil

  def with_name(name) do
    %__MODULE__{path: name, format: format(name)}
  end

  defp format(path) do
    case Path.extname(path) do
      "" ->
        raise Vapor.FileFormatNotFoundError, path

      ".json" ->
        :json
    end
  end

  defimpl Vapor.Provider do
    def load(%{path: path, format: format}) do
      case File.read(path) do
        {:ok, str} ->
          case format do
            :json ->
              Jason.decode(str)
          end

        {:error, _} ->
          raise Vapor.FileNotFoundError, path
      end
    end
  end
end
