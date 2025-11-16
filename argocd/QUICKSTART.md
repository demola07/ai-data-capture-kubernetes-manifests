# ArgoCD Quick Start

## 🚀 Deploy Your Application with ArgoCD

### Step 1: Push to GitHub

```bash
git add .
git commit -m "Add ArgoCD configuration"
git push origin main
```

### Step 2: Create Secret (Not in Git)

```bash
kubectl apply -f manifests/secret.yaml
```

### Step 3: Deploy ArgoCD Application

```bash
kubectl apply -f argocd/application.yaml
```

### Step 4: Check Status

```bash
# Watch the application sync
kubectl get application -n argocd -w

# Or view in UI
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Open: http://localhost:8080
```

## ✅ What Gets Deployed

Only these files from `manifests/`:
- namespace.yaml
- deployment.yaml
- service.yaml
- hpa.yaml
- pdb.yaml
- networkpolicy.yaml
- rbac.yaml

**Excluded:** Gateway API files, secrets, certificates

## 🔄 Making Changes

1. Edit files in `manifests/`
2. Commit and push to GitHub
3. ArgoCD auto-syncs (within 3 minutes)
4. Check status in ArgoCD UI

## 🛠️ Common Commands

```bash
# View app status
kubectl get app -n argocd

# Force sync
argocd app sync ai-data-capture-api

# View diff
argocd app diff ai-data-capture-api

# Refresh (check for changes)
argocd app get ai-data-capture-api --refresh
```

## 📊 Expected Result

```
NAME                   SYNC STATUS   HEALTH STATUS
ai-data-capture-api    Synced        Healthy
```

That's it! Your application is now managed by GitOps! 🎉
