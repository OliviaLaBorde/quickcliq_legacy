using System.Runtime.InteropServices;
using System.Text;

namespace QuickCliq.Core.Win32;

/// <summary>
/// P/Invoke declarations for path operations (Shlwapi.dll)
/// </summary>
public static partial class NativeMethods
{
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, EntryPoint = "PathIsURLW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PathIsURL(string pszPath);
    
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, EntryPoint = "PathIsDirectoryW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PathIsDirectory(string pszPath);
    
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, EntryPoint = "PathIsRelativeW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PathIsRelative(string pszPath);
    
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, EntryPoint = "PathIsFileSpecW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PathIsFileSpec(string pszPath);
    
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, EntryPoint = "PathIsNetworkPathW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PathIsNetworkPath(string pszPath);
    
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern bool PathRemoveFileSpec(
        [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath);
    
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern bool PathAppend(
        [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
        [MarshalAs(UnmanagedType.LPWStr)] string pszMore);
}
