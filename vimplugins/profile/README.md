# profile

A lua profiler for neovim

## Usage

At the start of your neovim init.lua, add:
```lua
require("profile").instrument_autocmds()
require("profile").instrument("*")
-- If you want to profile events *after* startup, call this later
require("profile").start()
```

Then to stop profiling and export the trace, call
```lua
require("profile").stop("profile.json")
```

You can view the traces in `chrome://tracing` or at https://ui.perfetto.dev/
