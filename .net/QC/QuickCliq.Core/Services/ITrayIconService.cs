namespace QuickCliq.Core.Services;

/// <summary>
/// Interface for tray icon management
/// Implementation in UI project (WPF/WinForms)
/// </summary>
public interface ITrayIconService
{
    bool IsVisible { get; set; }
    string ToolTipText { get; set; }
    
    void Show();
    void Hide();
    void ShowBalloon(string title, string message, int timeoutMs = 3000);
    
    event EventHandler? IconClicked;
    event EventHandler? OpenEditorClicked;
    event EventHandler? SuspendHotkeysClicked;
    event EventHandler? SuspendGesturesClicked;
    event EventHandler? OptionsClicked;
    event EventHandler? CheckUpdatesClicked;
    event EventHandler? ExitClicked;
}
