# Quick EC2 Deployment Script for Windows PowerShell
# Run this from your local machine

# Configuration - UPDATE THESE!
$EC2_IP = Read-Host "Enter your EC2 Elastic IP"
$KEY_PATH = "$HOME\.ssh\autoreportai-key.pem"

if ([string]::IsNullOrWhiteSpace($EC2_IP)) {
    Write-Host "ERROR: EC2 IP is required!" -ForegroundColor Red
    exit
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "AutoReportAI - EC2 Deployment Script" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Check if key exists
if (-not (Test-Path $KEY_PATH)) {
    Write-Host "ERROR: SSH key not found at $KEY_PATH" -ForegroundColor Red
    Write-Host "Please update the `$KEY_PATH variable in this script" -ForegroundColor Yellow
    exit
}

# Files to deploy
$files = @(
    "server.js",
    "package.json",
    "index.html",
    "styles.css",
    "script.js"
)

# Optional files (images)
$optionalFiles = @(
    "logo.png",
    "product-image.jpg"
)

Write-Host "Step 1: Uploading application files..." -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  Uploading $file..." -ForegroundColor Gray
        scp -i $KEY_PATH -o StrictHostKeyChecking=no $file "ubuntu@${EC2_IP}:~/autoreportai/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $file uploaded" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Failed to upload $file" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠ $file not found - skipping" -ForegroundColor Yellow
    }
}

# Upload optional files
foreach ($file in $optionalFiles) {
    if (Test-Path $file) {
        Write-Host "  Uploading $file..." -ForegroundColor Gray
        scp -i $KEY_PATH -o StrictHostKeyChecking=no $file "ubuntu@${EC2_IP}:~/autoreportai/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $file uploaded" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⚠ $file not found - skipping" -ForegroundColor Yellow
    }
}

# Upload setup scripts
Write-Host ""
Write-Host "Step 2: Uploading setup scripts..." -ForegroundColor Cyan
scp -i $KEY_PATH -o StrictHostKeyChecking=no setup-complete.sh "ubuntu@${EC2_IP}:~/"
scp -i $KEY_PATH -o StrictHostKeyChecking=no start-app.sh "ubuntu@${EC2_IP}:~/"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Upload Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next: SSH into EC2 and run:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ssh -i $KEY_PATH ubuntu@$EC2_IP" -ForegroundColor Cyan
Write-Host ""
Write-Host "Then on EC2, run these commands:" -ForegroundColor Yellow
Write-Host "  chmod +x ~/setup-complete.sh ~/start-app.sh" -ForegroundColor Cyan
Write-Host "  ./setup-complete.sh" -ForegroundColor Cyan
Write-Host "  ./start-app.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "Then set up SSL:" -ForegroundColor Yellow
Write-Host "  sudo certbot --nginx -d autoreportform.click -d www.autoreportform.click" -ForegroundColor Cyan
Write-Host ""
Write-Host "Done! Your site will be live at https://autoreportform.click" -ForegroundColor Green
Write-Host ""
