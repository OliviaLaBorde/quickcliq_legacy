# Quick Cliq .NET Rewrite - Roadmap 🗺️

**Project**: Quick Cliq - AutoHotkey to .NET 10 Rewrite  
**Last Updated**: February 14, 2026

---

## Project Status

| Phase | Name | Status | Completion |
|-------|------|--------|------------|
| **Phase 1** | Foundation | ✅ Complete | 100% |
| **Phase 2** | Core Functionality | ✅ Complete | 100% |
| **Phase 3** | Editor & UI | ✅ Complete | 100% |
| **Phase 4** | Advanced Features | 📋 Not Started | 0% |
| **Phase 5** | Polish & Distribution | 📋 Not Started | 0% |

**Overall Progress**: 60% (3 of 5 phases complete)

---

## Phase 1: Foundation ✅ COMPLETE

**Duration**: Initial setup  
**Focus**: Project structure, configuration, core services

### Completed Items
- ✅ Solution structure (.NET 10)
- ✅ QuickCliq.Core class library
- ✅ QC.net WPF application
- ✅ IConfigService interface
- ✅ JsonConfigService implementation
- ✅ IOptionsService interface
- ✅ OptionsService implementation
- ✅ Configuration models (MenuItem, MenuConfig, etc.)
- ✅ JSON configuration file format
- ✅ AppConstants and version info

**Files**: `PHASE_1_TASKS.md`

---

## Phase 2: Core Functionality ✅ COMPLETE

**Duration**: February 14, 2026  
**Focus**: Hotkeys, tray icon, menu display, command execution

### Completed Items
- ✅ Global hotkey registration (Win32 API)
- ✅ Tray icon with context menu
- ✅ Native popup menu (Win32 API)
- ✅ Menu builder from config
- ✅ Command executor
- ✅ Multi-target commands ({N} support)
- ✅ Special command prefixes (RUNAS, WAIT, REP, RUN_MIN, RUN_MAX)
- ✅ Special commands (EDITOR, TRAY, SOFF, etc.)
- ✅ Icon loading from files/registry
- ✅ Menu item colors and styling
- ✅ Separator items
- ✅ Nested submenus
- ✅ Message window for hotkey processing

**Files**: `PHASE_2_TASKS.md`, `PHASE_2_FINAL.md`

---

## Phase 3: Editor & UI ✅ COMPLETE

**Duration**: February 14, 2026  
**Focus**: WPF editor for menus and settings

### Completed Items
- ✅ MainWindow (Menu Editor)
  - ✅ TreeView with hierarchical menu display
  - ✅ Drag-and-drop reordering with visual feedback
  - ✅ Drop into submenus
  - ✅ Add/Edit/Delete buttons
  - ✅ Properties panel for item editing
  - ✅ Add Shortcut dialog
  - ✅ Icon file picker
  - ✅ Save with auto-rebuild
  - ✅ Toast notifications
  - ✅ Move Up/Down buttons
- ✅ OptionsWindow (Settings)
  - ✅ General tab (editor, tray, delay, startup)
  - ✅ Appearance tab (icons, fonts, colors)
  - ✅ Hotkeys tab (main hotkey, suspend)
  - ✅ Features tab (Clips, Wins, Memos, Recent)
  - ✅ About tab
  - ✅ Apply/OK/Cancel buttons
- ✅ MVVM architecture (MenuItemViewModel)
- ✅ Event-driven menu rebuilding
- ⏭️ Item Editor Dialog (skipped - properties panel sufficient)
- ⏭️ Advanced Icon Picker (deferred - simple picker works)
- 🎨 Menu Styling (stretch goal - deferred to Phase 5)

**Bug Fixes**:
- ✅ Editor window off-screen issue
- ✅ Nested menu execution bug (static dictionaries)
- ✅ Dialog positioning
- ✅ Explicit isMenu property

**Files**: `PHASE_3_TASKS.md`, `PHASE_3_COMPLETE.md`

---

## Phase 4: Advanced Features 📋 NOT STARTED

**Focus**: Clips, Wins, Memos, Recent, Folder Menus

