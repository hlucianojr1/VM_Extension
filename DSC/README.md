# PowerShell DSC Configuration Files

This directory contains the PowerShell Desired State Configuration (DSC) scripts for deploying the .NET 4.8 Windows Service and ASP.NET 4.8 Web Application.

## Files in This Directory

### DscConfiguration.ps1
The main DSC configuration script that defines the desired state for:
- .NET Framework 4.8 installation
- IIS installation and configuration
- Windows Service deployment
- ASP.NET Web Application deployment
- Application Pool configuration

### DeployConfiguration.ps1
Orchestration script that:
- Validates source paths
- Loads the DSC configuration
- Generates MOF (Managed Object Format) files
- Applies the configuration to the local machine
- Provides interactive prompts and status updates

### VerifyConfiguration.ps1
Post-deployment verification script that checks:
- DSC configuration status
- Windows Service installation and status
- IIS website and application pool status
- Windows Features installation
- Web application accessibility
- Event logs

## Usage

### Basic Deployment

```powershell
# From the DSC directory
cd C:\code\VM_Extension\DSC

# Run the deployment script
.\DeployConfiguration.ps1
```

### Prerequisites

Before running the deployment, ensure:

1. **Built Applications**: Build the Windows Service and Web App first
   ```powershell
   cd C:\code\VM_Extension
   .\Build-Applications.ps1
   ```

2. **Required Modules**: Install PowerShell DSC modules
   ```powershell
   Install-Module -Name xWebAdministration -Force
   Install-Module -Name PSDesiredStateConfiguration -Force
   ```

3. **Administrator Rights**: Run PowerShell as Administrator

### Configuration Parameters

You can customize the deployment by editing `DeployConfiguration.ps1`:

```powershell
$params = @{
    NodeName                = "localhost"              # Target machine
    ServiceSourcePath       = "C:\code\DeploymentSource\WindowsService"
    ServiceDestinationPath  = "C:\code\services"       # Where to install service
    ServiceName             = "MyWindowsService"       # Service name
    ServiceExecutable       = "MyWindowsService.exe"   # Service EXE name
    WebAppSourcePath        = "C:\code\DeploymentSource\WebApp"
    WebAppName              = "MyWebApp"               # IIS site name
    WebAppPhysicalPath      = "C:\inetpub\MyWebApp"   # Web files location
    ConfigurationData       = $configData
    OutputPath              = "C:\code"                # MOF output location
}
```

## DSC Configuration Details

### Windows Features Installed

The configuration ensures these Windows features are present:
- NET-Framework-45-Core (.NET Framework 4.5+)
- NET-Framework-45-ASPNET (ASP.NET 4.5+)
- Web-Server (IIS)
- Web-Mgmt-Tools (IIS Management Tools)
- Web-Mgmt-Console (IIS Management Console)
- Web-Asp-Net45 (ASP.NET 4.5)
- Web-Net-Ext45 (.NET Extensibility 4.5)
- Web-ISAPI-Ext (ISAPI Extensions)
- Web-ISAPI-Filter (ISAPI Filters)

### DSC Resources Used

1. **WindowsFeature**: Installs Windows Features
2. **File**: Copies application files and creates directories
3. **Script**: Custom PowerShell scripts for service installation
4. **xWebAppPool**: Creates and configures IIS Application Pool
5. **xWebsite**: Creates and configures IIS Website

### Deployment Flow

1. Install .NET Framework 4.8 features
2. Install IIS with all required components
3. Create service directory and copy service files
4. Install and start Windows Service
5. Create web application directory and copy web files
6. Stop default IIS website (to free port 80)
7. Create dedicated Application Pool (v4.0, Integrated pipeline)
8. Create IIS Website with HTTP binding on port 80
9. Register ASP.NET 4.x with IIS

## Remote Deployment

To deploy to a remote Windows VM:

1. **Enable PowerShell Remoting on target VM:**
   ```powershell
   Enable-PSRemoting -Force
   Configure-SMBRemoting -Force
   ```

2. **Update NodeName in DeployConfiguration.ps1:**
   ```powershell
   NodeName = "RemoteVMName" # or IP address
   ```

3. **Copy deployment source files to accessible location:**
   ```powershell
   # Use UNC path or copy files to remote machine
   $ServiceSourcePath = "\\RemoteVM\Share\WindowsService"
   ```

4. **Apply configuration to remote machine:**
   ```powershell
   Start-DscConfiguration -Path "C:\code" -ComputerName "RemoteVMName" -Wait -Verbose -Force -Credential (Get-Credential)
   ```

## Troubleshooting

### Check DSC Status
```powershell
Get-DscConfigurationStatus -Verbose
Test-DscConfiguration -Verbose
```

### View DSC Logs
```powershell
Get-WinEvent -LogName "Microsoft-Windows-DSC/Operational" -MaxEvents 50 | Format-Table -Wrap
```

### Re-apply Configuration
```powershell
Start-DscConfiguration -Path "C:\code" -Wait -Verbose -Force
```

### Remove and Re-deploy

If you need to start fresh:

```powershell
# Stop and remove service
Stop-Service -Name "MyWindowsService" -ErrorAction SilentlyContinue
sc.exe delete "MyWindowsService"

# Remove IIS site
Remove-Website -Name "MyWebApp" -ErrorAction SilentlyContinue
Remove-WebAppPool -Name "MyWebApp-AppPool" -ErrorAction SilentlyContinue

# Clean up directories
Remove-Item -Path "C:\code\services" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\inetpub\MyWebApp" -Recurse -Force -ErrorAction SilentlyContinue

# Re-run deployment
.\DeployConfiguration.ps1
```

### Common Issues

#### "Source path not found"
- Ensure applications are built: `.\Build-Applications.ps1`
- Check that deployment source folders exist and contain files

#### "Service won't start"
- Check Event Viewer: Application logs
- Verify .NET 4.8 is installed: `Get-WindowsFeature NET-Framework-45-Core`
- Check service executable exists at destination

#### "Website returns 503 error"
- Check Application Pool state: `Get-WebAppPoolState -Name "MyWebApp-AppPool"`
- Restart Application Pool: `Restart-WebAppPool -Name "MyWebApp-AppPool"`
- Check IIS logs: `C:\inetpub\logs\LogFiles\`

#### "Port 80 already in use"
- Stop default website: `Stop-Website -Name "Default Web Site"`
- Or change binding in DscConfiguration.ps1 to use different port

## Advanced Customization

### Using HTTPS

Add SSL binding to the website configuration in `DscConfiguration.ps1`:

```powershell
xWebsite WebSite
{
    # ... existing configuration ...
    BindingInfo = @(
        MSFT_xWebBindingInformation
        {
            Protocol = "https"
            Port     = 443
            CertificateThumbprint = "YOUR_CERT_THUMBPRINT"
            CertificateStoreName = "My"
        }
    )
}
```

### Service Credentials

To run service under specific account:

```powershell
Script InstallWindowsService
{
    SetScript = {
        $credential = Get-Credential
        New-Service -Name $using:ServiceName `
            -BinaryPathName $exePath `
            -Credential $credential `
            -StartupType Automatic
    }
}
```

### Multiple Websites

Duplicate the xWebsite and xWebAppPool resources with different names and paths.

## Additional Resources

- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [xWebAdministration DSC Resource](https://github.com/dsccommunity/xWebAdministration)
- [DSC Best Practices](https://docs.microsoft.com/en-us/powershell/dsc/best-practices)
