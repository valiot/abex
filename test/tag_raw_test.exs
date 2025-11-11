defmodule Abex.Tag.RawTest do
  use ExUnit.Case, async: false

  import Mox

  setup :verify_on_exit!
  setup :set_mox_global

  describe "read/1" do
    test "builds correct command arguments for uint32" do
      Abex.CmdMock
      |> expect(:cmd, fn cmd, args ->
        assert String.ends_with?(cmd, "tag_rw2")

        assert args == [
          "--type=uint32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=TestTag&path=1,0"
        ]

        {"data[0]=42\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :uint32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "TestTag"
      )

      assert value == 42
    end

    test "builds correct command arguments for real32" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=real32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=CompactLogix&name=Temperature&path=1,0"
        ]

        {"data[0]=25.5\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :real32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :CompactLogix,
        name: "Temperature"
      )

      assert value == 25.5
    end

    test "builds correct command arguments with timeout" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=uint32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=TestTag",
          "--timeout=10000"
        ]

        {"data[0]=100\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :uint32,
        gateway: "192.168.1.10",
        plc: :ControlLogix,
        name: "TestTag",
        timeout: 10000
      )

      assert value == 100
    end

    test "builds correct command arguments with debug level" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=uint32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=TestTag",
          "--debug=3"
        ]

        {"data[0]=50\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :uint32,
        gateway: "192.168.1.10",
        plc: :ControlLogix,
        name: "TestTag",
        debug: :info
      )

      assert value == 50
    end

    test "builds correct command arguments for uint64" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=uint64",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=BigCounter&path=1,0"
        ]

        {"data[0]=9223372036854775807\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :uint64,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "BigCounter"
      )

      assert value == 9223372036854775807
    end

    test "builds correct command arguments for sint32" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=sint32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=SignedValue&path=1,0"
        ]

        {"data[0]=-1234\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :sint32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "SignedValue"
      )

      assert value == -1234
    end

    test "builds correct command arguments for string" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=string",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=Message&path=1,0"
        ]

        {"data[0]=\"Hello PLC\"\n", 0}
      end)

      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :string,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "Message"
      )

      assert value == "Hello PLC"
    end

    test "builds correct command arguments with elem_count and elem_size" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=uint16",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=Array&path=1,0&elem_size=2&elem_count=5"
        ]

        {"data[0]=10\ndata[1]=20\ndata[2]=30\ndata[3]=40\ndata[4]=50\n", 0}
      end)

      {:ok, values} = Abex.Tag.Raw.read(
        type: :uint16,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "Array",
        elem_size: 2,
        elem_count: 5
      )

      assert values == [10, 20, 30, 40, 50]
    end

    test "normalizes PLC type from string" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        [_, tag_arg] = args
        assert String.contains?(tag_arg, "plc=Micro800")

        {"data[0]=1\n", 0}
      end)

      {:ok, _} = Abex.Tag.Raw.read(
        type: :uint8,
        gateway: "192.168.1.10",
        plc: "Micro800",
        name: "Tag"
      )
    end

    test "handles read errors" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, _args ->
        {"ERROR: Tag not found", 1}
      end)

      result = Abex.Tag.Raw.read(
        type: :uint32,
        gateway: "192.168.1.10",
        plc: :ControlLogix,
        name: "NonExistent"
      )

      assert {:error, error_msg} = result
      assert String.contains?(error_msg, "exit code 1")
    end

    test "returns error when missing required parameters" do
      result = Abex.Tag.Raw.read(
        type: :uint32,
        gateway: "192.168.1.10"
        # Missing name and plc
      )

      assert {:error, error_msg} = result
      assert String.contains?(error_msg, "Missing required options")
    end
  end

  describe "write/1" do
    test "builds correct command arguments for single value" do
      Abex.CmdMock
      |> expect(:cmd, fn cmd, args ->
        assert String.ends_with?(cmd, "tag_rw2")

        assert args == [
          "--type=uint32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=Output&path=1,0",
          "--write=42"
        ]

        {"Write successful\n", 0}
      end)

      result = Abex.Tag.Raw.write(
        type: :uint32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "Output",
        values: 42
      )

      assert result == :ok
    end

    test "builds correct command arguments for multiple values" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=real32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=Setpoints&path=1,0",
          "--write=1.5,2.5,3.5,4.5"
        ]

        {"", 0}
      end)

      result = Abex.Tag.Raw.write(
        type: :real32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "Setpoints",
        values: [1.5, 2.5, 3.5, 4.5]
      )

      assert result == :ok
    end

    test "builds correct command arguments with timeout and debug" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=uint32",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=Value",
          "--timeout=5000",
          "--debug=2",
          "--write=999"
        ]

        {"", 0}
      end)

      result = Abex.Tag.Raw.write(
        type: :uint32,
        gateway: "192.168.1.10",
        plc: :ControlLogix,
        name: "Value",
        values: 999,
        timeout: 5000,
        debug: :warn
      )

      assert result == :ok
    end

    test "handles write errors" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, _args ->
        {"ERROR: Write failed - tag is read-only", 1}
      end)

      result = Abex.Tag.Raw.write(
        type: :uint32,
        gateway: "192.168.1.10",
        plc: :ControlLogix,
        name: "ReadOnlyTag",
        values: 100
      )

      assert {:error, error_msg} = result
      assert String.contains?(error_msg, "exit code 1")
    end

    test "returns error when missing values parameter" do
      result = Abex.Tag.Raw.write(
        type: :uint32,
        gateway: "192.168.1.10",
        plc: :ControlLogix,
        name: "Output"
        # Missing values
      )

      assert {:error, error_msg} = result
      assert String.contains?(error_msg, "Missing required option: :values")
    end
  end

  describe "read_metadata/1" do
    test "builds correct command arguments for metadata" do
      Abex.CmdMock
      |> expect(:cmd, fn _cmd, args ->
        assert args == [
          "--type=metadata",
          "--tag=protocol=ab-eip&gateway=192.168.1.10&plc=ControlLogix&name=TestTag&path=1,0"
        ]

        {"Tag metadata info\nSize: 4\nType: DINT\n", 0}
      end)

      {:ok, metadata} = Abex.Tag.Raw.read_metadata(
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "TestTag"
      )

      assert is_map(metadata)
      assert Map.has_key?(metadata, :raw_output)
    end
  end

  describe "debug level normalization" do
    test "normalizes atom debug levels to integers" do
      debug_mappings = [
        {nil, []},
        {:none, ["--debug=0"]},
        {:error, ["--debug=1"]},
        {:warn, ["--debug=2"]},
        {:info, ["--debug=3"]},
        {:detail, ["--debug=4"]},
        {:all, ["--debug=5"]}
      ]

      for {level, expected_args} <- debug_mappings do
        Abex.CmdMock
        |> expect(:cmd, fn _cmd, args ->
          # Check if debug arg is present or not
          debug_args = Enum.filter(args, &String.starts_with?(&1, "--debug="))
          assert debug_args == expected_args

          {"data[0]=1\n", 0}
        end)

        opts = [
          type: :uint8,
          gateway: "192.168.1.10",
          plc: :ControlLogix,
          name: "Tag"
        ]

        opts = if level, do: Keyword.put(opts, :debug, level), else: opts

        {:ok, _} = Abex.Tag.Raw.read(opts)
      end
    end
  end

  describe "PLC type normalization" do
    test "converts atom PLC types to strings" do
      plc_types = [
        :ControlLogix,
        :CompactLogix,
        :Micro800,
        :PLC5,
        :SLC500,
        :MicroLogix,
        :FlexLogix
      ]

      for plc_type <- plc_types do
        Abex.CmdMock
        |> expect(:cmd, fn _cmd, args ->
          [_, tag_arg] = args
          assert String.contains?(tag_arg, "plc=#{plc_type}")

          {"data[0]=1\n", 0}
        end)

        {:ok, _} = Abex.Tag.Raw.read(
          type: :uint8,
          gateway: "192.168.1.10",
          plc: plc_type,
          name: "Tag"
        )
      end
    end
  end
end
