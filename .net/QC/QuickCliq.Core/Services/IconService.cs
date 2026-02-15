using System.Runtime.InteropServices;
using QuickCliq.Core.Win32;

namespace QuickCliq.Core.Services;

/// <summary>
/// Icon extraction service wrapping Win32 icon functions
/// </summary>
public class IconService
{
    /// <summary>
    /// Extract icon from file path
    /// Format: "path:index" or "path"
    /// </summary>
    public IntPtr ExtractIcon(string iconPath, int size = 32)
    {
        var (path, index) = ParseIconPath(iconPath);
        
        if (string.IsNullOrEmpty(path))
            return IntPtr.Zero;
        
        // Try PrivateExtractIcons first
        var icons = new IntPtr[1];
        var count = NativeMethods.PrivateExtractIcons(
            path,
            index,
            size,
            size,
            icons,
            null,
            1,
            0);
        
        if (count > 0 && icons[0] != IntPtr.Zero)
            return icons[0];
        
        // Fallback to ExtractAssociatedIcon for .exe
        if (Path.GetExtension(path).Equals(".exe", StringComparison.OrdinalIgnoreCase))
        {
            ushort iconIndex = (ushort)index;
            return NativeMethods.ExtractAssociatedIcon(IntPtr.Zero, path, ref iconIndex);
        }
        
        return IntPtr.Zero;
    }
    
    /// <summary>
    /// Parse icon path string "path:index"
    /// </summary>
    public (string Path, int Index) ParseIconPath(string iconPath)
    {
        if (string.IsNullOrWhiteSpace(iconPath))
            return (string.Empty, 0);
        
        var lastColon = iconPath.LastIndexOf(':');
        if (lastColon > 1) // Not drive letter (e.g., C:)
        {
            var indexStr = iconPath[(lastColon + 1)..];
            if (int.TryParse(indexStr, out var index))
            {
                return (iconPath[..lastColon], index);
            }
        }
        
        return (iconPath, 0);
    }
    
    /// <summary>
    /// Get icon for file extension
    /// </summary>
    public string? GetIconForExtension(string extension, string? filePath = null)
    {
        if (extension == ".exe" && !string.IsNullOrEmpty(filePath))
            return $"{filePath}:0";
        
        if (extension == ".ico" && !string.IsNullOrEmpty(filePath))
            return filePath;
        
        // Query registry for default icon
        try
        {
            using var extKey = Microsoft.Win32.Registry.ClassesRoot.OpenSubKey(extension);
            if (extKey != null)
            {
                var progId = extKey.GetValue(null) as string;
                if (!string.IsNullOrEmpty(progId))
                {
                    using var progIdKey = Microsoft.Win32.Registry.ClassesRoot.OpenSubKey($"{progId}\\DefaultIcon");
                    if (progIdKey != null)
                    {
                        var iconPath = progIdKey.GetValue(null) as string;
                        return iconPath?.Replace("\"", "").Replace(",", ":");
                    }
                }
            }
        }
        catch
        {
            // Ignore registry errors
        }
        
        return null;
    }
    
    /// <summary>
    /// Make icon path relative to Data\user_icons
    /// </summary>
    public string MakeRelative(string iconPath)
    {
        var (path, index) = ParseIconPath(iconPath);
        var userIconsPath = AppConstants.UserIconsPath;
        
        if (path.StartsWith(userIconsPath, StringComparison.OrdinalIgnoreCase))
        {
            var relativePath = Path.GetRelativePath(AppConstants.DataPath, path);
            return index > 0 ? $"{relativePath}:{index}" : relativePath;
        }
        
        return iconPath;
    }
    
    /// <summary>
    /// Dispose icon handle
    /// </summary>
    public void DestroyIcon(IntPtr hIcon)
    {
        if (hIcon != IntPtr.Zero)
            NativeMethods.DestroyIcon(hIcon);
    }
}
