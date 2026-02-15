# Phase 5: Polish & Advanced — NOT STARTED 🎨

## Overview
Final polish, advanced features, testing, documentation, and stretch goals.

---

## Tasks

### 1. Gestures 🔲
- [ ] Mouse gesture detection service
- [ ] Configure gesture button (RButton, MButton, etc.)
- [ ] Gesture pattern recognition (U, D, L, R, UR, UL, DR, DL, etc.)
- [ ] Global gesture hook
- [ ] Gesture to open main menu
- [ ] Gesture to open Clips/Wins/Memos
- [ ] Visual gesture feedback
- [ ] Gesture enable/disable per window (exclusion list)

### 2. Custom Hotkeys (CHK) 🔲
- [ ] Global hotkey registration service
- [ ] Custom hotkey configuration UI
- [ ] Map hotkeys to menu items
- [ ] Hotkey conflict detection
- [ ] Hotkey enable/disable
- [ ] Persist hotkey config

### 3. CopyTo Feature 🔲
- [ ] CopyTo command parsing (copyto*, copyto^)
- [ ] Multi-file selection
- [ ] Copy to target folder
- [ ] Update working directory if ^ suffix

### 4. Advanced Command Features 🔲
- [ ] {clip} / {clip0} expansion (system clipboard)
- [ ] {clip1}..{clip9} expansion (custom clips)
- [ ] killproc command
- [ ] Environment variable expansion in paths
- [ ] Relative path resolution

### 5. Menu Styling (Owner-Drawn) 🎨 STRETCH GOAL
- [ ] Research GDI+ vs SkiaSharp approach
- [ ] Implement WM_MEASUREITEM handler
- [ ] Implement WM_DRAWITEM handler
- [ ] Custom rendering (colors, fonts, icons, gradients)
- [ ] Column breaks support
- [ ] Frame width and selection mode
- [ ] Font quality settings
- [ ] OR: Custom WPF overlay menu instead of Win32

### 6. Updates & Auto-Update 🔲
- [ ] Check for updates on startup (if enabled)
- [ ] Download updates from GitHub releases
- [ ] Apply updates and restart
- [ ] Version comparison logic
- [ ] Update UI (progress, changelog)

### 7. Logging & Diagnostics 🔲
- [ ] ILoggingService interface
- [ ] Log levels (Debug, Info, Warning, Error)
- [ ] Log to file (qc_log.txt)
- [ ] Log rotation
- [ ] View logs in UI
- [ ] Export/clear logs

### 8. Testing & Quality 🔲
- [ ] Unit tests for core services
- [ ] Integration tests for menu building
- [ ] Test command execution edge cases
- [ ] Test multi-target commands
- [ ] Test special command prefixes
- [ ] Test dynamic menu features
- [ ] Performance profiling
- [ ] Memory leak detection

### 9. Documentation 📚
- [ ] User guide (markdown)
- [ ] Command syntax reference
- [ ] Special command prefix guide
- [ ] Configuration file format docs
- [ ] Developer documentation
- [ ] Code comments and XML docs
- [ ] README with screenshots

### 10. Installer & Distribution 📦
- [ ] Create installer (WiX, Inno Setup, or MSIX)
- [ ] Registry keys for startup
- [ ] Uninstaller
- [ ] Portable mode (no install)
- [ ] GitHub release pipeline
- [ ] Auto-build on tag

---

## Current Status

**Phase**: 5 of 5  
**Focus**: Polish, advanced features, and deployment  
**Not Started**: Waiting for Phase 4 completion

---

## Phase 5 Goals

By the end of Phase 5, Quick Cliq should:
- Support mouse gestures for quick access
- Have custom hotkey mapping for any item
- Include all advanced command features
- Have polished, custom-drawn menus (stretch)
- Auto-update from GitHub releases
- Have comprehensive logging
- Be fully tested and documented
- Have an installer for distribution

---

## Technical Approach

### Gestures
- Use low-level mouse hook (`SetWindowsHookEx` with `WH_MOUSE_LL`)
- Track mouse movement deltas
- Recognize patterns (e.g., right + down = "DR")
- Configurable gesture timeout (`gest_time`)

### Custom Hotkeys
- Extend HotkeyService to support multiple hotkeys
- UI to assign hotkey to any menu item
- Store in config as `hotkey_assignments`

### Owner-Drawn Menus
- **Option 1**: Use GDI+ with WM_MEASUREITEM/WM_DRAWITEM (traditional)
- **Option 2**: Use SkiaSharp for modern rendering
- **Option 3**: Create WPF popup overlay (no Win32 menu)

### Auto-Update
- Check GitHub API for latest release
- Compare version numbers (semantic versioning)
- Download zip/msi to temp folder
- Extract and replace executable
- Restart application

### Logging
- Use `ILogger<T>` from `Microsoft.Extensions.Logging`
- File logger provider for persistence
- UI window to view logs in real-time

---

## Stretch Goals (Nice to Have)

- [ ] Dark mode for editor UI
- [ ] Icon theme support
- [ ] Custom menu skins
- [ ] Plugins/extensions API
- [ ] Scripting support (C# scripts)
- [ ] Cloud sync for config
- [ ] Multi-monitor awareness
- [ ] Touch gesture support
- [ ] Accessibility features
- [ ] Localization (i18n)

---

## Next Steps
1. Complete Phase 4 first
2. Prioritize gestures and custom hotkeys
3. Implement logging early for debugging
4. Test thoroughly before distribution
5. Create installer and release on GitHub
