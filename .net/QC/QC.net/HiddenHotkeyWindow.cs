using System.Windows;
using System.Windows.Interop;

namespace QC.net;

/// <summary>
/// Hidden window for receiving WM_HOTKEY messages
/// Positioned at 0,0 with 1x1 size to stay invisible but receive messages
/// </summary>
public class HiddenHotkeyWindow : Window
{
    private const int WM_HOTKEY = 0x0312;
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    
    public event Action<int>? HotkeyPressed;
    
    public HiddenHotkeyWindow()
    {
        // Create minimal 1x1 window at 0,0 (should be under taskbar/hidden)
        Width = 1;
        Height = 1;
        Left = 0;
        Top = 0;
        WindowStyle = WindowStyle.None;
        ShowInTaskbar = false;
        ShowActivated = false;
        Topmost = false;
        ResizeMode = ResizeMode.NoResize;
        
        // Make it completely transparent
        AllowsTransparency = true;
        Opacity = 0.01; // Nearly invisible but not 0 (0 might disable messages)
        Background = System.Windows.Media.Brushes.Transparent;
        
        // Hook into window messages after initialization
        SourceInitialized += (s, e) =>
        {
            var hwnd = new WindowInteropHelper(this).Handle;
            
            // Set WS_EX_TOOLWINDOW to hide from taskbar completely
            var exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
            SetWindowLong(hwnd, GWL_EXSTYLE, exStyle | WS_EX_TOOLWINDOW);
            
            var hwndSource = HwndSource.FromHwnd(hwnd);
            if (hwndSource != null)
            {
                hwndSource.AddHook(WndProc);
                Console.WriteLine($"WndProc hook added to window handle: {hwnd}");
            }
            else
            {
                Console.WriteLine("ERROR: Failed to get HwndSource for hotkey window!");
            }
        };
        
        Console.WriteLine("HiddenHotkeyWindow created");
    }
    
    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WM_HOTKEY)
        {
            int hotkeyId = wParam.ToInt32();
            Console.WriteLine($">>> WM_HOTKEY received in WndProc! ID={hotkeyId}");
            HotkeyPressed?.Invoke(hotkeyId);
            handled = true;
        }
        
        return IntPtr.Zero;
    }
    
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
}
