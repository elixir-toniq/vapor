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

defmodule Vapor.LoadError do
  defexception [:message]

  @impl true
  def exception(errors) do
    msgs = Enum.join(errors, "\n")

    msg = """
    There were errors loading configuration:
    #{msgs}
    """

    %__MODULE__{message: msg}
  end
end

