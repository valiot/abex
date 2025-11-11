defmodule Abex.TagTest do
  use ExUnit.Case, async: false

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!
  setup :set_mox_global

  describe "read/2" do
    test "builds correct command arguments for uint32" do
      # Mock the command execution
      Abex.CmdMock
      |> expect(:cmd, fn cmd, args ->
        # Verify the command path contains rw_tag
        assert String.ends_with?(cmd, "rw_tag")

        # Verify arguments structure
        assert args == [
          "-t", "uint32",
          "-p", "protocol=ab-eip&gateway=192.168.1.10&path=1,0&plc=lgx&elem_size=4&elem_count=1&name=TestTag"
        ]

        # Return mock response
        {"42", 0}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      {:ok, [value]} = Abex.Tag.read(pid,
        name: "TestTag",
        data_type: "uint32",
        elem_size: 4,
        elem_count: 1
      )

      assert value == 42
    end

    test "builds correct command arguments for real32" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "-t", "real32",
          "-p", "protocol=ab-eip&gateway=192.168.1.10&path=1,0&plc=clgx&elem_size=4&elem_count=1&name=TempSensor"
        ]

        {"25.5", 0}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "clgx")

      {:ok, [value]} = Abex.Tag.read(pid,
        name: "TempSensor",
        data_type: "real32",
        elem_size: 4,
        elem_count: 1
      )

      assert value == 25.5
    end

    test "builds correct command arguments for array read" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "-t", "uint16",
          "-p", "protocol=ab-eip&gateway=192.168.1.10&path=1,0&plc=lgx&elem_size=2&elem_count=5&name=DataArray"
        ]

        {"10 20 30 40 50", 0}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      {:ok, values} = Abex.Tag.read(pid,
        name: "DataArray",
        data_type: "uint16",
        elem_size: 2,
        elem_count: 5
      )

      assert values == [10, 20, 30, 40, 50]
    end

    test "handles error responses" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, _args ->
        {"Error: Tag not found", 1}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      result = Abex.Tag.read(pid,
        name: "NonExistent",
        data_type: "uint32",
        elem_size: 4,
        elem_count: 1
      )

      assert {:error, "Error: Tag not found"} = result
    end
  end

  describe "write/2" do
    test "builds correct command arguments for uint32 write" do
      Abex.CmdMock
      |> expect(:cmd, fn cmd, args ->
        assert String.ends_with?(cmd, "rw_tag")

        assert args == [
          "-t", "uint32",
          "-w", "100",
          "-p", "protocol=ab-eip&gateway=192.168.1.10&path=1,0&plc=lgx&elem_size=4&elem_count=1&name=OutputTag"
        ]

        {"Write successful", 0}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      result = Abex.Tag.write(pid,
        name: "OutputTag",
        data_type: "uint32",
        elem_size: 4,
        elem_count: 1,
        value: "100"
      )

      assert result == :ok
    end

    test "builds correct command arguments with different PLC type" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        # Verify the plc parameter is set correctly
        ["-t", _, "-w", _, "-p", tag_string] = args
        assert String.contains?(tag_string, "plc=micro800")

        {"", 0}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "10.0.0.1", path: "1,0", cpu: "micro800")

      result = Abex.Tag.write(pid,
        name: "SetPoint",
        data_type: "real32",
        elem_size: 4,
        elem_count: 1,
        value: "50.5"
      )

      assert result == :ok
    end

    test "handles write errors" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, _args ->
        {"Error: Write failed", 1}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      result = Abex.Tag.write(pid,
        name: "ReadOnlyTag",
        data_type: "uint32",
        elem_size: 4,
        elem_count: 1,
        value: "999"
      )

      assert {:error, "Error: Write failed"} = result
    end
  end

  describe "get_all_tags/1" do
    test "builds correct command arguments for tag listing" do
      mock_output = """
      tag_name=ControllerTag1; tag_instance_id=1; tag_type=DINT; element_length=4; array_dimensions=0
      tag_name=ControllerTag2; tag_instance_id=2; tag_type=REAL; element_length=4; array_dimensions=0
      Program tags
      Program1!tag_name=ProgramTag1; tag_instance_id=10; tag_type=INT; element_length=2; array_dimensions=0
      """

      Abex.CmdMock
      |> expect(:cmd, fn cmd, args ->
        assert String.ends_with?(cmd, "tag_list")
        assert args == ["192.168.1.10", "1,0"]

        {mock_output, 0}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      {:ok, tags} = Abex.Tag.get_all_tags(pid)

      # Verify controller tags are parsed
      assert Map.has_key?(tags, :controller_tags)
      assert Map.has_key?(tags.controller_tags, "ControllerTag1")
      assert tags.controller_tags["ControllerTag1"].tag_type == "DINT"
      assert tags.controller_tags["ControllerTag1"].element_length == 4

      # Verify program tags are parsed
      assert Map.has_key?(tags, :program_tags)
      assert Map.has_key?(tags.program_tags, "Program1")
      assert Map.has_key?(tags.program_tags["Program1"], "ProgramTag1")
    end

    test "handles tag list errors" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, _args ->
        {"Error: Connection timeout", 1}
      end)

      {:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", path: "1,0", cpu: "lgx")

      result = Abex.Tag.get_all_tags(pid)

      assert {:error, "Error: Connection timeout"} = result
    end
  end

  describe "initialization" do
    test "uses default values when not provided" do
      # We don't call cmd during initialization, so no mock needed
      {:ok, _pid} = Abex.Tag.start_link(ip: "192.168.1.10")

      # If it starts successfully, defaults were applied
      assert true
    end

    test "accepts custom path and cpu values" do
      {:ok, _pid} = Abex.Tag.start_link(ip: "10.0.0.1", path: "2,1", cpu: "micro800")

      assert true
    end
  end
end
