# DevSecOps Kubernetes Deployment - Complete Guide

## 🎯 Overview
Django web application deployed on Kubernetes (minikube) with PostgreSQL database and persistent storage.

**Components:**
- Django web app (Python 3.11)
- PostgreSQL 15 database with PVC
- NodePort service for external access
- ConfigMap and Secrets for configuration

---

## 📋 Prerequisites

- **kubectl** installed and configured
- **minikube** running (or Docker Desktop Kubernetes)
- **Docker** for building images
- **PowerShell** 5.1+ (Windows)

---

## 🚀 Quick Start

### 1. Start Minikube
```powershell
minikube start
kubectl config use-context minikube
kubectl get nodes
```

### 2. Build and Load Image
```powershell
# Build image inside minikube
cd "C:\Users\malin\Desktop\Projet kurbernette\DevSecOps_Kubernetes"
minikube image build -t devsecops-kubernetes:latest .
```

### 3. Deploy to Kubernetes
```powershell
# Apply all manifests
kubectl apply -f .\k8s\namespace.yaml
kubectl apply -f .\k8s\configmap.yaml
kubectl apply -f .\k8s\secret.yaml
kubectl apply -f .\k8s\postgres.yaml
kubectl apply -f .\k8s\deployment.yaml
kubectl apply -f .\k8s\service.yaml

# Wait for rollout
kubectl rollout status deploy/devsecops-web -n devsecops
```

### 4. Initialize Database
```powershell
# Run migrations
kubectl exec -n devsecops deploy/devsecops-web -- python manage.py migrate

# Create admin user
kubectl exec -it -n devsecops deploy/devsecops-web -- python manage.py createsuperuser --noinput --username admin --email admin@test.com
```

### 5. Access Application
```powershell
# Get minikube IP
$ip = minikube ip
Write-Host "Access app at: http://${ip}:30080/"

# Open in browser
Start-Process "http://${ip}:30080/"
```

---

## ✅ Validation Tests

### Run Automated Test Script
```powershell
powershell -ExecutionPolicy Bypass -File .\test-validation.ps1
```

### Manual Verification

#### 1. External Access
```powershell
$ip = minikube ip

# Open in browser
Start-Process "http://${ip}:30080/"
```

#### 2. Data Persistence Test

**Create sample data:**
```powershell
kubectl exec -n devsecops deploy/devsecops-web -- python manage.py shell -c "from django.contrib.auth.models import User; from movie.models import UserMovie; u = User.objects.first(); UserMovie.objects.create(user=u, movie_id=99999, title='Resilience Test', release_date='2025-01-01'); print('Data created')"
```

**Restart pods:**
```powershell
kubectl rollout restart deploy/devsecops-web -n devsecops
kubectl rollout status deploy/devsecops-web -n devsecops
```

**Verify data persisted:**
```powershell
kubectl exec -n devsecops deploy/devsecops-web -- python manage.py shell -c "from movie.models import UserMovie; print(f'Movies after restart: {UserMovie.objects.count()}')"
```

✅ **Expected Result**: Data survives pod restart (stored in PostgreSQL with PVC)

---

## 🔧 Useful Commands

### View Resources
```powershell
# All resources in namespace
kubectl get all,pvc,configmap,secret -n devsecops

# Pod details
kubectl get pods -n devsecops -o wide

# Service details
kubectl get svc devsecops-web -n devsecops
```

### Logs and Debugging
```powershell
# View logs (follow)
kubectl logs -n devsecops deploy/devsecops-web --tail=50 -f

# Execute commands in pod
kubectl exec -it -n devsecops deploy/devsecops-web -- /bin/bash
```

### Database Operations
```powershell
# Django shell
kubectl exec -it -n devsecops deploy/devsecops-web -- python manage.py shell

# Run migrations
kubectl exec -n devsecops deploy/devsecops-web -- python manage.py migrate
```

---

## 📊 Validation Report

See `VALIDATION_REPORT.md` for detailed test results covering:
- ✅ External access verification
- ✅ Application feature testing
- ✅ Data persistence validation
- ✅ Pod resilience testing

---

**Status**: ✅ All validation tests passed  
**Last Updated**: November 27, 2025
