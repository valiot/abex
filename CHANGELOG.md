# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-11-12

### Fixed
- **Nerves Support**: Fixed "command not found" error (exit code 127) when running on embedded systems like Raspberry Pi
- All executables now link statically with libplctag, eliminating runtime shared library dependencies
- Debug output from libplctag now captured consistently on both development and embedded systems

### Added
- Comprehensive Nerves documentation in README with troubleshooting guide
- Verified platform compatibility list (RPi 3B+, RPi 4, RPi Zero W, BeagleBone Black)
- NERVES_DEBUG.md with detailed debugging information
- `stderr_to_stdout` option in CmdWrapper to capture debug logs from libplctag

### Changed
- **BREAKING**: All executables now always use static linking for consistency and portability
- Simplified CMakeLists.txt by removing conditional linking logic
- Binaries now work identically on development (HOST) and embedded (Target) systems
- CmdWrapper now captures both stdout and stderr for better debug visibility

## [0.2.0] - 2024

### Added
- Updated libplctag from v2.0.26 to v2.6.12
- New `Abex.Tag.Raw` module for low-level PLC operations
- Support for 64-bit data types (uint64, sint64, real64)
- Support for string, bit, raw, and metadata data types
- `Abex.Cmd.Behaviour` and `Abex.Cmd.Wrapper` for command execution abstraction
- Unified tag listing supporting multiple PLC types
- UDT (User Defined Types) introspection
- Comprehensive test coverage with Mox-based mocking
- Enhanced documentation with usage examples

### Changed
- Protocol string changed from `ab_eip` to `ab-eip`
- Parameter `cpu` changed to `plc` in internal calls
- Moved `Abex.Tag` to `lib/tag/` directory for better organization
- Combined `list_tags_logix.c` and `list_tags_micro8x0.c` into single `tag_list.c`
- Updated C source files to use new libplctag API

### Fixed
- Adapted `rw_tag.c` and `tag_list.c` to new libplctag API
- Improved error handling in all modules

## [0.1.2] - Earlier

### Initial Features
- GenServer-based interface for PLC communication
- Basic read/write operations
- Tag listing functionality
- Support for ControlLogix, CompactLogix, and Micro800 PLCs
- Integration with libplctag v2.0.26

[0.2.1]: https://github.com/valiot/abex/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/valiot/abex/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/valiot/abex/releases/tag/v0.1.2


