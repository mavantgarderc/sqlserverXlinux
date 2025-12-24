# Troubleshooting cheats

## mssql-server service not starting

Check status:

```bash
systemctl status mssql-server
sudo journalctl -u mssql-server --since "10 minutes ago"
```

Look at `/var/opt/mssql/log/errorlog`:

```bash
tail -n 100 /var/opt/mssql/log/errorlog
```

Common issues:

- Data/log directory permissions
- Wrong TLS cert/key paths
- Port conflicts (another service on 1433)

## sqlcmd TLS error (self‑signed certificate)

Symptom:

```text
SSL Provider: ... certificate verify failed:self-signed certificate
Client unable to establish connection.
```

Fix for local dev:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

Equivalent connection string:

```text
Encrypt=True;TrustServerCertificate=True;
```

## Cannot find sqlcmd

On Arch:

```bash
yay -Qi mssql-tools
ls -1 /opt/mssql-tools/bin
```

On Ubuntu:

```bash
dpkg -l | grep mssql-tools
ls -1 /opt/mssql-tools18/bin
```

Add to PATH:

```bash
echo 'export PATH="$PATH:/opt/mssql-tools/bin:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

## SA login / wrong password

If SA login fails:

1. Make sure SQL Server is running:

   ```bash
   systemctl status mssql-server
   ```

2. Reset SA password:

   ```bash
   sudo /opt/mssql/bin/mssql-conf set-sa-password
   sudo systemctl restart mssql-server
   ```

## Port connectivity

Check port 1433:

```bash
sudo ss -tulpn | grep 1433
```

From another machine:

```bash
nc -vz your-hostname 1433
```

If it fails, check firewall / `ufw` / security groups.
