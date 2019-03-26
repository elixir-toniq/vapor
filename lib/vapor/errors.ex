defmodule Vapor.NotFoundError do
  defexception [:message]

  @impl true
  def exception({key, _}) do
    msg = "did not find a value for key: #{inspect(key)}"
    %__MODULE__{message: msg}
  end
end

defmodule Vapor.ConversionError do
  defexception [:message]

  @impl true
  def exception({key, type}) when is_atom(type) do
    msg = "could not convert #{key} to type: #{type}"
    %__MODULE__{message: msg}
  end

  def exception({key, type}) when is_function(type) do
    msg = "could not convert #{key} with custom type"
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
