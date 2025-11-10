<div align="center">
  <img src="https://raw.githubusercontent.com/valiot/abex/master/assets/images/abex-logo.png" alt="abex Logo" width="512" height="151" />
</div>

***
<br>
<div align="center">
  <img src="https://raw.githubusercontent.com/valiot/abex/master/assets/images/valiot-logo-blue.png" alt="Valiot Logo" width="384" height="80" />
</div>
<br>

# ABex - Allen-Bradley PLC Communication Library

ABex is an Elixir library for communicating with Allen-Bradley PLCs using [libplctag](https://github.com/libplctag/libplctag) (v2.6.12). It provides both a high-level GenServer-based interface and a low-level raw interface for advanced use cases.

## Features

- 🔌 **GenServer-based interface** for stateful PLC connections
- 🚀 **Raw interface** with direct access to all libplctag features
- 📊 **Multiple data types**: integers (8/16/32/64-bit), floats (32/64-bit), strings, bits
- 🏭 **Wide PLC support**: ControlLogix, CompactLogix, Micro800, PLC-5, SLC 500, MicroLogix
- 📋 **Tag listing** with UDT (User Defined Type) introspection
- ⚡ **Array operations** and batch read/write
- 🔍 **Metadata reading** for tag discovery
- ⏱️ **Configurable timeouts** and debug levels

## Installation

Add `abex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abex, "~> 0.2.0"},
    # the current elixir-cmake (0.1.0) hex package is not compatible.
    {:elixir_cmake, github: "valiot/elixir-cmake", override: true}
  ]
end
```

## Usage

ABex provides two interfaces: `Abex.Tag` (high-level GenServer) and `Abex.Tag.Raw` (low-level direct access).

### High-Level Interface: `Abex.Tag`

The GenServer-based interface maintains a persistent connection to the PLC.

#### 1. Start a Tag Process

```elixir
{:ok, tag_pid} = Abex.Tag.start_link(
  ip: "192.168.1.10",
  cpu: "lgx",        # ControlLogix
  path: "1,0"        # PLC path
)
```

**Options:**
- `ip` - PLC IP address (required)
- `path` - Path to the device containing the named data (default: "1,0")
- `cpu` - PLC type (default: "lgx")
  - Supported: `lgx`, `clgx`, `controllogix`, `compactlogix`, `micro800`, `micrologix`, `mlgx`, `plc5`, `slc`, `slc500`, `flexlogix`, `flgx`

#### 2. List All Tags

```elixir
{:ok, tags} = Abex.Tag.get_all_tags(tag_pid)

# Returns a map with controller tags and program tags
%{
  controller_tags: %{
    "MyTag" => %{
      tag_instance_id: "...",
      tag_type: "...",
      element_length: 4,
      array_dim: "..."
    }
  },
  program_tags: %{
    "MyProgram" => %{...}
  }
}
```

#### 3. Read Tag Data

```elixir
{:ok, [value]} = Abex.Tag.read(tag_pid,
  name: "MyTag",
  data_type: "uint32",
  elem_size: 4,
  elem_count: 1
)

# Read array
{:ok, values} = Abex.Tag.read(tag_pid,
  name: "MyArray",
  data_type: "real32",
  elem_size: 4,
  elem_count: 10
)
```

**Read Options:**
- `name` - Tag name (required)
- `data_type` - Data type: `"uint8"`, `"uint16"`, `"uint32"`, `"sint8"`, `"sint16"`, `"sint32"`, `"real32"`, etc.
- `elem_size` - Element size in bytes (required)
- `elem_count` - Number of elements to read (required)

#### 4. Write Tag Data

```elixir
:ok = Abex.Tag.write(tag_pid,
  name: "MyTag",
  data_type: "uint32",
  elem_size: 4,
  elem_count: 1,
  value: "42"
)
```

### Low-Level Interface: `Abex.Tag.Raw`

The raw interface provides access to all libplctag features without maintaining a GenServer connection.

#### Read Operations

```elixir
# Simple read
{:ok, [value]} = Abex.Tag.Raw.read(
  type: :uint32,
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "MyTag"
)

# Read with timeout and debug
{:ok, [temp]} = Abex.Tag.Raw.read(
  type: :real32,
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "Temperature",
  timeout: 10000,
  debug: :info
)

# Read 64-bit integer
{:ok, [big_value]} = Abex.Tag.Raw.read(
  type: :uint64,
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "BigCounter"
)

# Read string
{:ok, [text]} = Abex.Tag.Raw.read(
  type: :string,
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "MessageText"
)
```

#### Write Operations

```elixir
# Write single value
:ok = Abex.Tag.Raw.write(
  type: :uint32,
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "MyTag",
  values: 42
)

# Write array
:ok = Abex.Tag.Raw.write(
  type: :real32,
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "MyArray",
  values: [1.5, 2.5, 3.5, 4.5]
)
```

#### Metadata Reading

```elixir
{:ok, metadata} = Abex.Tag.Raw.read_metadata(
  gateway: "192.168.1.10",
  path: "1,0",
  plc: :ControlLogix,
  name: "MyTag"
)
```

**Raw Interface Options:**
- `type` - Data type atom: `:uint8`, `:uint16`, `:uint32`, `:uint64`, `:sint8`, `:sint16`, `:sint32`, `:sint64`, `:real32`, `:real64`, `:string`, `:bit`, `:raw`, `:metadata`
- `gateway` - PLC IP address (required)
- `path` - PLC path (required for most PLCs)
- `plc` - PLC type atom: `:ControlLogix`, `:CompactLogix`, `:Micro800`, `:PLC5`, `:SLC500`, `:MicroLogix`, `:FlexLogix`
- `name` - Tag name (required)
- `values` - Value or list of values to write (for write operations)
- `elem_count` - Number of elements for arrays (optional)
- `elem_size` - Size of each element in bytes (optional)
- `timeout` - Timeout in milliseconds (optional, default: 5000)
- `debug` - Debug level: `:none`, `:error`, `:warn`, `:info`, `:detail`, `:all` (optional)

## Supported Data Types

### Unsigned Integers
- `uint8` / `:uint8` - 8-bit unsigned (0 to 255)
- `uint16` / `:uint16` - 16-bit unsigned (0 to 65,535)
- `uint32` / `:uint32` - 32-bit unsigned (0 to 4,294,967,295)
- `uint64` / `:uint64` - 64-bit unsigned (0 to 18,446,744,073,709,551,615)

### Signed Integers
- `sint8` / `:sint8` - 8-bit signed (-128 to 127)
- `sint16` / `:sint16` - 16-bit signed (-32,768 to 32,767)
- `sint32` / `:sint32` - 32-bit signed (-2,147,483,648 to 2,147,483,647)
- `sint64` / `:sint64` - 64-bit signed

### Floating Point
- `real32` / `:real32` - 32-bit float (IEEE 754 single precision)
- `real64` / `:real64` - 64-bit float (IEEE 754 double precision)

### Other Types
- `string` / `:string` - PLC string type
- `bit` / `:bit` - Single bit value
- `raw` / `:raw` - Raw byte access
- `metadata` / `:metadata` - Tag metadata (type, size, etc.)

## Supported PLC Types

| PLC Family | Aliases |
|-----------|---------|
| **ControlLogix** | `lgx`, `controllogix`, `contrologix` |
| **CompactLogix** | `clgx`, `compactlogix` |
| **Micro800** | `micro800` |
| **PLC-5** | `plc`, `plc5` |
| **SLC 500** | `slc`, `slc500` |
| **MicroLogix** | `micrologix`, `mlgx` |
| **FlexLogix** | `flexlogix`, `flgx` |

## Building from Source

ABex includes C bindings to libplctag, which are built automatically using CMake:

```bash
# Clone the repository
git clone https://github.com/valiot/abex.git
cd abex

# Update submodules
git submodule update --init --recursive

# Get dependencies and compile
mix deps.get
mix compile
```

The build process will:
1. Build libplctag v2.6.12 from the submodule
2. Compile custom C programs (`rw_tag`, `tag_list`)
3. Include the `tag_rw2` example from libplctag
4. Generate Elixir BEAM files

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
mix docs
```

Once published, the docs can be found at [https://hexdocs.pm/abex](https://hexdocs.pm/abex).

## License

Copyright (c) Valiot

## Credits

ABex uses [libplctag](https://github.com/libplctag/libplctag), an open-source library for communicating with PLCs.

Special thanks to the libplctag team for their excellent work.

