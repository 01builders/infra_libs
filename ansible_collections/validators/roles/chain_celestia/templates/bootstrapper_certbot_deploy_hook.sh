#!/bin/sh
# Path to the certificate directory
CERT_DIR=/etc/letsencrypt/live/{{ chain_celestia_bootstrapper_public_domain }}/

# Destination path
DESTINATION=/home/{{ chain_celestia_user }}/celestia-bootstrapper-certs/

owner_uid=$(stat -c '%u' ${DESTINATION})

# Copy the full certificate chain and private key
cp -f ${CERT_DIR}fullchain.pem ${DESTINATION}/cert.pem
cp -f ${CERT_DIR}privkey.pem ${DESTINATION}/key.pem

chown ${owner_uid}:100 ${DESTINATION}/cert.pem
chown ${owner_uid}:100 ${DESTINATION}/key.pem
