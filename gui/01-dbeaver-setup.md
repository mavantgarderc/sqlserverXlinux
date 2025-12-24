# DBeaver setup (SQL Server on Linux)

How to use **DBeaver** with SQL Server running on Linux (Arch / Ubuntu), including TLS quirks and SSH.

## 1. Install DBeaver

### Arch

Community edition via `pacman` (if available in your repos) or via AUR:

```bash
sudo pacman -S dbeaver
# or (if you prefer AUR)
yay -S dbeaver
```

### Ubuntu

Download DEB from https://dbeaver.io/download/ or:

```bash
wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb -O /tmp/dbeaver.deb
sudo apt install -y ./tmp/dbeaver.deb
```

Verify:

```bash
dbeaver -help | head -n 3
```

---

## 2. Create a connection to local SQL Server

Assumes SQL Server is running locally (see `linux/01-arch-setup.md` or `linux/02-ubuntu-setup.md`).

### 2.1 Basic connection

1. Open DBeaver.
2. Click **New Database Connection**.
3. Choose **SQL Server** (Microsoft driver).
4. In the **Main** tab:
   - Host: `localhost`
   - Port: `1433`
   - Database: (empty or `master`)
   - User name: `SA`
   - Password: `YourStrong!Passw0rd`

5. Click **Test Connection**.

You may get a TLS / certificate error — see below.

---

## 3. Fix TLS / certificate errors (self‑signed cert)

With ODBC Driver 18 / SQL Server 2022, encryption is on by default.  
If SQL Server is using a **self‑signed** certificate (default on Linux), DBeaver may show an error like:

> The driver could not establish a secure connection to SQL Server.

### 3.1 For local dev (trust server cert)

1. Edit the connection → **Edit Connection…**.
2. Go to **Driver properties**.
3. Set:
   - `encrypt` → `true`
   - `trustServerCertificate` → `true`

4. Test the connection again.

This is equivalent to `sqlcmd -C` and is fine for **localhost dev**.

### 3.2 For stricter TLS (production)

- Configure a proper server certificate via `mssql-conf` (see `docs/05-security-and-tls.md`).
- In DBeaver:
  - `encrypt` → `true`
  - `trustServerCertificate` → `false`
  - Ensure the issuing CA is trusted on the client OS.

---

## 4. Use DBeaver with Docker‑hosted SQL Server

If you run SQL Server via Docker and bind to host `1433` (see `linux/05-containers-and-docker.md`):

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name sql2022 \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

Connection settings in DBeaver:

- Host: `localhost`
- Port: `1433`
- User: `SA`
- Password: `YourStrong!Passw0rd`

TLS settings are the same as for a local install (use `trustServerCertificate=true` for dev).

---

## 5. Use DBeaver over SSH

For connecting to **remote** SQL Server via SSH, you can:

- Use **DBeaver SSH** tab, or
- Use manual `ssh -L` tunnels (see `linux/06-ssh-tunnels-and-remote.md`).

### 5.1 Using DBeaver’s SSH tab

1. Edit connection → **SSH** tab.
2. Enable **Use SSH tunnel**.
3. SSH settings:
   - Host: `remote-host` (your server)
   - Port: `22`
   - User name: your SSH user
   - Authentication: password or key
4. **Tunnel**:
   - Local host: `localhost`
   - Local port: e.g. `1433`
5. **Database** tab:
   - Host: `localhost`
   - Port: `1433`

Test connection; DBeaver will establish the tunnel automatically.

### 5.2 Manual SSH tunnel

From a terminal:

```bash
ssh -L 1433:localhost:1433 user@remote-host
```

Then in DBeaver:

- Host: `localhost`
- Port: `1433`

---

## 6. Basic workflow in DBeaver

### 6.1 Browse databases and tables

- Open the **Database Navigator** panel.
- Expand your SQL Server connection.
- Expand **Databases → Ecommerce → Tables**.

Right‑click a table → **View Data** to inspect rows.

### 6.2 Run queries

1. Right‑click connection → **SQL Editor → New SQL Script**.
2. Pick `Ecommerce` as the database.
3. Example script:

   ```sql
   SELECT @@VERSION;
   GO

   SELECT TOP (10) Id, Email, FullName, CreatedAt
   FROM Customers
   ORDER BY Id DESC;
   GO
   ```

### 6.3 Export results as CSV

1. Run a query.
2. Right‑click in the result grid → **Export Data**.
3. Choose **CSV** as the format.
4. Follow the wizard to save to a file.

---

## 7. Tips

- Mark frequently used connections as **Favorites**.
- Use **Projects** to group connections and scripts.
- Save your common queries as `.sql` files and commit them alongside your app code.
