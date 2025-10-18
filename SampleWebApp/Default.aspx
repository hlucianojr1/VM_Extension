<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="MyWebApp.Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>My Web App - .NET 4.8</title>
    <link href="Styles/Site.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <div class="header">
                <h1>My Web Application</h1>
                <p class="subtitle">ASP.NET 4.8 Web Application deployed via PowerShell DSC</p>
            </div>
            
            <div class="content">
                <div class="info-section">
                    <h2>System Information</h2>
                    <table class="info-table">
                        <tr>
                            <td class="label">Server Name:</td>
                            <td><asp:Label ID="lblServerName" runat="server"></asp:Label></td>
                        </tr>
                        <tr>
                            <td class="label">Server Time:</td>
                            <td><asp:Label ID="lblServerTime" runat="server"></asp:Label></td>
                        </tr>
                        <tr>
                            <td class="label">.NET Framework Version:</td>
                            <td><asp:Label ID="lblFrameworkVersion" runat="server"></asp:Label></td>
                        </tr>
                        <tr>
                            <td class="label">Application Path:</td>
                            <td><asp:Label ID="lblApplicationPath" runat="server"></asp:Label></td>
                        </tr>
                        <tr>
                            <td class="label">Request Count:</td>
                            <td><asp:Label ID="lblRequestCount" runat="server"></asp:Label></td>
                        </tr>
                    </table>
                </div>

                <div class="info-section">
                    <h2>Test Features</h2>
                    <div class="button-section">
                        <asp:Button ID="btnRefresh" runat="server" Text="Refresh Information" 
                            CssClass="button" OnClick="btnRefresh_Click" />
                        <asp:Button ID="btnTestDatabase" runat="server" Text="Test Database Connection" 
                            CssClass="button" OnClick="btnTestDatabase_Click" />
                    </div>
                    <div class="message-section">
                        <asp:Label ID="lblMessage" runat="server" CssClass="message"></asp:Label>
                    </div>
                </div>

                <div class="info-section">
                    <h2>About This Application</h2>
                    <p>
                        This is a sample ASP.NET 4.8 Web Application deployed using PowerShell Desired State Configuration (DSC).
                        It demonstrates the following features:
                    </p>
                    <ul>
                        <li>ASP.NET 4.8 Web Forms application</li>
                        <li>Running on IIS with dedicated Application Pool</li>
                        <li>Deployed alongside a Windows Service</li>
                        <li>Configured using PowerShell DSC for infrastructure as code</li>
                        <li>Automated deployment and configuration management</li>
                    </ul>
                </div>

                <div class="status-section">
                    <h3>? Application Status: Running</h3>
                    <p>If you can see this page, the DSC deployment was successful!</p>
                </div>
            </div>

            <div class="footer">
                <p>&copy; <%= DateTime.Now.Year %> - Sample Web Application</p>
            </div>
        </div>
    </form>
</body>
</html>
