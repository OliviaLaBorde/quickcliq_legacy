using System.Runtime.InteropServices;

namespace QuickCliq.Core.Win32;

/// <summary>
/// P/Invoke declarations for icon operations (User32, Shell32)
/// </summary>
public static partial class NativeMethods
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr LoadImage(
        IntPtr hinst,
        string lpszName,
        uint uType,
        int cxDesired,
        int cyDesired,
        uint fuLoad);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool DestroyIcon(IntPtr hIcon);
    
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr CopyImage(
        IntPtr hImage,
        uint uType,
        int cxDesired,
        int cyDesired,
        uint fuFlags);
    
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int PrivateExtractIcons(
        string szFileName,
        int nIconIndex,
        int cxIcon,
        int cyIcon,
        IntPtr[]? phicon,
        IntPtr[]? piconid,
        uint nIcons,
        uint flags);
    
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr ExtractAssociatedIcon(
        IntPtr hInst,
        string lpIconPath,
        ref ushort lpiIcon);
    
    // Icon constants
    public const uint IMAGE_ICON = 1;
    public const uint IMAGE_BITMAP = 0;
    public const uint LR_LOADFROMFILE = 0x10;
    public const uint LR_COPYDELETEORG = 0x8;
}
