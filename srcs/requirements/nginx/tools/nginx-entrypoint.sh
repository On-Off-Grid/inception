#!/bin/bash
set -e

mkdir -p /etc/nginx/ssl

if [ ! -f "/etc/nginx/ssl/inception.crt" ]; then
    echo "[NGINX] Generating self-signed TLS certificate for domain: ${DOMAIN_NAME:-sologin.42.fr}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME:-sologin.42.fr}"
fi

if [ -n "$DOMAIN_NAME" ]; then
    sed -i "s/server_name sologin.42.fr;/server_name ${DOMAIN_NAME};/g" /etc/nginx/conf.d/default.conf
fi

exec "$@"
