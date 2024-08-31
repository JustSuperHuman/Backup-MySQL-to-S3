#!/bin/bash

set -e

# Default MySQL path
DEFAULT_MYSQL_PATH="/usr/bin"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dest-mysql-host) DEST_MYSQL_HOST="$2"; shift ;;
    --dest-mysql-user) DEST_MYSQL_USER="$2"; shift ;;
    --dest-mysql-password) DEST_MYSQL_PASSWORD="$2"; shift ;;
    --dest-mysql-port) DEST_MYSQL_PORT="$2"; shift ;;
    --ca-cert) CA_CERT="$2"; shift ;;
    --backup-dir) BACKUP_DIR="$2"; shift ;;
    --mysql-path) MYSQL_PATH="$2"; shift ;;
    --new-user-password) NEW_USER_PASSWORD="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Set default port if not provided
DEST_MYSQL_PORT=${DEST_MYSQL_PORT:-3306}

# Set MySQL path
MYSQL_PATH=${MYSQL_PATH:-$DEFAULT_MYSQL_PATH}

# Validate required parameters
if [ -z "$DEST_MYSQL_HOST" ] || [ -z "$DEST_MYSQL_USER" ] || [ -z "$DEST_MYSQL_PASSWORD" ] || [ -z "$BACKUP_DIR" ] || [ -z "$NEW_USER_PASSWORD" ]; then
  echo "Missing required parameters. Please check your input."
  exit 1
fi

# Construct MySQL connection parameters
MYSQL_PARAMS="--host=$DEST_MYSQL_HOST --user=$DEST_MYSQL_USER --password=$DEST_MYSQL_PASSWORD --port=$DEST_MYSQL_PORT"

# Add CA certificate if provided
if [ ! -z "$CA_CERT" ]; then
  MYSQL_PARAMS="$MYSQL_PARAMS --ssl-ca=$CA_CERT --ssl-mode=VERIFY_CA"
fi

# Process each .sql file in the backup directory
for file in "$BACKUP_DIR"/*.sql; do
  [ -e "$file" ] || continue  # Handle case where no .sql files exist
  
  db_name=$(basename "$file" .sql)
  echo "Processing database: $db_name"

  # Create database if it doesn't exist
  $MYSQL_PATH/mysql $MYSQL_PARAMS -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;"

  # Import to destination
  echo "Importing database $db_name..."
  $MYSQL_PATH/mysql $MYSQL_PARAMS "$db_name" < "$file"

  # Create user and grant privileges
  new_user=$db_name
  echo "Creating user and granting privileges for $db_name..."
  $MYSQL_PATH/mysql $MYSQL_PARAMS << EOF
CREATE USER IF NOT EXISTS '$new_user'@'%' IDENTIFIED BY '$NEW_USER_PASSWORD';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$new_user'@'%';
FLUSH PRIVILEGES;
EOF
  echo "Created user '$new_user' with full access to database '$db_name'"
  echo "----------------------------------------"
done

echo "All databases have been imported to the MySQL server and users have been created."