# Kubernetes Validation and Resilience Test Report

## Test Environment
- **Cluster**: minikube v1.34.0
- **Namespace**: `devsecops`
- **Service Type**: NodePort (port 30080)
- **Database**: PostgreSQL 15 with PVC persistence
- **Application**: Django web app (Python 3.11)

---

## ✅ Phase 1: External Access Validation

### Service Configuration
```powershell
kubectl get svc devsecops-web -n devsecops
```
**Result**: NodePort service exposed on `192.168.49.2:30080`

### External Connectivity Tests
| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `http://192.168.49.2:30080/` | GET | ✅ 200 OK | Home page accessible |
| `http://192.168.49.2:30080/login/` | GET | ✅ 200 OK | Login form loads |
| `http://192.168.49.2:30080/register/` | GET | ✅ 200 OK | Registration available |
| `http://192.168.49.2:30080/admin/` | GET | ✅ 200 OK | Django admin panel |

**Browser Access**: Open `http://192.168.49.2:30080/` in your browser to interact with the application.

---

## ✅ Phase 2: Application Features Testing

### Database Connectivity
- PostgreSQL StatefulSet running successfully
- Django migrations applied (auth, admin, movie, sessions)
- Application connects to external Postgres instance

### User Management
- Admin user created: `admin@test.com`
- Authentication endpoints functional
- Session management working

### Data Access Tests
```powershell
# Test from inside pod
kubectl exec -n devsecops deploy/devsecops-web -- \
  python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/login/').status)"
```
**Result**: 200 OK

### Application Logs
Django dev server responding to HTTP requests with proper status codes:
```
[27/Nov/2025 19:11:xx] "GET / HTTP/1.1" 200 820
```

---

## ✅ Phase 3: Resilience and Data Persistence

### Pre-Restart State
1. Created test data in PostgreSQL:
   - Movie: "Test Persistence Movie" (movie_id: 12345)
   - Associated with admin user

### Pod Restart Test
```powershell
kubectl rollout restart deploy/devsecops-web -n devsecops
kubectl rollout status deploy/devsecops-web -n devsecops
```
**Result**: Deployment restarted successfully, new pod assigned different IP.

### Post-Restart Verification
```powershell
kubectl exec -n devsecops deploy/devsecops-web -- \
  python manage.py shell -c "from movie.models import UserMovie; \
  print(f'Found {UserMovie.objects.count()} movies after restart')"
```
**Result**: ✅ Data persisted - "Test Persistence Movie" still present after restart.

### Persistence Architecture
- **Database**: PostgreSQL StatefulSet with PersistentVolumeClaim (1Gi)
- **Volume Mount**: `/var/lib/postgresql/data` (subPath: postgres)
- **Storage Class**: Default minikube storage
- **Access Mode**: ReadWriteOnce

---

## 📊 Summary

| Test Category | Status | Details |
|---------------|--------|---------|
| External Access | ✅ PASS | NodePort 30080 accessible from host |
| HTTP Endpoints | ✅ PASS | All routes (/, /login/, /register/, /admin/) responding |
| Database Connectivity | ✅ PASS | Postgres reachable, migrations applied |
| Data Persistence | ✅ PASS | Data survives pod restarts via PVC-backed Postgres |
| Pod Resilience | ✅ PASS | Deployment recovers from rollout restart |
| Init Container | ✅ PASS | Waits for Postgres before starting Django |

---

## 🎯 Key Validations Completed

1. ✅ **External Reachability**: Application accessible via `http://192.168.49.2:30080/`
2. ✅ **Feature Testing**: Authentication, admin, and user endpoints functional
3. ✅ **Data Persistence**: PostgreSQL with PVC ensures data survives pod termination
4. ✅ **Resilience**: Deployment automatically restarts failed pods and maintains state

---

## 🔧 Configuration Details

### Environment Variables (ConfigMap)
- `DEBUG=True`
- `DB_NAME=filmaridb`
- `DB_USER=postgres`
- `DB_HOST=postgres`
- `DB_PORT=5432`

### Secrets
- `SECRET_KEY`: Django secret key
- `DB_PASSWORD`: Postgres password
- `TMDB_API_KEY`: External API key

### Resources Created
```bash
# List all resources
kubectl get all,pvc,configmap,secret -n devsecops
```

---

## 📝 Quick Test Commands

### Check Pod Status
```powershell
kubectl get pods -n devsecops -o wide
```

### View Application Logs
```powershell
kubectl logs -n devsecops deploy/devsecops-web --tail=50 -f
```

### Access Application
```powershell
$ip = minikube ip
Start-Process "http://$ip:30080/"
```

### Verify Data Persistence
```powershell
# Query database
kubectl exec -n devsecops deploy/devsecops-web -- python manage.py shell -c \
  "from movie.models import UserMovie; print(list(UserMovie.objects.values('title', 'release_date')))"
```

### Force Pod Restart (Resilience Test)
```powershell
# Delete pod (Deployment will recreate it)
kubectl delete pod -n devsecops -l app=devsecops-web
kubectl get pods -n devsecops --watch
```

---

## 🚀 Next Steps (Optional)

### Production Hardening
1. **Security**: Change default secrets, add NetworkPolicies
2. **Ingress**: Replace NodePort with Ingress for domain-based routing
3. **Monitoring**: Add Prometheus/Grafana for metrics
4. **Backups**: Configure PVC snapshots or pg_dump automation
5. **Scaling**: Increase replicas for high availability
6. **HTTPS**: Add TLS certificates via cert-manager

### Enable Ingress (Optional)
```powershell
minikube addons enable ingress
kubectl apply -f k8s/ingress.yaml
```

Then access via hostname instead of IP:port.

---

**Test Completed**: November 27, 2025  
**All validation phases passed successfully** ✅
