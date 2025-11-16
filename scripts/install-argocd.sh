#!/bin/bash
# ArgoCD Installation Script
# Installs ArgoCD using Helm with NodePort configuration
#
# Usage: ./install-argocd.sh

set -e

# Configuration
ARGOCD_NAMESPACE="argocd"
ARGOCD_RELEASE_NAME="argocd"
NODEPORT_HTTP=30100
NODEPORT_HTTPS=30200

echo "Installing ArgoCD..."
echo ""

# Prerequisites check
command -v kubectl &> /dev/null || { echo "Error: kubectl not found"; exit 1; }
command -v helm &> /dev/null || { echo "Error: helm not found"; exit 1; }
kubectl cluster-info &> /dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }

# Create namespace
kubectl create namespace ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - > /dev/null

# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update > /dev/null

# Install ArgoCD
echo "Installing ArgoCD (this may take a few minutes)..."
helm upgrade --install ${ARGOCD_RELEASE_NAME} argo/argo-cd \
  --namespace ${ARGOCD_NAMESPACE} \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=${NODEPORT_HTTP} \
  --set server.service.nodePortHttps=${NODEPORT_HTTPS} \
  --set server.extraArgs[0]="--insecure" \
  --set configs.params."server\.insecure"=true \
  --wait \
  --timeout 10m

# Wait for ArgoCD server
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n ${ARGOCD_NAMESPACE} \
  --timeout=100s > /dev/null

# Get admin password
ARGOCD_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "✓ ArgoCD installed successfully!"
echo ""
echo "Access Information:"
echo "  Username: admin"
echo "  Password: ${ARGOCD_PASSWORD}"
echo ""
echo "Access via port-forward:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "  Then open: http://localhost:8080"
echo ""
echo "Access via NodePort:"
echo "  http://<worker-node-ip>:${NODEPORT_HTTP}"
echo ""
