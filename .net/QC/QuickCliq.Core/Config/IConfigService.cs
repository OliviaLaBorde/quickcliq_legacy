using System.Xml.Linq;
using QuickCliq.Core.Models;

namespace QuickCliq.Core.Config;

/// <summary>
/// Service for loading, saving, and manipulating qc_conf.xml
/// Compatible with legacy AHK format
/// </summary>
public interface IConfigService
{
    string ConfigPath { get; }
    
    // Document nodes (for XElement-based implementations)
    XElement GetMenuNode();
    XElement GetSettingsNode();
    XElement GetWinsNode();
    
    // Typed access (for JSON-based implementations)
    MenuConfig GetMenu();
    void SetMenu(MenuConfig menu);
    Dictionary<string, object> GetSettings();
    List<HiddenWindow> GetHiddenWindows();
    
    // ID management
    int NextId();
    XElement? GetNodeById(int id);
    XElement? ItemResolve(object item); // int or XElement
    
    // Item queries
    bool IsMenu(XElement node);
    bool IsSeparator(XElement node);
    int GetItemsCount(XElement menu);
    IEnumerable<XElement> GetMenuItems(XElement menu);
    string GetItemPath(XElement item);
    
    // Command management
    string GetItemCmdByID(int id);
    string GetItemCmdString(XElement item);
    void ItemSetCmd(int itemId, string commands);
    
    // Attribute management
    void ItemSetAttr(int itemId, string attrName, string value);
    string? ItemGetAttr(int itemId, string attrName);
    void ItemDel(int itemId);
    
    // Item creation
    XElement CreateItemNode(XElement parent, XElement? before = null);
    
    // Options management
    void SetOpt(string name, object value); // value: string or string[]
    (object? Value, bool Exists) GetOpt(string name);
    void DelOpt(string name);
    
    // Persistence
    void Save();
    void Backup();
    void LoadFrom(string path); // For S-Menu
    
    // Initialization
    void EnsureDataDirectories();
    bool FileExists();
}
