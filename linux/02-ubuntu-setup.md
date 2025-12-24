# Ubuntu setup

SQL Server on Ubuntu using the unified installer script or manual steps.

Tested on Ubuntu 24.04 / Ubuntu‑like.

## 1. Prerequisites

- Ubuntu 24.04 (or similar).
- `sudo` configured for your user.
- Network access.

Check distro:

```bash
lsb_release -a 2>/dev/null || cat /etc/os-release
```

## 2. Quick install using the script

From this repo root:

```bash
chmod +x ./install-mssql-linux.sh
./install-mssql-linux.sh --log
```

Interactive answers (full local dev install):

```text
Q1) Continue with Microsoft SQL Server + tools installation? [Y/n]: y
Q2) Detected distro is ubuntu (...). Is this correct? [Y/n]: y
Q3) What do you want to install? → 1 (full)
Q4) Allow this script to add the Microsoft SQL Server apt repo if missing? [Y/n]: y
Q5) Is it OK to run apt-get update? [Y/n]: y
Q6) Install extra OS dependencies required by SQL Server? [Y/n]: y
Q7) Run 'mssql-conf setup' now? [Y/n]: y
Q8) Enable and start 'mssql-server' service? [Y/n]: y
Q9) Add /opt/mssql-tools*/bin to PATH in ~/.bashrc and ~/.zshrc? [Y/n]: y
Q10) Proceed with installation using these settings? [Y/n]: y
```

Log:

```bash
less ~/install-mssql.log
```

## 3. Manual install (Microsoft packages)

Add repo (24.04):

```bash
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/msprod.deb
sudo dpkg -i /tmp/msprod.deb
sudo apt-get update
```

Install engine:

```bash
sudo apt-get install -y mssql-server
```

Install tools:

```bash
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev
```

## 4. Service and initial config

Enable and start:

```bash
sudo systemctl enable --now mssql-server
systemctl status mssql-server
```

Run setup:

```bash
sudo /opt/mssql/bin/mssql-conf setup
sudo systemctl restart mssql-server
```

## 5. Tools on PATH

On Ubuntu, tools usually live in `/opt/mssql-tools18/bin`:

```bash
ls -1 /opt/mssql-tools18/bin
```

Add to PATH:

```bash
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

## 6. Quick verification

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

If you hit a TLS / certificate error, `-C` tells `sqlcmd` to trust the server’s self‑signed certificate for local dev.
