# Installation overview (Arch + Ubuntu)

Two main ways to install SQL Server + tools:

1. **Unified script**: `install-mssql-linux.sh` (recommended).
2. **Manual package install** (Arch AUR / Ubuntu apt).

This doc is the overview; distro details are in `linux/01-arch-setup.md` and `linux/02-ubuntu-setup.md`.

---

## 1. Using `install-mssql-linux.sh` (recommended)

From repo root:

```bash
chmod +x ./install-mssql-linux.sh
./install-mssql-linux.sh --log
```

Script capabilities:

- Detects distro (`arch`, `ubuntu`).
- Asks 10 questions:
  - Confirm distro
  - Install mode:
    - `full` (engine + tools)
    - `engine-only`
    - `client-only`
  - Package manager / AUR helper usage (`yay` on Arch)
  - System update permission
  - Extra dependencies
  - `mssql-conf setup` now?
  - Enable/start `mssql-server`?
  - Add tools to PATH?
- Writes a log file (`~/install-mssql.log`).

Non‑interactive (accept defaults):

```bash
./install-mssql-linux.sh --yes --log
```

If your script supports a stricter mode:

```bash
./install-mssql-linux.sh --non-interactive --yes --log
```

(Adjust to match your script’s CLI exactly.)

---

## 2. Install modes

### 2.1 Full

- Engine:
  - `mssql-server`
  - Full‑Text Search, Agent (depending on platform)
- Client tools:
  - `sqlcmd`, `bcp` via `mssql-tools` / `mssql-tools18`
  - ODBC driver (`msodbcsql` / `msodbcsql18`)

Use this on dev machines where you want everything local.

### 2.2 Engine only

- Installs `mssql-server` (and engine components).
- Skips tools and ODBC driver.

Useful for:

- Dedicated DB server where tools are on another box.
- Containers / minimal images (though official images are often easier).

### 2.3 Client tools only

- Installs:
  - ODBC driver (`msodbcsql` / `msodbcsql18`)
  - `mssql-tools` (`sqlcmd`, `bcp`, etc.)
- **No engine**.

Use this on:

- Jump hosts
- CI runners
- Workstations where SQL Server itself is remote

---

## 3. Manual install: Arch

Summary (see `linux/01-arch-setup.md` for full details).

1. Make sure `yay` is installed.
2. Install AUR packages:

   ```bash
   yay -S mssql-server msodbcsql mssql-tools
   ```

3. Enable and start service:

   ```bash
   sudo systemctl enable --now mssql-server
   ```

4. Run setup:

   ```bash
   sudo /opt/mssql/bin/mssql-conf setup
   sudo systemctl restart mssql-server
   ```

5. Ensure tools on PATH:

   ```bash
   echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

---

## 4. Manual install: Ubuntu

Summary (see `linux/02-ubuntu-setup.md`).

1. Add Microsoft repo:

   ```bash
   wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/msprod.deb
   sudo dpkg -i /tmp/msprod.deb
   sudo apt-get update
   ```

2. Install engine:

   ```bash
   sudo apt-get install -y mssql-server
   ```

3. Install tools:

   ```bash
   sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev
   ```

4. Enable and start:

   ```bash
   sudo systemctl enable --now mssql-server
   ```

5. Run setup:

   ```bash
   sudo /opt/mssql/bin/mssql-conf setup
   sudo systemctl restart mssql-server
   ```

6. PATH:

   ```bash
   echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

---

## 5. Post‑install checks

Common checks on both distros:

```bash
systemctl status mssql-server
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

If `sqlcmd` reports an SSL / self‑signed certificate error, the `-C` switch (trust server certificate) is expected for local dev. See `docs/05-security-and-tls.md` for more on TLS.
