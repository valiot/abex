defmodule Abex.CmdWrapper do
  @moduledoc """
  Wrapper for command execution that implements the behaviour.
  This allows dependency injection for testing.

  Captures both stdout and stderr from commands to ensure debug output
  from libplctag is visible on all platforms (including Nerves).
  """

  @behaviour Abex.CmdBehaviour

  @impl true
  def cmd(command, args) do
    # Merge stderr into stdout so debug logs are captured
    MuonTrap.cmd(command, args, stderr_to_stdout: true)
  end
end
