Mox.defmock(Abex.CmdMock, for: Abex.CmdBehaviour)
Application.put_env(:abex, :cmd_runner, Abex.CmdMock)

ExUnit.start()
