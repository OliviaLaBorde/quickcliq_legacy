namespace QuickCliq.Core.Menu;

/// <summary>
/// Custom popup menu interface
/// Based on legacy PUM (Popup Menu)
/// </summary>
public interface IPopupMenu
{
    /// <summary>
    /// Add menu item
    /// </summary>
    void Add(MenuItemParams item);
    
    /// <summary>
    /// Add separator
    /// </summary>
    void AddSeparator();
    
    /// <summary>
    /// Add disabled text-only item
    /// </summary>
    void AddText(string text);
    
    /// <summary>
    /// Show menu at coordinates and wait for selection
    /// </summary>
    MenuItemResult? Show(int x, int y, string mode = "normal");
    
    /// <summary>
    /// Destroy menu and free resources
    /// </summary>
    void Destroy();
    
    /// <summary>
    /// Get item by UID
    /// </summary>
    MenuItemParams? GetItemByUID(string uid);
    
    /// <summary>
    /// Update item parameters
    /// </summary>
    void UpdateItem(string uid, MenuItemParams newParams);
    
    /// <summary>
    /// Menu handle (for native operations)
    /// </summary>
    IntPtr Handle { get; }
    
    /// <summary>
    /// Is menu currently shown
    /// </summary>
    bool IsShown { get; }
}

/// <summary>
/// Menu appearance parameters
/// Based on legacy PUM menuParams
/// </summary>
public record MenuParams
{
    public int IconSize { get; init; } = 16;
    public int TextColor { get; init; } = 0x000000;
    public int BgColor { get; init; } = 0xf1f1f1;
    public int TextOffset { get; init; } = 8;
    public bool NoIcons { get; init; }
    public bool NoColors { get; init; }
    public bool NoText { get; init; }
    public int YMargin { get; init; } = 3;
    public string? FontName { get; init; }
    public int FontSize { get; init; } = 10;
    public int FontQuality { get; init; } = 5;
    public int FrameWidth { get; init; } = 1;
    public bool FrameSelMode { get; init; }
}

/// <summary>
/// Menu item parameters
/// </summary>
public record MenuItemParams
{
    public required string Name { get; init; }
    public required string Uid { get; init; }
    public string? Icon { get; init; }
    public IntPtr IconHandle { get; init; }
    public bool IconUseHandle { get; init; }
    public bool Bold { get; init; }
    public int? TColor { get; init; }
    public int? BgColor { get; init; }
    public bool Disabled { get; init; }
    public bool Break { get; init; }  // Column break
    public IPopupMenu? Submenu { get; init; }
    public object? Tag { get; init; }  // Custom data (e.g., FM_Target, WinsTopmost)
}

/// <summary>
/// Result from menu selection
/// </summary>
public record MenuItemResult
{
    public required string Uid { get; init; }
    public object? Tag { get; init; }
    public IPopupMenu? AssocMenu { get; init; }
    public bool IsMenu { get; init; }
    public string? Name { get; init; }
    public string? Icon { get; init; }
}

/// <summary>
/// Factory for creating popup menus
/// </summary>
public interface IPopupMenuFactory
{
    IPopupMenu CreateMenu(MenuParams parameters);
}
