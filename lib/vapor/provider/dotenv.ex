defmodule Vapor.Provider.Dotenv do
  @moduledoc """
  The dotenv config provider will look for a `.env` file and load all of
  the values for that file. The values can be written like so:

  ```
  DATABASE_URL=https://localhost:9432
  PORT=4000
  REDIS_HOST=1234
  ```

  If the file can't be found then this provider will still return an ok but
  will (obviously) not load any configuration values. The primary use case for
  this provider is local development where it might be inconvenient to add all
  of the necessary environment variables on your local machine and it makes
  tradeoffs for that use case.
  """
  defstruct filename: ".env"

  def default do
    %__MODULE__{}
  end

  def with_file(file) do
    %__MODULE__{filename: file}
  end

  defimpl Vapor.Provider do
    def load(%{filename: filename}) do
      case File.read(filename) do
        {:ok, contents} ->
          {:ok, parse(contents)}

        _ ->
          {:ok, %{}}
      end
    end

    defp parse(contents) do
      contents
      |> String.split(~r/\n/, trim: true)
      |> Enum.reject(&comment?/1)
      |> Enum.map(fn pair -> String.split(pair, "=") end)
      |> Enum.filter(&good_pair/1)
      |> Enum.map(fn [key, value] -> {String.trim(key), String.trim(value)} end)
      |> Enum.map(fn {key, value} -> {normalize(key), value} end)
      |> Enum.into(Map.new())
    end

    defp comment?(line) do
      Regex.match?(~R/\A\s*#/, line)
    end

    defp good_pair(pair) do
      case pair do
        [key, value] ->
          String.length(key) > 0 && String.length(value) > 0

        _ ->
          false
      end
    end

    defp normalize(str) do
      str
      |> String.downcase()
      |> String.split("_")
    end
  end
end
