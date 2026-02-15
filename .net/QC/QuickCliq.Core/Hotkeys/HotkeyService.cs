using System.Runtime.InteropServices;
using QuickCliq.Core.Win32;

namespace QuickCliq.Core.Hotkeys;

/// <summary>
/// Hotkey service implementation
/// Based on legacy hk_hotkey.ahk
/// </summary>
public class HotkeyService : IHotkeyService, IDisposable
{
    private readonly Dictionary<string, HotkeyRegistration> _registeredHotkeys = new();
    private readonly IntPtr _windowHandle;
    private int _nextHotkeyId = 1;
    private bool _allEnabled = true;

    public HotkeyService(IntPtr windowHandle)
    {
        _windowHandle = windowHandle;
    }

    public bool Register(string hotkeyString, Action callback)
    {
        if (string.IsNullOrWhiteSpace(hotkeyString))
            return false;

        // Parse hotkey string
        var parsed = Parse(hotkeyString);
        if (parsed == null)
            return false;

        var (vk, mods) = parsed.Value;
        
        // Check if already registered
        if (_registeredHotkeys.ContainsKey(hotkeyString))
        {
            Unregister(hotkeyString);
        }

        var id = _nextHotkeyId++;
        
        // Register with Windows
        if (!NativeMethods.RegisterHotKey(_windowHandle, id, mods, vk))
        {
            var error = Marshal.GetLastWin32Error();
            Console.WriteLine($"Failed to register hotkey {hotkeyString}: Error {error}");
            return false;
        }

        _registeredHotkeys[hotkeyString] = new HotkeyRegistration
        {
            Id = id,
            HotkeyString = hotkeyString,
            VirtualKey = vk,
            Modifiers = mods,
            Callback = callback,
            Enabled = true
        };

        return true;
    }

    public bool Unregister(string hotkeyString)
    {
        if (!_registeredHotkeys.TryGetValue(hotkeyString, out var registration))
            return false;

        var success = NativeMethods.UnregisterHotKey(_windowHandle, registration.Id);
        _registeredHotkeys.Remove(hotkeyString);
        return success;
    }

    public void SetAllEnabled(bool enabled)
    {
        _allEnabled = enabled;
        
        foreach (var (hotkeyString, registration) in _registeredHotkeys)
        {
            if (enabled && !registration.Enabled)
            {
                // Re-register
                NativeMethods.RegisterHotKey(_windowHandle, registration.Id, 
                    registration.Modifiers, registration.VirtualKey);
                registration.Enabled = true;
            }
            else if (!enabled && registration.Enabled)
            {
                // Unregister but keep in dictionary
                NativeMethods.UnregisterHotKey(_windowHandle, registration.Id);
                registration.Enabled = false;
            }
        }
    }

    /// <summary>
    /// Handle WM_HOTKEY message
    /// Call this from your window procedure
    /// </summary>
    public void ProcessHotkeyMessage(int hotkeyId)
    {
        if (!_allEnabled)
            return;

        var registration = _registeredHotkeys.Values.FirstOrDefault(r => r.Id == hotkeyId);
        if (registration != null && registration.Enabled)
        {
            registration.Callback?.Invoke();
        }
    }

    public string ToDisplayString(string hotkeyString)
    {
        var parts = new List<string>();
        
        if (hotkeyString.Contains('#')) parts.Add("Win");
        if (hotkeyString.Contains('^')) parts.Add("Ctrl");
        if (hotkeyString.Contains('!')) parts.Add("Alt");
        if (hotkeyString.Contains('+')) parts.Add("Shift");
        
        // Extract key (remove modifiers)
        var key = hotkeyString.TrimStart('#', '^', '!', '+');
        
        // Convert common key names
        key = key.ToUpperInvariant() switch
        {
            "RBUTTON" => "Right Mouse",
            "MBUTTON" => "Middle Mouse",
            "LBUTTON" => "Left Mouse",
            "SPACE" => "Space",
            "RETURN" or "ENTER" => "Enter",
            "ESCAPE" or "ESC" => "Esc",
            "TAB" => "Tab",
            "BACK" or "BACKSPACE" => "Backspace",
            _ => key.ToUpperInvariant()
        };
        
        parts.Add(key);
        return string.Join("+", parts);
    }

    public (uint VirtualKey, uint Modifiers)? Parse(string hotkeyString)
    {
        if (string.IsNullOrWhiteSpace(hotkeyString))
            return null;

        uint modifiers = 0;
        var key = hotkeyString;

        // Parse modifiers
        if (key.Contains('#'))
        {
            modifiers |= NativeMethods.MOD_WIN;
            key = key.Replace("#", "");
        }
        if (key.Contains('^'))
        {
            modifiers |= NativeMethods.MOD_CONTROL;
            key = key.Replace("^", "");
        }
        if (key.Contains('!'))
        {
            modifiers |= NativeMethods.MOD_ALT;
            key = key.Replace("!", "");
        }
        if (key.Contains('+'))
        {
            modifiers |= NativeMethods.MOD_SHIFT;
            key = key.Replace("+", "");
        }

        // Parse virtual key
        var vk = GetVirtualKeyCode(key);
        if (vk == 0)
            return null;

        return (vk, modifiers);
    }

    private uint GetVirtualKeyCode(string key)
    {
        key = key.Trim().ToUpperInvariant();

        // Single character
        if (key.Length == 1)
        {
            char c = key[0];
            if (c >= '0' && c <= '9') return (uint)c;
            if (c >= 'A' && c <= 'Z') return (uint)c;
        }

        // Named keys
        return key switch
        {
            "SPACE" => 0x20,
            "RETURN" or "ENTER" => 0x0D,
            "ESCAPE" or "ESC" => 0x1B,
            "TAB" => 0x09,
            "BACK" or "BACKSPACE" => 0x08,
            "DELETE" or "DEL" => 0x2E,
            "INSERT" or "INS" => 0x2D,
            "HOME" => 0x24,
            "END" => 0x23,
            "PGUP" or "PAGEUP" => 0x21,
            "PGDN" or "PAGEDOWN" => 0x22,
            "UP" => 0x26,
            "DOWN" => 0x28,
            "LEFT" => 0x25,
            "RIGHT" => 0x27,
            
            // F keys
            "F1" => 0x70,
            "F2" => 0x71,
            "F3" => 0x72,
            "F4" => 0x73,
            "F5" => 0x74,
            "F6" => 0x75,
            "F7" => 0x76,
            "F8" => 0x77,
            "F9" => 0x78,
            "F10" => 0x79,
            "F11" => 0x7A,
            "F12" => 0x7B,
            
            // Mouse buttons (note: can't use RegisterHotKey for mouse)
            "LBUTTON" => NativeMethods.VK_LBUTTON,
            "RBUTTON" => NativeMethods.VK_RBUTTON,
            "MBUTTON" => NativeMethods.VK_MBUTTON,
            
            _ => 0
        };
    }

    public void Dispose()
    {
        foreach (var hotkeyString in _registeredHotkeys.Keys.ToList())
        {
            Unregister(hotkeyString);
        }
        GC.SuppressFinalize(this);
    }
}

internal class HotkeyRegistration
{
    public int Id { get; set; }
    public string HotkeyString { get; set; } = string.Empty;
    public uint VirtualKey { get; set; }
    public uint Modifiers { get; set; }
    public Action? Callback { get; set; }
    public bool Enabled { get; set; }
}
