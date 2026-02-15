# Quick Cliq .NET Rewrite

> **A modern, high-performance rewrite of Quick Cliq launcher from AutoHotkey to .NET 10**

[![.NET](https://img.shields.io/badge/.NET-10.0-blue)](https://dotnet.microsoft.com/)
[![Status](https://img.shields.io/badge/Status-Phase%203%20Complete-green)]()
[![Progress](https://img.shields.io/badge/Progress-60%25-yellow)]()

---

## 📋 Table of Contents

- [About](#about)
- [Project Status](#project-status)
- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Development Phases](#development-phases)
- [Roadmap](#roadmap)
- [Original AHK Version](#original-ahk-version)
- [Documentation](#documentation)
- [Contributing](#contributing)

---

## 🎯 About

**Quick Cliq** is a powerful Windows launcher and automation tool that provides instant access to applications, files, and custom commands through a global hotkey-triggered popup menu. Originally written in AutoHotkey, this project is a complete rewrite to **.NET 10** bringing modern performance, stability, and maintainability.

### Why Rewrite?

- **Native performance** with compiled .NET vs interpreted AHK
- **Modern UI** with WPF and Material Design
- **Better stability** with managed code and exception handling
- **Maintainability** with clean architecture and strong typing
- **Future-proof** with .NET's long-term support
- **Plug-in support** fully extendable via plug-ins with menu integrations!!

---

## 🚀 Project Status

| Phase | Name | Status | Completion |
|-------|------|--------|------------|
| **Phase 1** | Foundation | ✅ Complete | 100% |
| **Phase 2** | Core Functionality | ✅ Complete | 100% |
| **Phase 3** | Editor & UI | 🔄 Currently being worked | 80% |
| **Phase 4** | Plugin System & Advanced Features | 📋 Next Up | 0% |
| **Phase 5** | Polish & Distribution | 📋 Planned | 0% |

**Overall Progress**: 60% (3 of 5 phases complete)

### Latest Achievements (Phase 3)

✅ **Material Design WPF Editor** with TreeView and drag-and-drop  
✅ **Comprehensive Icon Support** - Material Design icons, emojis (1000+), and file icons  
✅ **Live Icon Preview** in editor with search-first Material icon picker  
✅ **Font Customization** with system font picker  
✅ **Command Builder Dialog** with visual command construction  
✅ **Auto-rebuild** on changes with immediate menu updates  
✅ **Color inheritance** system for submenus  

---

## ✨ Features

### Current Features (Phases 1-3)

#### Core Functionality
- 🔥 **Global Hotkey** - Instant menu access with customizable hotkey
- 📋 **Popup Menu System** -  Material Design WPF with Native Win32 menus fallback option (switch coming soon)
- 🎯 **Command Execution** - Run programs, open files, execute scripts
- 🎨 **Rich Customization** - Colors, fonts, icons, and styling
- 📂 **Nested Submenus** - Unlimited menu hierarchy
- 🔀 **Multi-Target Commands** - Execute multiple commands

#### Icon Support
- 🎨 **Material Design Icons** - 1000+ searchable native icons (`material:Home`)
- 😀 **Unicode Emojis** - 1000+ emojis across 9 categories (`emoji:🎯`)
- 📁 **File Icons** - Extract from .exe, .ico, .dll files (`file:C:\icon.ico`)
- 🔍 **Search-First Picker** - Fast icon discovery with live preview

#### Special Commands
- `EDITOR` - Open menu editor
- `TRAY` - Show tray menu  
- `SOFF` - System shutdown commands
- `RUNAS` - Run as administrator
- `WAIT` - Wait for process
- `REP` - Repeat command
- `RUN_MIN` / `RUN_MAX` - Launch with window state

#### Editor Features
- 🌲 **TreeView Editor** - Hierarchical menu structure
- 🖱️ **Drag & Drop** - Visual reordering with drop indicators
- 🎨 **Property Panel** - Context-sensitive editing
- 💾 **Auto-Save** - Changes apply instantly
- 📝 **Command Builder** - Visual command construction with help
- 🎨 **Live Preview** - See icons and colors as you edit

---

## 🏗️ Architecture

### Technology Stack

- **.NET 10** (C# 13) - Latest long-term support release
- **WPF** - Windows Presentation Foundation for UI
- **Material Design in XAML** - Modern UI components and styling
- **Win32 APIs** - Native Windows integration (hotkeys, menus, icons)
- **System.Text.Json** - Fast configuration serialization
- **MVVM Pattern** - Clean separation of concerns

### Project Structure

```
quickcliq_legacy/
├── .net/QC/                          # .NET Solution
│   ├── QuickCliq.Core/              # Core library
│   │   ├── Config/                  # Configuration services
│   │   ├── Execution/               # Command execution
│   │   ├── Hotkeys/                 # Global hotkey system
│   │   ├── Menu/                    # Menu building & display
│   │   ├── Models/                  # Data models
│   │   ├── Services/                # Core services (Icon, Options)
│   │   └── Win32/                   # P/Invoke wrappers
│   ├── QC.net/                      # WPF Application
│   │   ├── Menu/                    # Menu implementations
│   │   ├── ViewModels/              # MVVM view models
│   │   ├── MainWindow.xaml          # Menu editor
│   │   ├── OptionsWindow.xaml       # Settings
│   │   ├── IconPickerDialog.xaml    # Icon picker
│   │   └── CommandBuilderDialog.xaml # Command builder
│   └── Data/                        # User data
│       └── qc_config.json           # Configuration file
├── ahk_legacy_src/                  # Original AutoHotkey source
│   └── Quick Cliq.ahk               # Legacy codebase
└── cursor/docs/                     # Project documentation
    ├── ROADMAP.md                   # Development roadmap
    ├── PHASE_*_TASKS.md             # Phase specifications
    └── ICON_SUPPORT_IMPLEMENTATION.md
```

### Key Services

- **IConfigService** - JSON configuration management
- **IOptionsService** - Application settings with caching
- **ICommandExecutor** - Command parsing and execution
- **IHotkeyService** - Global hotkey registration
- **IPopupMenu** - Menu display abstraction
- **MenuBuilder** - Hierarchical menu construction
- **IconResolver** - Multi-format icon handling

---

## 🚀 Getting Started

### Prerequisites

- Windows 10/11
- .NET 10 Runtime (or SDK for development)
- Visual Studio 2022 (for development)

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd quickcliq_legacy/.net/QC

# Build the solution
dotnet build QC.slnx

# Run the application
dotnet run --project QC.net
```

### First Run

1. Launch `QC.net.exe`
2. Right-click tray icon → Editor to customize menu
3. Press your hotkey (default: `ctrl+alt+z`) to open menu

### Configuration

Configuration is stored in JSON format at `.net/QC/Data/qc_config.json`

Example menu structure:
```json
{
  "version": "2.1.0",
  "menu": {
    "name": "main",
    "font": "Segoe UI",
    "fontSize": 14,
    "items": [
      {
        "name": "Notepad",
        "icon": "material:Note",
        "commands": ["notepad.exe"]
      },
      {
        "name": "Tools",
        "isMenu": true,
        "children": [
          {
            "name": "Calculator",
            "icon": "emoji:🧮",
            "commands": ["calc.exe"]
          }
        ]
      }
    ]
  }
}
```

---

## 📈 Development Phases

### Phase 1: Foundation ✅ COMPLETE
**Duration**: Initial setup  
**Focus**: Project structure, configuration, core services

#### Completed
- Solution structure (.NET 10)
- QuickCliq.Core class library  
- Configuration services (JSON)
- Options management
- Core data models

### Phase 2: Core Functionality ✅ COMPLETE
**Duration**: February 14, 2026  
**Focus**: Hotkeys, menus, command execution

#### Completed
- Global hotkey registration (Win32 API)
- Tray icon with context menu
- Native popup menu system
- Menu builder from configuration
- Command executor with special prefixes
- Multi-target commands ({N} support)
- Icon loading and display
- Menu styling (colors, fonts, bold)
- Nested submenus

### Phase 3: Editor & UI ✅ COMPLETE
**Duration**: February 14, 2026  
**Focus**: WPF editor and settings

#### Completed
- **MainWindow** (Menu Editor)
  - TreeView with hierarchical display
  - Drag-and-drop reordering
  - Properties panel
  - Add/Edit/Delete operations
  - Command list management
  - Icon picker with Material Design + Emoji support
  - Font picker with live preview
  - Color picker with inheritance
  - Auto-rebuild on save
  
- **IconPickerDialog**
  - Material Design icons (1000+, search-first)
  - Unicode emojis (1000+, 9 categories)
  - File browser (ico, png, jpg)
  - Live preview
  
- **CommandBuilderDialog**
  - Visual command construction
  - Help for special commands
  - Variable expansion hints
  

### Phase 4: Plugin System & Advanced Features 🔄 NEXT UP

**New Direction**: Instead of hardcoding advanced features, Phase 4 will focus on building a **plugin architecture** that allows features to be added modularly.

#### Planned Plugin System
- 🔌 **Plugin API** - Interface-based plugin system
- 📦 **Plugin Discovery** - Dynamic loading from plugins folder
- 🔄 **Plugin Lifecycle** - Initialize, activate, deactivate, dispose
- 🎛️ **Plugin Configuration** - Per-plugin settings in UI
- 🔗 **Plugin Dependencies** - Declare and resolve dependencies
- 📋 **Plugin Manifest** - Metadata (name, version, author, description)

#### Plugins to Implement
- 📋 **Clips Plugin** - Clipboard manager with history
- 🪟 **Wins Plugin** - Window switcher and manager
- 📝 **Memos Plugin** - Quick notes system
- ⏱️ **Recent Plugin** - Recently executed commands
- 📁 **FolderMenu Plugin** - Dynamic folder browsing
- 🔗 **S-Menu Plugin** - External menu loading

Each plugin will be self-contained and optional, following the plugin API contract.

### Phase 5: Polish & Distribution 📋 PLANNED

#### Planned Features
- 🖱️ **Mouse Gestures** - Pattern recognition and actions
- ⌨️ **Custom Hotkeys** - Per-item hotkey mapping
- 🎨 **Advanced Theming** - Dark mode, custom themes
- 🔄 **Auto-Update** - Check and install updates
- 📊 **Logging & Diagnostics** - Debug and performance monitoring
- 🧪 **Testing Suite** - Unit and integration tests
- 📦 **Installer** - Professional deployment package
- 📚 **Documentation** - User guide and API docs

---

## 🗺️ Roadmap

### Immediate Next Steps (Phase 4)

1. **Design Plugin API**
   - Define `IPlugin` interface
   - Create plugin lifecycle contracts
   - Design plugin manifest format
   - Implement plugin loader

2. **Build Core Plugins**
   - Clips (clipboard manager)
   - Wins (window manager)  
   - Memos (quick notes)
   - Recent (command history)

3. **Plugin Management UI**
   - Plugin list in Options window
   - Enable/disable plugins
   - Plugin settings pages
   - Plugin installation/removal

---

## 🔄 Original AHK Version

The original Quick Cliq was written in AutoHotkey and served thousands of users for years. The legacy source code is preserved in `ahk_legacy_src/` for reference. Original was written by myself and my old friend from Russia, Pavel. After I became a parent I handed everything to him where he kept it alive for sometime, however he has since let the site (apathysoftworks.com) go dormant and the domain parked. I'm actually not sure what happened to him - Pavel, if you're still around please reach out!! After 13 years it's time to get this running the way we originally envisioned it - I believe it still has massive viability for Windows power users :)

### Key Files
- `Quick Cliq.ahk` - Main entry point
- `lib/` - Library modules (PUM, Config, Commands, etc.)
- `Data/` - User data and configuration

---

## 🤝 Contributing

This is currently a personal rewrite project, but contributions and suggestions are welcome!

### Development Setup

1. Clone the repository
2. Open `.net/QC/QC.slnx` in Visual Studio 2022
3. Build solution (Ctrl+Shift+B)
4. Run QC.net project (F5)

### Code Style
- Follow C# naming conventions
- Use MVVM pattern for WPF code
- Keep services interface-based
- Document public APIs with XML comments
- Write clean, testable code

### Submitting Changes
1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit pull request with description

