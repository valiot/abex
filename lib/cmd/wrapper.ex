defmodule Abex.CmdWrapper do
  @moduledoc """
  Wrapper for command execution that implements the behaviour.
  This allows dependency injection for testing.
  """

  @behaviour Abex.CmdBehaviour

  @impl true
  def cmd(command, args) do
    MuonTrap.cmd(command, args)
  end
end
