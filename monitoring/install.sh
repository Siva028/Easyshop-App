#!/bin/bash
set -e

ENV=${1:-dev}   # pass "dev" or "prod" — defaults to dev

echo "==> Installing kube-prometheus-stack for $ENV environment"

helm repo add prometheus-community   https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack   prometheus-community/kube-prometheus-stack   --namespace monitoring   --create-namespace   --values monitoring/values.$ENV.yaml   --wait   --timeout 5m

echo ""
echo "==> Installation complete"
echo ""
echo "==> Grafana admin password:"
kubectl get secret kube-prometheus-stack-grafana   -n monitoring   -o jsonpath="{.data.admin-password}" | base64 -d; echo

echo ""
echo "==> Access Grafana:"
echo "    kubectl port-forward svc/kube-prometheus-stack-grafana 3001:80 -n monitoring"
echo "    Then open: http://localhost:3001"
echo "    Username: admin"
echo ""
echo "==> Access Prometheus:"
echo "    kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring"
echo "    Then open: http://localhost:9090"
echo ""
echo "==> Apply ServiceMonitor and alerts:"
echo "    kubectl apply -f monitoring/servicemonitor.yaml"
echo "    kubectl apply -f monitoring/alerts.yaml"