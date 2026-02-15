using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using System.Windows.Input;
using QuickCliq.Core.Menu;
using QuickCliq.Core.Models;

namespace QC.net.Menu;

/// <summary>
/// WPF-based popup menu with Material Design styling
/// </summary>
public class MaterialDesignPopupMenu : IPopupMenu
{
    private readonly Window _parentWindow;
    private readonly List<MenuItemData> _items = new();
    private MenuParams _params = new();
    private System.Windows.Controls.ContextMenu? _contextMenu;
    private Window? _overlayWindow;
    private bool _isShown;
    
    public MaterialDesignPopupMenu(Window parentWindow)
    {
        _parentWindow = parentWindow;
    }
    
    public void Add(MenuItemParams item)
    {
        _items.Add(new MenuItemData(item));
    }
    
    public void AddSeparator()
    {
        _items.Add(new MenuItemData(null) { IsSeparator = true });
    }
    
    public void AddText(string text)
    {
        _items.Add(new MenuItemData(new MenuItemParams { Name = text, Uid = Guid.NewGuid().ToString(), Disabled = true }));
    }
    
    public MenuItemResult? Show(int x, int y, string mode = "normal")
    {
        var resultWrapper = new MenuResultWrapper();
        
        // Must be called on UI thread
        _parentWindow.Dispatcher.Invoke(() =>
        {
            // Create a transparent full-screen overlay window to capture outside clicks
            _overlayWindow = new Window
            {
                WindowStyle = WindowStyle.None,
                ResizeMode = ResizeMode.NoResize,
                AllowsTransparency = true,
                Background = System.Windows.Media.Brushes.Transparent,
                ShowInTaskbar = false,
                Topmost = true,
                Left = SystemParameters.VirtualScreenLeft,
                Top = SystemParameters.VirtualScreenTop,
                Width = SystemParameters.VirtualScreenWidth,
                Height = SystemParameters.VirtualScreenHeight,
                Focusable = true,
                Content = new Grid() // Add content so the window has a presentation source
            };
            
            _contextMenu = BuildContextMenu();
            _isShown = true;
            
            // Set the overlay's content (Grid) as the placement target
            _contextMenu.PlacementTarget = _overlayWindow.Content as UIElement;
            _contextMenu.Placement = PlacementMode.Relative;
            
            // Calculate position relative to overlay window (which starts at virtual screen origin)
            var relativeX = x - SystemParameters.VirtualScreenLeft;
            var relativeY = y - SystemParameters.VirtualScreenTop;
            _contextMenu.HorizontalOffset = relativeX;
            _contextMenu.VerticalOffset = relativeY;
            
            // Create dispatcher frame for message loop
            var frame = new DispatcherFrame();
            
            // Setup closed handler to exit message loop
            RoutedEventHandler? closedHandler = null;
            closedHandler = (s, e) =>
            {
                _isShown = false;
                if (closedHandler != null)
                    _contextMenu.Closed -= closedHandler;
                frame.Continue = false;
                
                // Close overlay window
                if (_overlayWindow != null)
                {
                    _overlayWindow.Close();
                    _overlayWindow = null;
                }
            };
            _contextMenu.Closed += closedHandler;
            
            // Handle Escape key
            System.Windows.Input.KeyEventHandler? keyHandler = null;
            keyHandler = (s, e) =>
            {
                if (e.Key == System.Windows.Input.Key.Escape)
                {
                    Console.WriteLine("Escape pressed, closing menu");
                    _contextMenu.IsOpen = false;
                }
            };
            _overlayWindow.KeyDown += keyHandler;
            
            // Handle clicks outside the menu - click anywhere on transparent overlay
            System.Windows.Input.MouseButtonEventHandler? mouseHandler = null;
            mouseHandler = (s, e) =>
            {
                // Check if click is on the overlay (not on the context menu)
                var source = e.OriginalSource as DependencyObject;
                if (source != null && !IsDescendantOf(source, _contextMenu))
                {
                    Console.WriteLine("Clicked outside menu, closing");
                    _contextMenu.IsOpen = false;
                }
            };
            _overlayWindow.PreviewMouseDown += mouseHandler;
            
            // Remove handlers when menu closes
            _contextMenu.Closed += (s, e) =>
            {
                if (keyHandler != null && _overlayWindow != null)
                    _overlayWindow.KeyDown -= keyHandler;
                if (mouseHandler != null && _overlayWindow != null)
                    _overlayWindow.PreviewMouseDown -= mouseHandler;
            };
            
            // Wire up menu item click handlers
            WireMenuEvents(_contextMenu, resultWrapper);
            
            // Show overlay window and wait for it to be loaded
            _overlayWindow.Show();
            _overlayWindow.Activate(); // Give it focus so it can receive keyboard input
            
            // Wait for window to be fully rendered before opening menu
            _overlayWindow.Dispatcher.Invoke(() => { }, DispatcherPriority.Loaded);
            
            _contextMenu.IsOpen = true;
            
            // Manual message pump - process messages until menu closes
            Dispatcher.PushFrame(frame);
        });
        
        return resultWrapper.Result;
    }
    
