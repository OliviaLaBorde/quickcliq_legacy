using System.Text.Json.Serialization;

namespace QuickCliq.Core.Models;

/// <summary>
/// Root configuration model for JSON format
/// Replaces legacy XML structure
/// </summary>
public class QuickCliqConfig
{
    [JsonPropertyName("version")]
    public string Version { get; set; } = AppConstants.Version;
    
    [JsonPropertyName("lastId")]
    public int LastId { get; set; }
    
    [JsonPropertyName("menu")]
    public MenuConfig Menu { get; set; } = new();
    
    [JsonPropertyName("settings")]
    public Dictionary<string, object> Settings { get; set; } = new();
    
    [JsonPropertyName("hiddenWindows")]
    public List<HiddenWindow> HiddenWindows { get; set; } = new();
}

/// <summary>
/// Menu configuration
/// </summary>
public class MenuConfig
{
    [JsonPropertyName("id")]
    public int Id { get; set; }
    
    [JsonPropertyName("name")]
    public string Name { get; set; } = "main";
    
    [JsonPropertyName("textColor")]
    public int TextColor { get; set; }
    
    [JsonPropertyName("bgColor")]
    public int BgColor { get; set; }
    
    [JsonPropertyName("items")]
    public List<MenuItem> Items { get; set; } = new();
}

/// <summary>
/// Hidden window entry
/// </summary>
public class HiddenWindow
{
    [JsonPropertyName("hwnd")]
    public int Hwnd { get; set; }
    
    [JsonPropertyName("isTopmost")]
    public bool IsTopmost { get; set; }
}
