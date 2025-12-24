# Service management

Managing the `mssql-server` systemd service on Linux.

Applies to both Arch and Ubuntu.

## Check status

```bash
systemctl status mssql-server
```

## Start / stop / restart

```bash
sudo systemctl start mssql-server
sudo systemctl stop mssql-server
sudo systemctl restart mssql-server
```

## Enable / disable at boot

```bash
sudo systemctl enable mssql-server
sudo systemctl disable mssql-server
```

## Check listening ports

By default, SQL Server listens on TCP 1433.

```bash
sudo ss -tulpn | grep 1433
```

You should see a line with `sqlservr` and `:1433`.

If you have changed the port in `mssql-conf`, adjust accordingly.

## Changing TCP port

Set new port (example: 1500):

```bash
sudo /opt/mssql/bin/mssql-conf set network.tcpport 1500
sudo systemctl restart mssql-server
```

Verify:

```bash
sudo ss -tulpn | grep 1500
```

## Environment and limits

Often you don’t need to touch this, but for large systems:

- Systemd unit: `/usr/lib/systemd/system/mssql-server.service`
- Override file (recommended instead of editing the unit):

```bash
sudo systemctl edit mssql-server
```

Example override (for higher `LimitNOFILE`):

```ini
[Service]
LimitNOFILE=65535
```

Reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart mssql-server
```
