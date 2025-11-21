using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace ClockApp
{
    public class ClockForm : Form
    {
        private System.Windows.Forms.Timer clockTimer;
        private NotifyIcon trayIcon;
        private ContextMenuStrip trayMenu;

        public ClockForm()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            // Form setup
            this.Text = "Basic Window 64";
            this.ClientSize = new Size(640, 480);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.DoubleBuffered = true; // Reduce flicker
            this.FormBorderStyle = FormBorderStyle.Sizable;
            this.MinimizeBox = true;
            this.MaximizeBox = true;

            // Load icon if available
            try
            {
                string iconPath = System.IO.Path.Combine(
                    System.IO.Path.GetDirectoryName(Application.ExecutablePath) ?? "",
                    "..",
                    "logo.ico"
                );
                if (System.IO.File.Exists(iconPath))
                {
                    this.Icon = new Icon(iconPath);
                }
            }
            catch
            {
                // Use default icon if file not found
            }

            // Setup tray icon
            trayIcon = new NotifyIcon();
            trayIcon.Text = "My Tray Application";
            trayIcon.Visible = true;

            // Use form icon for tray, or default
            if (this.Icon != null)
            {
                trayIcon.Icon = this.Icon;
            }
            else
            {
                trayIcon.Icon = SystemIcons.Application;
            }

            // Setup context menu
            trayMenu = new ContextMenuStrip();
            trayMenu.Items.Add("Show", null, OnTrayShow);
            trayMenu.Items.Add("Exit", null, OnTrayExit);
            trayIcon.ContextMenuStrip = trayMenu;

            // Tray icon click behavior
            trayIcon.MouseClick += (sender, e) =>
            {
                if (e.Button == MouseButtons.Left)
                {
                    ShowAndActivate();
                }
            };

            // Setup timer (1 second interval)
            clockTimer = new System.Windows.Forms.Timer();
            clockTimer.Interval = 1000; // 1000 ms = 1 second
            clockTimer.Tick += OnTimerTick;
            clockTimer.Start();

            // Handle form closing
            this.FormClosing += (sender, e) =>
            {
                if (e.CloseReason == CloseReason.UserClosing)
                {
                    e.Cancel = true;
                    this.Hide();
                }
            };

            // Start hidden (like the Assembly version)
            this.WindowState = FormWindowState.Normal;
            this.ShowInTaskbar = true;
        }

        private void OnTimerTick(object? sender, EventArgs e)
        {
            // Beep on each timer tick (matching Assembly version)
            System.Media.SystemSounds.Beep.Play();

            // Invalidate to trigger repaint
            this.Invalidate();
        }

        private void ShowAndActivate()
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            this.Activate();
            this.BringToFront();
        }

        private void OnTrayShow(object? sender, EventArgs e)
        {
            ShowAndActivate();
        }

        private void OnTrayExit(object? sender, EventArgs e)
        {
            // Cleanup
            clockTimer.Stop();
            trayIcon.Visible = false;
            trayIcon.Dispose();

            // Actually exit the application
            Application.Exit();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);

            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            // Get client rectangle
            Rectangle clientRect = this.ClientRectangle;

            // Calculate center and radius
            int centerX = clientRect.Width / 2;
            int centerY = clientRect.Height / 2;
            int radius = Math.Min(centerX, centerY) - 10;

            // Draw clock face (circle)
            int left = centerX - radius;
            int top = centerY - radius;
            int diameter = radius * 2;

            using (Pen pen = new Pen(Color.Black, 2))
            {
                g.DrawEllipse(pen, left, top, diameter, diameter);
            }

            // Get current time
            DateTime now = DateTime.Now;
            int hour = now.Hour;
            int minute = now.Minute;
            int second = now.Second;

            // Draw second hand (90% radius, thin line)
            DrawHand(g, centerX, centerY, radius * 0.9, second, 60, Color.Red, 1);

            // Draw minute hand (80% radius, medium line)
            DrawHand(g, centerX, centerY, radius * 0.8, minute, 60, Color.Blue, 2);

            // Draw hour hand (50% radius, thick line)
            double hourAngle = (hour % 12) + (minute / 60.0);
            DrawHand(g, centerX, centerY, radius * 0.5, hourAngle, 12, Color.Black, 3);
        }

        private void DrawHand(Graphics g, int centerX, int centerY, double length,
                             double value, int maxValue, Color color, int width)
        {
            // Calculate angle: value * PI / (maxValue/2)
            // For seconds/minutes: value * PI / 30
            // For hours: value * PI / 6
            double angle = value * Math.PI / (maxValue / 2.0);

            // Calculate end point
            // X = centerX + length * sin(angle)
            // Y = centerY - length * cos(angle)  [subtract because Y increases downward]
            int endX = centerX + (int)(length * Math.Sin(angle));
            int endY = centerY - (int)(length * Math.Cos(angle));

            using (Pen pen = new Pen(color, width))
            {
                g.DrawLine(pen, centerX, centerY, endX, endY);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                clockTimer?.Dispose();
                trayIcon?.Dispose();
                trayMenu?.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
