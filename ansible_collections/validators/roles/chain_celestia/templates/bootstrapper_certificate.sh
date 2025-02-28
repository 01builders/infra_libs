#!/bin/sh

# Check if the certificate file exists
if ! ls /etc/letsencrypt/live/{{ chain_celestia_bootstrapper_public_domain }}/fullchain.pem 1> /dev/null; then
    # Generate certificate if it doesn't exist
    certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email devops@binary.builders \
        --agree-tos --non-interactive \
        --domains {{ chain_celestia_bootstrapper_public_domain }} \
        --deploy-hook /certbot_deploy_hook.sh
else
    # Renew certificate if it exists
    certbot renew --deploy-hook /certbot_deploy_hook.sh
fi
