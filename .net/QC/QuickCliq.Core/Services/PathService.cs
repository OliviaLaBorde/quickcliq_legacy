using System.Text;
using QuickCliq.Core.Win32;

namespace QuickCliq.Core.Services;

/// <summary>
/// Path utility service wrapping Win32 Shlwapi functions
/// </summary>
public class PathService
{
    public bool IsUrl(string path) => NativeMethods.PathIsURL(path);
    
    public bool IsDirectory(string path) => NativeMethods.PathIsDirectory(path);
    
    public bool IsRelative(string path) => NativeMethods.PathIsRelative(path);
    
    public bool IsFileSpec(string path) => NativeMethods.PathIsFileSpec(path);
    
    public bool IsNetworkPath(string path) => NativeMethods.PathIsNetworkPath(path);
    
    /// <summary>
    /// Extract arguments from path string
    /// </summary>
    public string GetArgs(string path)
    {
        // Find first space not in quotes
        bool inQuotes = false;
        for (int i = 0; i < path.Length; i++)
        {
            if (path[i] == '"') inQuotes = !inQuotes;
            if (path[i] == ' ' && !inQuotes)
                return path[(i + 1)..].Trim();
        }
        return string.Empty;
    }
    
    /// <summary>
    /// Remove arguments from path
    /// </summary>
    public string RemoveArgs(string path)
    {
        var args = GetArgs(path);
        return args.Length > 0 ? path[..^args.Length].Trim() : path;
    }
    
    /// <summary>
    /// Get directory from path
    /// </summary>
    public string GetDirectory(string path)
    {
        path = UnquoteSpaces(path);
        if (IsDirectory(path))
            return path.TrimEnd('\\');
        
        var sb = new StringBuilder(path);
        NativeMethods.PathRemoveFileSpec(sb);
        return sb.ToString();
    }
    
    /// <summary>
    /// Resolve relative path to absolute
    /// </summary>
    public string Resolve(string path)
    {
        path = UnquoteSpaces(path);
        if (IsRelative(path) && IsProperPath(path))
        {
            return QuoteSpaces(Path.Combine(Environment.CurrentDirectory, path));
        }
        return QuoteSpaces(path);
    }
    
    /// <summary>
    /// Make path relative to Data directory
    /// </summary>
    public string MakeRelative(string path)
    {
        var dataPath = AppConstants.DataPath;
        if (path.StartsWith(dataPath, StringComparison.OrdinalIgnoreCase))
        {
            return Path.GetRelativePath(dataPath, path);
        }
        return path;
    }
    
    /// <summary>
    /// Quote path if it contains spaces
    /// </summary>
    public string QuoteSpaces(string path)
    {
        path = path.Trim();
        if (path.Contains(' ') && !path.Contains('"'))
            return $"\"{path}\"";
        return path;
    }
    
    /// <summary>
    /// Remove quotes from path
    /// </summary>
    public string UnquoteSpaces(string path)
    {
        path = path.Trim();
        if (path.StartsWith('"') && path.EndsWith('"'))
            return path[1..^1];
        return path;
    }
    
    /// <summary>
    /// Check if path is proper (not just a file spec or URL)
    /// </summary>
    public bool IsProperPath(string path)
    {
        if (path is "." or "..")
            return true;
        return !(IsFileSpec(path) || IsUrl(path) || path.Contains('%'));
    }
    
    /// <summary>
    /// Expand environment variables in path
    /// </summary>
    public string ExpandEnvVars(string path)
    {
        return Environment.ExpandEnvironmentVariables(path);
    }
    
    /// <summary>
    /// Split path into components (path, args, working dir)
    /// </summary>
    public (string Path, string Args, string WorkDir) Split(string fullPath)
    {
        var args = GetArgs(fullPath);
        var path = args.Length > 0 ? RemoveArgs(fullPath) : fullPath;
        var workDir = GetDirectory(path);
        path = ExpandEnvVars(path);
        return (path, args, workDir);
    }
}
