# MySQL Backup and Import Scripts

This repository contains two Bash scripts for managing MySQL databases:
1. `mysql-backup-databases.sh`: Creates SQL dumps of your databases
2. `mysql_import_databases.sh`: Restores databases from SQL dumps

Both scripts are designed to work with MySQL 8 and support SSL connections.

## Prerequisites

- Bash shell
- MySQL 8 client tools installed
- Access to a MySQL 8 server

## Installing MySQL (works with MariaDB also)

### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install mysql-server
```
or 


Schedule with cron
```back
sudo chmod +x /home/backups/backup-to-s3.sh
sudo crontab -e
```
Add `0 */12 * * * /home/backups/backup-to-s3.sh >> /var/log/backup-to-s3.log 2>&1` to the file.

## Backup Script (mysql-backup-databases.sh)

This script creates SQL dumps of your MySQL databases.

### Usage

```bash
./mysql-backup-databases.sh --mysql-host <host> --mysql-user <user> --mysql-password <password> [--mysql-port <port>] [--ca-cert <path>] [--backup-dir <path>] [--mysql-path <path>] [--ignore-list <db1,db2,...>]
```

### Parameters

- `--mysql-host`: MySQL server hostname (required)
- `--mysql-user`: MySQL user with privileges to read all databases (required)
- `--mysql-password`: Password for the MySQL user (required)
- `--mysql-port`: MySQL server port (optional, default: 3306)
- `--ca-cert`: Path to CA certificate file for SSL connection (optional)
- `--backup-dir`: Directory to store backup files (optional, default: ./backups)
- `--mysql-path`: Path to the directory containing MySQL executables (optional, default: /usr/bin)
- `--ignore-list`: Comma-separated list of databases to ignore (optional)

### Examples

1. Basic backup:
   ```bash
   ./mysql-backup-databases.sh --mysql-host "db.example.com" --mysql-user "backup_user" --mysql-password "securepass123" --backup-dir "/path/to/backups"
   ```

2. Backup with SSL and custom port:
   ```bash
   ./mysql-backup-databases.sh --mysql-host "db.example.com" --mysql-user "backup_user" --mysql-password "securepass123" --mysql-port 3307 --ca-cert "/path/to/ca-cert.pem" --backup-dir "/path/to/backups"
   ```

3. Backup with ignore list and custom MySQL path:
   ```bash
   ./mysql-backup-databases.sh --mysql-host "db.example.com" --mysql-user "backup_user" --mysql-password "securepass123" --ignore-list "test_db,temp_db" --mysql-path "/usr/local/mysql/bin" --backup-dir "/path/to/backups"
   ```

## Import Script (mysql_import_databases.sh)

This script restores databases from SQL dumps.

### Usage

```bash
./mysql_import_databases.sh --dest-mysql-host <host> --dest-mysql-user <user> --dest-mysql-password <password> --backup-dir <path> --new-user-password <password> [--dest-mysql-port <port>] [--ca-cert <path>] [--mysql-path <path>]
```

### Parameters

- `--dest-mysql-host`: Destination MySQL server hostname (required)
- `--dest-mysql-user`: MySQL user with privileges to create databases and users (required)
- `--dest-mysql-password`: Password for the MySQL user (required)
- `--backup-dir`: Directory containing the `.sql` backup files (required)
- `--new-user-password`: Password to set for newly created users (required)
- `--dest-mysql-port`: MySQL server port (optional, default: 3306)
- `--ca-cert`: Path to CA certificate file for SSL connection (optional)
- `--mysql-path`: Path to the directory containing MySQL executables (optional, default: /usr/bin)

### Examples

1. Basic import:
   ```bash
   ./mysql_import_databases.sh --dest-mysql-host "db.example.com" --dest-mysql-user "admin" --dest-mysql-password "adminpass123" --backup-dir "/path/to/backups" --new-user-password "newuserpass123"
   ```

2. Import with SSL and custom port:
   ```bash
   ./mysql_import_databases.sh --dest-mysql-host "db.example.com" --dest-mysql-user "admin" --dest-mysql-password "adminpass123" --dest-mysql-port 3307 --ca-cert "/path/to/ca-cert.pem" --backup-dir "/path/to/backups" --new-user-password "newuserpass123"
   ```

3. Import with custom MySQL path:
   ```bash
   ./mysql_import_databases.sh --dest-mysql-host "db.example.com" --dest-mysql-user "admin" --dest-mysql-password "adminpass123" --backup-dir "/path/to/backups" --new-user-password "newuserpass123" --mysql-path "/usr/local/mysql/bin"
   ```

## Notes

- Both scripts support SSL connections by providing the `--ca-cert` parameter.
- The backup script will create a separate `.sql` file for each database in the specified backup directory.
- The backup script removes the "tekprepp_" prefix from the backup filenames if present.
- The import script will create a new database for each `.sql` file in the backup directory if it doesn't already exist.
- For each imported database, the import script will create a new user with the same name as the database and grant full privileges on that database.
- Ensure that the MySQL users specified have sufficient privileges for their respective operations.
- The default MySQL path is set to `/usr/bin`. If your MySQL installation is in a different location, use the `--mysql-path` parameter to specify the correct path.
