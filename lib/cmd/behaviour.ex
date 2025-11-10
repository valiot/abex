defmodule Abex.CmdBehaviour do
  @moduledoc """
  Behaviour for command execution.
  This allows mocking in tests.
  """

  @callback cmd(binary(), list()) :: {binary(), non_neg_integer()}
end
