# Logs and troubleshooting (Linux)

Where to look when SQL Server misbehaves on Linux.

## Log locations

Default:

```bash
ls -1 /var/opt/mssql/log
```

Key files:

- `errorlog` – main SQL Server log
- `errorlog.[1-6]` – rotated logs
- `<dbname>_log.trc` – trace logs (depends on config)

## View recent errors

```bash
tail -n 100 /var/opt/mssql/log/errorlog
```

Or with `less`:

```bash
less /var/opt/mssql/log/errorlog
```

## Systemd logs

```bash
sudo journalctl -u mssql-server --since "10 minutes ago"
```

Or:

```bash
sudo journalctl -u mssql-server -f
```

(follow mode)

## Common failure patterns

### Service failed to start

1. Check `systemctl status`:

   ```bash
   systemctl status mssql-server
   ```

2. Look at errorlog:

   ```bash
   tail -n 100 /var/opt/mssql/log/errorlog
   ```

3. Look at `journalctl` for startup errors:

   ```bash
   sudo journalctl -u mssql-server --since "10 minutes ago"
   ```

Common causes:

- Wrong permissions on data/log directories.
- Invalid TLS certificate paths (set via `mssql-conf`).
- Port conflicts (something else on 1433).

### Cannot connect from `sqlcmd` (local)

Check service:

```bash
systemctl status mssql-server
sudo ss -tulpn | grep 1433
```

If TLS error about self‑signed cert:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

### SA password issues

Reset SA password:

```bash
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl restart mssql-server
```

### Performance issues (high CPU / memory)

- Check active sessions:

  ```bash
  sqlcmd -S localhost -U SA -C -Q "SELECT * FROM sys.dm_exec_requests;"
  ```

- Check top queries (outline only; see MS docs for detailed DMVs).
- On Linux, also inspect:

  ```bash
  top
  htop
  iostat
  vmstat
  ```

## When in doubt

1. Capture:
   - `systemctl status mssql-server`
   - `tail -n 100 /var/opt/mssql/log/errorlog`
   - `sudo journalctl -u mssql-server --since "15 minutes ago"`

2. Keep these snippets around for bug reports or GitHub issues.
