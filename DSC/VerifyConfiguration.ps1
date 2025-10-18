# VerifyConfiguration.ps1
# This script verifies that the DSC configuration was applied successfully

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "DSC Configuration Verification" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration parameters (should match DeployConfiguration.ps1)
$serviceName = "MyWindowsService"
$webAppName = "MyWebApp"
$servicePath = "C:\code\services"
$webAppPath = "C:\inetpub\MyWebApp"

$allSuccess = $true

# Check DSC Configuration Status
Write-Host "1. Checking DSC Configuration Status..." -ForegroundColor Yellow
try {
    $dscStatus = Get-DscConfigurationStatus -ErrorAction Stop
    Write-Host "   Status: $($dscStatus.Status)" -ForegroundColor $(if ($dscStatus.Status -eq 'Success') { 'Green' } else { 'Red' })
    Write-Host "   Type: $($dscStatus.Type)" -ForegroundColor White
    Write-Host "   Mode: $($dscStatus.Mode)" -ForegroundColor White
    Write-Host "   Start Date: $($dscStatus.StartDate)" -ForegroundColor White
    
    if ($dscStatus.Status -ne 'Success') {
        $allSuccess = $false
    }
} catch {
    Write-Host "   [ERROR] Could not retrieve DSC status: $($_.Exception.Message)" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Check Windows Service
Write-Host "2. Checking Windows Service: $serviceName" -ForegroundColor Yellow
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   [OK] Service found" -ForegroundColor Green
    Write-Host "   Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Yellow' })
    Write-Host "   Start Type: $($service.StartType)" -ForegroundColor White
    Write-Host "   Display Name: $($service.DisplayName)" -ForegroundColor White
    
    if ($service.Status -ne 'Running') {
        Write-Host "   [WARNING] Service is not running" -ForegroundColor Yellow
        $allSuccess = $false
    }
} else {
    Write-Host "   [ERROR] Service not found" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Check Service Files
Write-Host "3. Checking Windows Service Files..." -ForegroundColor Yellow
if (Test-Path $servicePath) {
    Write-Host "   [OK] Service directory exists: $servicePath" -ForegroundColor Green
    $serviceFiles = Get-ChildItem -Path $servicePath -File
    Write-Host "   Files found: $($serviceFiles.Count)" -ForegroundColor White
    
    $exePath = Join-Path $servicePath "$serviceName.exe"
    if (Test-Path $exePath) {
        Write-Host "   [OK] Service executable found: $exePath" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Service executable not found: $exePath" -ForegroundColor Red
        $allSuccess = $false
    }
} else {
    Write-Host "   [ERROR] Service directory not found: $servicePath" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Check Windows Features
Write-Host "4. Checking Windows Features..." -ForegroundColor Yellow
$requiredFeatures = @(
    @{ Name = "Web-Server"; Description = "IIS Web Server" },
    @{ Name = "Web-Asp-Net45"; Description = "ASP.NET 4.5/4.8" },
    @{ Name = "Web-Net-Ext45"; Description = ".NET Extensibility 4.5" },
    @{ Name = "NET-Framework-45-Core"; Description = ".NET Framework 4.5+ Core" }
)

foreach ($feature in $requiredFeatures) {
    $installed = Get-WindowsFeature -Name $feature.Name -ErrorAction SilentlyContinue
    if ($installed -and $installed.Installed) {
        Write-Host "   [OK] $($feature.Description)" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] $($feature.Description) not installed" -ForegroundColor Red
        $allSuccess = $false
    }
}
Write-Host ""

# Check IIS Website
Write-Host "5. Checking IIS Website: $webAppName" -ForegroundColor Yellow
Import-Module WebAdministration -ErrorAction SilentlyContinue
$website = Get-Website -Name $webAppName -ErrorAction SilentlyContinue
if ($website) {
    Write-Host "   [OK] Website found" -ForegroundColor Green
    Write-Host "   State: $($website.State)" -ForegroundColor $(if ($website.State -eq 'Started') { 'Green' } else { 'Yellow' })
    Write-Host "   Physical Path: $($website.PhysicalPath)" -ForegroundColor White
    Write-Host "   Application Pool: $($website.ApplicationPool)" -ForegroundColor White
    
    foreach ($binding in $website.Bindings.Collection) {
        Write-Host "   Binding: $($binding.protocol)://$($binding.bindingInformation)" -ForegroundColor White
    }
    
    if ($website.State -ne 'Started') {
        Write-Host "   [WARNING] Website is not started" -ForegroundColor Yellow
        $allSuccess = $false
    }
} else {
    Write-Host "   [ERROR] Website not found" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Check Application Pool
Write-Host "6. Checking Application Pool: $webAppName-AppPool" -ForegroundColor Yellow
$appPool = Get-WebAppPoolState -Name "$webAppName-AppPool" -ErrorAction SilentlyContinue
if ($appPool) {
    Write-Host "   [OK] Application Pool found" -ForegroundColor Green
    Write-Host "   State: $($appPool.Value)" -ForegroundColor $(if ($appPool.Value -eq 'Started') { 'Green' } else { 'Yellow' })
    
    $appPoolConfig = Get-Item "IIS:\AppPools\$webAppName-AppPool" -ErrorAction SilentlyContinue
    if ($appPoolConfig) {
        Write-Host "   Runtime Version: $($appPoolConfig.managedRuntimeVersion)" -ForegroundColor White
        Write-Host "   Pipeline Mode: $($appPoolConfig.managedPipelineMode)" -ForegroundColor White
    }
    
    if ($appPool.Value -ne 'Started') {
        Write-Host "   [WARNING] Application Pool is not started" -ForegroundColor Yellow
        $allSuccess = $false
    }
} else {
    Write-Host "   [ERROR] Application Pool not found" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Check Web App Files
Write-Host "7. Checking Web Application Files..." -ForegroundColor Yellow
if (Test-Path $webAppPath) {
    Write-Host "   [OK] Web app directory exists: $webAppPath" -ForegroundColor Green
    $webFiles = Get-ChildItem -Path $webAppPath -File -Recurse
    Write-Host "   Files found: $($webFiles.Count)" -ForegroundColor White
    
    $webConfig = Join-Path $webAppPath "Web.config"
    if (Test-Path $webConfig) {
        Write-Host "   [OK] Web.config found" -ForegroundColor Green
    } else {
        Write-Host "   [WARNING] Web.config not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "   [ERROR] Web app directory not found: $webAppPath" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Test Web Application
Write-Host "8. Testing Web Application..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost/$webAppName" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "   [OK] Web app is responding" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor White
    Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor White
} catch {
    Write-Host "   [ERROR] Web app is not responding: $($_.Exception.Message)" -ForegroundColor Red
    $allSuccess = $false
}
Write-Host ""

# Check Event Logs
Write-Host "9. Checking Recent Event Logs..." -ForegroundColor Yellow
try {
    $serviceEvents = Get-EventLog -LogName Application -Source $serviceName -Newest 5 -ErrorAction SilentlyContinue
    if ($serviceEvents) {
        Write-Host "   Recent service events found: $($serviceEvents.Count)" -ForegroundColor Green
        foreach ($event in $serviceEvents) {
            $color = switch ($event.EntryType) {
                'Error' { 'Red' }
                'Warning' { 'Yellow' }
                default { 'White' }
            }
            Write-Host "   [$($event.EntryType)] $($event.TimeGenerated): $($event.Message.Substring(0, [Math]::Min(80, $event.Message.Length)))" -ForegroundColor $color
        }
    } else {
        Write-Host "   [INFO] No service events found yet" -ForegroundColor Gray
    }
} catch {
    Write-Host "   [INFO] Could not retrieve service events (this is normal for new services)" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
if ($allSuccess) {
    Write-Host "VERIFICATION SUCCESSFUL!" -ForegroundColor Green
    Write-Host "All components are deployed and running." -ForegroundColor Green
} else {
    Write-Host "VERIFICATION COMPLETED WITH WARNINGS/ERRORS" -ForegroundColor Yellow
    Write-Host "Please review the issues above." -ForegroundColor Yellow
}
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Additional commands
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  Service Status: Get-Service -Name '$serviceName'" -ForegroundColor White
Write-Host "  Service Logs: Get-EventLog -LogName Application -Source '$serviceName' -Newest 10" -ForegroundColor White
Write-Host "  Website Status: Get-Website -Name '$webAppName'" -ForegroundColor White
Write-Host "  Browse Web App: Start-Process 'http://localhost/$webAppName'" -ForegroundColor White
Write-Host "  DSC Status: Get-DscConfigurationStatus" -ForegroundColor White
Write-Host ""
