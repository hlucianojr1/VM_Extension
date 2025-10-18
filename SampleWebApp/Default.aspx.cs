using System;
using System.Web;
using System.Web.UI;

namespace MyWebApp
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadSystemInformation();
            }
        }

        private void LoadSystemInformation()
        {
            try
            {
                lblServerName.Text = Environment.MachineName;
                lblServerTime.Text = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                lblFrameworkVersion.Text = Environment.Version.ToString() + " (.NET Framework 4.8)";
                lblApplicationPath.Text = Request.PhysicalApplicationPath;
                
                // Get request count from Application state
                if (Application["RequestCount"] == null)
                {
                    Application["RequestCount"] = 0;
                }
                
                int requestCount = (int)Application["RequestCount"];
                requestCount++;
                Application["RequestCount"] = requestCount;
                
                lblRequestCount.Text = requestCount.ToString();
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Error loading system information: " + ex.Message;
                lblMessage.CssClass = "message error";
            }
        }

        protected void btnRefresh_Click(object sender, EventArgs e)
        {
            LoadSystemInformation();
            lblMessage.Text = "Information refreshed at " + DateTime.Now.ToString("HH:mm:ss");
            lblMessage.CssClass = "message success";
        }

        protected void btnTestDatabase_Click(object sender, EventArgs e)
        {
            try
            {
                // This is a mock database test
                // In a real application, you would test your actual database connection here
                System.Threading.Thread.Sleep(500); // Simulate database call
                
                lblMessage.Text = "Database connection test successful! (Simulated)";
                lblMessage.CssClass = "message success";
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Database connection test failed: " + ex.Message;
                lblMessage.CssClass = "message error";
            }
        }
    }
}
