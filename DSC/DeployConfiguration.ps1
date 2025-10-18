# DeployConfiguration.ps1
# This script generates the MOF file and applies the DSC configuration

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    exit 1
}

# Import the configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\DscConfiguration.ps1"

# Define configuration data
$configData = @{
    AllNodes = @(
        @{
            NodeName                    = "localhost"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }
    )
}

# Configuration parameters
$params = @{
    NodeName                = "localhost"
    ServiceSourcePath       = "C:\code\DeploymentSource\WindowsService"
    ServiceDestinationPath  = "C:\code\services"
    ServiceName             = "MyWindowsService"
    ServiceExecutable       = "MyWindowsService.exe"
    WebAppSourcePath        = "C:\code\DeploymentSource\WebApp"
    WebAppName              = "MyWebApp"
    WebAppPhysicalPath      = "C:\inetpub\MyWebApp"
    ConfigurationData       = $configData
    OutputPath              = "C:\code"
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PowerShell DSC Deployment Configuration" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verify source paths exist
Write-Host "Validating source paths..." -ForegroundColor Yellow
$sourcePaths = @(
    $params.ServiceSourcePath,
    $params.WebAppSourcePath
)

$missingPaths = @()
foreach ($path in $sourcePaths) {
    if (-not (Test-Path $path)) {
        $missingPaths += $path
        Write-Host "  [ERROR] Source path not found: $path" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Found: $path" -ForegroundColor Green
    }
}

if ($missingPaths.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: Some source paths are missing. Please ensure your applications are built and copied to the deployment source folders." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected locations:" -ForegroundColor Yellow
    Write-Host "  - Windows Service binaries: $($params.ServiceSourcePath)" -ForegroundColor Yellow
    Write-Host "  - Web App published files: $($params.WebAppSourcePath)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run the following to create and copy files:" -ForegroundColor Cyan
    Write-Host "  New-Item -Path 'C:\code\DeploymentSource\WindowsService' -ItemType Directory -Force" -ForegroundColor Cyan
    Write-Host "  New-Item -Path 'C:\code\DeploymentSource\WebApp' -ItemType Directory -Force" -ForegroundColor Cyan
    Write-Host "  Copy-Item -Path 'SampleWindowsService\bin\Release\*' -Destination 'C:\code\DeploymentSource\WindowsService\' -Recurse -Force" -ForegroundColor Cyan
    Write-Host "  Copy-Item -Path 'SampleWebApp\bin\Release\*' -Destination 'C:\code\DeploymentSource\WebApp\' -Recurse -Force" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
Write-Host "Configuration Parameters:" -ForegroundColor Yellow
Write-Host "  Node Name: $($params.NodeName)" -ForegroundColor White
Write-Host "  Service Source: $($params.ServiceSourcePath)" -ForegroundColor White
Write-Host "  Service Destination: $($params.ServiceDestinationPath)" -ForegroundColor White
Write-Host "  Service Name: $($params.ServiceName)" -ForegroundColor White
Write-Host "  Web App Source: $($params.WebAppSourcePath)" -ForegroundColor White
Write-Host "  Web App Destination: $($params.WebAppPhysicalPath)" -ForegroundColor White
Write-Host "  Web App Name: $($params.WebAppName)" -ForegroundColor White
Write-Host "  DSC Output Path: $($params.OutputPath)" -ForegroundColor White
Write-Host ""

# Generate MOF file
Write-Host "Generating DSC configuration (MOF file)..." -ForegroundColor Yellow
try {
    DeployDotNetApplication @params
    Write-Host "  [OK] MOF file generated successfully at: $($params.OutputPath)" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to generate MOF file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Would you like to apply this configuration now? (Y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-Host "Applying DSC configuration..." -ForegroundColor Yellow
    Write-Host "This may take several minutes..." -ForegroundColor Gray
    Write-Host ""
    
    try {
        Start-DscConfiguration -Path $params.OutputPath -Wait -Verbose -Force
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Green
        Write-Host "DSC Configuration Applied Successfully!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "  1. Verify the deployment with: .\VerifyConfiguration.ps1" -ForegroundColor White
        Write-Host "  2. Check Windows Service: Get-Service -Name '$($params.ServiceName)'" -ForegroundColor White
        Write-Host "  3. Test Web App: http://localhost/$($params.WebAppName)" -ForegroundColor White
        Write-Host ""
    } catch {
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Red
        Write-Host "ERROR: Failed to Apply Configuration" -ForegroundColor Red
        Write-Host "============================================" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "To troubleshoot:" -ForegroundColor Yellow
        Write-Host "  Get-DscConfigurationStatus -Verbose" -ForegroundColor White
        Write-Host "  Get-WinEvent -LogName 'Microsoft-Windows-DSC/Operational' -MaxEvents 20" -ForegroundColor White
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "Configuration generated but not applied." -ForegroundColor Yellow
    Write-Host "To apply later, run:" -ForegroundColor Cyan
    Write-Host "  Start-DscConfiguration -Path '$($params.OutputPath)' -Wait -Verbose -Force" -ForegroundColor White
    Write-Host ""
}
