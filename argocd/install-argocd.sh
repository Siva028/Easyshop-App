#!/bin/bash
# Run from your local machine — kubectl must be configured
# Verify first: kubectl get nodes

# ── Step 1: Install ArgoCD ────────────────────────────────────────
kubectl create namespace argocd

kubectl apply -n argocd   -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD pods..."
kubectl wait --for=condition=available deployment/argocd-server   -n argocd --timeout=180s

# ── Step 2: Expose ArgoCD UI via LoadBalancer ─────────────────────
# This gives ArgoCD a public IP so you can access the UI in browser
kubectl patch svc argocd-server -n argocd   -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for LoadBalancer IP to be assigned (takes ~60 seconds on AWS)
echo "Waiting for LoadBalancer IP..."
kubectl get svc argocd-server -n argocd --watch

# ── Step 3: Get ArgoCD admin password ─────────────────────────────
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret   -o jsonpath="{.data.password}" | base64 -d; echo

# ── Step 4: Install NGINX Ingress Controller ──────────────────────
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx   --namespace ingress-nginx   --create-namespace   --set controller.service.type=LoadBalancer   --wait

# ── Step 5: Install cert-manager ─────────────────────────────────
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.14.0   --set installCRDs=true   --wait

echo ""
echo "Done. Next steps:"
echo "1. Note ArgoCD LoadBalancer IP: kubectl get svc argocd-server -n argocd"
echo "2. Open https://<EXTERNAL-IP> in browser"
echo "3. Login: admin / <password from above>"
echo "4. Apply: kubectl apply -f argocd/cluster-issuer.yaml"
echo "5. Apply: kubectl apply -f argocd/application.dev.yaml"