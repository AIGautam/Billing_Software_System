#!/bin/sh
set -eu

DATADIR=/var/lib/mysql
SOCKET=/run/mysqld/mysqld.sock
DB_NAME="${MYSQL_DATABASE:-billing_app}"
ROOT_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${MYSQL_ROOT_PASSWORD:-change-me-in-production}}"

sql_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

wait_for_socket() {
  i=0
  while [ "$i" -lt 60 ]; do
    if mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  echo "MariaDB did not start in time" >&2
  return 1
}

mkdir -p /run/mysqld "$DATADIR"
chown -R mysql:mysql /run/mysqld "$DATADIR"

if [ ! -d "$DATADIR/mysql" ]; then
  mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db >/dev/null

  mariadbd --user=mysql --datadir="$DATADIR" --socket="$SOCKET" --skip-networking &
  bootstrap_pid="$!"
  wait_for_socket

  escaped_db="$(sql_escape "$DB_NAME")"
  escaped_password="$(sql_escape "$ROOT_PASSWORD")"

  mariadb --socket="$SOCKET" -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`$escaped_db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$escaped_password';
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '$escaped_password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

  if [ -f /docker-entrypoint-initdb.d/billing_app.sql ]; then
    sed 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' /docker-entrypoint-initdb.d/billing_app.sql \
      | mariadb --socket="$SOCKET" -uroot -p"$ROOT_PASSWORD" "$DB_NAME"
  fi

  mariadb-admin --socket="$SOCKET" -uroot -p"$ROOT_PASSWORD" shutdown
  wait "$bootstrap_pid" || true
fi

exec mariadbd --user=mysql --datadir="$DATADIR" --socket="$SOCKET" --bind-address=127.0.0.1 --port=3306 --skip-networking=0
