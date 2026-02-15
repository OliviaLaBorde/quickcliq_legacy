namespace QuickCliq.Core.Config;

/// <summary>
/// Typed access to application settings stored in XML config
/// Provides caching and default values
/// </summary>
public interface IOptionsService
{
    T Get<T>(string name);
    void Set<T>(string name, T value);
    bool Exists(string name);
    void Reset(string name); // Reset to default
    void ResetAll();
    void ClearCache(); // Clear cache to force reload from config
}
