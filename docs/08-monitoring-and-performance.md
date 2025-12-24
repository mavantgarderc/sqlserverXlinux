# Monitoring and performance (Linux focus)

Lightweight view of checking health & performance for SQL Server on Linux.

Covers:

- Basic health checks
- OS‑level tools
- A few useful DMVs for queries and waits

---

## 1. Basic health / status checks

Service:

```bash
systemctl status mssql-server
sudo journalctl -u mssql-server --since "10 minutes ago"
```

Connectivity:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

Databases:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT name, create_date FROM sys.databases ORDER BY name;"
```

---

## 2. OS‑level monitoring

Useful Linux tools:

```bash
top          # or htop
iostat -xz 1 # requires sysstat package
vmstat 1
dmesg | tail
```

Install `sysstat` on Ubuntu:

```bash
sudo apt-get install -y sysstat
```

On Arch:

```bash
sudo pacman -S --needed sysstat
```

Look for:

- CPU saturation
- High I/O wait
- Memory pressure (swapping)

---

## 3. DMVs: active requests and sessions

### 3.1 Active requests

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
SELECT
    r.session_id,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.wait_type,
    r.wait_time,
    r.blocking_session_id,
    DB_NAME(r.database_id) AS database_name
FROM sys.dm_exec_requests AS r
WHERE r.session_id <> @@SPID
ORDER BY r.total_elapsed_time DESC;
GO
SQL
```

### 3.2 Sessions and logins

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time,
    s.memory_usage
FROM sys.dm_exec_sessions AS s
WHERE s.is_user_process = 1
ORDER BY s.cpu_time DESC;
GO
SQL
```

---

## 4. DMVs: top queries (high‑level)

**Note**: This is just a starting point; real performance tuning is deeper.

Top queries by total CPU:

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
SELECT TOP (20)
    qs.total_worker_time / 1000 AS total_cpu_ms,
    qs.execution_count,
    qs.total_worker_time / qs.execution_count / 1000 AS avg_cpu_ms,
    qs.total_elapsed_time / qs.execution_count / 1000 AS avg_elapsed_ms,
    SUBSTRING(st.text,
              (qs.statement_start_offset/2) + 1,
              ((CASE qs.statement_end_offset
                   WHEN -1 THEN DATALENGTH(st.text)
                   ELSE qs.statement_end_offset
               END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.total_worker_time DESC;
GO
SQL
```

---

## 5. Wait statistics (very high‑level)

Wait stats can hint at bottlenecks.

```bash
sqlcmd -S localhost -U SA -C <<'SQL'
SELECT TOP (20)
    wait_type,
    wait_time_ms,
    signal_wait_time_ms,
    waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE 'SLEEP%'
ORDER BY wait_time_ms DESC;
GO
SQL
```

Interpreting wait types requires deeper SQL Server knowledge; use MS documentation for each wait type.

---

## 6. Logs and errors

See:

- `linux/04-logs-and-troubleshooting.md`

Key commands:

```bash
tail -n 100 /var/opt/mssql/log/errorlog
sudo journalctl -u mssql-server --since "10 minutes ago"
```

Look for:

- Repeated restarts
- I/O errors
- Memory / resource exhaustion
- TLS / certificate issues

---

## 7. What this doc is and is not

This **is**:

- A minimal set of commands to:
  - Check health
  - See active requests
  - Spot heavy queries
  - Glance at wait stats

This is **not**:

- A full performance tuning guide.
- A replacement for a DBA or for official perf docs.

For deeper tuning, use:

- Official SQL Server performance docs
- Tools like Query Store, Extended Events, and dedicated monitoring tools.
