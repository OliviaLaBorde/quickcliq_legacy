using QuickCliq.Core.Models;

namespace QuickCliq.Core.Services;

/// <summary>
/// Service for parsing and resolving icon strings
/// </summary>
public class IconResolver
{
    /// <summary>
    /// Parse icon string and return structured icon data
    /// Supports prefixes: material:, emoji:, file:
    /// No prefix defaults to file path (backward compatibility)
    /// </summary>
    public IconData Resolve(string? iconString)
    {
        if (string.IsNullOrWhiteSpace(iconString))
            return IconData.None;
        
        if (iconString.StartsWith("material:", StringComparison.OrdinalIgnoreCase))
            return new IconData { Type = IconType.Material, Value = iconString[9..] };
        
        if (iconString.StartsWith("emoji:", StringComparison.OrdinalIgnoreCase))
        {
            var emojiValue = iconString[6..];
            // Convert hex code to emoji if needed (e.g., "1F600" -> 😀)
            if (emojiValue.Length >= 4 && !emojiValue.Contains(' ') && IsHexString(emojiValue))
            {
                try
                {
                    var codePoint = Convert.ToInt32(emojiValue, 16);
                    emojiValue = char.ConvertFromUtf32(codePoint);
                }
                catch
                {
                    // Invalid hex code, use as-is
                }
            }
            return new IconData { Type = IconType.Emoji, Value = emojiValue };
        }
        
        if (iconString.StartsWith("file:", StringComparison.OrdinalIgnoreCase))
            return new IconData { Type = IconType.File, Value = iconString[5..] };
        
        // Backward compatibility: no prefix = file
        return new IconData { Type = IconType.File, Value = iconString };
    }
    
    /// <summary>
    /// Create icon string from type and value
    /// </summary>
    public string CreateIconString(IconType type, string value)
    {
        return type switch
        {
            IconType.Material => $"material:{value}",
            IconType.Emoji => $"emoji:{value}",
            IconType.File => string.IsNullOrWhiteSpace(value) ? "" : $"file:{value}",
            _ => ""
        };
    }
    
    private static bool IsHexString(string str)
    {
        foreach (char c in str)
        {
            if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f')))
                return false;
        }
        return true;
    }
}
