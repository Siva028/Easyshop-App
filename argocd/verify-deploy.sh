#!/bin/bash
# Run after ArgoCD syncs to verify everything is healthy

echo "==> ArgoCD app status"
kubectl get applications -n argocd

echo ""
echo "==> Pods in easyshop-dev namespace"
kubectl get pods -n easyshop-dev

echo ""
echo "==> Services"
kubectl get svc -n easyshop-dev

echo ""
echo "==> Ingress"
kubectl get ingress -n easyshop-dev

echo ""
echo "==> MongoDB StatefulSet"
kubectl get statefulset -n easyshop-dev

echo ""
echo "==> Recent pod logs (app)"
kubectl logs -n easyshop-dev   -l app.kubernetes.io/name=easyshop   --tail=50

# ── Expected healthy state ────────────────────────────────────────
# PODS:
#   easyshop-xxxx   1/1   Running   0   2m
#   mongodb-0       1/1   Running   0   2m
#
# SERVICES:
#   easyshop-easyshop   ClusterIP   ...   80/TCP
#   mongodb-service     ClusterIP   None  27017/TCP
#
# INGRESS:
#   easyshop-easyshop   nginx   dev.easyshop.yourdomain.com   <EXTERNAL-IP>