    private bool IsDescendantOf(DependencyObject child, DependencyObject parent)
    {
        var current = child;
        while (current != null)
        {
            if (current == parent)
                return true;
            current = VisualTreeHelper.GetParent(current);
        }
        return false;
    }
    
    private T? FindVisualChild<T>(DependencyObject parent) where T : DependencyObject
    {
        for (int i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        {
            var child = VisualTreeHelper.GetChild(parent, i);
            if (child is T typedChild)
                return typedChild;
            
            var result = FindVisualChild<T>(child);
            if (result != null)
                return result;
        }
        return null;
    }
    
    private void WireMenuEvents(ItemsControl menu, MenuResultWrapper resultWrapper)
    {
        foreach (var item in menu.Items)
        {
            if (item is System.Windows.Controls.MenuItem menuItem && menuItem.Tag is MenuItemData data)
            {
                var localData = data; // Capture for closure
                
                // Debug: Check if this is a submenu
                bool hasSubItems = menuItem.Items.Count > 0;
                Console.WriteLine($"Menu item: '{localData.Params?.Name}' HasSubItems: {hasSubItems} SubItemCount: {menuItem.Items.Count}");
                
                // Only wire click handler if this is NOT a submenu
                if (!hasSubItems)
                {
                    menuItem.Click += (s, e) =>
                    {
                        Console.WriteLine($"Clicked: '{localData.Params?.Name}'");
                        resultWrapper.Result = new MenuItemResult
                        {
                            Uid = localData.Params?.Uid ?? "",
                            Tag = localData.Params?.Tag,
                            AssocMenu = localData.Params?.Submenu, // FIX: use Params.Submenu
                            IsMenu = localData.Params?.Submenu != null
                        };
                        
                        if (_contextMenu != null)
                            _contextMenu.IsOpen = false;
                        
                        e.Handled = true;
                    };
                }
                else
                {
                    Console.WriteLine($"  -> Wiring submenu items for '{localData.Params?.Name}'");
                    // For submenus, wire events for child items
                    WireMenuEvents(menuItem, resultWrapper);
                }
            }
        }
    }
    
    private System.Windows.Controls.ContextMenu BuildContextMenu()
    {
        var menu = new System.Windows.Controls.ContextMenu
        {
            MinWidth = 200,
            StaysOpen = false // Allow clicking outside to close
        };
        
        // Apply font if specified
        if (!string.IsNullOrEmpty(_params.FontName))
        {
            menu.FontFamily = new System.Windows.Media.FontFamily(_params.FontName);
        }
        if (_params.FontSize > 0)
        {
            menu.FontSize = _params.FontSize;
        }
        
        // Apply menu-level colors if specified and NOT the default values
        // 0x000000 = black text (default for Win32, but we want Material Design default for WPF)
        // 0xf1f1f1 = light grey bg (default for Win32, but we want Material Design default for WPF)
        
        // Only apply text color if it's not the default black
        if (_params.TextColor >= 0 && _params.TextColor != 0x000000)
        {
            var r = (_params.TextColor >> 16) & 0xFF;
            var g = (_params.TextColor >> 8) & 0xFF;
            var b = _params.TextColor & 0xFF;
            menu.Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb((byte)r, (byte)g, (byte)b));
        }
        
        // Only apply bg color if it's not the default light grey
        if (_params.BgColor >= 0 && _params.BgColor != 0xf1f1f1)
        {
            var r = (_params.BgColor >> 16) & 0xFF;
            var g = (_params.BgColor >> 8) & 0xFF;
            var b = _params.BgColor & 0xFF;
            menu.Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb((byte)r, (byte)g, (byte)b));
        }
        
