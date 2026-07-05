---
name: nvim
description: Send commands to a running Neovim instance using nvr (Neovim remote)
disable-model-invocation: true
argument-hint: "[command] e.g. ':e path/to/file' or ':vsplit'"
user-invocable: true
allowed-tools: Bash(nvr *)
---

# Neovim Remote Command

Send a command to the user's running Neovim instance via `nvr`.

## Finding the server

1. List available servers: `nvr --serverlist`
2. Ask the user which PID is theirs if multiple instances exist, or check with: `nvr --servername <socket> --remote-expr 'getpid()'`

## Sending commands

Use the socket path to send commands:

```bash
nvr --servername <socket> -c '<vim command>'
```

Examples:
- Open a file: `nvr --servername <socket> -c 'edit /path/to/file.go'`
- Open in vsplit: `nvr --servername <socket> -c 'vsplit /path/to/file.go'`
- Go to a line: `nvr --servername <socket> -c 'edit +42 /path/to/file.go'`
- Run any Ex command: `nvr --servername <socket> -c '<command>'`

## Reading state

```bash
nvr --servername <socket> --remote-expr '<vimscript expression>'
```

Examples:
- Current file: `nvr --servername <socket> --remote-expr 'expand("%:p")'`
- Current line number: `nvr --servername <socket> --remote-expr 'line(".")'`
- PID: `nvr --servername <socket> --remote-expr 'getpid()'`

## User arguments

If the user provides arguments via `/nvim`, they are: $ARGUMENTS

Parse the arguments and send the appropriate nvr command. If no arguments given, ask what they want to do.

## Notes

- Always use absolute file paths when opening files
- The nvr command may take a few seconds to respond — use a 10s timeout
- Always use `dangerouslyDisableSandbox: true` for nvr commands as they need socket access
