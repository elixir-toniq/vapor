defmodule Vapor.Plan do
  @moduledoc """
  This module provides a behaviour that allows other modules to define their own configuration plans. This allows modules to define their configuration on the module which can later
  be loaded using `Vapor.load/1`.
  """

  @callback config_plan :: list() | map()
end
