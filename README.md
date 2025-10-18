# PowerShell DSC Deployment Solution

This solution demonstrates how to deploy a .NET 4.8 Windows Service and ASP.NET 4.8 Web Application to a Windows VM using PowerShell Desired State Configuration (DSC).

## Solution Structure

```
C:\code\VM_Extension\
??? DSC/
?   ??? DscConfiguration.ps1          # Main DSC configuration script
?   ??? DeployConfiguration.ps1       # Script to generate and apply configuration
?   ??? VerifyConfiguration.ps1       # Script to verify the deployment
??? SampleWindowsService/
?   ??? MyWindowsService.csproj       # Windows Service project
?   ??? Program.cs                    # Service entry point
?   ??? MyService.cs                  # Service implementation
?   ??? App.config                    # Service configuration
??? SampleWebApp/
?   ??? MyWebApp.csproj              # ASP.NET Web App project
?   ??? Default.aspx                  # Sample web page
?   ??? Default.aspx.cs               # Code-behind
?   ??? Web.config                    # Web app configuration
??? README.md                         # This file
```

## Prerequisites

### On Your Development Machine
- Visual Studio 2019 or later
- .NET Framework 4.8 Developer Pack
- PowerShell 5.1 or later

### On the Target Windows VM
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrator access

## Quick Start Guide

### Step 1: Build the Applications

1. Open PowerShell in the solution directory:
   ```powershell
   cd C:\code\VM_Extension
   ```

2. Build the Windows Service:
   ```powershell
   cd SampleWindowsService
   dotnet build -c Release
   # Or use MSBuild if dotnet CLI doesn't work with .NET Framework
   msbuild MyWindowsService.csproj /p:Configuration=Release
   cd ..
   ```

3. Build the Web Application:
   ```powershell
   cd SampleWebApp
   msbuild MyWebApp.csproj /p:Configuration=Release /p:DeployOnBuild=true /p:PublishProfile=FileSystem
   cd ..
   ```

### Step 2: Prepare Deployment Package

1. Copy built files to deployment source folders:
   ```powershell
   # Create source directories
   New-Item -Path "C:\code\DeploymentSource\WindowsService" -ItemType Directory -Force
   New-Item -Path "C:\code\DeploymentSource\WebApp" -ItemType Directory -Force
   
   # Copy Windows Service binaries
   Copy-Item -Path "SampleWindowsService\bin\Release\*" -Destination "C:\code\DeploymentSource\WindowsService\" -Recurse -Force
   
   # Copy Web App published files
   Copy-Item -Path "SampleWebApp\bin\Release\Publish\*" -Destination "C:\code\DeploymentSource\WebApp\" -Recurse -Force
   ```

### Step 3: Install Required DSC Modules

Run PowerShell as Administrator:
```powershell
# Install required PowerShell modules
Install-Module -Name xWebAdministration -Force -Scope AllUsers
Install-Module -Name PSDesiredStateConfiguration -Force -Scope AllUsers

# Verify installation
Get-DscResource -Module xWebAdministration
```

### Step 4: Deploy Using DSC

1. Navigate to the DSC directory:
   ```powershell
   cd C:\code\VM_Extension\DSC
   ```

2. Review and update the `DeployConfiguration.ps1` file with your specific settings:
   - Service name
   - Web app name
   - Source paths
   - Destination paths

3. Run the deployment:
   ```powershell
   # Load the configuration
   . .\DscConfiguration.ps1
   
   # Execute the deployment
   . .\DeployConfiguration.ps1
   ```

4. Verify the deployment:
   ```powershell
   . .\VerifyConfiguration.ps1
   ```

### Step 5: Test the Applications

1. **Test Windows Service:**
   ```powershell
   Get-Service -Name "MyWindowsService"
   Get-EventLog -LogName Application -Source "MyWindowsService" -Newest 10
   ```

