# Containers and Docker

Run SQL Server in Docker for dev and CI.

## Local SQL Server 2022 container

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name sql2022 \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

Check:

```bash
docker ps
sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"
```

Stop / start:

```bash
docker stop sql2022
docker start sql2022
```

Remove:

```bash
docker rm -f sql2022
```

## Use with apps (connection strings)

Typical local dev connection string:

```text
Server=localhost,1433;
Database=Ecommerce;
User ID=SA;
Password=YourStrong!Passw0rd;
Encrypt=True;
TrustServerCertificate=True;
```

Works with:

- .NET apps (`SqlConnection`)
- DBeaver
- Azure Data Studio
- VS Code SQL tools

## CI sketch

```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 \
  --name sqlci \
  -d mcr.microsoft.com/mssql/server:2022-latest

sleep 20

sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION;"

sqlcmd -S localhost -U SA -C -i ./migrations/001-init.sql

# dotnet test / npm test / etc.

docker rm -f sqlci
```
