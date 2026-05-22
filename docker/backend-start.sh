#!/bin/sh
set -eu

DB_NAME="${MYSQL_DATABASE:-billing_app}"
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mariadb://127.0.0.1:3306/$DB_NAME}"
export SPRING_DATASOURCE_DRIVER_CLASS_NAME="${SPRING_DATASOURCE_DRIVER_CLASS_NAME:-org.mariadb.jdbc.Driver}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-root}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${MYSQL_ROOT_PASSWORD:-change-me-in-production}}"

i=0
while [ "$i" -lt 60 ]; do
  if mariadb -h 127.0.0.1 --protocol=tcp -u"$SPRING_DATASOURCE_USERNAME" -p"$SPRING_DATASOURCE_PASSWORD" "$DB_NAME" -e "SELECT 1" >/dev/null 2>&1; then
    exec java -jar /app/app.jar
  fi
  i=$((i + 1))
  sleep 1
done

echo "Database was not ready after 60 seconds" >&2
exit 1
