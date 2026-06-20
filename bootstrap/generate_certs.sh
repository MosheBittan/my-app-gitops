#!/bin/bash
set -e

# Configuration
CA_NAME="MyLocalRootCA"
DOMAIN="moshe.lab"
CERT_NAME="ingress"

echo "--- 1. Generating Root CA ---"
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
  -subj "/C=IL/ST=South/L=TelAviv/O=Infrastructure/OU=DevOps/CN=$CA_NAME"

echo "--- 2. Generating Server Key and CSR ---"
openssl genrsa -out $CERT_NAME.key 2048
openssl req -new -key $CERT_NAME.key -out $CERT_NAME.csr \
  -subj "/C=IL/ST=South/L=TelAviv/O=Infrastructure/OU=DevOps/CN=app.$DOMAIN"

echo "--- 3. Creating v3.ext Configuration ---"
cat <<EOF > v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = app.$DOMAIN
DNS.2 = *.app.$DOMAIN
DNS.3 = argocd.$DOMAIN
DNS.4 = *.argocd.$DOMAIN
DNS.5 = grafana.$DOMAIN
DNS.6 = *.grafana.$DOMAIN
DNS.7 = prometheus.$DOMAIN
DNS.8 = *.prometheus.$DOMAIN
DNS.9 = jenkins.$DOMAIN
DNS.10 = *.jenkins.$DOMAIN
IP.1 = 127.0.0.1
EOF

echo "--- 4. Signing Certificate ---"
openssl x509 -req -in $CERT_NAME.csr -CA rootCA.crt -CAkey rootCA.key \
  -CAcreateserial -out $CERT_NAME.crt -days 365 -sha256 -extfile v3.ext

echo "--- Done! Files generated: rootCA.crt, $CERT_NAME.key, $CERT_NAME.crt ---"
