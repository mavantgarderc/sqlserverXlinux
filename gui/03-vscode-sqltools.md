# VS Code SQL tools (SQL Server extension)

Using Visual Studio Code with SQL Server on Linux via the official **mssql** extension.

## 1. Install VS Code and the extension

Install VS Code (Arch / Ubuntu) via your usual method.

Then install the extension:

```bash
code --install-extension ms-mssql.mssql
```

Or via UI:

- Open VS Code → Extensions → search for “SQL Server (mssql)” → Install.

---

## 2. Create a connection profile

1. Open the **Command Palette**: `Ctrl+Shift+P`.
2. Run: **MS SQL: Connect**.
3. Choose **Create Connection Profile**.
4. Fill in:

   - **Server name**: `localhost,1433`
   - **Database name**: (leave blank for default, or `master`)
   - **Authentication type**: `SqlLogin`
   - **User name**: `SA`
   - **Password**: `YourStrong!Passw0rd`
   - **Save password?**: up to you
   - **Profile name**: e.g. `local-sqlserver`

5. When prompted, choose the profile to connect.

If you get an encryption / certificate error, see below.

---

## 3. Handle TLS / certificate issues

The mssql extension uses connection string options too. For **local dev** you can:

1. Open **Command Palette** → **Preferences: Open Settings (JSON)**.
2. Add or adjust:

   ```json
   "mssql.connections": [
     {
       "server": "localhost,1433",
       "database": "master",
       "authenticationType": "SqlLogin",
       "user": "SA",
       "password": "YourStrong!Passw0rd",
       "encrypt": true,
       "trustServerCertificate": true,
       "profileName": "local-sqlserver"
     }
   ]
   ```

- `encrypt: true`
- `trustServerCertificate: true` = equivalent to `sqlcmd -C`.

For production:

- Configure proper TLS on the server.
- Set `"trustServerCertificate": false`.

See: [`docs/05-security-and-tls.md`](../docs/05-security-and-tls.md).

---

## 4. Running queries in VS Code

1. Open a `.sql` file.
2. Choose the connection from the status bar (bottom right) or via:
   - **MS SQL: Connect** in the Command Palette.
3. Press `Ctrl+Shift+E` or click **Run** in the editor title bar.

Example:

```sql
SELECT @@VERSION;
GO

SELECT TOP (10) *
FROM sys.databases;
GO
```

Results will appear in the **Results** panel inside VS Code.

---

## 5. Snippets and query organization

- Use VS Code snippets for common T‑SQL patterns (CREATE TABLE, SELECT TOP, etc.).
- Save queries into a `sql/` folder in your repo and commit them:
  - `sql/001-init-database.sql`
  - `sql/010-schema.sql`
  - `sql/020-seed-data.sql`

You can reuse the same `.sql` files with:

- `sqlcmd` (CLI)
- VS Code (mssql)
- Azure Data Studio / DBeaver

---

## 6. Notes on other extensions

There are other SQL extensions (e.g. **SQLTools**), but for SQL Server specifically:

- The official `ms-mssql.mssql` extension is usually the best starting point.
- For a **Neovim**‑centric experience, see:  
  https://github.com/mavantgarderc/sqlserverXnvim
