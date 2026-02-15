namespace QuickCliq.Core.Models;

/// <summary>
/// Icon type enumeration
/// </summary>
public enum IconType
{
    None,
    Material,
    Emoji,
    File
}

/// <summary>
/// Parsed icon data
/// </summary>
public class IconData
{
    public IconType Type { get; set; }
    public string Value { get; set; } = string.Empty;
    
    public static IconData None => new IconData { Type = IconType.None, Value = string.Empty };
}
