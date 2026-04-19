#!/bin/bash
# Run this ONCE before ArgoCD does its first sync
# These are the real secrets injected into your pods at runtime
# Generate strong values — never commit these to Git

# ── Generate strong secret values ────────────────────────────────
NEXTAUTH_SECRET=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

echo "Generated secrets (save these somewhere safe):"
echo "NEXTAUTH_SECRET: $NEXTAUTH_SECRET"
echo "JWT_SECRET:      $JWT_SECRET"

# ── Create namespace first ────────────────────────────────────────
kubectl create namespace easyshop-dev --dry-run=client -o yaml | kubectl apply -f -

# ── Create the K8s Secret ─────────────────────────────────────────
kubectl create secret generic easyshop-secrets   --namespace easyshop-dev   --from-literal=NEXTAUTH_SECRET="$NEXTAUTH_SECRET"   --from-literal=JWT_SECRET="$JWT_SECRET"   --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Secret created in easyshop-dev namespace."
echo "Verify: kubectl get secret easyshop-secrets -n easyshop-dev"

# ── NOTE ──────────────────────────────────────────────────────────
# The --dry-run=client -o yaml | kubectl apply pattern is used
# so re-running this script updates the secret instead of failing
# with "already exists"