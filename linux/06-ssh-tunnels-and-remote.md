# SSH tunnels and remote access

Access remote SQL Server over SSH without exposing port 1433 publicly.

## Basic SSH tunnel

Forward local 1433 → remote 1433:

```bash
ssh -L 1433:localhost:1433 user@remote-host
````

- Leave this terminal open.
- On your local machine, connect to `localhost,1433`.

`sqlcmd`:

```bash
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

DBeaver:

- Host: `localhost`
- Port: `1433`

## DBeaver built‑in SSH

Instead of manual `ssh -L`, DBeaver can manage tunnels:

1. Edit connection → **SSH** tab.
2. Enable SSH:
   - Host: `remote-host`
   - User: `user`
   - Auth method: password or key
3. Database connection:
   - Host: `localhost`
   - Port: `1433`

DBeaver will create an SSH tunnel and forward for you.

## Example workflows

### Remote prod over SSH, read‑only

1. Create a **read‑only** login on the remote SQL Server.
2. Set up:

   ```bash
   ssh -L 1433:localhost:1433 readonly@prod-db.example.com
   ```

3. Connect with:

   ```bash
   sqlcmd -S localhost -U readonly_user -C
   ```

4. Or connect from DBeaver / Azure Data Studio to `localhost:1433`.

### Multiple tunnels

You can use different local ports:

```bash
ssh -L 11433:localhost:1433 user@staging-db
ssh -L 12433:localhost:1433 user@prod-db
```

Then:

- Staging: `sqlcmd -S localhost,11433 ...`
- Prod: `sqlcmd -S localhost,12433 ...`
