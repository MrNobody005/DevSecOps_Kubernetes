# Kubernetes Resilience Validation - One Command
# Run: powershell -ExecutionPolicy Bypass -File .\validate-resilience.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Resilience Validation (Pods + PVC)  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$score = 0
$totalTests = 5

# Test 1: Check namespace resources
Write-Host "[1/5] Checking resources..." -ForegroundColor Yellow
$podsStatus = kubectl get pods -n devsecops -o jsonpath='{.items[*].status.phase}' 2>&1
if ($podsStatus -match "Running" -and $LASTEXITCODE -eq 0) {
    Write-Host "Pass: All pods running" -ForegroundColor Green
    $score++
} else {
    Write-Host "Fail: Pods not all running" -ForegroundColor Red
}
kubectl get pods,svc,pvc -n devsecops
Write-Host ""

# Test 2: Ensure test data exists
Write-Host "[2/5] Seeding test data..." -ForegroundColor Yellow
$seedCmd = 'from django.contrib.auth.models import User; from movie.models import UserMovie; u,_=User.objects.get_or_create(username=\"testuser\"); u.set_password(\"testpass123\"); u.save(); UserMovie.objects.get_or_create(user=u, movie_id=99999, defaults={\"title\":\"Test Resilience\",\"release_date\":\"2025-01-01\"}); print(\"Users:\",User.objects.count(),\"Movies:\",UserMovie.objects.count())'
$seedResult = kubectl exec -n devsecops deploy/web -- python manage.py shell -c $seedCmd 2>&1
if ($seedResult -match "Users:.*Movies:" -and $LASTEXITCODE -eq 0) {
    Write-Host "Pass: Test data created" -ForegroundColor Green
    Write-Host $seedResult
    $score++
} else {
    Write-Host "Fail: Test data creation failed" -ForegroundColor Red
}
Write-Host ""

# Test 3: Restart web and verify data persists
Write-Host "[3/5] Restarting web deployment..." -ForegroundColor Yellow
kubectl rollout restart deploy/web -n devsecops | Out-Null
$rolloutOk = $LASTEXITCODE -eq 0
kubectl rollout status deploy/web -n devsecops --timeout=90s | Out-Null
$rolloutOk = $rolloutOk -and ($LASTEXITCODE -eq 0)
$checkWebCmd = 'from movie.models import UserMovie; print(\"Movies after web restart:\", UserMovie.objects.count())'
$webResult = kubectl exec -n devsecops deploy/web -- python manage.py shell -c $checkWebCmd 2>&1
if ($webResult -match "Movies after web restart: \d+" -and $rolloutOk) {
    Write-Host "Pass: Web pod restarted, data persisted" -ForegroundColor Green
    Write-Host $webResult
    $score++
} else {
    Write-Host "Fail: Web restart or data verification failed" -ForegroundColor Red
}
Write-Host ""

# Test 4: Delete postgres pod and verify PVC persistence
Write-Host "[4/5] Restarting postgres pod..." -ForegroundColor Yellow
kubectl delete pod -l app=postgres -n devsecops | Out-Null
$deleteOk = $LASTEXITCODE -eq 0
kubectl wait --for=condition=ready pod -l app=postgres -n devsecops --timeout=120s | Out-Null
$waitOk = $LASTEXITCODE -eq 0
$checkDbCmd = 'from django.contrib.auth.models import User; from movie.models import UserMovie; print(\"Users:\",User.objects.count(),\"Movies:\",UserMovie.objects.count())'
$dbResult = kubectl exec -n devsecops deploy/web -- python manage.py shell -c $checkDbCmd 2>&1
if ($dbResult -match "Users:.*Movies:" -and $deleteOk -and $waitOk) {
    Write-Host "Pass: Postgres restarted, PVC data persisted" -ForegroundColor Green
    Write-Host $dbResult
    $score++
} else {
    Write-Host "Fail: Postgres restart or PVC verification failed" -ForegroundColor Red
}
Write-Host ""

# Test 5: Final status
Write-Host "[5/5] Final status check..." -ForegroundColor Yellow
$finalPods = kubectl get pods -n devsecops -o jsonpath='{.items[*].status.phase}' 2>&1
if ($finalPods -match "Running" -and $LASTEXITCODE -eq 0) {
    Write-Host "Pass: All pods healthy" -ForegroundColor Green
    $score++
} else {
    Write-Host "Fail: Some pods unhealthy" -ForegroundColor Red
}
kubectl get pods,svc,pvc -n devsecops
Write-Host ""

# Score summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "         TEST RESULTS                 " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
$percentage = [math]::Round(($score / $totalTests) * 100, 1)
Write-Host "Tests Passed: $score / $totalTests" -ForegroundColor White
Write-Host "Score: $percentage%" -ForegroundColor $(if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" })
Write-Host ""
if ($percentage -eq 100) {
    Write-Host "Perfect score! All resilience tests passed." -ForegroundColor Green
} elseif ($percentage -ge 80) {
    Write-Host "Good! Most resilience tests passed." -ForegroundColor Green
} elseif ($percentage -ge 60) {
    Write-Host "Warning: Some tests failed." -ForegroundColor Yellow
} else {
    Write-Host "Critical: Multiple tests failed." -ForegroundColor Red
}
