# Kubernetes Resilience Validation - One Command
# Run: powershell -ExecutionPolicy Bypass -File .\validate-resilience.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Resilience Validation (Pods + PVC)  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check namespace resources
Write-Host "[1/5] Checking resources..." -ForegroundColor Yellow
kubectl get pods,svc,pvc -n devsecops
Write-Host ""

# Ensure test data exists
Write-Host "[2/5] Seeding test data..." -ForegroundColor Yellow
$seedCmd = "from django.contrib.auth.models import User; from movie.models import UserMovie; u,_=User.objects.get_or_create(username='testuser'); u.set_password('testpass123'); u.save(); UserMovie.objects.get_or_create(user=u, movie_id=99999, defaults={'title':'Test Resilience','release_date':'2025-01-01'}); print('Users:',User.objects.count(),'Movies:',UserMovie.objects.count())"
kubectl exec -n devsecops deploy/web -- python manage.py shell -c "$seedCmd"
Write-Host ""

# Restart web and verify data persists
Write-Host "[3/5] Restarting web deployment..." -ForegroundColor Yellow
kubectl rollout restart deploy/web -n devsecops | Out-Null
kubectl rollout status deploy/web -n devsecops --timeout=90s | Out-Null
$checkWebCmd = "from movie.models import UserMovie; print('Movies after web restart:', UserMovie.objects.count())"
kubectl exec -n devsecops deploy/web -- python manage.py shell -c "$checkWebCmd"
Write-Host ""

# Delete postgres pod and verify PVC persistence
Write-Host "[4/5] Restarting postgres pod..." -ForegroundColor Yellow
kubectl delete pod -l app=postgres -n devsecops | Out-Null
kubectl wait --for=condition=ready pod -l app=postgres -n devsecops --timeout=120s | Out-Null
$checkDbCmd = "from django.contrib.auth.models import User; from movie.models import UserMovie; print('Users:',User.objects.count(),'Movies:',UserMovie.objects.count())"
kubectl exec -n devsecops deploy/web -- python manage.py shell -c "$checkDbCmd"
Write-Host ""

# Final status
Write-Host "[5/5] Final status..." -ForegroundColor Yellow
kubectl get pods,svc,pvc -n devsecops
Write-Host ""
Write-Host "Validation complete ✅" -ForegroundColor Green
