defmodule Vapor.NotFoundError do
  defexception [:message]

  @impl true
  def exception(key) do
    msg = "did not find a value for key: #{inspect(key)}"
    %__MODULE__{message: msg}
  end
end

defmodule Vapor.FileFormatNotFoundError do
  defexception [:message]

  @impl true
  def exception(path) do
    msg = "configuration file: #{path} is not a registered file format"
    %__MODULE__{message: msg}
  end
end

defmodule Vapor.FileNotFoundError do
  defexception [:message]

  @impl true
  def exception(path) do
    msg = "configuration file: #{path} can not be found"
    %__MODULE__{message: msg}
  end
end

defmodule Vapor.ConfigurationError do
  defexception [:message]
end
