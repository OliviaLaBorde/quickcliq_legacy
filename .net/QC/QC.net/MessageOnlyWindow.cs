using System.Runtime.InteropServices;

namespace QC.net;

/// <summary>
/// Win32 message-only window for receiving WM_HOTKEY messages
/// This window has NO visual representation and NO taskbar entry
/// </summary>
public class MessageOnlyWindow : IDisposable
{
    private const int WM_HOTKEY = 0x0312;
    private IntPtr _hwnd;
    private WndProcDelegate? _wndProcDelegate;
    
    public event Action<int>? HotkeyPressed;
    
    public IntPtr Handle => _hwnd;
    
    public MessageOnlyWindow()
    {
        // Create message-only window (HWND_MESSAGE parent = no taskbar, no visibility)
        _wndProcDelegate = WndProc;
        
        var wc = new WNDCLASSEX
        {
            cbSize = Marshal.SizeOf<WNDCLASSEX>(),
            lpfnWndProc = _wndProcDelegate,
            lpszClassName = "QuickCliqHotkeyWindow" + Guid.NewGuid().ToString("N")
        };
        
        var atom = RegisterClassEx(ref wc);
        if (atom == 0)
        {
            Console.WriteLine("Failed to register window class");
            return;
        }
        
        // HWND_MESSAGE = -3 (message-only window, completely hidden)
        _hwnd = CreateWindowEx(
            0,                          // dwExStyle
            wc.lpszClassName,           // lpClassName
            "QuickCliq Hotkey Window",  // lpWindowName
            0,                          // dwStyle (no WS_VISIBLE)
            0, 0, 0, 0,                 // x, y, width, height
            new IntPtr(-3),             // hWndParent = HWND_MESSAGE
            IntPtr.Zero,                // hMenu
            IntPtr.Zero,                // hInstance
            IntPtr.Zero);               // lpParam
        
        if (_hwnd == IntPtr.Zero)
        {
            Console.WriteLine("Failed to create message-only window");
        }
        else
        {
            Console.WriteLine($"Message-only window created: Handle={_hwnd}");
        }
    }
    
    private IntPtr WndProc(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam)
    {
        if (msg == WM_HOTKEY)
        {
            int hotkeyId = wParam.ToInt32();
            Console.WriteLine($">>> WM_HOTKEY received! ID={hotkeyId}");
            HotkeyPressed?.Invoke(hotkeyId);
            return IntPtr.Zero;
        }
        
        return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    
    public void Dispose()
    {
        if (_hwnd != IntPtr.Zero)
        {
            DestroyWindow(_hwnd);
            _hwnd = IntPtr.Zero;
        }
        GC.SuppressFinalize(this);
    }
    
    // Win32 APIs
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate IntPtr WndProcDelegate(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct WNDCLASSEX
    {
        public int cbSize;
        public uint style;
        [MarshalAs(UnmanagedType.FunctionPtr)]
        public WndProcDelegate? lpfnWndProc;
        public int cbClsExtra;
        public int cbWndExtra;
        public IntPtr hInstance;
        public IntPtr hIcon;
        public IntPtr hCursor;
        public IntPtr hbrBackground;
        public string? lpszMenuName;
        public string lpszClassName;
        public IntPtr hIconSm;
    }
    
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern ushort RegisterClassEx([In] ref WNDCLASSEX lpwcx);
    
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr CreateWindowEx(
        uint dwExStyle, string lpClassName, string lpWindowName, uint dwStyle,
        int x, int y, int nWidth, int nHeight, IntPtr hWndParent, IntPtr hMenu,
        IntPtr hInstance, IntPtr lpParam);
    
    [DllImport("user32.dll")]
    private static extern bool DestroyWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    private static extern IntPtr DefWindowProc(IntPtr hWnd, uint uMsg, IntPtr wParam, IntPtr lParam);
}
