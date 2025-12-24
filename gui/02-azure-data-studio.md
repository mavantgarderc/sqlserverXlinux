# Azure Data Studio on Linux

Using **Azure Data Studio (ADS)** with SQL Server on Linux.

## 1. Install Azure Data Studio

Download from:  
https://learn.microsoft.com/sql/azure-data-studio/download-azure-data-studio

### Arch (AUR)

Look for an AUR package like `azure-data-studio-bin`:

```bash
yay -S azure-data-studio-bin
```

### Ubuntu (DEB)

Download the latest `.deb` and install:

```bash
wget https://azuredatastudiobuilds.blob.core.windows.net/releases/latest/azuredatastudio-linux.deb -O /tmp/azuredatastudio.deb
sudo apt install -y /tmp/azuredatastudio.deb
```

Verify:

```bash
azuredatastudio --help | head -n 3
```

---

## 2. Connect to local SQL Server

1. Open Azure Data Studio.
2. Click **New Connection** (or the plug icon in the sidebar).
3. Fill the connection dialog:
   - Connection type: `Microsoft SQL Server`
   - Server: `localhost,1433`
   - Authentication type: `SQL Login`
   - User name: `SA`
   - Password: `YourStrong!Passw0rd`
   - Database: (Default or `master`)

4. Click **Connect**.

If you get an encryption / certificate error, see next section.

---

## 3. TLS / encryption settings

ADS uses connection string properties under the hood.

For **local dev**, you typically want:

- `Encrypt` → `True`
- `Trust Server Certificate` → `True`  
  (equivalent to `TrustServerCertificate=True` in a connection string)

### Setting these options

1. In the **Connection Details** dialog:
   - Click **Advanced…** (or similar).
2. Under **Security** / **Additional parameters**, set:
   - `Encrypt` → `True`
   - `Trust Server Certificate` → `True`

Connect again.

For production:

- Configure a proper server certificate (see `docs/05-security-and-tls.md`).
- Set:
  - `Encrypt` → `True`
  - `Trust Server Certificate` → `False`

---

## 4. Basic usage

### 4.1 Run queries

1. After connecting, click **New Query**.
2. Ensure the correct database is selected from the dropdown (e.g. `Ecommerce`).
3. Example:

   ```sql
   SELECT @@VERSION;
   GO

   SELECT TOP (5) name, create_date
   FROM sys.databases
   ORDER BY name;
   GO
   ```

4. Press **F5** or click **Run**.

### 4.2 Object Explorer

- Use the **Connections** sidebar.
- Expand your server → Databases.
- Right‑click objects (tables, views, procedures) to:
  - Script as CREATE/ALTER
  - View data
  - Manage permissions (for appropriate logins)

### 4.3 Notebooks

ADS supports **SQL notebooks** (Markdown + code cells).

- New Notebook → add a SQL code cell.
- Useful for documenting learning steps or runbooks.

---

## 5. Connecting to Docker or remote instances

For Docker on the same machine (see `linux/05-containers-and-docker.md`):

- Server: `localhost,1433`
- Same credentials as container env vars.

For remote instances via SSH tunnel (see `linux/06-ssh-tunnels-and-remote.md`):

- Create SSH tunnel (`ssh -L 1433:localhost:1433 user@remote-host`).
- Use server: `localhost,1433` in ADS.

---

## 6. When to use Azure Data Studio vs DBeaver

- **Azure Data Studio**:
  - Strong SQL Server focus.
  - Notebooks, extensions, T‑SQL templates.
- **DBeaver**:
  - Great multi‑DB tool (Postgres, MySQL, Oracle, etc.).
  - If you switch between many DB engines, DBeaver might be more central.

Both can happily coexist. Use whichever feels better for the task.
