using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Timers;

namespace MyWindowsService
{
    public partial class MyService : ServiceBase
    {
        private Timer _timer;
        private EventLog _eventLog;
        private int _executionCount = 0;

        public MyService()
        {
            ServiceName = "MyWindowsService";
            CanStop = true;
            CanPauseAndContinue = true;
            AutoLog = true;

            // Create event log
            _eventLog = new EventLog();
            if (!EventLog.SourceExists(ServiceName))
            {
                EventLog.CreateEventSource(ServiceName, "Application");
            }
            _eventLog.Source = ServiceName;
            _eventLog.Log = "Application";
        }

        protected override void OnStart(string[] args)
        {
            _eventLog.WriteEntry("MyWindowsService is starting...", EventLogEntryType.Information);

            // Set up a timer to trigger every 30 seconds
            _timer = new Timer();
            _timer.Interval = 30000; // 30 seconds
            _timer.Elapsed += new ElapsedEventHandler(OnTimer);
            _timer.Start();

            _eventLog.WriteEntry("MyWindowsService started successfully.", EventLogEntryType.Information);
        }

        protected override void OnStop()
        {
            _eventLog.WriteEntry("MyWindowsService is stopping...", EventLogEntryType.Information);

            _timer?.Stop();
            _timer?.Dispose();

            _eventLog.WriteEntry($"MyWindowsService stopped. Total executions: {_executionCount}", EventLogEntryType.Information);
        }

        protected override void OnPause()
        {
            _timer?.Stop();
            _eventLog.WriteEntry("MyWindowsService paused.", EventLogEntryType.Information);
        }

        protected override void OnContinue()
        {
            _timer?.Start();
            _eventLog.WriteEntry("MyWindowsService resumed.", EventLogEntryType.Information);
        }

        private void OnTimer(object sender, ElapsedEventArgs e)
        {
            try
            {
                _executionCount++;
                
                // Perform some work here
                string message = $"MyWindowsService is running. Execution #{_executionCount} at {DateTime.Now:yyyy-MM-dd HH:mm:ss}";
                
                _eventLog.WriteEntry(message, EventLogEntryType.Information);

                // You can add your business logic here
                // For example: process files, check databases, send notifications, etc.
            }
            catch (Exception ex)
            {
                _eventLog.WriteEntry($"Error in OnTimer: {ex.Message}\n{ex.StackTrace}", EventLogEntryType.Error);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _timer?.Dispose();
                _eventLog?.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
