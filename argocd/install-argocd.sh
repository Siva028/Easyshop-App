#!/bin/bash
# Run from your local machine — kubectl must be configured
# Verify first: kubectl get nodes

set -e

# ── Step 1: Install ArgoCD ────────────────────────────────────────
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd --server-side=true --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD pods..."
kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=180s

# ── Step 2: ArgoCD stays internal — exposed later via NGINX Ingress ─
echo "ArgoCD installed. Will be exposed via NGINX Ingress (not a separate LoadBalancer)."

# ── Step 3: Install NGINX Ingress Controller as NLB ───────────────
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
  --set controller.extraArgs.enable-ssl-passthrough=true \
  --wait

# ── Step 4: Install cert-manager ─────────────────────────────────
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.0 \
  --set installCRDs=true \
  --wait

# ── Step 5: Get NGINX LoadBalancer hostname ──────────────────────
echo ""
echo "Waiting for NGINX LoadBalancer hostname..."
while true; do
  NGINX_LB=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ -n "$NGINX_LB" ]; then
    echo "NGINX LoadBalancer hostname: $NGINX_LB"
    break
  fi
  echo "Still waiting..."
  sleep 10
done

# ── Step 6: Print ArgoCD admin password ───────────────────────────
echo ""
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

echo ""
echo "===================================================================="
echo "Done. Next steps:"
echo "===================================================================="
echo "1. In Route 53, create 3 A-Alias records pointing to NLB: $NGINX_LB"
echo "   - argocd.easyshop-siva.online"
echo "   - dev.easyshop-siva.online"
echo "   - easyshop-siva.online (root, leave name blank)"
echo ""
echo "2. After DNS propagates (1-2 min), apply:"
echo "   kubectl apply -f argocd/cluster-issuer.yaml"
echo "   kubectl apply -f argocd/argocd-ingress.yaml"
echo "   kubectl apply -f argocd/application.dev.yaml or argocd/application.prod.yaml"
echo ""
echo "3. Login at: https://argocd.easyshop-siva.online"
echo "   Username: admin"
echo "   Password: (printed above)"
echo "===================================================================="