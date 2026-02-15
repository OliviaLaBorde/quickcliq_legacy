using System.Runtime.InteropServices;
using System.Windows.Forms;
using QuickCliq.Core;
using QuickCliq.Core.Services;

namespace QC.net.Services;

/// <summary>
/// System tray icon implementation using WinForms NotifyIcon
/// </summary>
public class TrayIconService : ITrayIconService, IDisposable
{
    private readonly NotifyIcon _notifyIcon;
    private readonly ContextMenuStrip _contextMenu;

    public bool IsVisible
    {
        get => _notifyIcon.Visible;
        set => _notifyIcon.Visible = value;
    }

    public string ToolTipText
    {
        get => _notifyIcon.Text;
        set => _notifyIcon.Text = value;
    }

    public event EventHandler? IconClicked;
    public event EventHandler? OpenEditorClicked;
    public event EventHandler? SuspendHotkeysClicked;
    public event EventHandler? SuspendGesturesClicked;
    public event EventHandler? OptionsClicked;
    public event EventHandler? CheckUpdatesClicked;
    public event EventHandler? ExitClicked;

    public TrayIconService()
    {
        _notifyIcon = new NotifyIcon
        {
            Text = $"{AppConstants.AppName} {AppConstants.Version}",
            Visible = true,
            // Use default application icon for now
            Icon = System.Drawing.Icon.ExtractAssociatedIcon(Application.ExecutablePath) 
                   ?? System.Drawing.SystemIcons.Application
        };

        _contextMenu = CreateContextMenu();
        
        // Handle mouse clicks to differentiate left vs right
        _notifyIcon.MouseClick += (s, e) =>
        {
            if (e.Button == MouseButtons.Left)
            {
                // Left-click = show main launcher menu
                IconClicked?.Invoke(this, EventArgs.Empty);
            }
            else if (e.Button == MouseButtons.Right)
            {
                // Right-click = show context menu (Options, Exit, etc.)
                ShowContextMenu();
            }
        };
    }

    private void ShowContextMenu()
    {
        // Required for proper context menu behavior in WPF apps
        // See: https://stackoverflow.com/questions/2208690/
        
        // Get current foreground window (if any)
        var hwnd = GetForegroundWindow();
        
        // Make our app the foreground temporarily
        if (hwnd != IntPtr.Zero)
        {
            SetForegroundWindow(hwnd);
        }
        
        // Show the menu
        _contextMenu.Show(Cursor.Position);
        
        // Post a message to ensure menu can dismiss properly
        // This is a WinForms + WPF interop requirement
        PostMessage(hwnd, 0, IntPtr.Zero, IntPtr.Zero);
    }

    private ContextMenuStrip CreateContextMenu()
    {
        var menu = new ContextMenuStrip();

        menu.Items.Add("Open Editor", null, (s, e) => OpenEditorClicked?.Invoke(this, e));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Suspend Hotkeys", null, (s, e) => SuspendHotkeysClicked?.Invoke(this, e));
        menu.Items.Add("Suspend Gestures", null, (s, e) => SuspendGesturesClicked?.Invoke(this, e));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Options...", null, (s, e) => OptionsClicked?.Invoke(this, e));
        menu.Items.Add("Check for Updates", null, (s, e) => CheckUpdatesClicked?.Invoke(this, e));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Exit", null, (s, e) => ExitClicked?.Invoke(this, e));

        return menu;
    }

    public void Show() => _notifyIcon.Visible = true;

    public void Hide() => _notifyIcon.Visible = false;

    public void ShowBalloon(string title, string message, int timeoutMs = 3000)
    {
        _notifyIcon.BalloonTipTitle = title;
        _notifyIcon.BalloonTipText = message;
        _notifyIcon.ShowBalloonTip(timeoutMs);
    }

    public void Dispose()
    {
        _contextMenu?.Dispose();
        _notifyIcon?.Dispose();
        GC.SuppressFinalize(this);
    }
    
    // Win32 for proper context menu behavior
    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    private static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
