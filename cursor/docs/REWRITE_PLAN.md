# Quick Cliq Rewrite Plan — Detailed Module Specification

**Target:** .NET 8, C#, WPF  
**Purpose:** Handoff document for AI agents. Each section is self-contained with interfaces, data structures, and implementation notes.

---

## Table of Contents

1. [Project Overview & Tech Stack](#1-project-overview--tech-stack)
2. [Solution Structure](#2-solution-structure)
3. [Module: Config / XmlConfigService](#3-module-config--xmlconfigservice)
4. [Module: Options / QC_Options](#4-module-options--qc_options)
5. [Module: Command Execution](#5-module-command-execution)
6. [Module: Popup Menu (PUM)](#6-module-popup-menu-pum)
7. [Module: Menu Builder](#7-module-menu-builder)
8. [Module: Hotkeys](#8-module-hotkeys)
9. [Module: Main Editor (WPF)](#9-module-main-editor-wpf)
10. [Module: Options Window (WPF)](#10-module-options-window-wpf)
11. [Module: Clips (Clipboard Manager)](#11-module-clips-clipboard-manager)
12. [Module: Windows (Window Management)](#12-module-windows-window-management)
13. [Module: Recent Items](#13-module-recent-items)
14. [Module: Memos](#14-module-memos)
15. [Module: Folder Menu](#15-module-folder-menu)
16. [Module: Mouse Gestures](#16-module-mouse-gestures)
17. [Module: Host / Application Shell](#17-module-host--application-shell)
18. [Module: S-Menus](#18-module-s-menus)
19. [Module: Context Menu & Shell Integration](#19-module-context-menu--shell-integration)
20. [Implementation Order & Dependencies](#20-implementation-order--dependencies)

---

## 1. Project Overview & Tech Stack

### Tech Stack
- **.NET 10** (STS - upgraded from original .NET 8 plan)
- **C# 13**
- **WPF** for all UI (Main Editor, Options, dialogs)
- **System.IO.Pipes** for IPC (single-instance, S-Menu)
- **System.Xml** or **System.Xml.Linq** for config
- **P/Invoke** for Win32 (hotkeys, clipboard, window management, icons)

### Key Constants (from legacy `Constants.ahk`)
```
AppName: "Quick Cliq"
Version: "2.1.0"
DataPath: {AppDir}\Data
ConfigPath: {DataPath}\qc_conf.xml
MemosDir: {DataPath}\memos
ClipsDir: {DataPath}\Clips
PipeName: \\.\pipe\quickcliq
MultiTargetDivider: "{N}"  // separator for multiple commands in one item
```

### Paths
- `glb["qcDataPath"]` = `{AppDir}\Data`
- `glb["xmlConfPath"]` = `{DataPath}\qc_conf.xml`
- `glb["memosDir"]` = `{DataPath}\memos`
- `glb["clipsDir"]` = `{DataPath}\Clips`

---

## 2. Solution Structure

```
QuickCliq.sln
├── src/
│   ├── QuickCliq.Core/              # Class library, no UI
│   │   ├── Models/
│   │   │   ├── MenuItem.cs
│   │   │   ├── MenuNode.cs
│   │   │   └── ...
│   │   ├── Config/
│   │   ├── Services/
│   │   └── Win32/                   # P/Invoke declarations
│   │
│   ├── QuickCliq.Menu/               # Custom popup menu (no WPF dependency for menu itself)
│   │   ├── PopupMenu.cs
│   │   ├── MenuItemRenderer.cs
│   │   └── ...
│   │
│   ├── QuickCliq.Editor/             # WPF app, references Core + Menu
│   │   ├── MainWindow.xaml
│   │   ├── ViewModels/
│   │   └── ...
│   │
│   └── QuickCliq/                    # Host project (exe)
│       ├── App.xaml
│       ├── TrayIcon.cs
│       ├── PipeServer.cs
│       └── ...
│
└── tests/
    └── QuickCliq.Core.Tests/
```

---

## 3. Module: Config / XmlConfigService

### Purpose
Load, save, and manipulate `qc_conf.xml`. Must be compatible with legacy format.

### XML Schema (qc_conf.xml)

```xml
<qc_>
  <lastID>123</lastID>
  <menu ID="0" name="main" mtcolor="0" mbgcolor="0">
    <item ID="1" name="Item Name" icon="path:0" hotkey="" bold="0" issep="0" autorun="0">
      <command>C:\path\to\app.exe</command>
      <command>second command</command>   <!-- multi-target: divider is {N} -->
    </item>
    <item ID="2" name="Submenu" ...>
      <!-- nested: item can contain menu -->
      <menu ID="3" name="sub" ...>
        <item .../>
      </menu>
    </item>
  </menu>
  <settings>
    <opt name="gen_trayicon" value="1"/>
    <opt name="main_hotkey" value="#Z"/>
    <!-- some opts have multiple <value> children -->
  </settings>
  <wins>
    <win type="hidden" hwnd="12345" istopmost="0"/>
  </wins>
</qc_>
```

### Interface: IConfigService

```csharp
public interface IConfigService
{
    string ConfigPath { get; }
    XElement GetMenuNode();
    XElement GetSettingsNode();
    XElement GetWinsNode();
    
    int NextId();
    XElement GetNodeById(int id);
    XElement ItemResolve(object item);  // int or XElement
    bool IsMenu(XElement node);
    bool IsSeparator(XElement node);
    
    string GetItemCmdByID(int id);
    string GetItemCmdString(XElement item);
    void ItemSetCmd(int itemId, string commands);
    void ItemSetAttr(int itemId, string attrName, string value);
    string ItemGetAttr(int itemId, string attrName);
    void ItemDel(int itemId);
    
    void SetOpt(string name, object value);  // value: string or string[]
    (object Value, bool Exists) GetOpt(string name);
    void DelOpt(string name);
    
    XElement CreateItemNode(XElement parent, XElement before = null);
    IEnumerable<XElement> GetMenuItems(XElement menu);
    int GetItemsCount(XElement menu);
    
    void Save();
    void Backup();
    
    // For S-Menu: load from external path
    void LoadFrom(string path);
}
```

### Implementation Notes
- Use `System.Xml.Linq` (XDocument, XElement).
- `optMTDivider` = `"{N}"` — split commands by this when parsing.
- `gen_CmdRelPath` / `gen_IconRelPath`: when true, save paths relative to Data dir.
- Backup: copy `qc_conf.xml` to `qc_conf.xml.bak` before save.
- Handle missing file: create default structure (see `XMLCreateNewQCConf` in legacy).

### Option Names Reference (from OptSets.ahk)
See [Module: Options](#4-module-options--qc_options) for full list.

---

## 4. Module: Options / QC_Options

### Purpose
Provide typed access to settings. Options are stored in XML; this layer caches and exposes them with defaults.

### Interface: IOptionsService

```csharp
public interface IOptionsService
{
    T Get<T>(string name);
    void Set<T>(string name, T value);
}
```

### Default Values (from OptSets.ahk)

| Option | Default | Type |
|--------|---------|------|
| aprns_iconssize | 16 | int |
| aprns_lightmenu | 0 | bool |
| aprns_heightadjust | 0 | int |
| aprns_iconsonly | 0 | bool |
| aprns_columns | 0 | bool |
| aprns_colnum | 2 | int |
| aprns_transp | 255 | int |
| aprns_mainfont | "" | string |
| aprns_frameWidth | 1 | int |
| aprns_frameSelMode | 0 | bool |
| recent_maxitems | 7 | int |
| recent_on | 1 | bool |
| recent_sub | 1 | bool |
| recent_gesture | "UR" | string |
| recent_hotkey | "#Q" | string |
| main_hotkey | "#Z" | string |
| main_gesture | "D" | string |
| main_geston | 1 | bool |
| main_ctrlrbhkey | 0 | bool |
| main_ctrlmbhkey | 0 | bool |
| main_ctrllrbhkey | 0 | bool |
| gen_trayicon | 1 | bool |
| gen_contextqc | 0 | bool |
| gen_runonstartup | 0 | bool |
| gen_cmddelay | 200 | int |
| gen_autoupd | 1 | bool |
| gen_smenuson | 0 | bool |
| gen_editoritem | 1 | bool |
| gen_iconrelpath | 0 | bool |
| gen_cmdrelpath | 0 | bool |
| gen_mnem_method | "run" | string |
| clips_on | 1 | bool |
| clips_sub | 1 | bool |
| clips_hotkey | "#X" | string |
| clips_gesture | "U" | string |
| clips_saveonexit | 1 | bool |
| wins_on | 1 | bool |
| wins_sub | 1 | bool |
| wins_hotkey | "#c" | string |
| wins_wndhidehkey | "^space" | string |
| memos_on | 1 | bool |
| memos_sub | 1 | bool |
| memos_hotkey | "#A" | string |
| gest_curbut | "rbutton" | string |
| gest_glbon | 1 | bool |
| gest_time | 10000 | int |
| gest_win_excl_on | 0 | bool |
| hkey_glbon | 1 | bool |
| fm_show_open_item | 1 | bool |
| fm_showicons | 1 | bool |
| fm_iconssize | "global" | string |
| fm_files_first | 0 | bool |
| fm_sort_type | "Name" | string |
| fm_sort_mode | "Asc" | string |

### Implementation
- `OptionsService` reads from `IConfigService.GetOpt`/`SetOpt`.
- Cache values in memory; flush to config on `Set`.
- Implement `INotifyPropertyChanged` if needed for UI binding.

---

## 5. Module: Command Execution

### Purpose
Execute commands (files, URLs, shell verbs). Support multi-target, Ctrl+click (copy to clipboard), Shift (run as admin), special prefixes.

### Interface: ICommandExecutor

```csharp
public interface ICommandExecutor
{
    Task ExecuteAsync(ExecuteParams args, CancellationToken ct = default);
}

public record ExecuteParams
{
    public string Command { get; init; }      // May contain {N} for multi-target
    public string Name { get; init; }
    public string Icon { get; init; }
    public bool NoCtrl { get; init; }         // Don't treat Ctrl as "copy"
    public bool NoShift { get; init; }        // Don't treat Shift as "run as admin"
    public bool NoLog { get; init; }          // Don't add to Recent
    public string Verb { get; init; }         // e.g. "RUNAS"
}
```

### Behavior
1. **Ctrl+click**: Copy all targets to clipboard (newline-separated), show toast, return.
2. **Shift+click**: Run each target with `RUNAS` verb.
3. **Normal click**: Run each target. Split by `{N}`. Delay between targets = `gen_cmdDelay` ms.

### Special Command Prefixes (in target string)
- `RUNAS ` — run as admin
- `RUN_MIN ` — run minimized (SW_MINIMIZE)
- `RUN_MAX ` — run maximized (SW_MAXIMIZE)
- `REP{n} ` — repeat next command n times
- `W{n}` or `WAIT{n}` — wait n seconds before next
- `CHK` — open Custom Hotkeys GUI
- `{clip}` or `{clip0}` — system clipboard text
- `{clip1}`..`{clip9}` — custom clip 1–9
- `copyto* ` or `copyto^ ` — Copy To command (see CopyTo module)
- `^` at end — change active window's working directory
- `killproc` or `killproc <name>` — kill process

### Implementation
- Use `Process.Start` with `UseShellExecute = true` for files/URLs.
- For custom verbs: `ProcessStartInfo.Verb = "RUNAS"` etc.
- `nShowCmd`: 1=SW_SHOWNORMAL, 3=SW_MAXIMIZE, 6=SW_MINIMIZE.
- Resolve paths: expand env vars, handle relative paths.
- Error handling: ShellExecute returns < 32 on error; show user-friendly message.

### Max Concurrent Threads
- Legacy uses 8 threads. Cap concurrent executions to avoid "Please wait" dialog.

---

## 6. Module: Popup Menu (PUM)

### Purpose
Custom-drawn popup menu with icons, colors, submenus. Replaces native Windows menu for full control over appearance.

### Interface: IPopupMenu

```csharp
public interface IPopupMenu
{
    IPopupMenu CreateMenu(MenuParams p);
    void Add(MenuItemParams item);
    void AddSeparator();
    void Add(string text);  // disabled/text-only item
    MenuItemResult Show(int x, int y, string mode = "normal");
    void Destroy();
}

public record MenuParams
{
    public int IconSize { get; init; } = 16;
    public int TextColor { get; init; }
    public int BgColor { get; init; }
    public int TextOffset { get; init; } = 8;
    public bool NoIcons { get; init; }
    public bool NoColors { get; init; }
    public bool NoText { get; init; }
    public int YMargin { get; init; } = 3;
    public string FontName { get; init; }
    public int FontQuality { get; init; }
    public int FrameWidth { get; init; }
    public bool FrameSelMode { get; init; }
}

public record MenuItemParams
{
    public string Name { get; init; }
    public string Uid { get; init; }           // e.g. "Clips_Sub1", "wins_12345"
    public object Icon { get; init; }           // path or HICON
    public bool IconUseHandle { get; init; }
    public bool Bold { get; init; }
    public int TColor { get; init; }
    public int BgColor { get; init; }
    public bool Disabled { get; init; }
    public bool Break { get; init; }            // column break
    public IPopupMenu Submenu { get; init; }
    public object Tag { get; init; }           // e.g. FM_Target, WinsTopmost
}

public record MenuItemResult
{
    public string Uid { get; init; }
    public object Tag { get; init; }
    public IPopupMenu AssocMenu { get; init; }
    public bool IsMenu { get; init; }
}
```

### Implementation Notes
- Legacy uses GDI+ (GdipCreateBitmapFromFileICM, GdipCreateHICONFromBitmap) and User32 (CreatePopupMenu, TrackPopupMenuEx, DrawIconEx, etc.).
- Options: **GDI+** (built-in) or **SkiaSharp** for rendering.
- Must support: icons, custom colors per item/menu, bold text, column breaks, submenus.
- `GetItemByUID(uid)` — retrieve item by Uid for dynamic updates (e.g. clip icon).
- Mnemonic: `gen_mnem_method` = "run" (activate on key) or "select" (highlight only).

### Events (from legacy pumParams)
- `onrun` — item selected
- `onselect` — hover
- `oninit` / `onuninit` — menu open/close
- `onmbutton` / `onrbutton` — middle/right click
- `onshow` / `onclose` — menu visibility

---

## 7. Module: Menu Builder

### Purpose
Build the main menu (and submenus) from config + dynamic sources (Clips, Wins, Recent, Memos, FolderMenu).

### Interface: IMenuBuilder

```csharp
public interface IMenuBuilder
{
    IPopupMenu BuildMainMenu();
    void Rebuild(string menuNode = "main");
}
```

### Build Order
1. Iterate `qcconf.GetMenuItems(menuNode)`.
2. For each `item`:
   - If `item` has child `menu` → recurse, add as submenu.
   - If `item` name ends with `*` and no submenu → **FolderMenu** (dynamic folder).
   - Else add regular item with commands.
3. Add separator, then **AddExtras**:
   - Clips submenu (if clips_on && clips_sub)
   - Wins submenu (if wins_on && wins_sub)
   - Memos submenu (if memos_on && memos_sub)
   - Recent submenu (if recent_on && recent_sub)
4. Add system items: Suspend Hotkeys, Suspend Gestures, Open Editor, Help.

### Folder Menu
- `*` suffix = folder path. Resolve at show-time.
- Build submenu with folders first or files first (fm_files_first).
- Each subfolder = nested submenu.

### Item UIDs
- Integer string = config item ID.
- `FolderMenu_Item` = folder menu entry.
- `wins_{hwnd}` = hidden window.
- `wins_HideAWin`, `wins_UnHideAll`, `wins_ModWin`, `wins_ToggleDesktop`, `wins_TileH`, `wins_TileV`, `wins_Cascade`.
- `Clips_Sub0`..`Clips_Sub9`, `Clips_ClearAll`.
- `Memos_1`..`Memos_N`, `Memos_Change`, `Memos_empty`.
- `Recent_*`, `Recent_Clear`.
- `QCEditor`, `HK_Susp`, `GS_Susp`, `QuickHelp`.

---

## 8. Module: Hotkeys

### Purpose
Register global hotkeys. Support Win, Ctrl, Alt, Shift modifiers and custom combinations.

### Interface: IHotkeyService

```csharp
public interface IHotkeyService
{
    bool Register(string hotkey, Action callback);
    void Unregister(string hotkey);
    void SetAllEnabled(bool enabled);
    string HotkeyToString(int vk, int mods);  // for display
}
```

### Hotkey Format (legacy)
- `#` = Win, `^` = Ctrl, `!` = Alt, `+` = Shift
- `#Z` = Win+Z, `^RButton` = Ctrl+Right-click, `~LButton & RButton` = LButton+RButton combo
- Parse to Virtual Key + Modifiers for `RegisterHotKey`.

### Implementation
- P/Invoke `RegisterHotKey` / `UnregisterHotKey` (User32).
- Message loop: handle `WM_HOTKEY` (0x0312).
- Store mapping: hotkey → label/callback.
- On conflict: show error, offer reset to default.

### Hotkeys to Register (from config)
- Main: `main_hotkey`, `^RButton`, `^MButton`, `~LButton & RButton` (if enabled)
- Clips: `clips_hotkey`, `clips_copyhk`, `clips_appendhk`, `clips_pastehk`
- Wins: `wins_hotkey`, `wins_wndhidehkey`
- Memos: `memos_hotkey`
- Recent: `recent_hotkey`
- Per-item hotkeys from config (custom hotkeys).

---

## 9. Module: Main Editor (WPF)

### Purpose
TreeView-based editor for organizing menu items. Add, edit, delete, reorder, drag-drop.

### UI Elements
- **TreeView**: Hierarchical menu structure. Icons per item.
- **Toolbar**: Add Shortcut, Add Menu, Add Separator, Expand/Collapse, Move Up/Down, Delete, Hints, Save & Rebuild
- **Edit box**: Multi-line for commands (one per line or `{N}` separated)
- **Status bar**: Random aphorism (optional)
- **Properties panel**: Item name, icon, hotkey, autorun, etc.

### Data Binding
- `TreeView` bound to `ObservableCollection<MenuItemViewModel>`.
- Each node: `MenuItemViewModel` with `Children`, `Name`, `Icon`, `Commands`, `IsSeparator`, `IsMenu`, etc.
- Sync with `IConfigService` on Save.

### Operations
- Add Shortcut: dialog to pick file/URL, set name, icon, commands.
- Add Menu: new submenu node.
- Add Separator: `issep="1"` item.
- Delete: remove from config, rebuild.
- Move Up/Down: reorder siblings in config.
- Drag-drop: reorder or move between parents.
- Double-click item: edit commands in main edit box.
- Item Properties: dialog for icon, hotkey, autorun, colors.

### Dependencies
- `IConfigService`, `IMenuBuilder`, `IIconService`

---

## 10. Module: Options Window (WPF)

### Purpose
Tabbed settings UI. Ten tabs: General, Appearance, Hotkeys, Gestures, Clips, Wins, Memos, Recent, Folder Menu, Other (Backup).

### Tab Layout
- Left: ListView with tab names.
- Right: Content for selected tab.
- Buttons: OK, Apply, Defaults.

### Tabs (from tab_*.ahk)
1. **General**: Editor item, Help, Suspend, tray icon, Context QC, Run on startup, Auto-update, S-Menus, command delay, mnemonic method, portability (icon/cmd rel path).
2. **Appearance**: Icon size, light menu, height adjust, icons only, columns, colors, transparency, font, frame.
3. **Hotkeys**: Main hotkey, extra hotkeys (Ctrl+RButton, etc.), custom hotkeys list.
4. **Gestures**: Button, temp disable time, exclusions.
5. **Clips**: On/off, submenu, hotkeys, save on exit.
6. **Wins**: On/off, submenu, hotkeys, transparency, fade.
7. **Memos**: On/off, submenu, hotkeys.
8. **Recent**: On/off, submenu, max items, hotkey, gesture, log sources.
9. **Folder Menu**: Refresh, show open item, icons, sort, etc.
10. **Other**: Backup path, reset defaults.

### Apply Flow
- Validate hotkeys (no conflicts).
- Write to `IOptionsService` / `IConfigService`.
- Call `IMenuBuilder.Rebuild()`.
- Re-register hotkeys.

---

## 11. Module: Clips (Clipboard Manager)

### Purpose
10 clipboards: 0 = system, 1–9 = custom. Copy, paste, append. Persist on exit (optional).

### Interface: IClipsService

```csharp
public interface IClipsService
{
    bool IsEnabled { get; set; }
    void CopyToClip(int clipNum, bool append = false);   // from system to clip N
    void PasteFromClip(int clipNum);                      // from clip N to system
    void ClearClip(int clipNum);
    void ClearAll();
    bool IsEmpty(int clipNum);
    bool HasFormat(int clipNum, int format);
    string GetText(int clipNum);
    void SetText(int clipNum, string text);
    // For menu: update icon when clip content changes
    void RefreshMenuIcons();
}
```

### Implementation
- Clip 0: use system clipboard (OpenClipboard, GetClipboardData, etc.).
- Clips 1–9: store in memory. Serialize to `{ClipsDir}\clip_N.dat` on exit if `clips_saveonexit`.
- Use Win32 clipboard API for multi-format (text, HTML, bitmap). Legacy uses WinClip.
- Skip certain formats (e.g. CF_OEMTEXT) to avoid issues.

### Hotkeys
- `clips_copyhk` (default `^`): copy to next clip
- `clips_appendhk` (default `#^`): append to next clip
- `clips_pastehk` (default `!`): paste from next clip
- `clips_hotkey`: show Clips menu

### Menu
- 10 items: Clip 1..9, System Clipboard (0).
- Clear All.
- Context menu: View, To Clipboard, To File (Text/HTML/Bitmap/Binary), Run Links, Clear.

---

## 12. Module: Windows (Window Management)

### Purpose
Hide/show windows, tile, cascade, toggle desktop.

### Interface: IWindowsService

```csharp
public interface IWindowsService
{
    bool IsEnabled { get; set; }
    void HideWindow(IntPtr hwnd);
    void UnhideWindow(IntPtr hwnd);
    void UnhideAll();
    void ShowAll();
    void ToggleDesktop();
    void TileHorizontal();
    void TileVertical();
    void Cascade();
    void ModifyWindow(IntPtr hwnd);  // transparency, etc.
}
```

### Implementation
- Hidden windows stored in config `<wins>` node.
- Use `ShowWindow(hwnd, SW_HIDE)` / `SW_SHOW`.
- Tile/Cascade: `PostMessage` with `WM_MDITILE`, etc., or use Taskbar API.
- Toggle desktop: minimize all or use `Shell.Application`.

### Exclusions
- Do not hide: `Shell_TrayWnd`, `Progman`, `WorkerW`, or QC's own windows.

---

## 13. Module: Recent Items

### Purpose
Track and show recent shortcuts, folders, processes, Windows recent.

### Interface: IRecentService

```csharp
public interface IRecentService
{
    bool IsEnabled { get; set; }
    void Add(string name, string icon, string path);
    void Clear();
    IEnumerable<RecentItem> GetItems();
    void Save();
    void Restore();
}
```

### Sources
- QC shortcuts (when `recent_logQC`)
- Windows Recent folder (`%APPDATA%\Microsoft\Windows\Recent\*.lnk`)
- Active folders (poll `GetForegroundWindow` → path)
- Processes (poll running processes)
- Intervals: `RecentProcTrackInterval`, `RecentFolTrackInterval`, `RecentWinRecTrackInterval`

### Storage
- In-memory + persist to config or separate file.
- Max items: `recent_maxitems`.

---

## 14. Module: Memos

### Purpose
Sticky notes. Stored as `.mmo` files. Optional encryption.

### Interface: IMemosService

```csharp
public interface IMemosService
{
    bool IsEnabled { get; set; }
    IEnumerable<string> GetMemoNames();
    string GetText(string name);
    void SetText(string name, string text);
    void Delete(string name);
    void ShowOnTop(string name, IntPtr? targetWindow);
    void Encrypt(string name, string password);
    void Decrypt(string name, string password);
}
```

### Storage
- `{MemosDir}\{name}.mmo`
- Encryption: legacy uses custom Crypt module. Consider `ProtectedData` or similar for .NET.

### Menu
- List memos, "Memos Editor", "No Memos" if empty.
- Context: Copy, Show on top, Edit, Email.

---

## 15. Module: Folder Menu

### Purpose
Dynamic submenu built from folder contents. Triggered by item name ending with `*`.

### Interface: IFolderMenuBuilder

```csharp
public interface IFolderMenuBuilder
{
    IPopupMenu BuildMenu(string path, MenuParams baseParams);
}
```

### Behavior
- Resolve path (env vars, relative to Data dir).
- List folders and files. Sort by `fm_sort_type` (Name/Date/Size), `fm_sort_mode` (Asc/Desc).
- Folders first or files first per `fm_files_first`.
- Show ".." to open parent if `fm_show_open_item`.
- Icons: `fm_showicons`, size from `fm_iconssize` or global.
- Each item: `FolderMenu_Item` with `FM_Target` = path.

---

## 16. Module: Mouse Gestures

### Purpose
Recognize U/D/L/R mouse movements. Map to actions (main menu, clips, wins, memos, recent).

### Interface: IGestureService

```csharp
public interface IGestureService
{
    bool IsEnabled { get; set; }
    void Suspend(int durationMs = 0);  // 0 = toggle, >0 = temp
    string Recognize();  // Returns "U", "D", "L", "R", "UR", "DL", etc. or ""
}
```

### Implementation (from mg.ahk)
- Track mouse from button down. Compute angle between start and current position.
- Map angle to sector: U (0–90°), R (90–180°), D (180–270°), L (270–360°).
- Min movement: 9 pixels.
- Max moves: 3 (configurable).
- Return gesture string (e.g. "UR", "DL") or empty if canceled.

### Gesture Hotkey
- `gest_curbut` (default "rbutton") + `gest_butmods`.
- On gesture: match `main_gesture`, `clips_gesture`, `wins_gesture`, `memos_gesture`, `recent_gesture` → invoke corresponding action.

### Exclusions
- `gest_win_excl_on`: disable gestures in certain windows (e.g. games).

---

## 17. Module: Host / Application Shell

### Purpose
Single-instance app. Tray icon. Pipe server. Startup. Exit handling.

### Components

#### Single Instance
- Named pipe: `\\.\pipe\quickcliq`
- On startup: try create pipe. If fails, another instance exists → optionally show message and exit, or continue.
- Pipe server: accept connections. Messages: `-a <path>` (add shortcut), `-sm <qcm_path>` (S-Menu run).

#### Tray Icon
- `NotifyIcon` (System.Windows.Forms or WPF).
- Menu: Open Editor, Suspend Hotkeys, Suspend Gestures, Check Updates, Options, Exit.
- Show/hide per `gen_trayicon`.

#### Startup
- Parse args: `-startup` = run startup items (autorun).
- `-getprocs` = admin, send process list to pipe (for Add From Process).
- `-smreg 1/0`, `-rcnwinrec 1/0`, `-ctxreg 1/0` = registry changes, then exit.
- `-a <path>` = add shortcut, send to existing instance via pipe.
- `-sm <path>` = run S-Menu.

#### Exit
- Save use time, clips (if save on exit), config backup, config save.
- Close pipe handle.

#### Run on Startup
- Create shortcut in `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup` or use registry.

---

## 18. Module: S-Menus

### Purpose
Standalone menu from `.qcm` file. Can be run from Explorer context menu "Update S-Menu".

### Behavior
- `.qcm` = same XML structure as qc_conf but only a subtree.
- `SMenu_Run(qcmPath)`: load config from path, build menu, show at cursor. Wait for commands to finish.
- `SMenu_Copy(menuId, destPath)`: export menu subtree to .qcm.
- `SMenu_UpdateMenu(qcmPath)`: sync .qcm with current config (by PRE_ID link).

### Registry
- S-Menu context: `s_registry.ahk`. Register shell extension or context menu handler.
- "Update S-Menu" = run `QuickCliq.exe -smupd <qcm_path>`.

---

## 19. Module: Context Menu & Shell Integration

### Purpose
"Add to Quick Cliq" in Explorer context menu. "Update S-Menu" for .qcm files.

### Implementation
- Registry: `HKEY_CLASSES_ROOT\*\shell\=> Quick Cliq\command` (or similar).
- Command: `QuickCliq.exe -a "%1"`.
- App receives via pipe, adds shortcut to config, shows editor or toast.

### Add Shortcut Flow
- `-a <path>`: resolve path, create item with default icon, add to menu (user configurable location), save.

---

## 20. Implementation Order & Dependencies

### Phase 1: Foundation (weeks 1–2)
1. **QuickCliq.Core** — Models, constants, path helpers
2. **XmlConfigService** — load/save qc_conf.xml
3. **OptionsService** — options with defaults
4. **PipeServer** — single-instance, basic IPC
5. **TrayIcon** — minimal tray, exit

### Phase 2: Execution & Menu (weeks 3–4)
6. **CommandExecutor** — RunCommand with special prefixes
7. **IconService** — extract icons from path (Win32)
8. **PopupMenu** — custom menu (GDI+ or Skia)
9. **MenuBuilder** — build from config (no Clips/Wins/Recent/Memos yet)
10. **HotkeyService** — register main hotkey

### Phase 3: Editor & Options (weeks 5–6)
11. **Main Editor** — WPF TreeView, toolbar, DnD
12. **Add Shortcut dialog**
13. **Options window** — all tabs
14. **Item Properties** — edit dialog

### Phase 4: Extended Features (weeks 7–9)
15. **ClipsService** — 10 clipboards
16. **WindowsService** — hide/show, tile, cascade
17. **RecentService** — recent items
18. **MemosService** — sticky notes
19. **FolderMenuBuilder** — dynamic folders
20. **GestureService** — mouse gestures

### Phase 5: Polish (weeks 10–11)
21. **S-Menus** — .qcm load, run, update
22. **Context menu** — Add to Quick Cliq
23. **Copy To** — special command
24. **Auto-update** — check, download
25. **Installer** — Inno Setup or MSIX

---

## Appendix A: Hotkey String Parsing

Legacy uses `HotkeyGetVK` to convert string to VK+mods. Example mappings:
- `#` → MOD_WIN
- `^` → MOD_CONTROL
- `!` → MOD_ALT
- `+` → MOD_SHIFT
- `RButton` → VK_RBUTTON
- `#Z` → Win+Z

---

## Appendix B: Icon Path Format

- `path:index` — e.g. `C:\Windows\System32\shell32.dll:166`
- `path` — for .ico, index 0
- Relative: `Data\user_icons\foo.ico`
- `Data\qc_icons.icl:0` — internal icon list

---

## Appendix C: Legacy File Mapping

| AHK File | C# Module |
|----------|-----------|
| xml_mgr.ahk, xml_common.ahk | XmlConfigService |
| OptSets.ahk, tab_*.ahk | OptionsService, Options window |
| QC_execute.ahk | CommandExecutor |
| MenuBuilding.ahk, FeaturesAdding.ahk | MenuBuilder |
| PUM/* | PopupMenu |
| hk_hotkey.ahk, hk_common.ahk | HotkeyService |
| Main.ahk, Main_TV.ahk, etc. | Main Editor |
| clips.ahk, clips_common.ahk | ClipsService |
| qWins.ahk | WindowsService |
| qRecent.ahk | RecentService |
| memos.ahk | MemosService |
| FolderMenu.ahk | FolderMenuBuilder |
| mg.ahk | GestureService |
| S-Menu.ahk | S-Menus |
| QC_contextMenus.ahk | Context menu handlers |
