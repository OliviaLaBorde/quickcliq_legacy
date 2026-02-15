using System.Runtime.InteropServices;
using System.Diagnostics;

namespace QuickCliq.Core.Hotkeys;

/// <summary>
/// Low-level keyboard hook service (alternative to RegisterHotKey)
/// More reliable for global hotkeys - works like AHK
/// </summary>
public class LowLevelHotkeyService : IHotkeyService
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    
    private IntPtr _hookId = IntPtr.Zero;
    private LowLevelKeyboardProc? _hookCallback;
    private readonly Dictionary<string, HotkeyInfo> _hotkeys = new();
    private bool _enabled = true;
    
    public LowLevelHotkeyService()
    {
        _hookCallback = HookCallback;
        _hookId = SetHook(_hookCallback);
        
        if (_hookId == IntPtr.Zero)
        {
            Console.WriteLine("WARNING: Failed to install keyboard hook");
        }
        else
        {
            Console.WriteLine($"Keyboard hook installed: {_hookId}");
        }
    }
    
    public bool Register(string hotkeyString, Action callback)
    {
        var parsed = Parse(hotkeyString);
        if (parsed == null)
            return false;
        
        var (vk, mods) = parsed.Value;
        
        _hotkeys[hotkeyString] = new HotkeyInfo
        {
            VirtualKey = vk,
            Modifiers = mods,
            Callback = callback,
            HotkeyString = hotkeyString
        };
        
        Console.WriteLine($"Hotkey registered: {hotkeyString} → VK={vk}, Mods={mods}");
        return true;
    }
    
    public bool Unregister(string hotkeyString)
    {
        return _hotkeys.Remove(hotkeyString);
    }
    
    public void SetAllEnabled(bool enabled)
    {
        _enabled = enabled;
    }
    
    public string ToDisplayString(string hotkeyString)
    {
        var parts = new List<string>();
        
        if (hotkeyString.Contains('#')) parts.Add("Win");
        if (hotkeyString.Contains('^')) parts.Add("Ctrl");
        if (hotkeyString.Contains('!')) parts.Add("Alt");
        if (hotkeyString.Contains('+')) parts.Add("Shift");
        
        var key = hotkeyString.TrimStart('#', '^', '!', '+');
        parts.Add(key.ToUpperInvariant());
        
        return string.Join("+", parts);
    }
    
    public (uint VirtualKey, uint Modifiers)? Parse(string hotkeyString)
    {
        if (string.IsNullOrWhiteSpace(hotkeyString))
            return null;

        uint modifiers = 0;
        var key = hotkeyString;

        if (key.Contains('#')) { modifiers |= 0x08; key = key.Replace("#", ""); } // Win
        if (key.Contains('^')) { modifiers |= 0x02; key = key.Replace("^", ""); } // Ctrl
        if (key.Contains('!')) { modifiers |= 0x01; key = key.Replace("!", ""); } // Alt
        if (key.Contains('+')) { modifiers |= 0x04; key = key.Replace("+", ""); } // Shift

        var vk = GetVirtualKeyCode(key);
        if (vk == 0)
            return null;

        return (vk, modifiers);
    }
    
    public void ProcessHotkeyMessage(int hotkeyId)
    {
        // Not used for low-level hooks
    }
    
    private IntPtr SetHook(LowLevelKeyboardProc proc)
    {
        using (var curProcess = Process.GetCurrentProcess())
        using (var curModule = curProcess.MainModule)
        {
            if (curModule?.ModuleName == null)
                return IntPtr.Zero;
                
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc, 
                GetModuleHandle(curModule.ModuleName), 0);
        }
    }
    
    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (!_enabled || nCode < 0)
            return CallNextHookEx(_hookId, nCode, wParam, lParam);
        
        if (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN)
        {
            int vkCode = Marshal.ReadInt32(lParam);
            
            // Check current modifier states
            uint currentMods = 0;
            if ((GetAsyncKeyState(0x5B) & 0x8000) != 0 || (GetAsyncKeyState(0x5C) & 0x8000) != 0) 
                currentMods |= 0x08; // Win
            if ((GetAsyncKeyState(0x11) & 0x8000) != 0) 
                currentMods |= 0x02; // Ctrl
            if ((GetAsyncKeyState(0x12) & 0x8000) != 0) 
                currentMods |= 0x01; // Alt
            if ((GetAsyncKeyState(0x10) & 0x8000) != 0) 
                currentMods |= 0x04; // Shift
            
            // Check if any registered hotkey matches
            foreach (var (hotkeyString, info) in _hotkeys)
            {
                if (info.VirtualKey == vkCode && info.Modifiers == currentMods)
                {
                    Console.WriteLine($">>> LOW-LEVEL HOTKEY MATCHED: {hotkeyString}");
                    info.Callback?.Invoke();
                    return (IntPtr)1; // Block the key
                }
            }
        }
        
        return CallNextHookEx(_hookId, nCode, wParam, lParam);
    }
    
    private uint GetVirtualKeyCode(string key)
    {
        key = key.Trim().ToUpperInvariant();
        
        if (key.Length == 1)
        {
            char c = key[0];
            if (c >= '0' && c <= '9') return (uint)c;
            if (c >= 'A' && c <= 'Z') return (uint)c;
        }
        
        return key switch
        {
            "SPACE" => 0x20,
            "RETURN" or "ENTER" => 0x0D,
            "ESCAPE" or "ESC" => 0x1B,
            "F1" => 0x70, "F2" => 0x71, "F3" => 0x72, "F4" => 0x73,
            "F5" => 0x74, "F6" => 0x75, "F7" => 0x76, "F8" => 0x77,
            "F9" => 0x78, "F10" => 0x79, "F11" => 0x7A, "F12" => 0x7B,
            _ => 0
        };
    }
    
    public void Dispose()
    {
        if (_hookId != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_hookId);
            _hookId = IntPtr.Zero;
        }
        GC.SuppressFinalize(this);
    }
    
    // Win32 APIs
    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
    
    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);
}

internal class HotkeyInfo
{
    public uint VirtualKey { get; set; }
    public uint Modifiers { get; set; }
    public Action? Callback { get; set; }
    public string HotkeyString { get; set; } = "";
}
