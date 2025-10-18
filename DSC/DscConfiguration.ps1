Configuration DeployDotNetApplication
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$NodeName,
        
        [Parameter(Mandatory=$true)]
        [string]$ServiceSourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$ServiceDestinationPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$true)]
        [string]$ServiceExecutable,
        
        [Parameter(Mandatory=$true)]
        [string]$WebAppSourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$WebAppName,
        
        [Parameter(Mandatory=$true)]
        [string]$WebAppPhysicalPath
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    
    Node $NodeName
    {
        # Ensure .NET Framework 4.8 Features are installed
        WindowsFeature NETFramework48
        {
            Ensure = "Present"
            Name   = "NET-Framework-45-Core"
        }
        
        WindowsFeature NETFrameworkASPNet
        {
            Ensure    = "Present"
            Name      = "NET-Framework-45-ASPNET"
            DependsOn = "[WindowsFeature]NETFramework48"
        }
        
        # Ensure IIS is installed
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name   = "Web-Server"
        }
        
        WindowsFeature IISManagementTools
        {
            Ensure    = "Present"
            Name      = "Web-Mgmt-Tools"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        WindowsFeature IISManagementConsole
        {
            Ensure    = "Present"
            Name      = "Web-Mgmt-Console"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        WindowsFeature ASPNet45
        {
            Ensure    = "Present"
            Name      = "Web-Asp-Net45"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        WindowsFeature WebNetExt45
        {
            Ensure    = "Present"
            Name      = "Web-Net-Ext45"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        WindowsFeature WebISAPIExt
        {
            Ensure    = "Present"
            Name      = "Web-ISAPI-Ext"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        WindowsFeature WebISAPIFilter
        {
            Ensure    = "Present"
            Name      = "Web-ISAPI-Filter"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        # Create directory for Windows Service
        File ServiceDirectory
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = $ServiceDestinationPath
            DependsOn       = "[WindowsFeature]NETFramework48"
        }
        
        # Copy Windows Service files
        File ServiceFiles
        {
            Ensure          = "Present"
            Type            = "Directory"
            Recurse         = $true
            SourcePath      = $ServiceSourcePath
            DestinationPath = $ServiceDestinationPath
            DependsOn       = "[File]ServiceDirectory"
            Force           = $true
            MatchSource     = $true
        }
        
        # Install Windows Service
        Script InstallWindowsService
        {
            GetScript = {
                $service = Get-Service -Name $using:ServiceName -ErrorAction SilentlyContinue
                return @{ 
                    Result = if ($service) { 
                        "Present - Status: $($service.Status)" 
                    } else { 
                        "Absent" 
                    } 
                }
            }
            
            TestScript = {
                $service = Get-Service -Name $using:ServiceName -ErrorAction SilentlyContinue
                if ($null -eq $service) {
                    Write-Verbose "Service $using:ServiceName does not exist"
                    return $false
                }
                Write-Verbose "Service $using:ServiceName exists with status: $($service.Status)"
                return $true
            }
            
            SetScript = {
                $exePath = Join-Path $using:ServiceDestinationPath $using:ServiceExecutable
                Write-Verbose "Installing service from: $exePath"
                
                # Check if service exists and remove it first
                $existingService = Get-Service -Name $using:ServiceName -ErrorAction SilentlyContinue
                if ($existingService) {
                    Write-Verbose "Stopping existing service..."
                    Stop-Service -Name $using:ServiceName -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                    
                    Write-Verbose "Removing existing service..."
                    sc.exe delete $using:ServiceName
                    Start-Sleep -Seconds 2
                }
                
                # Create the service
                New-Service -Name $using:ServiceName `
                    -BinaryPathName $exePath `
                    -DisplayName $using:ServiceName `
                    -StartupType Automatic `
                    -Description "Sample .NET 4.8 Windows Service deployed via DSC"
                
                Write-Verbose "Starting service..."
                Start-Service -Name $using:ServiceName
            }
            
            DependsOn = "[File]ServiceFiles"
        }
        
        # Create Web App directory
        File WebAppDirectory
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = $WebAppPhysicalPath
            DependsOn       = "[WindowsFeature]IIS"
        }
        
        # Copy Web App files
        File WebAppFiles
        {
            Ensure          = "Present"
            Type            = "Directory"
            Recurse         = $true
            SourcePath      = $WebAppSourcePath
            DestinationPath = $WebAppPhysicalPath
            DependsOn       = "[File]WebAppDirectory"
            Force           = $true
            MatchSource     = $true
        }
        
        # Stop Default Website to free up port 80
        xWebsite DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }
        
        # Create Application Pool
        xWebAppPool WebAppPool
        {
            Name                  = "$WebAppName-AppPool"
            Ensure                = "Present"
            State                 = "Started"
            managedRuntimeVersion = "v4.0"
            managedPipelineMode   = "Integrated"
            identityType          = "ApplicationPoolIdentity"
            DependsOn             = "[WindowsFeature]ASPNet45"
        }
        
        # Create IIS Website
        xWebsite WebSite
        {
            Name            = $WebAppName
            Ensure          = "Present"
            State           = "Started"
            PhysicalPath    = $WebAppPhysicalPath
            ApplicationPool = "$WebAppName-AppPool"
            BindingInfo     = @(
                MSFT_xWebBindingInformation
                {
                    Protocol = "http"
                    Port     = 80
                    HostName = ""
                }
            )
            DependsOn       = @("[xWebAppPool]WebAppPool", "[File]WebAppFiles", "[xWebsite]DefaultSite")
        }
        
        # Verify .NET 4.8 registration with IIS
        Script RegisterAspNet
        {
            GetScript = {
                return @{ Result = "Checking ASP.NET registration" }
            }
            
            TestScript = {
                # Always return true since aspnet_regiis can be run multiple times safely
                return $true
            }
            
            SetScript = {
                $aspnetRegiis = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
                if (Test-Path $aspnetRegiis) {
                    Write-Verbose "Registering ASP.NET 4.x with IIS..."
                    & $aspnetRegiis -i
                }
            }
            
            DependsOn = @("[WindowsFeature]ASPNet45", "[xWebsite]WebSite")
        }
    }
}
