using System.Text.Json;
using System.Xml.Linq;
using QuickCliq.Core.Models;

namespace QuickCliq.Core.Config;

/// <summary>
/// JSON-based configuration service (v3.x format)
/// Primary implementation for .NET rewrite
/// </summary>
public class JsonConfigService : IConfigService
{
    private QuickCliqConfig _config;
    private readonly string _configPath;
    private readonly JsonSerializerOptions _jsonOptions;

    public string ConfigPath => _configPath;

    public JsonConfigService(string? configPath = null)
    {
        _configPath = configPath ?? AppConstants.ConfigPath;
        _jsonOptions = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };
        
        _config = LoadOrCreate();
        
        // Sync menu font to aprns_mainfont setting if menu font is set
        if (!string.IsNullOrEmpty(_config.Menu.Font))
        {
            _config.Settings["aprns_mainfont"] = _config.Menu.Font;
        }
        // Otherwise, sync from aprns_mainfont to menu font
        else if (_config.Settings.TryGetValue("aprns_mainfont", out var fontValue) && fontValue is string fontStr)
        {
            _config.Menu.Font = fontStr;
        }
        
        // Sync font size - no default in settings, use 10 if not set
        if (_config.Menu.FontSize.HasValue)
        {
            _config.Settings["aprns_fontsize"] = _config.Menu.FontSize.Value;
        }
        else if (_config.Settings.TryGetValue("aprns_fontsize", out var sizeValue))
        {
            if (sizeValue is int fontSize)
                _config.Menu.FontSize = fontSize;
            else if (int.TryParse(sizeValue?.ToString(), out int parsedSize))
                _config.Menu.FontSize = parsedSize;
        }
    }

    private QuickCliqConfig LoadOrCreate()
    {
        if (!File.Exists(_configPath))
        {
            EnsureDataDirectories();
            return CreateDefaultConfig();
        }

        try
        {
            var json = File.ReadAllText(_configPath);
            return JsonSerializer.Deserialize<QuickCliqConfig>(json, _jsonOptions) 
                   ?? CreateDefaultConfig();
        }
        catch
        {
            // On error, backup bad file and create new
            if (File.Exists(_configPath))
                File.Copy(_configPath, $"{_configPath}.corrupt.{DateTime.Now:yyyyMMddHHmmss}", true);
            return CreateDefaultConfig();
        }
    }

    private QuickCliqConfig CreateDefaultConfig()
    {
        return new QuickCliqConfig
        {
            Version = AppConstants.Version,
            LastId = 0,
            Menu = new MenuConfig
            {
                Id = 0,
                Name = "main",
                Items = new List<MenuItem>()
            },
            Settings = new Dictionary<string, object>(),
            HiddenWindows = new List<HiddenWindow>()
        };
    }

    public void Save()
    {
        // Sync menu font to aprns_mainfont setting before saving
        if (!string.IsNullOrEmpty(_config.Menu.Font))
        {
            _config.Settings["aprns_mainfont"] = _config.Menu.Font;
        }
        
        // Sync menu font size to aprns_fontsize setting before saving
        if (_config.Menu.FontSize.HasValue)
        {
            _config.Settings["aprns_fontsize"] = _config.Menu.FontSize.Value;
        }
        
        var json = JsonSerializer.Serialize(_config, _jsonOptions);
        File.WriteAllText(_configPath, json);
    }

    public void Backup()
    {
        if (!File.Exists(_configPath)) return;
        
        var bakPath = $"{_configPath}.bak";
        var bak2Path = $"{_configPath}.bak2";
        
        if (File.Exists(bakPath))
            File.Copy(bakPath, bak2Path, true);
        
        File.Copy(_configPath, bakPath, true);
    }

    public void EnsureDataDirectories()
    {
        Directory.CreateDirectory(AppConstants.DataPath);
        Directory.CreateDirectory(AppConstants.MemosDir);
        Directory.CreateDirectory(AppConstants.ClipsDir);
        Directory.CreateDirectory(AppConstants.UserIconsPath);
    }

    public bool FileExists() => File.Exists(_configPath);

    // Menu operations
    public XElement GetMenuNode() => throw new NotSupportedException("Use GetMenu() for JSON config");
    public XElement GetSettingsNode() => throw new NotSupportedException("Use Settings property for JSON config");
    public XElement GetWinsNode() => throw new NotSupportedException("Use HiddenWindows property for JSON config");

    public MenuConfig GetMenu() => _config.Menu;
    public void SetMenu(MenuConfig menu) => _config.Menu = menu;
    public Dictionary<string, object> GetSettings() => _config.Settings;
    public List<HiddenWindow> GetHiddenWindows() => _config.HiddenWindows;

    public int NextId() => ++_config.LastId;

    public XElement? GetNodeById(int id) => throw new NotSupportedException("XElement not used in JSON config");
    public XElement? ItemResolve(object item) => throw new NotSupportedException("XElement not used in JSON config");

    public MenuItem? GetItemById(int id)
    {
        return FindItemRecursive(_config.Menu.Items, id);
    }

    private MenuItem? FindItemRecursive(List<MenuItem> items, int id)
    {
        foreach (var item in items)
        {
            if (item.Id == id) return item;
            if (item.Children.Count > 0)
            {
                var found = FindItemRecursive(item.Children, id);
                if (found != null) return found;
            }
        }
        return null;
    }

    public bool IsMenu(XElement node) => throw new NotSupportedException("Use MenuItem.IsMenu for JSON config");
    public bool IsMenu(MenuItem item) => item.IsMenu;

    public bool IsSeparator(XElement node) => throw new NotSupportedException("Use MenuItem.IsSeparator for JSON config");
    public bool IsSeparator(MenuItem item) => item.IsSeparator;

    public int GetItemsCount(XElement menu) => throw new NotSupportedException("Use MenuItem.Children.Count for JSON config");
    public int GetItemsCount(MenuItem parent) => parent.Children.Count;

    public IEnumerable<XElement> GetMenuItems(XElement menu) => throw new NotSupportedException("Use MenuItem.Children for JSON config");
    public IEnumerable<MenuItem> GetMenuItems(MenuItem parent) => parent.Children;

    public string GetItemPath(XElement item) => throw new NotSupportedException("Use GetItemPath(MenuItem) for JSON config");
    public string GetItemPath(MenuItem item)
    {
        var path = new List<string>();
        // TODO: Implement path building by traversing up the tree
        return "/" + string.Join("/", path);
    }

    public string GetItemCmdByID(int id)
    {
        var item = GetItemById(id);
        return item?.GetCommandString() ?? string.Empty;
    }

    public string GetItemCmdString(XElement item) => throw new NotSupportedException("Use GetItemCmdString(MenuItem) for JSON config");
    public string GetItemCmdString(MenuItem item) => item.GetCommandString();

    public void ItemSetCmd(int itemId, string commands)
    {
        var item = GetItemById(itemId);
        if (item != null)
            item.SetCommandString(commands);
    }

    public void ItemSetAttr(int itemId, string attrName, string value)
    {
        var item = GetItemById(itemId);
        if (item == null) return;

        switch (attrName.ToLowerInvariant())
        {
            case "name": item.Name = value; break;
            case "icon": item.Icon = value; break;
            case "hotkey": item.Hotkey = value; break;
            case "bold": item.Bold = bool.Parse(value); break;
            case "isseparator": item.IsSeparator = bool.Parse(value); break;
            case "autorun": item.Autorun = bool.Parse(value); break;
            case "textcolor": item.TextColor = int.Parse(value); break;
            case "bgcolor": item.BgColor = int.Parse(value); break;
        }
    }

    public string? ItemGetAttr(int itemId, string attrName)
    {
        var item = GetItemById(itemId);
        if (item == null) return null;

        return attrName.ToLowerInvariant() switch
        {
            "name" => item.Name,
            "icon" => item.Icon,
            "hotkey" => item.Hotkey,
            "bold" => item.Bold.ToString(),
            "isseparator" => item.IsSeparator.ToString(),
            "autorun" => item.Autorun.ToString(),
            "textcolor" => item.TextColor.ToString(),
            "bgcolor" => item.BgColor.ToString(),
            _ => null
        };
    }

    public void ItemDel(int itemId)
    {
        RemoveItemRecursive(_config.Menu.Items, itemId);
    }

    private bool RemoveItemRecursive(List<MenuItem> items, int id)
    {
        var item = items.FirstOrDefault(i => i.Id == id);
        if (item != null)
        {
            items.Remove(item);
            return true;
        }

        foreach (var parent in items.Where(i => i.Children.Count > 0))
        {
            if (RemoveItemRecursive(parent.Children, id))
                return true;
        }

        return false;
    }

    public XElement CreateItemNode(XElement parent, XElement? before = null) => 
        throw new NotSupportedException("Use CreateItem() for JSON config");

    public MenuItem CreateItem(MenuItem? parent = null, MenuItem? before = null)
    {
        var newItem = new MenuItem
        {
            Id = NextId(),
            Name = "New Item"
        };

        parent ??= new MenuItem { Children = _config.Menu.Items };
        
        if (before != null)
        {
            var index = parent.Children.IndexOf(before);
            if (index >= 0)
                parent.Children.Insert(index, newItem);
            else
                parent.Children.Add(newItem);
        }
        else
        {
            parent.Children.Add(newItem);
        }

        return newItem;
    }

    // Options
    public void SetOpt(string name, object value)
    {
        _config.Settings[name.ToLowerInvariant()] = value;
    }

    public (object? Value, bool Exists) GetOpt(string name)
    {
        name = name.ToLowerInvariant();
        if (_config.Settings.TryGetValue(name, out var value))
            return (value, true);
        return (null, false);
    }

    public void DelOpt(string name)
    {
        _config.Settings.Remove(name.ToLowerInvariant());
    }

    public void LoadFrom(string path)
    {
        var json = File.ReadAllText(path);
        _config = JsonSerializer.Deserialize<QuickCliqConfig>(json, _jsonOptions) 
                  ?? CreateDefaultConfig();
    }
}
