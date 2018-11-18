defprotocol Vapor.Provider do
  @doc """
  Loads a configuration plan.
  """
  @spec load(any()) :: {:ok, %{optional(String.t) => term()}}
                     | {:error, term()}
  def load(plan)
end

