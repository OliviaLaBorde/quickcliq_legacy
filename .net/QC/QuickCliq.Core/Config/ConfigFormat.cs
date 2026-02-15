namespace QuickCliq.Core.Config;

/// <summary>
/// Configuration format for Quick Cliq
/// </summary>
public enum ConfigFormat
{
    /// <summary>
    /// Legacy XML format (v2.x AHK)
    /// </summary>
    Xml,
    
    /// <summary>
    /// Modern JSON format (v3.x .NET)
    /// </summary>
    Json
}
