# Architecture: SQL Server on Linux

High‑level view of how SQL Server runs on Linux (Arch / Ubuntu).

## 1. Main components

- **Engine process**: `sqlservr`
- **Service manager**: `systemd` unit `mssql-server`
- **Config tool**: `/opt/mssql/bin/mssql-conf`
- **Data + logs**:
  - Data files: `/var/opt/mssql/data`
  - Logs: `/var/opt/mssql/log`
- **Client tools**:
  - `sqlcmd`, `bcp`, etc. from `mssql-tools` / `mssql-tools18`
- **Drivers**:
  - ODBC driver: `msodbcsql` (Arch) / `msodbcsql18` (Ubuntu)
  - Used by tools and apps (DBeaver, ADS, .NET, etc.)

---

## 2. Service and process model

On systemd‑based distros:

- Unit file: `mssql-server.service`
- Start:

  ```bash
  sudo systemctl start mssql-server
  ```

- Process tree (simplified):

  ```bash
  ps aux | grep sqlservr | grep -v grep
  ```

Typical path:

- `/opt/mssql/bin/sqlservr` is launched by systemd.

---

## 3. Directories and files

Defaults (Linux layout):

| Path                        | Description                    |
| --------------------------- | ------------------------------ |
| `/opt/mssql/`               | Binaries and tools             |
| `/opt/mssql/bin/mssql-conf` | Config CLI tool                |
| `/var/opt/mssql/`           | Data + logs root               |
| `/var/opt/mssql/data`       | Database data files (`.mdf`)   |
| `/var/opt/mssql/log`        | Logs (`errorlog`, `.trc`, etc) |
| `/etc/opt/mssql/`           | Config files / settings        |

Inspect:

```bash
ls -1 /opt/mssql
ls -1 /var/opt/mssql
ls -1 /var/opt/mssql/data
ls -1 /var/opt/mssql/log
```

You can move default data/log dirs via `mssql-conf` (see `docs/04-configuration-mssql-conf.md`).

---

## 4. Networking

Default:

- Listens on TCP port **1433**
- Binds to configured IP / wildcard (`0.0.0.0` or `127.0.0.1`)

Check:

```bash
sudo ss -tulpn | grep 1433
```

Change port (example: 1500):

```bash
sudo /opt/mssql/bin/mssql-conf set network.tcpport 1500
sudo systemctl restart mssql-server
sudo ss -tulpn | grep 1500
```

---

## 5. Configuration model

`mssql-conf` writes settings under `/var/opt/mssql` and `/etc/opt/mssql`.

- View config:

  ```bash
  sudo /opt/mssql/bin/mssql-conf list
  ```

- Set values:

  ```bash
  sudo /opt/mssql/bin/mssql-conf set <section.option> <value>
  sudo systemctl restart mssql-server
  ```

Examples:

- `network.tcpport`
- `filelocation.defaultdatadir`
- `filelocation.defaultlogdir`
- TLS options: `network.tlscert`, `network.tlskey`, `network.tlsprotocols`

Details: `docs/04-configuration-mssql-conf.md`

---

## 6. Tools and drivers

### CLI tools

On Arch:

```bash
ls -1 /opt/mssql-tools/bin
```

On Ubuntu:

```bash
ls -1 /opt/mssql-tools18/bin
```

Common binaries:

- `sqlcmd` – T‑SQL CLI
- `bcp` – bulk import/export

### ODBC driver

Arch:

```bash
yay -Qi msodbcsql
```

Ubuntu:

```bash
dpkg -l | grep msodbcsql
```

These drivers are used by:

- `sqlcmd` / `bcp`
- DBeaver
- Azure Data Studio
- VS Code mssql extension
- .NET / other languages (via connection strings)

---

## 7. Local dev vs production notes

Local dev:

- Often:
  - Default port 1433
  - Self‑signed TLS certificate
  - Trust server certificate with tools (`sqlcmd -C`, `trustServerCertificate=true`)
- Focus on:
  - Fast setup
  - Easy resets
  - Experimentation

Production:

- Harden:
  - TLS with real certs
  - No SA usage for apps
  - Firewalls / network isolation
  - Monitoring + backups
- See:
  - `docs/05-security-and-tls.md`
  - `docs/06-backup-restore.md`
  - `docs/08-monitoring-and-performance.md`
