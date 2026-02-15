using System.Runtime.InteropServices;

namespace QuickCliq.Core.Win32;

/// <summary>
/// P/Invoke declarations for hotkey management (User32)
/// </summary>
public static partial class NativeMethods
{
    [LibraryImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static partial bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    
    [LibraryImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static partial bool UnregisterHotKey(IntPtr hWnd, int id);
    
    // Modifiers
    public const uint MOD_ALT = 0x0001;
    public const uint MOD_CONTROL = 0x0002;
    public const uint MOD_SHIFT = 0x0004;
    public const uint MOD_WIN = 0x0008;
    public const uint MOD_NOREPEAT = 0x4000;
    
    // Virtual keys (common ones)
    public const uint VK_LBUTTON = 0x01;
    public const uint VK_RBUTTON = 0x02;
    public const uint VK_MBUTTON = 0x04;
    public const uint VK_BACK = 0x08;
    public const uint VK_TAB = 0x09;
    public const uint VK_RETURN = 0x0D;
    public const uint VK_ESCAPE = 0x1B;
    public const uint VK_SPACE = 0x20;
}
