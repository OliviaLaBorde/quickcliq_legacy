# Configuration System

## Overview

Quick Cliq v3.x uses **JSON** for configuration, with automatic migration from legacy **XML** format (v2.x).

## Config Files

### Primary (v3.x)
- **`Data/qc_config.json`** — New JSON format
  ```json
  {
    "version": "3.0.0",
    "lastId": 123,
    "menu": {
      "id": 0,
      "name": "main",
      "textColor": 0,
      "bgColor": 0,
      "items": [...]
    },
    "settings": {
      "gen_trayicon": true,
      "main_hotkey": "#Z"
    },
    "hiddenWindows": []
  }
  ```

### Legacy (v2.x)
- **`Data/qc_conf.xml`** — Old AHK XML format
  - Automatically migrated on first run
  - Backed up as `qc_conf.xml.migrated.YYYYMMDD`

## Migration Flow

```
Startup
  ↓
Check for qc_config.json
  ↓ (not found)
Check for qc_conf.xml
  ↓ (found)
Migrate XML → JSON
  ↓
Backup original XML
  ↓
Use JSON going forward
```

## Usage

```csharp
// Auto-detect and load (migrates if needed)
var config = ConfigMigrator.LoadConfig();

// Or explicitly use JSON
var config = new JsonConfigService();

// Access menu
var menu = config.GetMenu();
foreach (var item in menu.Items)
{
    Console.WriteLine(item.Name);
}

// Access settings
var (value, exists) = config.GetOpt("main_hotkey");
config.SetOpt("gen_trayicon", true);

// Save
config.Save();  // Writes to Data/qc_config.json
```

## Benefits over XML

1. **Human-readable** — Easier to edit manually
2. **Native .NET** — System.Text.Json (no LINQ to XML)
3. **Type-safe** — Strong models with System.Text.Json attributes
4. **Smaller** — JSON is more compact than XML
5. **Modern** — JSON is the standard for config in .NET

## IConfigService Interface

Both `JsonConfigService` and legacy `XmlConfigService` implement the same interface, but JSON is preferred:

- **JSON methods**: `GetMenu()`, `GetSettings()`, `GetHiddenWindows()`
- **Legacy XML methods**: `GetMenuNode()`, `GetSettingsNode()`, etc. (throws `NotSupportedException` in JSON)

Use `ConfigMigrator.LoadConfig()` to auto-detect format and load appropriately.
