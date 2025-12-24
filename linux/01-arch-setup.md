# Arch Linux setup

SQL Server on Arch via AUR + the unified installer script.

## 1. Prerequisites

- Arch Linux or Arch‑based (EndeavourOS, Manjaro, etc.).
- `sudo` configured for your user.
- Network access.
- Optional but recommended: `yay` (AUR helper).

Check basics:

```bash
uname -a
lsb_release -a 2>/dev/null || cat /etc/os-release
```

## 2. Quick install using the script

From this repo root:

```bash
chmod +x ./install-mssql-linux.sh
./install-mssql-linux.sh --log
```

Typical interactive answers for a full local dev install:

```text
Q1) Continue with Microsoft SQL Server + tools installation? [Y/n]: y
Q2) Detected distro is arch (...). Is this correct? [Y/n]: y
Q3) What do you want to install? → 1 (full)
Q4) Allow this script to install and use 'yay'? [Y/n]: y
Q5) Is it OK to run package database update? [Y/n]: y or n (your choice)
Q6) Install extra OS dependencies required by SQL Server? [Y/n]: y
Q7) Run 'mssql-conf setup' now? [Y/n]: y
Q8) Enable and start 'mssql-server' service? [Y/n]: y
Q9) Add /opt/mssql-tools*/bin to PATH in ~/.bashrc and ~/.zshrc? [Y/n]: y
Q10) Proceed with installation using these settings? [Y/n]: y
```

Log file:

```bash
less ~/install-mssql.log
```

## 3. Manual AUR install (if you don’t want the script)

Install `yay` if needed:

```bash
sudo pacman -Sy --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
```

Install SQL Server packages:

```bash
yay -S mssql-server msodbcsql mssql-tools
```

Dependencies (usually pulled automatically, but safe to ensure):

```bash
sudo pacman -S --needed \
  curl ca-certificates git unixodbc krb5
```

## 4. Service and initial config

Enable and start service:

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

On Arch, tools live in `/opt/mssql-tools/bin`:

```bash
ls -1 /opt/mssql-tools/bin
```

If not already added by the script:

```bash
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

## 6. Quick verification

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

If you see a TLS error about self‑signed certificate, use the `-C` switch as shown (trust server cert for local dev).
