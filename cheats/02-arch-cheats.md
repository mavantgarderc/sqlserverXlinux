# Arch Linux cheats for SQL Server

## Core packages from AUR

```bash
yay -Si mssql-server msodbcsql mssql-tools
```

Install manually (if you don't use the script):

```bash
yay -S mssql-server msodbcsql mssql-tools
```

Check installed:

```bash
yay -Qi mssql-server msodbcsql mssql-tools
```

## Dependencies (rough set)

```bash
sudo pacman -S --needed \
  curl ca-certificates git \
  unixodbc krb5
```

(Other dependencies like `openssl-1.1`, `libldap24` etc. are handled by AUR packages.)

## Service

```bash
sudo systemctl enable --now mssql-server
systemctl status mssql-server
```

## PATH for tools

Tools live in `/opt/mssql-tools/bin`:

```bash
ls -1 /opt/mssql-tools/bin
```

Add to `~/.bashrc` (if not using the script):

```bash
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```