        foreach (var itemData in _items)
        {
            if (itemData.IsSeparator)
            {
                menu.Items.Add(new Separator());
            }
            else if (itemData.Params != null)
            {
                var menuItem = CreateMenuItem(itemData);
                menu.Items.Add(menuItem);
            }
        }
        
        return menu;
    }
    
    private System.Windows.Controls.MenuItem CreateMenuItem(MenuItemData data)
    {
        var menuItem = new System.Windows.Controls.MenuItem
        {
            Tag = data,
            IsEnabled = !(data.Params?.Disabled ?? false)
        };
        
        // Header with icon and text
        var stackPanel = new StackPanel
        {
            Orientation = System.Windows.Controls.Orientation.Horizontal,
            Margin = new Thickness(0)
        };
        
        // Icon
        if (!string.IsNullOrEmpty(data.Params?.Icon as string))
        {
            try
            {
                var iconPath = data.Params.Icon as string;
                var image = new System.Windows.Controls.Image
                {
                    Width = _params.IconSize,
                    Height = _params.IconSize,
                    Margin = new Thickness(0, 0, 8, 0),
                    Source = new BitmapImage(new Uri(iconPath, UriKind.Absolute))
                };
                stackPanel.Children.Add(image);
            }
            catch
            {
                // Icon loading failed, skip it
            }
        }
        
        // Text
        var textBlock = new TextBlock
        {
            Text = data.Params?.Name ?? "",
            VerticalAlignment = VerticalAlignment.Center,
            FontWeight = (data.Params?.Bold ?? false) ? FontWeights.Bold : FontWeights.Normal
        };
        
        // Apply custom text color if specified (null means use default, 0 is black which is valid)
        if (data.Params?.TColor.HasValue == true)
        {
            int color = data.Params.TColor.Value;
            byte r = (byte)((color >> 16) & 0xFF);
            byte g = (byte)((color >> 8) & 0xFF);
            byte b = (byte)(color & 0xFF);
            textBlock.Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(r, g, b));
        }
        
        stackPanel.Children.Add(textBlock);
        menuItem.Header = stackPanel;
        
        // Apply custom background color if specified (null means use default, 0 is black which is valid)
        if (data.Params?.BgColor.HasValue == true)
        {
            int color = data.Params.BgColor.Value;
            byte r = (byte)((color >> 16) & 0xFF);
            byte g = (byte)((color >> 8) & 0xFF);
            byte b = (byte)(color & 0xFF);
            menuItem.Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(r, g, b));
        }
        
        // Handle submenu - FIX: check data.Params.Submenu, not data.Submenu
        var submenu = data.Params?.Submenu;
        Console.WriteLine($"CreateMenuItem: '{data.Params?.Name}' Submenu={submenu != null} Type={submenu?.GetType().Name}");
        if (submenu != null)
        {
            Console.WriteLine($"  Submenu type check: is MaterialDesignPopupMenu? {submenu is MaterialDesignPopupMenu}");
            if (submenu is MaterialDesignPopupMenu wpfSubmenu)
            {
                Console.WriteLine($"  Submenu has {wpfSubmenu._items.Count} items");
                Console.WriteLine($"  Submenu params: TextColor={wpfSubmenu._params.TextColor:X6}, BgColor={wpfSubmenu._params.BgColor:X6}");
                
                // Create a style object to hold submenu colors
                var submenuStyle = new SubmenuStyle { OriginalData = data };
                
                // Apply submenu's background/foreground colors to the MenuItem's submenu popup
                // Don't apply if they're the default values (let Material Design theme apply)
                if (wpfSubmenu._params.BgColor >= 0 && wpfSubmenu._params.BgColor != 0xf1f1f1)
                {
                    var bgColor = wpfSubmenu._params.BgColor;
                    var r = (byte)((bgColor >> 16) & 0xFF);
                    var g = (byte)((bgColor >> 8) & 0xFF);
                    var b = (byte)(bgColor & 0xFF);
                    submenuStyle.BgBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(r, g, b));
                }
                
                if (wpfSubmenu._params.TextColor >= 0 && wpfSubmenu._params.TextColor != 0x000000)
                {
                    var fgColor = wpfSubmenu._params.TextColor;
                    var r = (byte)((fgColor >> 16) & 0xFF);
                    var g = (byte)((fgColor >> 8) & 0xFF);
                    var b = (byte)(fgColor & 0xFF);
                    submenuStyle.FgBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(r, g, b));
                }
                
                // Store the style object in the MenuItem's Tag
                menuItem.Tag = submenuStyle;
                
                // Hook into the submenu opened event to apply colors to the popup
                if (submenuStyle.BgBrush != null || submenuStyle.FgBrush != null)
                {
                    menuItem.SubmenuOpened += (s, e) =>
                    {
                        // Find the Popup that contains the submenu and apply background
                        var popup = FindVisualChild<System.Windows.Controls.Primitives.Popup>(menuItem);
                        if (popup?.Child is System.Windows.Controls.Border border && submenuStyle.BgBrush != null)
                        {
                            border.Background = submenuStyle.BgBrush;
                            border.BorderBrush = submenuStyle.BgBrush; // Also set border to match background
                        }
                    };
                }
                
                foreach (var subItemData in wpfSubmenu._items)
                {
                    if (subItemData.IsSeparator)
                    {
                        menuItem.Items.Add(new Separator());
                        Console.WriteLine($"    Added separator");
                    }
                    else if (subItemData.Params != null)
                    {
                        var subMenuItem = CreateMenuItem(subItemData);
                        
                        // Apply submenu colors to child items if they don't have their own colors
                        if (submenuStyle.BgBrush != null && subItemData.Params.BgColor == null)
                        {
                            subMenuItem.Background = submenuStyle.BgBrush;
                        }
                        if (submenuStyle.FgBrush != null && subItemData.Params.TColor == null)
                        {
                            // Need to set foreground on the TextBlock inside the header
                            if (subMenuItem.Header is StackPanel sp && sp.Children.Count > 0)
                            {
                                foreach (var child in sp.Children)
                                {
                                    if (child is TextBlock tb)
                                        tb.Foreground = submenuStyle.FgBrush;
                                }
                            }
                        }
                        
                        menuItem.Items.Add(subMenuItem);
                        Console.WriteLine($"    Added submenu item: {subItemData.Params.Name}");
                    }
                }
                
                // Restore the original Tag (MenuItemData)
                menuItem.Tag = submenuStyle.OriginalData;
            }
        }
        
        return menuItem;
    }
    
    public void Destroy()
    {
        _items.Clear();
        _contextMenu = null;
        _isShown = false;
    }
    
    public MenuItemParams? GetItemByUID(string uid)
    {
        return FindItemByUID(_items, uid);
    }
    
    private MenuItemParams? FindItemByUID(List<MenuItemData> items, string uid)
    {
        foreach (var item in items)
        {
            if (item.Params?.Uid == uid)
                return item.Params;
            
            if (item.Params?.Submenu is MaterialDesignPopupMenu wpfSubmenu)
            {
                var found = FindItemByUID(wpfSubmenu._items, uid);
                if (found != null)
                    return found;
            }
        }
        return null;
    }
    
    public void UpdateItem(string uid, MenuItemParams newParams)
    {
        // Find and update item
        for (int i = 0; i < _items.Count; i++)
        {
            if (_items[i].Params?.Uid == uid)
            {
                _items[i] = new MenuItemData(newParams);
                return;
            }
            
            if (_items[i].Params?.Submenu is MaterialDesignPopupMenu wpfSubmenu)
            {
                wpfSubmenu.UpdateItem(uid, newParams);
            }
        }
    }
    
    public IntPtr Handle => IntPtr.Zero; // WPF menus don't have native handles
    
    public bool IsShown => _isShown;
    
    private class MenuItemData
    {
        public MenuItemParams? Params { get; }
        public bool IsSeparator { get; set; }
        
        public MenuItemData(MenuItemParams? parameters)
        {
            Params = parameters;
        }
    }
    
    private class SubmenuStyle
    {
        public SolidColorBrush? BgBrush { get; set; }
        public SolidColorBrush? FgBrush { get; set; }
        public MenuItemData? OriginalData { get; set; }
    }
    
    private class MenuResultWrapper
    {
        public MenuItemResult? Result { get; set; }
    }
}
