#!/bin/bash

# Usage: ./create-secret.sh [dev|prod]
# Default: dev

ENV=${1:-dev}

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "Error: ENV must be 'dev' or 'prod'"
  exit 1
fi

NAMESPACE="easyshop-${ENV}"

NEXTAUTH_SECRET=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

echo "Generated secrets (save these somewhere safe):"
echo "NEXTAUTH_SECRET: $NEXTAUTH_SECRET"
echo "JWT_SECRET: $JWT_SECRET"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic easyshop-secrets \
  --namespace "$NAMESPACE" \
  --from-literal=NEXTAUTH_SECRET="$NEXTAUTH_SECRET" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Secret created in $NAMESPACE namespace."
echo "Verify: kubectl get secret easyshop-secrets -n $NAMESPACE"