# Developer workflow (SQL Server on Linux)

End‑to‑end flow for daily development with SQL Server on Linux.

High‑level:

1. Install engine + tools via `install-mssql-linux.sh`.
2. Configure instance with `mssql-conf`.
3. Create a dev database + schema (e.g. `Ecommerce`).
4. Use `sqlcmd` for repeatable scripts and migrations.
5. Use GUI (DBeaver / Azure Data Studio / VS Code) for exploration.
6. Optionally run SQL Server in Docker or access remote via SSH.
7. Add simple automation for local resets / CI.

---

## 1. Install engine + tools

From repo root:

```bash
chmod +x ./install-mssql-linux.sh
./install-mssql-linux.sh --log
```

Recommended answers for local dev:

```text
Q1) Continue with Microsoft SQL Server + tools installation? [Y/n]: y
Q2) Detected distro is ... Is this correct? [Y/n]: y
Q3) What do you want to install? → 1 (full)
Q4) Allow script to configure repos / yay? → y
Q5) Is it OK to run package database update? → y (or n if you prefer)
Q6) Install extra OS dependencies required by SQL Server? → y
Q7) Run 'mssql-conf setup' now? → y
Q8) Enable and start 'mssql-server' systemd service? → y
Q9) Add /opt/mssql-tools*/bin to PATH in ~/.bashrc and ~/.zshrc? → y
Q10) Proceed with installation using these settings? → y
```

Quick verification:

```bash
systemctl status mssql-server
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

---

## 2. Configure instance with `mssql-conf`

Initial or later configuration:

```bash
sudo /opt/mssql/bin/mssql-conf setup
sudo systemctl restart mssql-server
```

Non‑interactive example:

```bash
export MSSQL_SA_PASSWORD='YourStrong!Passw0rd'
export MSSQL_PID='Developer'

sudo MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" MSSQL_PID="$MSSQL_PID" \
  /opt/mssql/bin/mssql-conf -n setup accept-eula

sudo systemctl restart mssql-server
```

Change SA password later:

```bash
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl restart mssql-server
```

More details: `docs/04-configuration-mssql-conf.md`

---

## 3. Create dev database and basic schema

Connect with `sqlcmd`:

```bash
sqlcmd -S localhost -U SA -C
```

Inside `sqlcmd`:

```sql
CREATE DATABASE Ecommerce;
GO

USE Ecommerce;
GO

CREATE TABLE Customers (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    Email       NVARCHAR(255) NOT NULL UNIQUE,
    FullName    NVARCHAR(255) NOT NULL,
    CreatedAt   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Orders (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId  INT           NOT NULL,
    Total       DECIMAL(18,2) NOT NULL,
    CreatedAt   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (CustomerId) REFERENCES Customers(Id)
);
GO

INSERT INTO Customers (Email, FullName)
VALUES (N'ali@example.com', N'Ali Example'),
       (N'sara@example.com', N'Sara Example');
GO

SELECT TOP (10) Id, Email, FullName, CreatedAt
FROM Customers
ORDER BY Id DESC;
GO

QUIT
```

You can later move this into `samples/` as `.sql` files.

---

## 4. Use `sqlcmd` for daily dev

### One‑liner queries

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT name FROM sys.databases;"
```

### Run schema / seed scripts

Example layout:

```text
sql/
  001-create-database.sql
  010-schema.sql
  020-seed-data.sql
```

Bash script:

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVER="localhost"
USER="SA"
PASSWORD="YourStrong!Passw0rd"

run() {
  sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -C -i "$1"
}

run sql/001-create-database.sql
run sql/010-schema.sql
run sql/020-seed-data.sql
```

```bash
chmod +x scripts/run-migrations.sh
./scripts/run-migrations.sh
```

More: `cli/01-sqlcmd-basics.md`, `cli/02-scripting-with-sqlcmd.md`

---

## 5. Use GUI tools alongside CLI

Pick one or more:

- DBeaver → `gui/01-dbeaver-setup.md`
- Azure Data Studio → `gui/02-azure-data-studio.md`
- VS Code (mssql extension) → `gui/03-vscode-sqltools.md`

Typical settings for local dev:

- Server / Host: `localhost`
- Port: `1433`
- User: `SA`
- Password: `YourStrong!Passw0rd`
- Encryption:
  - `encrypt = true`
  - `trustServerCertificate = true`

Use GUI to:

- Browse `Ecommerce` database.
- Inspect tables and indexes.
- Run ad‑hoc queries and exports.

---

## 6. Optionally: Docker or remote instances

### 6.1 Docker for throwaway instances / CI

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name sql2022 \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

Then:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

Use the same `sql/` scripts and `scripts/run-migrations.sh`.

Details: `linux/05-containers-and-docker.md`

### 6.2 SSH tunnels for remote

```bash
ssh -L 1433:localhost:1433 user@remote-host
```

Then:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

Or configure SSH in DBeaver / ADS.

Details: `linux/06-ssh-tunnels-and-remote.md`

---

## 7. Simple automation / reset workflow

### 7.1 Reset dev database

Example script to drop and recreate `Ecommerce` locally:

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVER="localhost"
USER="SA"
PASSWORD="YourStrong!Passw0rd"
DB="Ecommerce"

sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -C -Q "IF DB_ID('$DB') IS NOT NULL ALTER DATABASE [$DB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; IF DB_ID('$DB') IS NOT NULL DROP DATABASE [$DB];"
sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -C -i sql/001-create-database.sql
sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -C -i sql/010-schema.sql
sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -C -i sql/020-seed-data.sql
```

```bash
chmod +x scripts/reset-ecommerce.sh
./scripts/reset-ecommerce.sh
```

### 7.2 CI sketch with Docker

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name sqlci \
  -d mcr.microsoft.com/mssql/server:2022-latest

sleep 20

sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
sqlcmd -S localhost -U SA -C -i sql/001-create-database.sql
sqlcmd -S localhost -U SA -C -i sql/010-schema.sql
sqlcmd -S localhost -U SA -C -i sql/020-seed-data.sql

# dotnet test / other tests here

docker rm -f sqlci
```

---

## 8. Summary

- Use `install-mssql-linux.sh` once per machine.
- Use `mssql-conf` for instance‑level settings (edition, ports, directories, TLS).
- Keep schema + seed scripts in `sql/` and run them via `sqlcmd`.
- Use GUI tools to explore and debug.
- Use Docker / SSH for non‑local instances.
- Add small scripts to reset and seed dev databases quickly.
