#!/bin/bash

# Usage: ./verify-deploy.sh [dev|prod]
# Default: dev

ENV=${1:-dev}

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "Error: ENV must be 'dev' or 'prod'"
  exit 1
fi

NAMESPACE="easyshop-${ENV}"
APP_NAME="easyshop-${ENV}"

echo "==> Verifying deployment for environment: $ENV (namespace: $NAMESPACE)"

echo ""
echo "==> ArgoCD app status"
kubectl get applications -n argocd "$APP_NAME"

echo ""
echo "==> Pods in $NAMESPACE namespace"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "==> Services"
kubectl get svc -n "$NAMESPACE"

echo ""
echo "==> Ingress"
kubectl get ingress -n "$NAMESPACE"

echo ""
echo "==> MongoDB StatefulSet"
kubectl get statefulset -n "$NAMESPACE"

echo ""
echo "==> Recent pod logs (app)"
kubectl logs -n "$NAMESPACE" -l app.kubernetes.io/name=easyshop --tail=50