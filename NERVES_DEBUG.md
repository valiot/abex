# Debugging ABex on Nerves

This guide helps you diagnose and fix issues when running ABex on Nerves/embedded systems.

## Common Issues

### Exit Code 127: Command Not Found

**Symptom:**
```
Command failed with exit code 127
```

**Root Cause:**
This error typically occurs when:
1. The executable binary is not found in the expected location
2. Required shared libraries (.so files) are missing from the target filesystem
3. The binary architecture doesn't match the target system

**Solution:**
Ensure you're using ABex >= 0.2.1, which automatically links executables statically when cross-compiling for Nerves.

## Verifying the Installation

### 1. Check Binary Location

SSH into your Nerves device and verify the binaries exist:

```bash
# List all ABex binaries
ls -lh /srv/erlang/lib/abex-*/priv/

# Expected output:
# -rwxr-xr-x 1 root root  XXK date time libplctag.so*
# -rwxr-xr-x 1 root root  XXK date time rw_tag*
# -rwxr-xr-x 1 root root  XXK date time tag_list*
# -rwxr-xr-x 1 root root  XXK date time tag_rw2*
```

### 2. Check Binary Architecture

Verify the binary architecture matches your target:

```bash
# Check binary architecture
file /srv/erlang/lib/abex-*/priv/rw_tag

# For Raspberry Pi 3B+ / 4, expected output:
# rw_tag: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, ...
#    OR (with static linking):
# rw_tag: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, ...
```

### 3. Check Library Dependencies

Check what libraries the executable requires:

```bash
# Check if binary is statically linked
ldd /srv/erlang/lib/abex-*/priv/rw_tag

# Expected output (v0.2.1+):
# not a dynamic executable
#   OR
# statically linked
#   OR (minimal dynamic dependencies)
# linux-vdso.so.1
# libpthread.so.0 => /lib/arm-linux-gnueabihf/libpthread.so.0
# libc.so.6 => /lib/arm-linux-gnueabihf/libc.so.6
```

Note: ABex >= 0.2.1 always uses static linking with libplctag. You should NOT see `libplctag.so` in the dependencies.

### 4. Test Binary Execution

Try running the binary directly:

```bash
# Test rw_tag help
/srv/erlang/lib/abex-*/priv/rw_tag -h

# Should print usage information
# If it prints "command not found" or nothing, there's a linking issue
```

## Verifying Static Linking

ABex >= 0.2.1 always uses static linking. To verify:

```bash
# Check compilation output for:
# "ABex: Using static linking with libplctag for portability"

# Verify locally built binary
file _build/dev/lib/abex/priv/rw_tag

# Should show "statically linked" or minimal dynamic dependencies (pthread, libc only)

# Check for libplctag dependency (should NOT be present)
ldd _build/dev/lib/abex/priv/rw_tag | grep libplctag
# Should return nothing
```

## Firmware Building Best Practices

### 1. Clean Build for Firmware

When changing linking mode, do a clean build:

```bash
mix deps.clean abex --build
mix deps.get
mix compile
mix firmware
```

### 2. Check Firmware Size

Static linking increases binary size. Check your firmware fits:

```bash
mix firmware
# Look for:
# Firmware output: /path/to/your_app.fw
# Size: XX.X MB

# Ensure it's within your target's limits (usually < 32MB for SD card images)
```

### 3. Test Before Deployment

Always test on the target device before production:

```elixir
# In IEx on device
{:ok, pid} = Abex.Tag.start_link(ip: "192.168.1.10", cpu: "Micro800")
{:ok, tags} = Abex.Tag.get_all_tags(pid)
```

## Platform-Specific Notes

### Raspberry Pi 3B+ / 4

- **Architecture**: ARMv7 (32-bit) for RPi 3B+, ARMv8 (64-bit capable) for RPi 4
- **Nerves System**: Use `nerves_system_rpi3` or `nerves_system_rpi4`
- **Static Linking**: Automatically detected with Nerves
- **Known Issues**: None with v0.2.1+

### Raspberry Pi Zero W

- **Architecture**: ARMv6 (32-bit)
- **Nerves System**: Use `nerves_system_rpi0`
- **Notes**: Older ARM version, ensure your Nerves toolchain supports it
- **Performance**: Slower CPU, consider longer timeouts

### BeagleBone Black

- **Architecture**: ARMv7 (32-bit)
- **Nerves System**: Use `nerves_system_bbb`
- **Notes**: Industrial-grade, excellent for production
- **Performance**: Good real-time characteristics

## Advanced Debugging

### Enable Debug Output

Add debug output to your PLC calls:

```elixir
# In Abex.Tag.Raw
{:ok, value} = Abex.Tag.Raw.read(
  type: :uint32,
  gateway: "192.168.1.10",
  plc: :Micro800,
  name: "MyTag",
  debug: :detail  # Enable detailed debugging
)
```

### Check System Resources

```bash
# On Nerves device
free -m          # Check available memory
df -h            # Check disk space
ps aux           # Check running processes
dmesg | tail     # Check kernel messages
```

### Capture Command Output

For more detailed error messages:

```elixir
# Temporarily modify Abex.CmdWrapper to see raw output
defmodule MyDebugWrapper do
  @behaviour Abex.CmdBehaviour
  
  @impl true
  def cmd(command, args) do
    IO.puts("Executing: #{command} #{inspect(args)}")
    result = MuonTrap.cmd(command, args)
    IO.puts("Result: #{inspect(result)}")
    result
  end
end

# In config
config :abex, :cmd_runner, MyDebugWrapper
```

## Getting Help

If you're still experiencing issues:

1. Gather diagnostic information:
   ```bash
   # On device
   uname -a
   cat /etc/os-release
   file /srv/erlang/lib/abex-*/priv/rw_tag
   ldd /srv/erlang/lib/abex-*/priv/rw_tag
   ```

2. Check ABex version:
   ```elixir
   Application.spec(:abex, :vsn)
   ```

3. Open an issue at https://github.com/valiot/abex/issues with:
   - ABex version
   - Nerves system and version
   - Target device model
   - Error messages
   - Diagnostic output from above commands

## See Also

- [Nerves Documentation](https://hexdocs.pm/nerves/getting-started.html)
- [libplctag Documentation](https://github.com/libplctag/libplctag/wiki)
- [ABex README](README.md)


