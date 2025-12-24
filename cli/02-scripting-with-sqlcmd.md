# Scripting with sqlcmd

## Run migration scripts in order

Directory:

```text
migrations/
  001-create-database.sql
  010-schema.sql
  020-seed-data.sql
```

Bash script:

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVER="localhost"
USER="SA"
PASSWORD="YourStrong!Passw0rd"

run() {
  local file="$1"
  echo "Running $file..."
  sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -C -i "$file"
}

run ./migrations/001-create-database.sql
run ./migrations/010-schema.sql
run ./migrations/020-seed-data.sql

echo "Migrations complete."
```

Make executable and run:

```bash
chmod +x ./scripts/run-migrations.sh
./scripts/run-migrations.sh
```
