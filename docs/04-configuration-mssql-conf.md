# Configuration with `mssql-conf`

`mssql-conf` is the main configuration tool for SQL Server on Linux.

Binary location:

```bash
ls -l /opt/mssql/bin/mssql-conf
```

## Initial setup

Interactive:

```bash
sudo /opt/mssql/bin/mssql-conf setup
```

This walks through:

- Edition (`MSSQL_PID`) – e.g., `Developer`
- SA password
- Telemetry preferences
- Default data/log directories

Unattended (non‑interactive):

```bash
export MSSQL_SA_PASSWORD='YourStrong!Passw0rd'
export MSSQL_PID='Developer'

sudo MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" MSSQL_PID="$MSSQL_PID" \
  /opt/mssql/bin/mssql-conf -n setup accept-eula
```

## Common configuration options

List current configuration:

```bash
sudo /opt/mssql/bin/mssql-conf list
```

Change TCP port (example: 1500):

```bash
sudo /opt/mssql/bin/mssql-conf set network.tcpport 1500
sudo systemctl restart mssql-server
```

Change default data/log directories:

```bash
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /data/mssql/data
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /data/mssql/log
sudo systemctl restart mssql-server
```

Change edition later (e.g., from Evaluation to Developer):

```bash
sudo /opt/mssql/bin/mssql-conf set-edition
sudo systemctl restart mssql-server
```

## Reset SA password

```bash
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl restart mssql-server
```

## Logs and diagnostics

Main logs:

```bash
ls -1 /var/opt/mssql/log
```

Example:

```bash
tail -n 100 /var/opt/mssql/log/errorlog
sudo journalctl -u mssql-server --since "10 minutes ago"
```
