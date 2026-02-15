namespace QuickCliq.Core.Hotkeys;

/// <summary>
/// Hotkey service interface
/// Registers/unregisters global hotkeys
/// </summary>
public interface IHotkeyService : IDisposable
{
    /// <summary>
    /// Register a global hotkey
    /// </summary>
    /// <param name="hotkeyString">Hotkey in AHK format (#Z, ^RButton, etc.)</param>
    /// <param name="callback">Action to invoke when hotkey is pressed</param>
    /// <returns>True if successful</returns>
    bool Register(string hotkeyString, Action callback);
    
    /// <summary>
    /// Unregister a hotkey
    /// </summary>
    bool Unregister(string hotkeyString);
    
    /// <summary>
    /// Enable/disable all hotkeys
    /// </summary>
    void SetAllEnabled(bool enabled);
    
    /// <summary>
    /// Convert hotkey to display string (Win+Z, Ctrl+Alt+X, etc.)
    /// </summary>
    string ToDisplayString(string hotkeyString);
    
    /// <summary>
    /// Parse hotkey string to VK and modifiers
    /// </summary>
    (uint VirtualKey, uint Modifiers)? Parse(string hotkeyString);
    
    /// <summary>
    /// Process WM_HOTKEY message (call from window procedure)
    /// </summary>
    void ProcessHotkeyMessage(int hotkeyId);
}