### Planned Items
- 🔲 Clips (Clipboard Manager)
  - Monitor clipboard changes
  - Store history (text, files, images)
  - Dynamic submenu
  - Custom clips (1-9)
  - Hotkey (#X)
- 🔲 Wins (Window Manager)
  - Enumerate open windows
  - Group by process
  - Dynamic submenu
  - Window actions (activate, close, minimize, topmost)
  - Hotkey (#C)
- 🔲 Memos (Quick Notes)
  - Store notes
  - Dynamic submenu
  - Add/Edit/Delete UI
  - Hotkey (#A)
- 🔲 Recent Items
  - Track executed commands
  - Dynamic submenu
  - Max limit
  - Click to re-execute
- 🔲 Folder Menus (FM)
  - FOLDER: special command
  - Enumerate files/folders
  - Sort options
  - File icons
  - Recursive submenus
- 🔲 S-Menus (External Menus)
  - SMENU: special command
  - Load external config files
  - Merge into main menu

**Files**: `PHASE_4_TASKS.md`

---

## Phase 5: Polish & Distribution 📋 NOT STARTED

**Focus**: Gestures, custom hotkeys, testing, installer

### Planned Items
- 🔲 Mouse Gestures
  - Gesture detection
  - Pattern recognition (U, D, L, R, UR, etc.)
  - Configure gesture button
  - Visual feedback
- 🔲 Custom Hotkeys (CHK)
  - Map hotkeys to any menu item
  - Conflict detection
  - Configuration UI
- 🔲 CopyTo Feature
  - copyto* and copyto^ commands
  - Multi-file copy
- 🔲 Advanced Command Features
  - {clip} / {clip0-9} expansion
  - killproc command
  - Environment variable expansion
- 🎨 Menu Styling (Owner-Drawn)
  - Custom GDI+ or SkiaSharp rendering
  - OR: WPF overlay menu
- 🔲 Auto-Update
  - Check for updates on startup
  - Download from GitHub
  - Apply and restart
- 🔲 Logging & Diagnostics
  - ILoggingService
  - Log to file
  - View logs in UI
- 🔲 Testing & Quality
  - Unit tests
  - Integration tests
  - Performance profiling
- 📚 Documentation
  - User guide
  - Command reference
  - Developer docs
- 📦 Installer & Distribution
  - Create installer (WiX/Inno/MSIX)
  - GitHub release pipeline
  - Auto-build on tag

**Stretch Goals**:
- Dark mode
- Icon themes
- Plugins API
- Cloud sync
- Localization

**Files**: `PHASE_5_TASKS.md`

---

## Technical Stack

### Core Technologies
- **.NET 10** (C#)
- **WPF** (Windows Presentation Foundation)
- **Win32 API** (P/Invoke for hotkeys, menus, icons)
- **System.Windows.Forms.NotifyIcon** (tray icon)
- **System.Text.Json** (configuration)

### Architecture
- **MVVM** pattern for WPF UI
- **Service-based** architecture
- **Interface-driven** design (IoC-ready)
- **Event-driven** communication

### Key Libraries
- `System.Windows.Forms` (NotifyIcon)
- `System.Text.Json` (config serialization)
- `System.Diagnostics` (process launching)
- Win32 APIs: `user32.dll`, `shell32.dll`, `kernel32.dll`

---

## Migration Status

### Features from Original AHK Version

| Feature | Status | Phase |
|---------|--------|-------|
| Hotkey menu | ✅ Complete | 2 |
| Tray icon | ✅ Complete | 2 |
| Command execution | ✅ Complete | 2 |
| Multi-target {N} | ✅ Complete | 2 |
| Special prefixes | ✅ Complete | 2 |
| Submenus | ✅ Complete | 2 |
| Icons | ✅ Complete | 2 |
| Colors & Bold | ✅ Complete | 2 |
| Separators | ✅ Complete | 2 |
| Menu editor | ✅ Complete | 3 |
| Options window | ✅ Complete | 3 |
| Clips | 📋 Planned | 4 |
| Wins | 📋 Planned | 4 |
| Memos | 📋 Planned | 4 |
| Recent | 📋 Planned | 4 |
| Folder Menus | 📋 Planned | 4 |
| S-Menus | 📋 Planned | 4 |
| Gestures | 📋 Planned | 5 |
| Custom Hotkeys | 📋 Planned | 5 |
| Owner-drawn menus | 🎨 Stretch | 5 |
| Auto-update | 📋 Planned | 5 |

---

## Performance Improvements vs AHK

### Expected Gains
- **10-100x faster** startup (compiled .NET vs interpreted AHK)
- **Near-instant** menu display (native Win32)
- **Lower memory** usage (no AHK runtime)
- **Better stability** (managed code, exception handling)
- **Modern UI** (WPF vs AHK Gui)

---

## Next Steps

1. ✅ **Complete Phase 3** (Editor & UI) — DONE!
2. 🔲 **Start Phase 4** - Begin with Clips service
3. 🔲 Implement Wins, Memos, Recent
4. 🔲 Add Folder Menus and S-Menus
5. 🔲 Move to Phase 5 (Gestures, CHK, polish)
6. 🔲 Create installer and release

---

## Resources

- **Project Docs**: `cursor/docs/`
- **Phase Plans**: `PHASE_1_TASKS.md` through `PHASE_5_TASKS.md`
- **Main Plan**: `REWRITE_PLAN.md`
- **Source Code**: `.net/QC/`
- **Config**: `.net/QC/Data/qc_config.json`

---

**Quick Cliq .NET Rewrite** — *Bringing modern performance to a classic launcher* 🚀