2. **Test Web Application:**
   - Open browser and navigate to: `http://localhost/MyWebApp`
   - Or use PowerShell:
     ```powershell
     Invoke-WebRequest -Uri "http://localhost/MyWebApp" -UseBasicParsing
     ```

## Configuration Options

### Customizing the Service

Edit `DscConfiguration.ps1` and modify these parameters in the deployment call:
- `ServiceName`: Name of the Windows Service
- `ServiceExecutable`: Name of the service executable file
- `ServiceDestinationPath`: Where to install the service

### Customizing the Web App

- `WebAppName`: Name of the IIS website
- `WebAppPhysicalPath`: Physical path for web files
- Port and bindings (in the `xWebsite` resource)

### Remote Deployment

To deploy to a remote VM:

1. Enable PowerShell Remoting on the target VM:
   ```powershell
   Enable-PSRemoting -Force
   ```

2. Update `DeployConfiguration.ps1` to use remote node name:
   ```powershell
   -NodeName "RemoteVMName"
   ```

3. Apply configuration to remote machine:
   ```powershell
   Start-DscConfiguration -Path "C:\code" -ComputerName "RemoteVMName" -Wait -Verbose -Force
   ```

## Troubleshooting

### DSC Configuration Issues

1. Check DSC logs:
   ```powershell
   Get-DscConfigurationStatus -Verbose
   Get-WinEvent -LogName "Microsoft-Windows-DSC/Operational" -MaxEvents 20
   ```

2. Test configuration without applying:
   ```powershell
   Test-DscConfiguration -Path "C:\code" -Verbose
   ```

### Service Issues

1. Check if service is installed:
   ```powershell
   Get-Service -Name "MyWindowsService" -ErrorAction SilentlyContinue
   ```

2. Check service event logs:
   ```powershell
   Get-EventLog -LogName Application -Source "MyWindowsService" -Newest 20
   ```

3. Manually install service (for testing):
   ```powershell
   New-Service -Name "MyWindowsService" -BinaryPathName "C:\code\services\MyWindowsService.exe" -StartupType Automatic
   Start-Service -Name "MyWindowsService"
   ```

### Web App Issues

1. Check IIS site status:
   ```powershell
   Get-Website | Where-Object { $_.Name -eq "MyWebApp" }
   Get-WebAppPoolState -Name "MyWebApp-AppPool"
   ```

2. Check IIS logs:
   ```powershell
   Get-Content "C:\inetpub\logs\LogFiles\W3SVC*\*.log" | Select-Object -Last 20
   ```

3. Verify .NET 4.8 is registered with IIS:
   ```powershell
   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -lv
   ```

## Clean Up

To remove the deployed applications:

```powershell
# Stop and remove Windows Service
Stop-Service -Name "MyWindowsService" -ErrorAction SilentlyContinue
sc.exe delete "MyWindowsService"

# Remove service files
Remove-Item -Path "C:\code\services" -Recurse -Force -ErrorAction SilentlyContinue

# Remove IIS Website and App Pool
Remove-Website -Name "MyWebApp" -ErrorAction SilentlyContinue
Remove-WebAppPool -Name "MyWebApp-AppPool" -ErrorAction SilentlyContinue

# Remove web app files
Remove-Item -Path "C:\inetpub\MyWebApp" -Recurse -Force -ErrorAction SilentlyContinue

# Remove DSC MOF files
Remove-Item -Path "C:\code\*.mof" -Force -ErrorAction SilentlyContinue
```

## Additional Resources

- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [xWebAdministration DSC Resource](https://github.com/dsccommunity/xWebAdministration)
- [Windows Service Development](https://docs.microsoft.com/en-us/dotnet/framework/windows-services/)
- [ASP.NET 4.8 Documentation](https://docs.microsoft.com/en-us/aspnet/overview)

## Support

For issues or questions, please refer to the troubleshooting section above or check the PowerShell DSC logs for detailed error messages.
