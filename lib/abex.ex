defmodule Abex do
  @moduledoc """
  ABex - Allen-Bradley PLC Communication Library for Elixir.

  ABex provides a GenServer-based interface for communicating with Allen-Bradley PLCs
  using the libplctag library. It supports reading, writing, and listing tags from
  various AB PLC models including ControlLogix, CompactLogix, Micro800, and more.

  ## Features

  - Read and write tag values from Allen-Bradley PLCs
  - List all available tags on a PLC
  - Support for multiple data types (integers, floats, strings)
  - Support for arrays and UDTs (User Defined Types)
  - Advanced raw interface for direct libplctag access

  ## Modules

  - `Abex.Tag` - High-level GenServer interface for PLC communication
  - `Abex.Tag.Raw` - Low-level interface with direct access to all libplctag features

  ## Quick Start

  ```elixir
  # Start a Tag process
  {:ok, tag_pid} = Abex.Tag.start_link(ip: "192.168.1.10", cpu: "lgx", path: "1,0")

  # Get all tags
  {:ok, tags} = Abex.Tag.get_all_tags(tag_pid)

  # Read a tag
  {:ok, [value]} = Abex.Tag.read(tag_pid,
    name: "MyTag",
    data_type: "uint32",
    elem_size: 4,
    elem_count: 1
  )

  # Write to a tag
  :ok = Abex.Tag.write(tag_pid,
    name: "MyTag",
    data_type: "uint32",
    elem_size: 4,
    elem_count: 1,
    value: "42"
  )
  ```

  ## Supported PLC Types

  - ControlLogix, CompactLogix (lgx, clgx, controllogix, compactlogix)
  - Micro800 series
  - PLC-5 (plc5, plc)
  - SLC 500 (slc, slc500)
  - MicroLogix (micrologix, mlgx)
  - FlexLogix (flexlogix, flgx)

  ## Supported Data Types

  - Unsigned integers: uint8, uint16, uint32, uint64
  - Signed integers: sint8, sint16, sint32, sint64
  - Floating point: real32, real64
  - Strings
  - Bits
  - Raw bytes

  For more information, see the documentation for `Abex.Tag` and `Abex.Tag.Raw`.
  """
end
