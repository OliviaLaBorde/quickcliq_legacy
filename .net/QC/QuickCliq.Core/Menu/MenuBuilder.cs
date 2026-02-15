using QuickCliq.Core.Config;
using QuickCliq.Core.Models;

namespace QuickCliq.Core.Menu;

/// <summary>
/// Menu builder interface
/// Builds popup menus from configuration
/// </summary>
public interface IMenuBuilder
{
    /// <summary>
    /// Build main menu from config
    /// </summary>
    IPopupMenu BuildMainMenu();
    
    /// <summary>
    /// Rebuild specific menu node
    /// </summary>
    IPopupMenu BuildMenu(MenuItem menuNode, MenuParams? baseParams = null);
    
    /// <summary>
    /// Rebuild all menus (called after config change)
    /// </summary>
    void RebuildAll();
    
    /// <summary>
    /// Get the main menu (cached)
    /// </summary>
    IPopupMenu GetMainMenu();
}

/// <summary>
/// Menu builder implementation
/// Based on legacy MenuBuilding.ahk
/// </summary>
public class MenuBuilder : IMenuBuilder
{
    private readonly IConfigService _config;
    private readonly IOptionsService _options;
    private readonly IPopupMenuFactory _menuFactory;
    private IPopupMenu? _mainMenu;

    public MenuBuilder(
        IConfigService config,
        IOptionsService options,
        IPopupMenuFactory menuFactory)
    {
        _config = config;
        _options = options;
        _menuFactory = menuFactory;
    }

    public IPopupMenu BuildMainMenu()
    {
        var menu = _config.GetMenu();
        var menuParams = CreateMenuParams(menu.TextColor, menu.BgColor);
        
        var popupMenu = _menuFactory.CreateMenu(menuParams);
        
        // Build items recursively
        foreach (var item in menu.Items)
        {
            AddItemToMenu(popupMenu, item, menuParams);
        }
        
        // Add separator before extras
        if (_options.Get<bool>("clips_sub") || 
            _options.Get<bool>("wins_sub") || 
            _options.Get<bool>("memos_sub") || 
            _options.Get<bool>("recent_sub"))
        {
            popupMenu.AddSeparator();
        }
        
        // Add extras (Clips, Wins, Memos, Recent)
        AddExtras(popupMenu, menuParams);
        
        // Add system items
        AddSystemItems(popupMenu);
        
        _mainMenu = popupMenu;
        return popupMenu;
    }

    public IPopupMenu BuildMenu(MenuItem menuNode, MenuParams? baseParams = null)
    {
        // If submenu has default colors (-1), inherit from parent (baseParams)
        // Otherwise, create new params from submenu's colors
        MenuParams menuParams;
        
        Console.WriteLine($"BuildMenu for '{menuNode.Name}': TextColor={menuNode.TextColor}, BgColor={menuNode.BgColor}");
        Console.WriteLine($"  baseParams: {(baseParams != null ? $"TextColor={baseParams.TextColor:X6}, BgColor={baseParams.BgColor:X6}" : "null")}");
        
        if (baseParams != null && menuNode.TextColor < 0 && menuNode.BgColor < 0)
        {
            // Both colors are default (-1), inherit parent's params entirely
            Console.WriteLine($"  -> Inheriting all colors from parent");
            menuParams = baseParams;
        }
        else if (baseParams != null && (menuNode.TextColor < 0 || menuNode.BgColor < 0))
        {
            // Partial override: some colors are default, inherit those from parent
            var textColor = menuNode.TextColor >= 0 ? menuNode.TextColor : baseParams.TextColor;
            var bgColor = menuNode.BgColor >= 0 ? menuNode.BgColor : baseParams.BgColor;
            Console.WriteLine($"  -> Partial inherit: TextColor={textColor:X6}, BgColor={bgColor:X6}");
            menuParams = CreateMenuParams(textColor, bgColor);
        }
        else
        {
            // Create new params from submenu's own colors (or defaults if no parent)
            Console.WriteLine($"  -> Using submenu's own colors (or defaults)");
            menuParams = CreateMenuParams(menuNode.TextColor, menuNode.BgColor);
        }
        
        var popupMenu = _menuFactory.CreateMenu(menuParams);
        
        foreach (var item in menuNode.Children)
        {
            AddItemToMenu(popupMenu, item, menuParams);
        }
        
        return popupMenu;
    }

