#!/bin/bash
set -e

mkdir -p /var/www/wordpress /run/php

# Read secrets
if [ -f "/run/secrets/db_password" ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ -f "/run/secrets/wp_admin_password" ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
fi

if [ -f "/run/secrets/wp_user_password" ]; then
    WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
fi

# Validate admin username constraint (Must NOT contain admin or administrator)
if echo "$WP_ADMIN_USER" | grep -iqE "admin|administrator"; then
    echo "ERROR: WP_ADMIN_USER ('$WP_ADMIN_USER') contains forbidden substring ('admin'/'administrator')."
    exit 1
fi

echo "[WordPress] Waiting for MariaDB connection on mariadb:3306..."
until mysqladmin ping -h mariadb --silent; do
    sleep 2
done
echo "[WordPress] MariaDB is ready."

if [ ! -f "/var/www/wordpress/wp-config.php" ]; then
    echo "[WordPress] Downloading and setting up WordPress core..."
    wp core download --allow-root --path=/var/www/wordpress

    wp config create \
        --allow-root \
        --path=/var/www/wordpress \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306"

    echo "[WordPress] Installing WordPress..."
    wp core install \
        --allow-root \
        --path=/var/www/wordpress \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    echo "[WordPress] Creating second user..."
    wp user create \
        --allow-root \
        --path=/var/www/wordpress \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"

    echo "[WordPress] Setup complete."
fi

chown -R www-data:www-data /var/www/wordpress

exec "$@"
