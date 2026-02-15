using System.Windows;
using QuickCliq.Core.Menu;
using QuickCliq.Core.Services;
using WpfControls = System.Windows.Controls;
using WpfMedia = System.Windows.Media;

namespace QC.net.Services;

/// <summary>
/// WPF-based popup menu implementation - no Win32 hassles!
/// </summary>
public class WpfPopupMenu : IPopupMenu
{
    private readonly WpfControls.ContextMenu _contextMenu;
    private readonly MenuParams _params;
    private readonly Dictionary<string, MenuItemParams> _items = new();
    private readonly Dictionary<WpfControls.MenuItem, string> _menuItemToUid = new();
    private readonly IconService _iconService;
    private TaskCompletionSource<MenuItemResult?>? _resultSource;

    public IntPtr Handle => IntPtr.Zero; // Not needed for WPF
    public bool IsShown { get; private set; }

    public WpfPopupMenu(MenuParams parameters, IconService iconService)
    {
        _params = parameters;
        _iconService = iconService;
        _contextMenu = new WpfControls.ContextMenu
        {
            // Style to look native
            Background = new WpfMedia.SolidColorBrush(WpfMedia.Color.FromRgb(
                (byte)((parameters.BgColor >> 16) & 0xFF),
                (byte)((parameters.BgColor >> 8) & 0xFF),
                (byte)(parameters.BgColor & 0xFF)
            )),
            Foreground = new WpfMedia.SolidColorBrush(WpfMedia.Color.FromRgb(
                (byte)((parameters.TextColor >> 16) & 0xFF),
                (byte)((parameters.TextColor >> 8) & 0xFF),
                (byte)(parameters.TextColor & 0xFF)
            )),
            HasDropShadow = true,
            StaysOpen = false // Dismiss when clicking outside
        };
        
        _contextMenu.Closed += OnMenuClosed;
    }

    public void Add(MenuItemParams item)
    {
        _items[item.Uid] = item;
        
        var menuItem = new WpfControls.MenuItem
        {
            Header = item.Name,
            Tag = item.Tag,
            FontWeight = item.Bold ? FontWeights.Bold : FontWeights.Normal
        };
        
        // Handle custom colors
        if (item.TColor.HasValue)
        {
            menuItem.Foreground = new WpfMedia.SolidColorBrush(WpfMedia.Color.FromRgb(
                (byte)((item.TColor.Value >> 16) & 0xFF),
                (byte)((item.TColor.Value >> 8) & 0xFF),
                (byte)(item.TColor.Value & 0xFF)
            ));
        }
        
        // Handle submenu
        if (item.Submenu is WpfPopupMenu wpfSubmenu)
        {
            // Copy submenu items
            foreach (var subItem in wpfSubmenu._contextMenu.Items)
            {
                if (subItem is WpfControls.MenuItem subMenuItem)
                {
                    menuItem.Items.Add(subMenuItem);
                }
                else if (subItem is WpfControls.Separator)
                {
                    menuItem.Items.Add(new WpfControls.Separator());
                }
            }
        }
        
        // Click handler (only for non-submenu items)
        if (item.Submenu == null)
        {
            menuItem.Click += (s, e) =>
            {
                var result = new MenuItemResult
                {
                    Uid = item.Uid,
                    Tag = item.Tag,
                    AssocMenu = item.Submenu,
                    IsMenu = false,
                    Name = item.Name,
                    Icon = item.Icon
                };
                
                _resultSource?.TrySetResult(result);
                _contextMenu.IsOpen = false;
            };
        }
        
        _menuItemToUid[menuItem] = item.Uid;
        _contextMenu.Items.Add(menuItem);
    }

    public void AddSeparator()
    {
        _contextMenu.Items.Add(new WpfControls.Separator());
    }

    public void AddText(string text)
    {
        var menuItem = new WpfControls.MenuItem
        {
            Header = text,
            IsEnabled = false
        };
        _contextMenu.Items.Add(menuItem);
    }

    public MenuItemResult? Show(int x, int y, string mode = "normal")
    {
        IsShown = true;
        _resultSource = new TaskCompletionSource<MenuItemResult?>();
        
        // WPF ContextMenu uses PlacementTarget - we need to use absolute positioning
        // Create a dummy element at the cursor position
        _contextMenu.Placement = WpfControls.Primitives.PlacementMode.MousePoint;
        
        // Show the menu
        _contextMenu.IsOpen = true;
        
        // Wait for selection (this makes it synchronous like Win32 version)
        var result = _resultSource.Task.Result;
        IsShown = false;
        
        return result;
    }
    
    private void OnMenuClosed(object? sender, RoutedEventArgs e)
    {
        IsShown = false;
        _resultSource?.TrySetResult(null);
    }

    public MenuItemParams? GetItemByUID(string uid)
    {
        return _items.TryGetValue(uid, out var item) ? item : null;
    }

    public void UpdateItem(string uid, MenuItemParams newParams)
    {
        if (_items.ContainsKey(uid))
        {
            _items[uid] = newParams;
            // TODO: Update menu display
        }
    }

    public void Destroy()
    {
        _contextMenu.Items.Clear();
        _items.Clear();
        _menuItemToUid.Clear();
    }
}

/// <summary>
/// Factory for creating WPF popup menus
/// </summary>
public class WpfPopupMenuFactory : IPopupMenuFactory
{
    private readonly IconService _iconService;

    public WpfPopupMenuFactory(IconService iconService)
    {
        _iconService = iconService;
    }

    public IPopupMenu CreateMenu(MenuParams parameters)
    {
        return new WpfPopupMenu(parameters, _iconService);
    }
}
