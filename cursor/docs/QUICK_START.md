# Quick Cliq .NET Rewrite — Quick Reference

## 🎯 Current Status: Phase 1 Complete ✅

**Build Status**: ✅ Success (0 errors, 0 warnings)  
**Target**: .NET 10, Windows  
**Progress**: 1 of 5 phases complete

---

## 📂 Project Structure

```
.net/QC/
├── QC.slnx                    # Open this in Visual Studio
├── QuickCliq.Core/            # Core library (business logic)
│   ├── Config/                # JSON config + XML migration
│   ├── Models/                # MenuItem, QuickCliqConfig
│   ├── Services/              # Options, Path, Icon, Pipe
│   └── Win32/                 # P/Invoke declarations
└── QC.net/                    # WPF host application
    └── Services/              # TrayIconService
```

---

## 🚀 How to Use

### Open in Visual Studio
1. Open `c:\dev\quickcliq_legacy\.net\QC\QC.slnx`
2. Both projects (QuickCliq.Core + QC.net) will load
3. Build solution (Ctrl+Shift+B)
4. Run QC.net (F5)

### Key Files to Know

#### Configuration
- **`QuickCliq.Core/Config/JsonConfigService.cs`** — Primary config implementation
- **`QuickCliq.Core/Config/ConfigMigrator.cs`** — XML → JSON migration
- **`QuickCliq.Core/Services/OptionsService.cs`** — 60+ default options

#### Usage Example
```csharp
// Load config (auto-migrates from XML if needed)
var config = ConfigMigrator.LoadConfig();

// Access menu
var menu = config.GetMenu();

// Get options with defaults
var options = new OptionsService(config);
var hotkey = options.Get<string>("main_hotkey"); // "#Z"
var trayIcon = options.Get<bool>("gen_trayicon"); // true

// Single instance check
var pipe = new PipeServer();
if (!pipe.TryStart())
{
    // Another instance running
    await PipeServer.SendMessageAsync("-a C:\\path\\to\\file.exe");
    return;
}

// Tray icon
var tray = new TrayIconService();
tray.OpenEditorClicked += (s, e) => /* ... */;
tray.ExitClicked += (s, e) => Application.Current.Shutdown();
```

---

## 📋 Phase Breakdown

### ✅ Phase 1: Foundation (Complete)
- [x] QuickCliq.Core library
- [x] JSON config with XML migration
- [x] OptionsService with defaults
- [x] PipeServer (single instance)
- [x] TrayIconService
- [x] Win32 interop layer

### 🔜 Phase 2: Execution & Menu (Next)
- [ ] CommandExecutor
- [ ] PopupMenu (custom rendering)
- [ ] MenuBuilder
- [ ] HotkeyService

### Phase 3: Editor & Options
- [ ] WPF Main Editor (TreeView)
- [ ] Options window
- [ ] Add/Edit dialogs

### Phase 4: Extended Features
- [ ] Clips (10 clipboards)
- [ ] Windows (hide/show, tile)
- [ ] Recent items
- [ ] Memos
- [ ] Folder Menu
- [ ] Gestures

### Phase 5: Polish
- [ ] S-Menus
- [ ] Context menu integration
- [ ] Auto-update
- [ ] Installer

---

## 📖 Documentation

| File | Purpose |
|------|---------|
| **REWRITE_PLAN.md** | Complete module specifications |
| **PROGRESS.md** | Detailed progress tracking |
| **PHASE_1_COMPLETE.md** | Phase 1 completion report |
| **QuickCliq.Core/Config/README.md** | Config system documentation |

---

## 🎨 Design Highlights

### Config System
- **Primary**: JSON (`Data/qc_config.json`)
- **Legacy**: XML (`Data/qc_conf.xml`) auto-migrates
- **Migration**: Automatic on first run
- **Type-safe**: Strong models with JSON attributes

### Architecture
- **Core**: Business logic, no UI dependencies
- **Host**: WPF app references Core
- **Separation**: Clean interfaces, testable

### Modern Patterns
- Async/await for I/O
- INotifyPropertyChanged for binding
- Event-based communication
- Dependency injection ready

---

## 🔨 Build Commands

```bash
cd c:\dev\quickcliq_legacy\.net\QC

# Build Core
dotnet build QuickCliq.Core\QuickCliq.Core.csproj

# Build Host
dotnet build QC.net\QC.net.csproj

# Build All
dotnet build QC.slnx

# Run
dotnet run --project QC.net\QC.net.csproj
```

---

## 💡 Tips

1. **Both projects in Solution Explorer?**
   - Open `QC.slnx` (not individual .csproj files)

2. **WinForms + WPF working together?**
   - Yes! Tray uses WinForms NotifyIcon, main UI is WPF

3. **Where's the data?**
   - `{AppDir}\Data\qc_config.json`
   - First run creates default config

4. **Legacy XML still works?**
   - Yes! Auto-migrates to JSON on first run
   - Original backed up as `.migrated.YYYYMMDD`

---

**Ready to continue with Phase 2!** 🚀
