defprotocol Vapor.Provider do
  @doc """
  The protocol required for loading a configuration. Providers need to implement
  this protocol and must return either an `{:ok, %{}}` or `{:error, term()}`.
  """
  @spec load(any()) ::
          {:ok, %{optional(String.t()) => term()}}
          | {:error, term()}
  def load(plan)
end

