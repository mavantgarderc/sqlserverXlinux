# Intro: SQL Server on Linux

This repo explains how to run **SQL Server on Linux** (Arch + Ubuntu):

- Use a unified installer script: `install-mssql-linux.sh`
- Manage configuration with `mssql-conf`
- Work with the database via:
  - CLI (`sqlcmd`, `bcp`)
  - GUI tools (DBeaver, Azure Data Studio, VS Code)
- Apply sensible security and production practices on Linux.

## Why SQL Server on Linux?

- You already live in Linux (Arch / Ubuntu) as a dev.
- You need SQL Server for:
  - .NET apps
  - Cross‑platform tools
  - Mixed Windows/Linux environments

This repo is **not** a replacement for Microsoft docs.  
Instead, it is:

- Opinionated
- Linux‑focused
- Command‑driven
- Paired with:

  - `.NET on Linux`: https://github.com/mavantgarderc/linuxXdotnet
  - Neovim SQL workflow: https://github.com/mavantgarderc/sqlserverXnvim
