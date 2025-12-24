# sqlserverXlinux

Educational docs + scripts for running **SQL Server on Linux** with a focus on:

- Arch Linux and Ubuntu
- Command‑line tooling (`sqlcmd`, `bcp`)
- GUI clients (DBeaver, Azure Data Studio, VS Code SQL tools)
- Local dev and production‑minded practices (TLS, users, backups)

This is a sibling project to:  
- https://github.com/mavantgarderc/linuxXdotnet  
- Neovim SQL tooling: https://github.com/mavantgarderc/sqlserverXnvim

---

## Who this repo is for

- You are **comfortable with Linux + shell**, but **new to SQL Server**.
- You want a **scripted install** and **copy‑paste‑ready commands**.
- You prefer **CLI‑first**, but also want **good GUI integration** (DBeaver).

---

## Quick start

### 1. Install SQL Server on Linux

On Arch or Ubuntu:

```bash
chmod +x ./install-mssql-linux.sh
./install-mssql-linux.sh --log
```

- Answers a consistent set of questions (like `linuxXdotnet`).
- Installs:
  - Engine (`mssql-server`, FTS, Agent)  
  - ODBC driver (`msodbcsql` on Arch, `msodbcsql18` on Ubuntu)  
  - Tools (`mssql-tools` / `mssql-tools18`) — includes `sqlcmd`, `bcp`.

Verify:

```bash
yay -Qi mssql-server msodbcsql mssql-tools    # Arch
# or
dpkg -l | grep -E 'mssql-server|msodbcsql|mssql-tools'   # Ubuntu

sqlcmd -? | head -n 5
systemctl status mssql-server
```

### 2. Configure SQL Server

Interactive:

```bash
sudo /opt/mssql/bin/mssql-conf setup
```

Unattended (example):

```bash
export MSSQL_SA_PASSWORD='YourStrong!Passw0rd'
export MSSQL_PID='Developer'

./install-mssql-linux.sh --yes --unattended-setup --log
```

Details: see [`docs/04-configuration-mssql-conf.md`](docs/04-configuration-mssql-conf.md).

### 3. Connect with `sqlcmd`

Local dev (trust self‑signed cert):

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

- `-C` = trust the server certificate (OK for localhost dev).
- For stricter TLS: see [`docs/05-security-and-tls.md`](docs/05-security-and-tls.md).

### 4. Connect from DBeaver

See: [`gui/01-dbeaver-setup.md`](gui/01-dbeaver-setup.md) for:

- Creating a SQL Server connection to `localhost`
- Fixing TLS / certificate errors
- Running queries and browsing schema

---

## Repo layout

| Path         | Purpose                                                  |
| ------------ | -------------------------------------------------------- |
| `install-mssql-linux.sh` | Unified Arch/Ubuntu installer script               |
| `cheats/`    | Short “cheat sheets” for shell, sqlcmd, DBeaver, fixes  |
| `cli/`       | CLI‑focused docs: sqlcmd, bcp, scripting, automation    |
| `docs/`      | Conceptual docs: architecture, config, security, backup |
| `linux/`     | Distro‑specific setup, services, logs, containers, SSH  |
| `gui/`       | DBeaver, Azure Data Studio, VS Code SQL tools           |
| `samples/`   | Example `ecommerce` database schema + data              |

---

## Related projects

- **.NET on Linux**: https://github.com/mavantgarderc/linuxXdotnet  
- **Neovim SQL tooling**: https://github.com/mavantgarderc/sqlserverXnvim  
