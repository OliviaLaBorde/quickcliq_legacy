using System.Text.Json.Serialization;

namespace QuickCliq.Core.Models;

/// <summary>
/// Represents a menu item from config
/// </summary>
public class MenuItem
{
    [JsonPropertyName("id")]
    public int Id { get; set; }
    
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;
    
    [JsonPropertyName("icon")]
    public string Icon { get; set; } = string.Empty;
    
    [JsonPropertyName("hotkey")]
    public string Hotkey { get; set; } = string.Empty;
    
    [JsonPropertyName("bold")]
    public bool Bold { get; set; }
    
    [JsonPropertyName("isSeparator")]
    public bool IsSeparator { get; set; }
    
    [JsonPropertyName("isMenu")]
    public bool IsMenu { get; set; }
    
    [JsonPropertyName("autorun")]
    public bool Autorun { get; set; }
    
    [JsonPropertyName("textColor")]
    public int TextColor { get; set; }
    
    [JsonPropertyName("bgColor")]
    public int BgColor { get; set; }
    
    [JsonPropertyName("commands")]
    public List<string> Commands { get; set; } = new();
    
    [JsonPropertyName("children")]
    public List<MenuItem> Children { get; set; } = new();
    
    /// <summary>
    /// Gets command string with {N} separator for multi-target
    /// </summary>
    public string GetCommandString() =>
        string.Join(AppConstants.MultiTargetDivider, Commands);
    
    /// <summary>
    /// Sets commands from string with {N} separator
    /// </summary>
    public void SetCommandString(string commandString) =>
        Commands = commandString.Split(new[] { AppConstants.MultiTargetDivider }, 
            StringSplitOptions.RemoveEmptyEntries).ToList();
}
