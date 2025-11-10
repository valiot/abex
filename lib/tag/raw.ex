defmodule Abex.Tag.Raw do
  @moduledoc """
  Advanced interface for Allen-Bradley PLC tag operations using the tag_rw2 binary.

  This module provides access to all advanced features of libplctag including:
  - Extended data types (64-bit integers, 64-bit floats, strings, metadata)
  - Configurable timeouts and debug levels
  - Raw byte access
  - Array operations

  ## Example

      # Read a 32-bit integer
      {:ok, [value]} = Abex.Tag.Raw.read(
        type: :uint32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "MyTag"
      )

      # Write multiple values to an array
      :ok = Abex.Tag.Raw.write(
        type: :uint32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "MyArray",
        values: [10, 20, 30]
      )

      # Read with custom timeout and debug
      {:ok, value} = Abex.Tag.Raw.read(
        type: :real32,
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "Temperature",
        timeout: 10000,
        debug: :info
      )
  """

  defp cmd_runner do
    Application.get_env(:abex, :cmd_runner, Abex.CmdWrapper)
  end

  @type data_type ::
          :bit
          | :uint8
          | :sint8
          | :uint16
          | :sint16
          | :uint32
          | :sint32
          | :uint64
          | :sint64
          | :real32
          | :real64
          | :string
          | :metadata
          | :raw

  @type plc_type ::
          :ControlLogix
          | :CompactLogix
          | :Micro800
          | :PLC5
          | :SLC500
          | :MicroLogix
          | String.t()

  @type debug_level :: :none | :error | :warn | :info | :detail | :all | 1..5

  @type read_opts :: [
          type: data_type(),
          gateway: String.t(),
          path: String.t(),
          plc: plc_type(),
          name: String.t(),
          elem_count: pos_integer(),
          elem_size: pos_integer(),
          timeout: pos_integer(),
          debug: debug_level()
        ]

  @type write_opts :: [
          type: data_type(),
          gateway: String.t(),
          path: String.t(),
          plc: plc_type(),
          name: String.t(),
          values: list() | any(),
          elem_count: pos_integer(),
          elem_size: pos_integer(),
          timeout: pos_integer(),
          debug: debug_level()
        ]

  @doc """
  Reads a tag from the PLC.

  ## Options

  - `:type` (required) - Data type: :bit, :uint8, :sint8, :uint16, :sint16, :uint32, :sint32, :uint64, :sint64, :real32, :real64, :string, :metadata, :raw
  - `:gateway` (required) - PLC IP address
  - `:path` (required for most PLCs) - PLC path, e.g., "1,0"
  - `:plc` (required) - PLC type, e.g., :ControlLogix, :Micro800
  - `:name` (required) - Tag name
  - `:elem_count` (optional) - Number of elements for arrays
  - `:elem_size` (optional) - Size of each element in bytes
  - `:timeout` (optional) - Timeout in milliseconds (default: 5000)
  - `:debug` (optional) - Debug level: :none, :error, :warn, :info, :detail, :all, or 1-5

  ## Returns

  - `{:ok, values}` - List of values read from the tag
  - `{:error, reason}` - Error message
  """
  @spec read(read_opts()) :: {:ok, list()} | {:error, String.t()}
  def read(opts) do
    with :ok <- validate_read_opts(opts),
         tag_string <- build_tag_string(opts),
         cmd_args <- build_read_args(opts, tag_string) do
      execute_command(cmd_args, :read, opts[:type])
    end
  end

  @doc """
  Writes value(s) to a tag in the PLC.

  ## Options

  Same as `read/1`, plus:
  - `:values` (required) - Single value or list of values to write

  ## Returns

  - `:ok` - Write successful
  - `{:error, reason}` - Error message
  """
  @spec write(write_opts()) :: :ok | {:error, String.t()}
  def write(opts) do
    with :ok <- validate_write_opts(opts),
         tag_string <- build_tag_string(opts),
         cmd_args <- build_write_args(opts, tag_string) do
      execute_command(cmd_args, :write, opts[:type])
    end
  end

  @doc """
  Reads tag metadata without reading the actual value.

  This is useful for discovering tag types and sizes.

  ## Example

      {:ok, metadata} = Abex.Tag.Raw.read_metadata(
        gateway: "192.168.1.10",
        path: "1,0",
        plc: :ControlLogix,
        name: "MyTag"
      )
  """
  @spec read_metadata(Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def read_metadata(opts) do
    opts = Keyword.put(opts, :type, :metadata)

    case read(opts) do
      {:ok, [metadata | _]} when is_map(metadata) -> {:ok, metadata}
      {:ok, metadata} when is_map(metadata) -> {:ok, metadata}
      error -> error
    end
  end

  # Private functions

  defp validate_read_opts(opts) do
    required = [:type, :gateway, :name, :plc]

    missing = required -- Keyword.keys(opts)

    if missing == [] do
      :ok
    else
      {:error, "Missing required options: #{inspect(missing)}"}
    end
  end

  defp validate_write_opts(opts) do
    with :ok <- validate_read_opts(opts) do
      if Keyword.has_key?(opts, :values) do
        :ok
      else
        {:error, "Missing required option: :values"}
      end
    end
  end

  defp build_tag_string(opts) do
    protocol = "ab-eip"
    gateway = Keyword.fetch!(opts, :gateway)
    plc = normalize_plc_type(Keyword.fetch!(opts, :plc))
    name = Keyword.fetch!(opts, :name)

    base = "protocol=#{protocol}&gateway=#{gateway}&plc=#{plc}&name=#{name}"

    base
    |> add_optional_param("path", opts[:path])
    |> add_optional_param("elem_size", opts[:elem_size])
    |> add_optional_param("elem_count", opts[:elem_count])
  end

  defp add_optional_param(string, _key, nil), do: string
  defp add_optional_param(string, key, value), do: "#{string}&#{key}=#{value}"

  defp normalize_plc_type(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_plc_type(type) when is_binary(type), do: type

  defp build_read_args(opts, tag_string) do
    type = Keyword.fetch!(opts, :type)

    args = [
      "--type=#{type}",
      "--tag=#{tag_string}"
    ]

    args
    |> add_timeout_arg(opts[:timeout])
    |> add_debug_arg(opts[:debug])
  end

  defp build_write_args(opts, tag_string) do
    values = Keyword.fetch!(opts, :values)
    values_str = format_write_values(values)

    opts
    |> build_read_args(tag_string)
    |> Kernel.++(["--write=#{values_str}"])
  end

  defp add_timeout_arg(args, nil), do: args
  defp add_timeout_arg(args, timeout), do: args ++ ["--timeout=#{timeout}"]

  defp add_debug_arg(args, nil), do: args
  defp add_debug_arg(args, level), do: args ++ ["--debug=#{normalize_debug_level(level)}"]

  defp normalize_debug_level(:none), do: 0
  defp normalize_debug_level(:error), do: 1
  defp normalize_debug_level(:warn), do: 2
  defp normalize_debug_level(:info), do: 3
  defp normalize_debug_level(:detail), do: 4
  defp normalize_debug_level(:all), do: 5
  defp normalize_debug_level(level) when is_integer(level) and level >= 0 and level <= 5, do: level
  defp normalize_debug_level(_), do: 0

  defp format_write_values(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.join(",")
  end
  defp format_write_values(value), do: to_string(value)

  defp execute_command(args, operation, type) do
    tag_rw2_cmd =
      :code.priv_dir(:abex)
      |> to_string()
      |> Path.join("tag_rw2")

    case cmd_runner().cmd(tag_rw2_cmd, args) do
      {output, 0} ->
        parse_output(output, operation, type)

      {error, exit_code} ->
        {:error, "Command failed with exit code #{exit_code}: #{String.trim(error)}"}
    end
  end

  defp parse_output(output, :write, _type) do
    if String.contains?(output, "ERROR") do
      {:error, extract_error(output)}
    else
      :ok
    end
  end

  defp parse_output(output, :read, type) do
    if String.contains?(output, "ERROR") do
      {:error, extract_error(output)}
    else
      parse_read_output(output, type)
    end
  end

  defp extract_error(output) do
    output
    |> String.split("\n")
    |> Enum.find("Unknown error", fn line -> String.contains?(line, "ERROR") end)
    |> String.trim()
  end

  defp parse_read_output(output, :metadata) do
    # Parse metadata output
    lines = String.split(output, "\n")

    metadata = %{
      raw_output: output,
      lines: lines
    }

    {:ok, metadata}
  end

  defp parse_read_output(output, type) when type in [:string] do
    # Parse string output - extract strings from data[N]="value" format
    values =
      output
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "data["))
      |> Enum.map(fn line ->
        case Regex.run(~r/data\[\d+\]="([^"]*)"/, line) do
          [_, value] -> value
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, values}
  end

  defp parse_read_output(output, type) when type in [:uint8, :uint16, :uint32, :uint64] do
    # Parse unsigned integer output - extract numbers from data[N]=value format
    values =
      output
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "data["))
      |> Enum.map(fn line ->
        case Regex.run(~r/data\[\d+\]=(\d+)/, line) do
          [_, value] -> String.to_integer(value)
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, values}
  end

  defp parse_read_output(output, type) when type in [:sint8, :sint16, :sint32, :sint64] do
    # Parse signed integer output
    values =
      output
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "data["))
      |> Enum.map(fn line ->
        case Regex.run(~r/data\[\d+\]=(-?\d+)/, line) do
          [_, value] -> String.to_integer(value)
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, values}
  end

  defp parse_read_output(output, type) when type in [:real32, :real64] do
    # Parse floating point output
    values =
      output
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "data["))
      |> Enum.map(fn line ->
        case Regex.run(~r/data\[\d+\]=(-?\d+\.?\d*)/, line) do
          [_, value] -> String.to_float(value)
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, values}
  end

  defp parse_read_output(output, :bit) do
    # Parse bit output - bit N = value
    case Regex.run(~r/bit \d+ = (\d+)/, output) do
      [_, value] -> {:ok, [String.to_integer(value)]}
      _ -> {:error, "Could not parse bit value"}
    end
  end

  defp parse_read_output(output, :raw) do
    # Parse raw hex output
    values =
      output
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "data["))
      |> Enum.map(fn line ->
        case Regex.run(~r/data\[\d+\]=\d+ \(0x([0-9a-fA-F]+)\)/, line) do
          [_, hex] -> String.to_integer(hex, 16)
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, values}
  end

  defp parse_read_output(output, _type) do
    {:ok, [output]}
  end
end
