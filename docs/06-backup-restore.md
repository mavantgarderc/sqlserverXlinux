# Backup and restore

Essential backup/restore flows for dev and basic production‑minded usage.

Covers:

- Local filesystem backups
- Restore on same server
- Restore into a Docker container

---

## 1. Prepare a backup directory

On the host:

```bash
sudo mkdir -p /var/opt/mssql/backups
sudo chown mssql:mssql /var/opt/mssql/backups
sudo chmod 700 /var/opt/mssql/backups
```

List:

```bash
ls -ld /var/opt/mssql/backups
```

---

## 2. Full backup to local filesystem

Example for `Ecommerce`:

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
BACKUP DATABASE [Ecommerce]
TO DISK = N'/var/opt/mssql/backups/Ecommerce_full.bak'
WITH INIT, COMPRESSION, STATS = 5;
GO
SQL
```

Key points:

- `WITH INIT` – overwrite existing file.
- `COMPRESSION` – smaller file.
- `STATS = 5` – progress output.

List backup:

```bash
ls -lh /var/opt/mssql/backups
```

---

## 3. Restore on the same server

### 3.1 Basic restore (overwrite existing DB)

**Danger**: this drops existing `Ecommerce` DB data.

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
ALTER DATABASE [Ecommerce] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE [Ecommerce]
FROM DISK = N'/var/opt/mssql/backups/Ecommerce_full.bak'
WITH REPLACE, STATS = 5;
GO

ALTER DATABASE [Ecommerce] SET MULTI_USER;
GO
SQL
```

Check:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT name, create_date FROM sys.databases WHERE name = 'Ecommerce';"
```

### 3.2 Restore under a new name

Useful if you want a copy for testing:

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
RESTORE DATABASE [Ecommerce_Test]
FROM DISK = N'/var/opt/mssql/backups/Ecommerce_full.bak'
WITH
  MOVE 'Ecommerce'     TO '/var/opt/mssql/data/Ecommerce_Test.mdf',
  MOVE 'Ecommerce_log' TO '/var/opt/mssql/data/Ecommerce_Test_log.ldf',
  STATS = 5;
GO
SQL
```

Logical names (`'Ecommerce'`, `'Ecommerce_log'`) come from:

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
RESTORE FILELISTONLY
FROM DISK = N'/var/opt/mssql/backups/Ecommerce_full.bak';
GO
SQL
```

---

## 4. Restore into a Docker container

Scenario: you have a `.bak` on the host and want it inside a SQL Server container.

### 4.1 Start container

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name sql2022restore \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

Wait for it to be ready:

```bash
sleep 20
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

### 4.2 Copy backup into container

Assume your `.bak` is on the host at `/var/opt/mssql/backups/Ecommerce_full.bak`:

```bash
docker cp /var/opt/mssql/backups/Ecommerce_full.bak sql2022restore:/var/opt/mssql/backups/Ecommerce_full.bak
```

Create directory inside container if needed:

```bash
docker exec sql2022restore mkdir -p /var/opt/mssql/backups
```

(re‑run `docker cp` if directory wasn’t there)

### 4.3 Restore inside container

From host, using `sqlcmd` (talking to the container on port 1433):

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
RESTORE DATABASE [Ecommerce]
FROM DISK = N'/var/opt/mssql/backups/Ecommerce_full.bak'
WITH
  MOVE 'Ecommerce'     TO '/var/opt/mssql/data/Ecommerce.mdf',
  MOVE 'Ecommerce_log' TO '/var/opt/mssql/data/Ecommerce_log.ldf',
  STATS = 5;
GO
SQL
```

Verify:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT name FROM sys.databases WHERE name = 'Ecommerce';"
```

---

## 5. Simple backup strategy for dev

For local dev (not full production strategy):

1. Take full backup periodically:

   ```bash
   sqlcmd -S localhost -U SA -C <<'SQL'
   BACKUP DATABASE [Ecommerce]
   TO DISK = N'/var/opt/mssql/backups/Ecommerce_full.bak'
   WITH INIT, COMPRESSION, STATS = 5;
   GO
   SQL
   ```

2. Copy `.bak` to another disk / machine if it matters.

3. Use restore scripts to:
   - Reset dev data
   - Create test copies (`Ecommerce_Test`)

For real production planning (diff/log backups, recovery time objectives), see official SQL Server backup documentation. This doc is intentionally minimal and dev‑oriented.
