# DBeaver cheats

## New connection to local SQL Server

1. Open DBeaver → **New Database Connection**.
2. Choose **SQL Server** (Microsoft or jTDS, Microsoft preferred).
3. Connection settings:
   - Host: `localhost`
   - Port: `1433`
   - Database: (empty or `master`)
   - User name: `SA`
   - Password: `YourStrong!Passw0rd`

Click **Test Connection**.

## Fix TLS / certificate errors

If you get encryption / certificate errors:

- Open connection properties → **Driver properties**.
- Set:
  - `encrypt` → `true`
  - `trustServerCertificate` → `true` (for local dev)

This is equivalent to `sqlcmd -C`.

For stricter TLS (production):

- Configure a real certificate on the server.
- Then use:
  - `encrypt` → `true`
  - `trustServerCertificate` → `false`

See: [`docs/05-security-and-tls.md`](../docs/05-security-and-tls.md).

## Run queries

1. Right‑click connection → **SQL Editor → New SQL Script**.
2. Choose database `Ecommerce` (or any).
3. Example:

   ```sql
   SELECT @@VERSION;
   GO

   SELECT TOP (5) name, create_date
   FROM sys.databases
   ORDER BY name;
   GO
   ```

## Browse schema and data

- Expand connection → Databases → Tables.
- Right‑click a table → **View Data**.
- Use filters and sorting from the result grid header.

## Export to CSV

- After a query:
  - Right‑click result grid → **Export Data** → CSV.
