# Linux + SQL Server basics

Quick reference for working with SQL Server on Linux (Arch + Ubuntu).

## Service management

### Check status

```bash
systemctl status mssql-server
```

### Start / stop / restart

```bash
sudo systemctl start mssql-server
sudo systemctl stop mssql-server
sudo systemctl restart mssql-server
```

Enable at boot:

```bash
sudo systemctl enable mssql-server
```

## Logs

Main log directory:

```bash
ls -1 /var/opt/mssql/log
```

Tail errorlog:

```bash
tail -n 100 /var/opt/mssql/log/errorlog
sudo journalctl -u mssql-server --since "10 minutes ago"
```

## Check that SQL Server is listening

```bash
sudo ss -tulpn | grep 1433
```

You should see `sqlservr` bound to `0.0.0.0:1433` or `127.0.0.1:1433`.

## Quick `sqlcmd` smoke test (local dev)

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

- If you see a TLS error about self‑signed cert: this is normal with ODBC 18.  
  Use `-C` (trust server cert) as above for local dev.

## Data directories

Default on Linux:

```bash
ls -1 /var/opt/mssql
ls -1 /var/opt/mssql/data
```

Change via `mssql-conf`:

```bash
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /data/mssql/data
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /data/mssql/log
sudo systemctl restart mssql-server
```
