# sqlcmd cheats

## Connect to local SQL Server (dev)

Trust self‑signed certificate:

```bash
sqlcmd -S localhost -U SA -C
```

Then:

```sql
SELECT @@VERSION;
GO
QUIT
```

Inline password (be careful with shell history):

```bash
sqlcmd -S localhost -U SA -P 'YourStrong!Passw0rd' -C -Q "SELECT @@VERSION;"
```

## Change database

```bash
sqlcmd -S localhost -U SA -C

-- inside sqlcmd:
USE Ecommerce;
GO

SELECT DB_NAME();
GO
```

## Run a .sql file

```bash
sqlcmd -S localhost -U SA -C -i ./scripts/init-database.sql
```

With variables:

```bash
sqlcmd -S localhost -U SA -C \
  -v DbName='Ecommerce' \
  -i ./scripts/create-database-template.sql
```

`create-database-template.sql`:

```sql
CREATE DATABASE [$(DbName)];
GO
```

## Basic output formatting

Comma‑separated, trimmed:

```bash
sqlcmd -S localhost -U SA -C \
  -Q "SET NOCOUNT ON; SELECT name FROM sys.databases;" \
  -s "," -W
```
