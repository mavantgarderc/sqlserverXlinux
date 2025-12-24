# Security and TLS on Linux

Covers:

- SA account basics
- Local dev vs production recommendations
- TLS / encryption, including the common self‑signed certificate error

## SA account

- SA is the built‑in sysadmin login.
- For local dev:
  - Set a strong SA password.
  - Use SA for quick experiments.
- For production:
  - Disable or avoid SA.
  - Use named logins with least privilege.

Change SA password:

```bash
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl restart mssql-server
```
````

## Local dev vs production

Local dev (localhost):

- Acceptable to:
  - Use SA
  - Trust self‑signed certificate (`sqlcmd -C` or `trustServerCertificate=true`)
- Focus on:
  - Fast setup
  - Repeatable database rebuilds

Production:

- Create dedicated logins and users.
- Configure firewall / security groups.
- Enforce TLS with real certificates.
- Monitor backups and error logs.

## TLS and the self‑signed certificate error

Typical error with ODBC Driver 18:

```text
SSL Provider: ... certificate verify failed:self-signed certificate
Client unable to establish connection.
```

Cause:

- ODBC Driver 18 uses `Encrypt=yes` and `TrustServerCertificate=no` by default.
- SQL Server uses a self‑signed certificate if no real cert is configured.

### Quick fix (local dev): trust server certificate

`sqlcmd`:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

Connection string style:

```text
Server=localhost,1433;
User ID=SA;
Password=YourStrong!Passw0rd;
Encrypt=True;
TrustServerCertificate=True;
```

DBeaver:

- Connection → **Driver properties**:
  - `encrypt` → `true`
  - `trustServerCertificate` → `true`

### Proper TLS (production‑oriented)

High level steps:

1. Obtain a certificate (from a CA or internal PKI).
2. Install certificate + private key on the Linux host.
3. Configure SQL Server to use it:

   ```bash
   sudo /opt/mssql/bin/mssql-conf set network.tlscert /path/to/server.crt
   sudo /opt/mssql/bin/mssql-conf set network.tlskey /path/to/server.key
   sudo /opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2
   sudo systemctl restart mssql-server
   ```

4. On clients:
   - Use `Encrypt=True; TrustServerCertificate=False;`
   - Ensure the CA is trusted by the client OS.

For deeper details, see Microsoft docs on _"Configure encrypted connections to SQL Server on Linux"_.
