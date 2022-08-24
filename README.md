<div align="center">
  <img src="https://raw.githubusercontent.com/valiot/abex/master/assets/images/abex-logo.png" alt="abex Logo" width="512" height="151" />
</div>

***
<br>
<div align="center">
  <img src="https://raw.githubusercontent.com/valiot/abex/master/assets/images/valiot-logo-blue.png" alt="Valiot Logo" width="384" height="80" />
</div>
<br>

## Usage

ABex is a GenServer-based implementation to expose tags and can be summarized by:

1. Start a Tag process use `start_link/1`.

    The following options are available:
    - `ip` - IP PLC address (string).
    - `path` - The path to the device containing the named data (string).
    - `cpu` - AB CPU models (string): plc,plc5,slc,slc500,micrologix,mlgx,compactlogix,clgx,lgx,controllogix,contrologix,flexlogix,flgx.

1. Send requests `get_all_tags/1`, `read/2`, `write/2`.

### Get Tags paths.

To get all available tags use `get_all_tags/1`.

```elixir
iex> {:ok, tag_pid} = ABex.Tag.start_link(ip: "20.0.0.70", cpu: "lgx", path: "1,0")
iex> {:ok, tag_list} = ABex.Tag.get_all_tags(tag_pid)
```

### Read tag data

Use `read/2`. The following options are available:
    - `data_type` - Expected data type (string).
    - `elem_size` - Expected data type size in bytes (integer).
    - `elem_count` - Number of items to request (integer).
    - `name` - Tag's name (string).

```elixir
iex> {:ok, tag_pid} = ABex.Tag.start_link(ip: "20.0.0.70", cpu: "lgx", path: "1,0")
iex> {:ok, values} = ABex.Tag.read(tag_pid, name: "Some_tag", elem_size: 8, elem_count: 1, data_type: "uint8")
```

### Write a value to a tag

Use `write/2`. The following options are available:
    - `data_type` - Expected data type (string).
    - `elem_size` - Expected data type size in bytes (integer).
    - `elem_count` - Number of items to request (integer).
    - `name` - Tag's name (string).
    - `value` - Value to be written on the tag.

```elixir
iex> {:ok, tag_pid} = ABex.Tag.start_link(ip: "20.0.0.70", cpu: "lgx", path: "1,0")
iex> :ok = ABex.Tag.read(tag_pid, name: "Some_tag", elem_size: 8, elem_count: 1, data_type: "uint8", value: 103)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `abex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:abex, "~> 0.1.1"},
    # the current elixir-cmake (0.1.0) hex package is not compatible.
    {:elixir_cmake, github: "valiot/elixir-cmake", override: true}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/abex](https://hexdocs.pm/abex).

