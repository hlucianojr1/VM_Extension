using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace MyWindowsService
{
    [RunInstaller(true)]
    public partial class ProjectInstaller : Installer
    {
        private ServiceProcessInstaller serviceProcessInstaller;
        private ServiceInstaller serviceInstaller;

        public ProjectInstaller()
        {
            serviceProcessInstaller = new ServiceProcessInstaller();
            serviceInstaller = new ServiceInstaller();

            // Service will run under the Local System account
            serviceProcessInstaller.Account = ServiceAccount.LocalSystem;

            // Service configuration
            serviceInstaller.ServiceName = "MyWindowsService";
            serviceInstaller.DisplayName = "My Windows Service";
            serviceInstaller.Description = "Sample .NET 4.8 Windows Service deployed via PowerShell DSC";
            serviceInstaller.StartType = ServiceStartMode.Automatic;

            Installers.Add(serviceProcessInstaller);
            Installers.Add(serviceInstaller);
        }
    }
}
