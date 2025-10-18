# PowerShell DSC Deployment Solution - Memory Prompt

## Project Overview
This is a complete PowerShell Desired State Configuration (DSC) solution for deploying:
1. A .NET Framework 4.8 Windows Service
2. An ASP.NET 4.8 Web Application on IIS

## Workspace Location
**Root Directory:** `C:\code\VM_Extension\`

## Solution Architecture

### 1. DSC Configuration Scripts (DSC/)
Located in: `DSC/` directory

#### DscConfiguration.ps1
- Main DSC configuration script
- Defines desired state for Windows Features, IIS, Windows Service, and Web App
- Uses DSC resources:
  - `WindowsFeature`: Installs .NET 4.8 and IIS components
  - `File`: Manages directories and copies application files
  - `Script`: Custom PowerShell for Windows Service installation
  - `xWebAppPool`: Creates IIS Application Pool (v4.0, Integrated mode)
  - `xWebsite`: Creates IIS Website on port 80
- Key features installed:
  - NET-Framework-45-Core, NET-Framework-45-ASPNET
  - Web-Server, Web-Asp-Net45, Web-Net-Ext45
  - Web-ISAPI-Ext, Web-ISAPI-Filter

#### DeployConfiguration.ps1
- Orchestration script that generates and applies DSC configuration
- Default configuration parameters:
  - Service Source: `C:\code\DeploymentSource\WindowsService`
  - Service Destination: `C:\code\services`
  - Service Name: `MyWindowsService`
  - Web App Source: `C:\code\DeploymentSource\WebApp`
  - Web App Destination: `C:\inetpub\MyWebApp`
  - Web App Name: `MyWebApp`
  - MOF Output: `C:\code`
- Validates source paths before deployment
- Interactive deployment with confirmation prompt

#### VerifyConfiguration.ps1
- Post-deployment verification script
- Checks:
  - DSC configuration status
  - Windows Service installation and running state
  - Service files at destination
  - Windows Features installation
  - IIS Website and Application Pool status
  - Web App accessibility (HTTP GET test)
  - Event logs for service

### 2. Sample Windows Service (SampleWindowsService/)

#### MyWindowsService.csproj
- .NET Framework 4.8 Windows Service project
- Output type: WinExe
- References: System.ServiceProcess, System.Configuration.Install

#### Program.cs
- Service entry point
- Runs MyService class

#### MyService.cs
- Main service implementation
- Features:
  - Timer-based execution (every 30 seconds)
  - Event Log integration (writes to Application log)
  - Pause/Continue support
  - Execution counter
  - Error handling
- Service Name: "MyWindowsService"

#### ProjectInstaller.cs
- Service installer component
- Runs under LocalSystem account
- Start Type: Automatic
- Display Name: "My Windows Service"

#### App.config
- .NET 4.8 runtime configuration
- AppSettings for service customization

### 3. Sample Web Application (SampleWebApp/)

#### MyWebApp.csproj
- ASP.NET 4.8 Web Forms project
- Target Framework: v4.8
- Uses IIS Express for development

#### Default.aspx / Default.aspx.cs
- Main web page with system information display:
  - Server name, time, .NET version
  - Application path, request count
- Features:
  - Refresh button to update information
  - Mock database connection test
  - Session state management via Application state

#### Global.asax / Global.asax.cs
- Application lifecycle management
- Initializes Application["RequestCount"] and Application["StartTime"]
- Error handling hooks

#### Web.config
- ASP.NET 4.8 configuration
- Custom errors mode: Off
- Default document: Default.aspx
- Directory browsing: Disabled

#### Styles/Site.css
- Modern gradient design (purple theme)
- Responsive layout with media queries
- Styled tables, buttons, and status messages
- Success/error message styling

### 4. Build and Deployment Scripts

#### Build-Applications.ps1
- Automated build script for both projects
- Locates MSBuild using multiple methods:
  - Hardcoded Visual Studio 2019/2022 paths
  - vswhere.exe utility
- Builds both projects in Release configuration
- Creates deployment source directories
- Copies binaries to:
  - `C:\code\DeploymentSource\WindowsService`
  - `C:\code\DeploymentSource\WebApp`
- Handles both service executables and web app files

#### Quick-Start.ps1
- One-command deployment automation
- Features:
  - Administrator privilege check
  - Optional DSC module installation
  - Build step (can be skipped with -SkipBuild)
  - Automated DSC deployment
  - Post-deployment verification
  - Browser launch option
- Parameters:
  - `-SkipBuild`: Use existing binaries
  - `-InstallModules`: Install xWebAdministration and PSDesiredStateConfiguration
  - `-BuildOnly`: Build without deploying

### 5. Documentation

#### README.md (Root)
- Complete solution overview
- Step-by-step deployment guide
- Prerequisites list
- Configuration options
- Troubleshooting section
- Remote deployment instructions
- Clean-up commands

#### DSC/README.md
- Detailed DSC configuration documentation
- Windows Features list
- DSC resources explanation
- Deployment flow diagram
- Remote deployment guide
- Advanced customization (HTTPS, credentials, multiple sites)
- Troubleshooting with DSC-specific commands

## Key Deployment Paths

### Source Paths (Build Output)
- Windows Service Binaries: `SampleWindowsService\bin\Release\`
- Web App Files: `SampleWebApp\bin\` and root files

### Staging Paths (Deployment Source)
- Windows Service: `C:\code\DeploymentSource\WindowsService`
- Web App: `C:\code\DeploymentSource\WebApp`

### Target Paths (Runtime)
- Windows Service: `C:\code\services\`
- Web App: `C:\inetpub\MyWebApp\`
- DSC MOF files: `C:\code\`

## Dependencies

### PowerShell Modules Required
- **xWebAdministration**: IIS configuration DSC resources
- **PSDesiredStateConfiguration**: Core DSC functionality

### Windows Features Required
- .NET Framework 4.5+ (includes 4.8)
- IIS Web Server with ASP.NET 4.5
- IIS Management Tools

## Typical Usage Flow

1. **First Time Setup:**
   ```powershell
   .\Quick-Start.ps1 -InstallModules
   ```

2. **Build Only:**
   ```powershell
   .\Build-Applications.ps1
   ```

3. **Deploy After Build:**
   ```powershell
   cd DSC
   .\DeployConfiguration.ps1
   ```

4. **Verify Deployment:**
   ```powershell
   .\VerifyConfiguration.ps1
   ```

5. **Full Automated Deployment:**
   ```powershell
   .\Quick-Start.ps1
   ```

## Testing

### Test Windows Service
```powershell
Get-Service -Name "MyWindowsService"
Get-EventLog -LogName Application -Source "MyWindowsService" -Newest 10
```

### Test Web Application
- Browser: http://localhost/MyWebApp
- PowerShell: `Invoke-WebRequest -Uri "http://localhost/MyWebApp"`

## Troubleshooting Commands

### DSC Status
```powershell
Get-DscConfigurationStatus -Verbose
Test-DscConfiguration -Verbose
Get-WinEvent -LogName "Microsoft-Windows-DSC/Operational" -MaxEvents 50
```

### Service Debugging
```powershell
Get-Service -Name "MyWindowsService"
Get-EventLog -LogName Application -Source "MyWindowsService"
```

### IIS Debugging
```powershell
Get-Website | Where-Object { $_.Name -eq "MyWebApp" }
Get-WebAppPoolState -Name "MyWebApp-AppPool"
Get-Content "C:\inetpub\logs\LogFiles\W3SVC*\*.log" | Select-Object -Last 20
```

## Important Notes

1. **Administrator Rights Required**: All deployment scripts require elevated privileges
2. **Port 80 Conflict**: DSC stops "Default Web Site" to free port 80
3. **Service Installation**: Uses `New-Service` cmdlet, not InstallUtil.exe
4. **Web App Deployment**: Copies files directly, no Web Deploy or MSI
5. **Idempotency**: DSC configuration can be reapplied safely
6. **Event Logs**: Service writes to Application log under source "MyWindowsService"
7. **Application State**: Web app tracks request count in Application state

## Customization Points

1. **Service Behavior**: Edit `MyService.cs` timer interval and business logic
2. **Web App Appearance**: Modify `Styles/Site.css` for branding
3. **Deployment Paths**: Update `DeployConfiguration.ps1` parameters
4. **Port Configuration**: Change binding in `DscConfiguration.ps1`
5. **Service Account**: Modify Script resource in `DscConfiguration.ps1`
6. **HTTPS**: Add SSL certificate binding to xWebsite resource

## File Count Summary
- Total PowerShell Scripts: 5 (3 DSC + 2 build/deployment)
- C# Files: 5 (3 service + 2 web app code-behind)
- Project Files: 2 (.csproj files)
- Configuration Files: 3 (App.config, Web.config, Global.asax)
- ASPX Files: 2 (Default.aspx + designer)
- CSS Files: 1
- README Files: 2
- Total Core Files: ~20 files

## Success Indicators

When deployment is successful:
1. Service shows "Running" status
2. Web page displays system information
3. Service writes events every 30 seconds
4. IIS site state is "Started"
5. Application Pool is running
6. HTTP request to web app returns 200 OK
7. DSC status shows "Success"

## Common Issues and Solutions

1. **MSBuild Not Found**: Install Visual Studio or use standalone Build Tools
2. **Source Paths Missing**: Run `Build-Applications.ps1` first
3. **Port 80 Busy**: Check if Default Web Site is stopped
4. **Service Won't Start**: Check Event Viewer for .NET errors
5. **503 Error**: Restart Application Pool or check .NET registration
6. **DSC Module Missing**: Run with `-InstallModules` flag

## Remote Deployment Considerations

- Enable PowerShell Remoting on target VM
- Copy deployment source files to accessible location (UNC or local)
- Use `-ComputerName` parameter with `Start-DscConfiguration`
- Consider using DSC Pull Server for large-scale deployments
- Use credentials parameter for domain authentication

This solution provides a complete, production-ready template for deploying .NET Framework applications using infrastructure-as-code principles with PowerShell DSC.