    private void AddItemToMenu(IPopupMenu menu, MenuItem item, MenuParams baseParams)
    {
        if (item.IsSeparator)
        {
            menu.AddSeparator();
            return;
        }

        // Check for Folder Menu (name ends with *)
        if (item.Name.EndsWith('*') && !item.IsMenu)
        {
            // TODO: Create FolderMenu submenu
            var folderPath = item.Name.TrimEnd('*');
            // For now, add as regular item
            menu.Add(new MenuItemParams
            {
                Name = item.Name,
                Uid = $"FolderMenu_{item.Id}",
                Icon = item.Icon,
                Bold = item.Bold,
                TColor = item.TextColor >= 0 ? item.TextColor : null,
                BgColor = item.BgColor >= 0 ? item.BgColor : null
            });
            return;
        }

        // Submenu
        IPopupMenu? submenu = null;
        if (item.IsMenu)
        {
            submenu = BuildMenu(item, baseParams);
        }

        menu.Add(new MenuItemParams
        {
            Name = item.Name,
            Uid = item.Id.ToString(),
            Tag = item, // Store the MenuItem for execution
            Icon = item.Icon,
            Bold = item.Bold,
            TColor = item.TextColor >= 0 ? item.TextColor : null,
            BgColor = item.BgColor >= 0 ? item.BgColor : null,
            Submenu = submenu
        });
    }

    private void AddExtras(IPopupMenu menu, MenuParams baseParams)
    {
        // TODO: Add Clips submenu
        if (_options.Get<bool>("clips_on") && _options.Get<bool>("clips_sub"))
        {
            // ClipsAddMenu(menu);
        }
        
        // TODO: Add Wins submenu
        if (_options.Get<bool>("wins_on") && _options.Get<bool>("wins_sub"))
        {
            // WinsAddMenu(menu);
        }
        
        // TODO: Add Memos submenu
        if (_options.Get<bool>("memos_on") && _options.Get<bool>("memos_sub"))
        {
            // MemosAddMenu(menu);
        }
        
        // TODO: Add Recent submenu
        if (_options.Get<bool>("recent_on") && _options.Get<bool>("recent_sub"))
        {
            // RecentAddMenu(menu);
        }
    }

    private void AddSystemItems(IPopupMenu menu)
    {
        menu.AddSeparator();
        
        // Open Editor
        if (_options.Get<bool>("gen_editoritem"))
        {
            // Create a special MenuItem with the EDITOR command
            var editorItem = new MenuItem
            {
                Id = -1, // Special system item
                Name = "⚙️ Open Editor",
                Bold = true,
                Commands = new List<string> { "EDITOR" }
            };
            
            menu.Add(new MenuItemParams
            {
                Name = editorItem.Name,
                Uid = "QCEditor",
                Tag = editorItem, // Include the MenuItem so it can be executed
                Bold = true,
                //TColor = 255 // Red text
            });
        }
        
        // Suspend menu
        if (_options.Get<bool>("gen_suspendsub"))
        {
            menu.Add(new MenuItemParams
            {
                Name = "Hotkeys: Turn OFF",
                Uid = "HK_Susp",
                Icon = AppConstants.IconsPath + ":9" // icoSuspOff
            });
            
            menu.Add(new MenuItemParams
            {
                Name = "Gestures: Turn OFF",
                Uid = "GS_Susp",
                Icon = AppConstants.IconsPath + ":9" // icoSuspOff
            });
        }
        
        // Help
        if (_options.Get<bool>("gen_helpsub"))
        {
            menu.Add(new MenuItemParams
            {
                Name = "Help",
                Uid = "QuickHelp",
                Icon = AppConstants.IconsPath + ":5" // icoHelpMe
            });
        }
    }

    public void RebuildAll()
    {
        _mainMenu?.Destroy();
        _mainMenu = null;
        
        // Clear all static menu item mappings
        BasicPopupMenu.ClearAllMenuItems();
        
        // Force rebuild on next call
    }

    public IPopupMenu GetMainMenu()
    {
        return _mainMenu ?? BuildMainMenu();
    }

    private MenuParams CreateMenuParams(int textColor, int bgColor)
    {
        return new MenuParams
        {
            IconSize = _options.Get<int>("aprns_iconssize"),
            TextColor = textColor >= 0 ? textColor : 0x000000,  // -1 means use default
            BgColor = bgColor >= 0 ? bgColor : 0xf1f1f1,         // -1 means use default
            TextOffset = AppConstants.MenuIconsOffset,
            NoIcons = _options.Get<bool>("aprns_lightmenu"),
            NoColors = _options.Get<bool>("aprns_lightmenu"),
            NoText = _options.Get<bool>("aprns_iconsonly") && !_options.Get<bool>("aprns_lightmenu"),
            YMargin = 3 + _options.Get<int>("aprns_heightadjust"),
            FontName = _options.Get<string>("aprns_mainfont"),
            FontSize = _options.Get<int>("aprns_fontsize"),
            FontQuality = _options.Get<int>("aprns_fontqlty"),
            FrameWidth = _options.Get<int>("aprns_framewidth"),
            FrameSelMode = _options.Get<bool>("aprns_frameselmode")
        };
    }
}
