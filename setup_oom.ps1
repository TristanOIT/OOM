# Save this as setup_oom.ps1 in your project root
# Right-click and "Run with PowerShell"

# Require admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

Write-Host "🚀 Starting OOM System Deployment..." -ForegroundColor Cyan

try {
    # 1. Install required software
    Write-Host "🔧 Checking system requirements..." -ForegroundColor Yellow
    if (-NOT (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "📦 Installing Chocolatey package manager..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    Write-Host "🐳 Installing Docker Desktop..." -ForegroundColor Yellow
    choco install docker-desktop -y
    
    Write-Host "📦 Installing Node.js (for frontend development)..." -ForegroundColor Yellow
    choco install nodejs-lts -y
    
    Write-Host "✅ Software installation complete" -ForegroundColor Green
}
catch {
    Write-Host "❌ Installation failed: $_" -ForegroundColor Red
    exit 1
}

try {
    # 2. Start Docker service
    Write-Host "🔌 Starting Docker Desktop..." -ForegroundColor Yellow
    Start-Service -Name "Docker Desktop Service" -ErrorAction Stop
    
    # Wait for Docker to be ready
    $retries = 0
    do {
        Start-Sleep -Seconds 5
        $dockerReady = (docker ps 2>&1 | Out-String) -notmatch "error"
        $retries++
    } while (-not $dockerReady -and $retries -lt 6)
    
    if (-not $dockerReady) {
        throw "Docker failed to start within 30 seconds"
    }
    
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker startup failed: $_" -ForegroundColor Red
    Write-Host "⚠️ Please start Docker Desktop manually and try again" -ForegroundColor Yellow
    exit 1
}

try {
    # 3. Build and start containers
    Set-Location $PSScriptRoot
    Write-Host "🏗️  Building OOM system containers..." -ForegroundColor Yellow
    docker-compose up --build -d
    
    Write-Host "🔄 Monitoring startup process..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10  # Allow containers to initialize
    
    Write-Host @"
    
    ✅ Deployment Successful!
    
    Access the system at:
    Frontend: http://localhost:80
    Backend API: http://localhost:5000/api
    
    To stop the system:
    docker-compose down
    
"@ -ForegroundColor Green
}
catch {
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    exit 1
}