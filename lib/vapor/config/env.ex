defmodule Vapor.Config.Env do
  defstruct [prefix: :none, bindings: []]

  def with_prefix(prefix) when is_binary(prefix) do
    %__MODULE__{prefix: "#{prefix}_"}
  end

  defimpl Vapor.Provider do
    def load(%{prefix: prefix}) do
      env = System.get_env()

      prefixed_envs =
        env
        |> Enum.filter(& matches_prefix?(&1, prefix))
        |> Enum.map(fn {k, v} -> {normalize(k, prefix), v} end)
        |> Enum.into(%{})

      {:ok, prefixed_envs}
    end

    defp normalize(str, prefix) do
      str
      |> String.replace_leading(prefix, "")
      |> String.downcase
    end

    defp matches_prefix?({k, _v}, prefix) do
      String.starts_with?(k, prefix)
    end
  end
end
