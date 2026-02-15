using System.Runtime.InteropServices;
using QuickCliq.Core.Services;

namespace QuickCliq.Core.Menu;

/// <summary>
/// Basic popup menu implementation using native Windows menus
/// 
/// PHASE 3 TODO: Implement custom rendering for full PUM features:
/// - Custom colors (text, background, frame)
/// - Custom fonts and font quality
/// - Custom icons with size control
/// - Gradient backgrounds
/// - Advanced selection modes
/// - See legacy include\PUM\PUM_API.ahk for reference
/// </summary>
public class BasicPopupMenu : IPopupMenu
{
    private IntPtr _hMenu;
    private readonly MenuParams _params;
    private static readonly Dictionary<string, MenuItemParams> _allItems = new(); // Shared across all menus
    private static readonly Dictionary<int, string> _itemIdToUid = new(); // Shared across all menus
    private readonly IconService _iconService;
    private static int _nextItemId = 1000; // Static to share across all menu instances

    public IntPtr Handle => _hMenu;
    public bool IsShown { get; private set; }

    public BasicPopupMenu(MenuParams parameters, IconService iconService)
    {
        _params = parameters;
        _iconService = iconService;
        _hMenu = CreatePopupMenu();
    }

    public void Add(MenuItemParams item)
    {
        _allItems[item.Uid] = item;
        
        var itemId = _nextItemId++;
        var flags = MF_STRING;
        
        if (item.Disabled)
            flags |= MF_GRAYED;
        
        if (item.Submenu != null)
            flags |= MF_POPUP;

        var text = item.Name;
        var menuHandle = item.Submenu?.Handle ?? IntPtr.Zero;
        
        if (item.Submenu != null)
        {
            AppendMenu(_hMenu, flags, menuHandle, text);
        }
        else
        {
            _itemIdToUid[itemId] = item.Uid; // Map ID to UID
            AppendMenu(_hMenu, flags, (IntPtr)itemId, text);
        }
    }

    public void AddSeparator()
    {
        AppendMenu(_hMenu, MF_SEPARATOR, IntPtr.Zero, null);
    }

    public void AddText(string text)
    {
        AppendMenu(_hMenu, MF_STRING | MF_GRAYED, IntPtr.Zero, text);
    }

    public MenuItemResult? Show(int x, int y, string mode = "normal")
    {
        IsShown = true;
        
        // Get our app's message window handle
        var ourWindow = GetAppMessageWindow();
        
        if (ourWindow != IntPtr.Zero)
        {
            // Make our window foreground (this will cause taskbar entry while menu is open)
            SetForegroundWindow(ourWindow);
            System.Threading.Thread.Sleep(10); // Small delay for window activation
            
            var flags = TPM_RETURNCMD | TPM_LEFTBUTTON | TPM_RIGHTBUTTON;
            var cmdId = TrackPopupMenu(_hMenu, flags, x, y, 0, ourWindow, IntPtr.Zero);
            
            // Post null message to ensure proper cleanup
            PostMessage(ourWindow, 0, IntPtr.Zero, IntPtr.Zero);
            
            IsShown = false;
            return ProcessMenuResult(cmdId);
        }
        
        return null;
    }
    
    private MenuItemResult? ProcessMenuResult(int cmdId)
    {
        if (cmdId == 0)
            return null;

        if (_itemIdToUid.TryGetValue(cmdId, out var uid) && _allItems.TryGetValue(uid, out var item))
        {
            return new MenuItemResult
            {
                Uid = item.Uid,
                Tag = item.Tag,
                AssocMenu = item.Submenu,
                IsMenu = item.Submenu != null,
                Name = item.Name,
                Icon = item.Icon
            };
        }

        return null;
    }
    
    private static IntPtr GetAppMessageWindow()
    {
        // Use reflection to get the message window handle from App
        try
        {
            var appType = Type.GetType("QC.net.App, QC.net");
            if (appType != null)
            {
                var method = appType.GetMethod("GetMessageWindowHandle", 
                    System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
                if (method != null)
                {
                    var result = method.Invoke(null, null);
                    if (result is IntPtr handle)
                    {
                        return handle;
                    }
                }
            }
        }
        catch
        {
            // Silently fail - just return zero
        }
        return IntPtr.Zero;
    }

    public MenuItemParams? GetItemByUID(string uid)
    {
        return _allItems.TryGetValue(uid, out var item) ? item : null;
    }

    public void UpdateItem(string uid, MenuItemParams newParams)
    {
        if (_allItems.ContainsKey(uid))
        {
            _allItems[uid] = newParams;
            // TODO: Update menu display
        }
    }
    
    /// <summary>
    /// Clears all static menu item mappings. Call this before rebuilding menus.
    /// </summary>
    public static void ClearAllMenuItems()
    {
        _allItems.Clear();
        _itemIdToUid.Clear();
        _nextItemId = 1000;
    }

    public void Destroy()
    {
        if (_hMenu != IntPtr.Zero)
        {
            DestroyMenu(_hMenu);
            _hMenu = IntPtr.Zero;
        }
        
        // Don't clear static dictionaries here - they're shared across all menus
        // Only clear them in RebuildAll when starting fresh
    }

    // Win32 APIs
    [DllImport("user32.dll")]
    private static extern IntPtr CreatePopupMenu();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern bool AppendMenu(IntPtr hMenu, uint uFlags, IntPtr uIDNewItem, string? lpNewItem);

    [DllImport("user32.dll")]
    private static extern int TrackPopupMenu(IntPtr hMenu, uint uFlags, int x, int y, 
        int nReserved, IntPtr hWnd, IntPtr prcRect);

    [DllImport("user32.dll")]
    private static extern bool DestroyMenu(IntPtr hMenu);
    
    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    private static extern IntPtr GetDesktopWindow();
    
    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    private static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    
    [DllImport("kernel32.dll")]
    private static extern IntPtr GetConsoleWindow();
    
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateWindowExW(
        uint dwExStyle, string lpClassName, string lpWindowName, uint dwStyle,
        int x, int y, int nWidth, int nHeight, 
        IntPtr hWndParent, IntPtr hMenu, IntPtr hInstance, IntPtr lpParam);
    
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    private const int SW_HIDE = 0;
    private const int SW_SHOWNA = 8;

    // Menu flags
    private const uint MF_STRING = 0x0000;
    private const uint MF_POPUP = 0x0010;
    private const uint MF_SEPARATOR = 0x0800;
    private const uint MF_GRAYED = 0x0001;
    private const uint TPM_RETURNCMD = 0x0100;
    private const uint TPM_LEFTBUTTON = 0x0000;
    private const uint TPM_RIGHTBUTTON = 0x0002;
    private const uint TPM_NONOTIFY = 0x0080;
}

/// <summary>
/// Factory for creating BasicPopupMenu instances
/// </summary>
public class BasicPopupMenuFactory : IPopupMenuFactory
{
    private readonly IconService _iconService;

    public BasicPopupMenuFactory(IconService iconService)
    {
        _iconService = iconService;
    }

    public IPopupMenu CreateMenu(MenuParams parameters)
    {
        return new BasicPopupMenu(parameters, _iconService);
    }
}
