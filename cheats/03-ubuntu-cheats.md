# Ubuntu cheats for SQL Server

Tested on Ubuntu 24.04 / Ubuntu-like.

## Microsoft repo setup (manual)

```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/msprod.deb
sudo dpkg -i /tmp/msprod.deb
sudo apt-get update
```

(Your script does this automatically when allowed.)

## Install packages

Engine:

```bash
sudo apt-get install -y mssql-server
```

Tools:

```bash
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev
```

Verify:

```bash
dpkg -l | grep -E 'mssql-server|msodbcsql|mssql-tools'
```

## Service

```bash
sudo systemctl enable --now mssql-server
systemctl status mssql-server
```

## PATH for tools

```bash
ls -1 /opt/mssql-tools18/bin
```

Add to `~/.bashrc`:

```bash
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```
