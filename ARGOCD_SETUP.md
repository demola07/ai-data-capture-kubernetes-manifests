# ArgoCD Setup Guide

This guide covers installing and configuring ArgoCD on your Kubernetes cluster.

## 📋 Prerequisites

- Kubernetes cluster up and running
- `kubectl` configured and connected to cluster
- Helm 3.x installed ([Installation Guide](https://helm.sh/docs/intro/install/))
- AWS CLI configured (for NLB setup)

## 🚀 Quick Start

### Step 1: Install ArgoCD (Recommended Method - Helm)

```bash
cd scripts/
./install-argocd.sh
```

**What this does:**
- ✅ Installs latest ArgoCD version using Helm (production-ready)
- ✅ Configures NodePort service (ports 30080, 30443)
- ✅ Waits for all pods to be ready
- ✅ Retrieves initial admin password
- ✅ Provides access instructions

**Output includes:**
- Admin username and password
- Multiple access methods
- Next steps

### Step 2: Access ArgoCD

**Option A: Port Forward (Recommended for Initial Access)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```
Then open: http://localhost:8080

**Option B: NodePort (Direct Node Access)**
```bash
# Get worker node IP
kubectl get nodes -o wide

# Access via browser
http://<worker-node-ip>:30080
```

### Step 3: Login

- **Username:** `admin`
- **Password:** (shown in installation script output)

**Change password after first login:**
1. Click on "User Info" (top right)
2. Click "Update Password"
3. Enter current and new password

## 📁 Files Overview

### Scripts

| File | Purpose |
|------|---------|
| `scripts/install-argocd.sh` | Installs latest ArgoCD version using Helm with NodePort |

## 🔧 Configuration

### Helm Installation Options

The installation script uses these Helm values:

```yaml
server:
  service:
    type: NodePort
    nodePortHttp: 30080
    nodePortHttps: 30443
  extraArgs:
    - --insecure  # Allows HTTP access (Cloudflare handles SSL)
configs:
  params:
    server.insecure: true
```

### Custom Installation

To customize the installation, edit `scripts/install-argocd.sh` and modify the `helm upgrade --install` command:

```bash
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --set server.replicas=3 \  # Add HA
  --set redis-ha.enabled=true \  # Add Redis HA
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=30080 \
  --wait
```

## 🏗️ Architecture

```
Port Forward Access:
  Your Machine → kubectl → K8s API → ArgoCD Pods

NodePort Access:
  Browser → Worker Node IP:30080 → ArgoCD Pods
```

## 🔐 Security Best Practices

### 1. Change Default Password
```bash
# Via CLI
argocd account update-password

# Via UI
User Info → Update Password
```

### 2. Enable SSO (Optional)
Configure OIDC/SAML in ArgoCD settings for team access.

### 3. RBAC Configuration
Create ArgoCD projects and roles for different teams:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    p, role:developers, applications, *, */*, allow
    g, developers-team, role:developers
```

### 4. Network Policies
Restrict ArgoCD access to specific IPs:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-server-network-policy
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/16  # Your VPC CIDR
```

## 🔄 Upgrades

### Upgrade ArgoCD

```bash
# Update Helm repo
helm repo update

# Check available versions
helm search repo argo/argo-cd --versions

# Upgrade to specific version
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --version 5.52.0 \
  --reuse-values

# Or upgrade to latest
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --reuse-values
```

## 🗑️ Uninstallation

```bash
# Uninstall ArgoCD
helm uninstall argocd -n argocd

# Delete namespace
kubectl delete namespace argocd

# Remove NLB listener (if configured)
aws elbv2 delete-listener --listener-arn <listener-arn>

# Remove target group
aws elbv2 delete-target-group --target-group-arn <tg-arn>
```

## 🐛 Troubleshooting

### ArgoCD UI Not Accessible

**Check pod status:**
```bash
kubectl get pods -n argocd
```

**Check service:**
```bash
kubectl get svc argocd-server -n argocd
```

**Check logs:**
```bash
kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd
```

### NLB Health Checks Failing

**Check target health:**
```bash
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

**Common issues:**
- Security group not allowing NodePort (30080)
- ArgoCD pods not running
- NodePort service not configured

**Test NodePort directly:**
```bash
# SSH to worker node
curl http://localhost:30080
```

### Password Not Working

**Reset admin password:**
```bash
# Delete the secret
kubectl -n argocd delete secret argocd-initial-admin-secret

# Restart ArgoCD server
kubectl -n argocd rollout restart deployment argocd-server

# Get new password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## 📚 Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps with ArgoCD](https://argo-cd.readthedocs.io/en/stable/user-guide/gitops/)

## 🎯 Next Steps

After installing ArgoCD:

1. **Connect Git Repository**
   - Add your application repository
   - Configure SSH keys or tokens

2. **Create Application**
   - Define application in ArgoCD
   - Point to your Kubernetes manifests

3. **Enable Auto-Sync**
   - Configure automatic deployment
   - Set sync policies

4. **Set Up Notifications**
   - Configure Slack/email notifications
   - Monitor deployment status

5. **Implement GitOps Workflow**
   - Use Git as single source of truth
   - Automate deployments via Git commits
