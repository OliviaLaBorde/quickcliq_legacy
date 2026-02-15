using System.Xml.Linq;
using QuickCliq.Core.Models;

namespace QuickCliq.Core.Config;

/// <summary>
/// Migrates legacy XML config (v2.x) to JSON format (v3.x)
/// </summary>
public class ConfigMigrator
{
    /// <summary>
    /// Detect which config format exists and load appropriately
    /// </summary>
    public static IConfigService LoadConfig()
    {
        var jsonPath = AppConstants.ConfigPath;
        var xmlPath = AppConstants.LegacyConfigPath;

        // Prefer JSON if it exists
        if (File.Exists(jsonPath))
        {
            var service = new JsonConfigService(jsonPath);
            MigrateColors(service);
            return service;
        }

        // Migrate from XML if found
        if (File.Exists(xmlPath))
        {
            var config = MigrateFromXml(xmlPath);
            var jsonService = new JsonConfigService(jsonPath);
            // TODO: Copy migrated data to jsonService
            jsonService.Save();
            
            // Backup old XML
            File.Copy(xmlPath, $"{xmlPath}.migrated.{DateTime.Now:yyyyMMdd}", true);
            
            MigrateColors(jsonService);
            return jsonService;
        }

        // No config found, create new JSON
        return new JsonConfigService(jsonPath);
    }
    
    /// <summary>
    /// Migrate colors from 0 (old "default") to -1 (new "default")
    /// This allows 0 to mean black
    /// </summary>
    private static void MigrateColors(IConfigService service)
    {
        bool changed = false;
        var menu = service.GetMenu();
        
        if (menu != null)
        {
            // Migrate menu-level colors
            if (menu.TextColor == 0)
            {
                menu.TextColor = -1;
                changed = true;
            }
            if (menu.BgColor == 0)
            {
                menu.BgColor = -1;
                changed = true;
            }
            
            // Migrate item colors
            foreach (var item in menu.Items)
            {
                if (MigrateItemColors(item))
                    changed = true;
            }
            
            if (changed)
            {
                service.SetMenu(menu);
                service.Save();
            }
        }
    }
    
    private static bool MigrateItemColors(MenuItem item)
    {
        bool changed = false;
        
        if (item.TextColor == 0)
        {
            item.TextColor = -1;
            changed = true;
        }
        if (item.BgColor == 0)
        {
            item.BgColor = -1;
            changed = true;
        }
        
        // Recursively migrate children
        if (item.Children != null)
        {
            foreach (var child in item.Children)
            {
                if (MigrateItemColors(child))
                    changed = true;
            }
        }
        
        return changed;
    }

    /// <summary>
    /// Migrate XML config to JSON model
    /// </summary>
    public static QuickCliqConfig MigrateFromXml(string xmlPath)
    {
        var xdoc = XDocument.Load(xmlPath);
        var root = xdoc.Root;

        if (root == null || root.Name != "qc_")
            throw new InvalidOperationException("Invalid XML config format");

        var config = new QuickCliqConfig
        {
            Version = AppConstants.Version,
            LastId = int.Parse(root.Element("lastID")?.Value ?? "0")
        };

        // Migrate menu
        var menuNode = root.Element("menu");
        if (menuNode != null)
        {
            config.Menu = MigrateMenuNode(menuNode);
        }

        // Migrate settings
        var settingsNode = root.Element("settings");
        if (settingsNode != null)
        {
            foreach (var opt in settingsNode.Elements("opt"))
            {
                var name = opt.Attribute("name")?.Value;
                var value = opt.Attribute("value")?.Value;
                
                if (!string.IsNullOrEmpty(name))
                {
                    // Check for multi-value options
                    var values = opt.Elements("value").Select(v => v.Value).ToList();
                    if (values.Count > 0)
                        config.Settings[name] = values;
                    else if (value != null)
                        config.Settings[name] = value;
                }
            }
        }

        // Migrate hidden windows
        var winsNode = root.Element("wins");
        if (winsNode != null)
        {
            foreach (var win in winsNode.Elements("win"))
            {
                if (win.Attribute("type")?.Value == "hidden")
                {
                    config.HiddenWindows.Add(new HiddenWindow
                    {
                        Hwnd = int.Parse(win.Attribute("hwnd")?.Value ?? "0"),
                        IsTopmost = bool.Parse(win.Attribute("istopmost")?.Value ?? "false")
                    });
                }
            }
        }

        return config;
    }

    private static MenuConfig MigrateMenuNode(XElement menuNode)
    {
        var menu = new MenuConfig
        {
            Id = int.Parse(menuNode.Attribute("ID")?.Value ?? "0"),
            Name = menuNode.Attribute("name")?.Value ?? "main",
            TextColor = int.Parse(menuNode.Attribute("mtcolor")?.Value ?? "0"),
            BgColor = int.Parse(menuNode.Attribute("mbgcolor")?.Value ?? "0")
        };

        foreach (var itemNode in menuNode.Elements("item"))
        {
            menu.Items.Add(MigrateItemNode(itemNode));
        }

        return menu;
    }

    private static MenuItem MigrateItemNode(XElement itemNode)
    {
        var item = new MenuItem
        {
            Id = int.Parse(itemNode.Attribute("ID")?.Value ?? "0"),
            Name = itemNode.Attribute("name")?.Value ?? "",
            Icon = itemNode.Attribute("icon")?.Value ?? "",
            Hotkey = itemNode.Attribute("hotkey")?.Value ?? "",
            Bold = bool.Parse(itemNode.Attribute("bold")?.Value ?? "false"),
            IsSeparator = bool.Parse(itemNode.Attribute("issep")?.Value ?? "false"),
            Autorun = bool.Parse(itemNode.Attribute("autorun")?.Value ?? "false"),
            TextColor = int.Parse(itemNode.Attribute("tcolor")?.Value ?? "0"),
            BgColor = int.Parse(itemNode.Attribute("bgcolor")?.Value ?? "0")
        };

        // Commands
        foreach (var cmdNode in itemNode.Elements("command"))
        {
            var cmd = cmdNode.Value;
            if (!string.IsNullOrWhiteSpace(cmd))
                item.Commands.Add(cmd);
        }

        // Submenu (nested menu or items)
        var subMenuNode = itemNode.Element("menu");
        if (subMenuNode != null)
        {
            foreach (var subItem in subMenuNode.Elements("item"))
            {
                item.Children.Add(MigrateItemNode(subItem));
            }
        }

        return item;
    }
}
