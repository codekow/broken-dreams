#!/usr/bin/env bash
# Generate a self-signed CA + one wildcard server cert that covers BOTH demo
# subdomains via SAN. Self-signed is fine for this demo; swap in cert-manager /
# a real CA for anything real.
set -euo pipefail
cd "$(dirname "$0")/certs" 2>/dev/null || { mkdir -p "$(dirname "$0")/certs"; cd "$(dirname "$0")/certs"; }

PASS="*.pass.tlsdemo.apps.hub.k8socp.com"
REENC="*.reenc.tlsdemo.apps.hub.k8socp.com"

# 1) self-signed CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -days 365 \
  -subj "/CN=tlsdemo-selfsigned-ca/O=tlsdemo" -out ca.crt

# 2) multi-SAN wildcard server cert signed by that CA
openssl genrsa -out gw.key 2048
cat > gw.cnf <<EOF
[req]
distinguished_name = dn
req_extensions = ext
prompt = no
[dn]
CN = tlsdemo-gateway
O  = tlsdemo
[ext]
subjectAltName = DNS:${PASS}, DNS:${REENC}
EOF
openssl req -new -key gw.key -out gw.csr -config gw.cnf
openssl x509 -req -in gw.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 365 -extensions ext -extfile gw.cnf -out gw.crt

openssl verify -CAfile ca.crt gw.crt
echo "Wrote certs/{ca.crt,ca.key,gw.crt,gw.key}"
