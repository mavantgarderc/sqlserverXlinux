# sqlcmd basics

## Help and version

```bash
sqlcmd -?
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

## Interactive session

```bash
sqlcmd -S localhost -U SA -C
```

Then:

```sql
SELECT DB_NAME();
GO
```

Exit:

```sql
QUIT
```

## One‑liner queries

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT name FROM sys.databases;"
```

Output as CSV‑like (set options in script):

```bash
sqlcmd -S localhost -U SA -C \
  -Q "SET NOCOUNT ON; SELECT name FROM sys.databases;" \
  -s "," -W
```

