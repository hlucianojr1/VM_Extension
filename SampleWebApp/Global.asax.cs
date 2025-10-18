using System;
using System.Web;

namespace MyWebApp
{
    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            // Code that runs on application startup
            Application["RequestCount"] = 0;
            Application["StartTime"] = DateTime.Now;
        }

        protected void Session_Start(object sender, EventArgs e)
        {
            // Code that runs when a new session is started
        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {
            // Code that runs on each request
        }

        protected void Application_AuthenticateRequest(object sender, EventArgs e)
        {
            // Code that runs when authentication occurs
        }

        protected void Application_Error(object sender, EventArgs e)
        {
            // Code that runs when an unhandled error occurs
            Exception ex = Server.GetLastError();
            // Log the exception here
        }

        protected void Session_End(object sender, EventArgs e)
        {
            // Code that runs when a session ends
        }

        protected void Application_End(object sender, EventArgs e)
        {
            // Code that runs on application shutdown
        }
    }
}
