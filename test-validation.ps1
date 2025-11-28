# Quick Test Script for Kubernetes Validation
# Run this after deploying the app to verify all functionality

Write-Host "=== Kubernetes Validation Test Script ===" -ForegroundColor Cyan
Write-Host ""

# Get minikube IP
$ip = minikube ip
Write-Host "[OK] Minikube IP: $ip" -ForegroundColor Green
Write-Host ""

# Test 1: External Access
Write-Host "Test 1: External Access" -ForegroundColor Yellow
Write-Host "Testing NodePort service on port 30080..."
try {
    $url = "http://" + $ip + ":30080/"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
    Write-Host "  [OK] Home page: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Home page failed" -ForegroundColor Red
}

try {
    $url = "http://" + $ip + ":30080/login/"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
    Write-Host "  [OK] Login page: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Login page failed" -ForegroundColor Red
}

Write-Host ""

# Test 2: Pod Status
Write-Host "Test 2: Pod Status" -ForegroundColor Yellow
$pods = kubectl get pods -n devsecops -o json | ConvertFrom-Json
foreach ($pod in $pods.items) {
    $status = $pod.status.phase
    $name = $pod.metadata.name
    if ($status -eq "Running") {
        Write-Host "  [OK] $name : $status" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $name : $status" -ForegroundColor Red
    }
}
Write-Host ""

# Test 3: Database Connectivity
Write-Host "Test 3: Database Connectivity" -ForegroundColor Yellow
$dbTest = kubectl exec -n devsecops deploy/devsecops-web -- python -c "from django.db import connection; connection.ensure_connection(); print('Connected')" 2>&1 | Out-String
if ($dbTest -match "Connected") {
    Write-Host "  [OK] Database connection successful" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Database connection failed" -ForegroundColor Red
}
Write-Host ""

# Test 4: Data Persistence
Write-Host "Test 4: Data Persistence Check" -ForegroundColor Yellow
$movieCount = kubectl exec -n devsecops deploy/devsecops-web -- python manage.py shell -c "from movie.models import UserMovie; print(UserMovie.objects.count())" 2>&1 | Out-String
$count = ($movieCount -split "`n" | Where-Object { $_ -match '^\d+$' }) | Select-Object -First 1
if ($count) {
    Write-Host "  [OK] Movies in database: $count" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Could not query database" -ForegroundColor Red
}
Write-Host ""

# Test 5: Service Endpoints
Write-Host "Test 5: Service Endpoints" -ForegroundColor Yellow
$endpoints = kubectl get endpoints devsecops-web -n devsecops -o json | ConvertFrom-Json
$endpointCount = 0
if ($endpoints.subsets) {
    foreach ($subset in $endpoints.subsets) {
        if ($subset.addresses) {
            $endpointCount += $subset.addresses.Count
        }
    }
}
Write-Host "  [OK] Active endpoints: $endpointCount" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
$url = "http://" + $ip + ":30080/"
Write-Host "Access your application at: $url" -ForegroundColor Green
Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Yellow
Write-Host "  View logs:        kubectl logs -n devsecops deploy/devsecops-web --tail=50 -f"
Write-Host "  Restart app:      kubectl rollout restart deploy/devsecops-web -n devsecops"
Write-Host "  Delete pod:       kubectl delete pod -n devsecops -l app=devsecops-web"
Write-Host "  Check resources:  kubectl get all,pvc -n devsecops"
Write-Host ""
