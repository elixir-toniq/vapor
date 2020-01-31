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

  ## Existing environment variables

  By default the dotenv provider won't overwrite any existing environment variables.
  You can change this by setting the `overwrite` key to `true`:

      %Dotenv{overwrite: true}

  ## File heirarchy

  If no file is specified then the dotenv provider will load these files in this
  order. Each proceeding file is loaded over the previous. In these examples `ENV`
  will be the current mix environment: `dev`, `test`, or `prod`.

  * `.env`
  * `.env.ENV`
  * `.env.local`
  * `.env.ENV.local`

  You should commit `.env` and `.env.ENV` files to your project and ignore any
  `.local` files. This allows users to provide a custom setup if they need to
  do that.
  """
  defstruct filename: nil, overwrite: false

  defimpl Vapor.Provider do
    def load(%{filename: nil, overwrite: overwrite}) do
      # Get the environment from mix. If mix isn't available we assume we're in
      # a prod release
      env = if Code.ensure_loaded?(Mix), do: Mix.env(), else: "prod"
      files = [".env", ".env.#{env}", ".env.local", ".env.#{env}.local"]

      files
      |> Enum.reduce(%{}, fn file, acc -> Map.merge(acc, load_file(file)) end)
      |> put_vars(overwrite)

      {:ok, %{}}
    end

    def load(%{filename: filename, overwrite: overwrite}) do
      filename
      |> load_file
      |> put_vars(overwrite)

      {:ok, %{}}
    end

    defp load_file(file) do
      case File.read(file) do
        {:ok, contents} ->
          parse(contents)

        _ ->
          %{}
      end
    end

    def put_vars(vars, overwrite) do
      for {k, v} <- vars do
        if overwrite || System.get_env(k) == nil do
          System.put_env(k, v)
        end
      end
    end

    defp parse(contents) do
      contents
      |> String.split(~r/\n/, trim: true)
      |> Enum.reject(&comment?/1)
      |> Enum.map(fn pair -> String.split(pair, "=", parts: 2) end)
      |> Enum.filter(&good_pair/1)
      |> Enum.map(fn [key, value] -> {String.trim(key), String.trim(value)} end)
      |> Enum.map(fn {key, value} -> {key, value} end)
      |> Enum.into(%{})
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
  end
end
