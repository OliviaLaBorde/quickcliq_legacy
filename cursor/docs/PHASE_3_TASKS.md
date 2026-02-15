# Phase 3: Editor & UI — IN PROGRESS 🚧

## Overview
Build the WPF user interface for editing menus, items, and options.

---

## Tasks

### 1. Main Window (Menu Editor) ✅ COMPLETE
- [x] MainWindow.xaml layout (TreeView + toolbar + preview)
- [x] MenuTreeViewModel for MVVM binding
- [x] TreeView item templates with icons
- [x] **Drag-and-drop reordering with visual feedback** (DONE!)
- [x] **Drop into submenus and between items** (DONE!)
- [x] Add/Delete/Edit buttons in toolbar
- [x] **Add Shortcut dialog** with Browse button (DONE!)
- [x] Context menu on tree items (right-click) - using toolbar buttons instead
- [x] Selection to edit item (properties panel)
- [x] **Move Up/Down buttons** as backup to drag-drop (DONE!)
- [x] Wire up "Open Editor" tray menu item
- [x] SetMenu() method in IConfigService
- [x] **Save functionality with recursive conversion** (DONE!)
- [x] **Proper deletion from nested collections** (DONE!)
- [x] **Icon file picker** (DONE!)
- [x] **Add to selected submenu** when submenu is selected (DONE!)
- [x] **Toast notifications instead of MessageBox** (DONE!)
- [x] **Dialog positioning centered on editor** (DONE!)
- [x] **Fixed nested menu execution bug** (static dictionaries) (DONE!)
- [x] **Explicit isMenu property** for empty menus (DONE!)

### 2. Item Editor Dialog ✅ COMPLETE (Redesigned)
- [x] Enhanced properties panel in MainWindow (instead of separate dialog)
- [x] Name, Command(s) input fields
- [x] Icon picker button
- [x] **Color pickers with visual preview boxes** (DONE!)
- [x] **Color picker buttons open ColorPickerDialog** (DONE!)
- [x] **Live color preview as you type hex** (DONE!)
- [x] Bold checkbox
- [x] IsMenu checkbox for submenus
- [x] Apply Changes button with validation
- [x] ColorPickerDialog with RGB sliders
- [x] Common colors palette (16 colors)
- [x] **Bug fix: NullReferenceException in color picker** (DONE!)
- [x] **Design improvement: Single editing location** (DONE!)
- ~~Separate ItemEditorWindow~~ (removed - redundant)

### 3. Icon Picker Dialog
- [ ] IconPickerWindow.xaml layout
- [ ] File browser for ICL/EXE/DLL
- [ ] Icon extraction and preview grid
- [ ] Icon index selector
- [ ] Recent icons list
- [ ] Search/filter functionality
- [ ] OK/Cancel buttons

### 4. Options Window ✅ COMPLETE
- [x] OptionsWindow.xaml with TabControl
- [x] Tab: General (editor item, tray icon, command delay, startup)
- [x] Tab: Appearance (icon size, light menu, icons only, height adjust, font)
- [x] Tab: Hotkeys (main hotkey, suspend)
- [x] Tab: Features (Clips, Wins, Memos, Recent enable/submenu)
- [x] Tab: About (version info)
- [x] Apply/OK/Cancel buttons
- [x] Load and save all settings via IOptionsService
- [x] Wire up tray icon Options menu item
- [x] Apply changes immediately (rebuild menus)

### 5. Menu Styling (Owner-Drawn) 🎨 STRETCH GOAL
- [ ] Research owner-drawn menu approach
- [ ] Implement WM_MEASUREITEM handler
- [ ] Implement WM_DRAWITEM handler
- [ ] Custom GDI+ rendering (colors, fonts, icons)
- [ ] OR: Custom WPF overlay menu (no Win32)

---

## Current Status

**Phase**: 3 of 5  
**Focus**: Editor & UI ✅ **NEARLY COMPLETE!**  
**Started**: 2026-02-14
**Completed Core Features**: 2026-02-14

All essential Phase 3 features are now complete:
- ✅ Main Window (Menu Editor) with drag-drop, toast notifications
- ✅ Options Window with 5 tabs (General, Appearance, Hotkeys, Features, About)
- ✅ Toast notifications instead of MessageBox interruptions
- ✅ All dialog positioning and nested menu bugs fixed
- ⏭️ Item Editor Dialog (skipped - properties panel is sufficient)
- ⏭️ Icon Picker Dialog (deferred - simple file picker works)
- ✅ **WPF Menu with Material Design** - Hotkey menus now use WPF with full styling support!

---

## Phase 3 Goals

By the end of Phase 3, users should be able to:
- ✅ Open the editor from tray icon
- ✅ See their menu structure in a tree view
- ✅ Add/edit/delete menu items
- ✅ Drag-and-drop to reorder items
- ✅ Choose icons for items
- ✅ Configure all application options
- ✅ Changes save to config and rebuild menu

---

## Technical Approach

### MVVM Architecture
- ViewModels for TreeView items with `INotifyPropertyChanged`
- Commands for toolbar buttons
- Data binding for live updates

### WPF Controls
- `TreeView` with `HierarchicalDataTemplate` for menu structure
- `StackPanel`/`Grid` layouts for forms
- `Button`, `TextBox`, `CheckBox`, `ComboBox` for inputs
- `ColorPicker` (custom or 3rd party)
- `TabControl` for Options window

### Drag-Drop
- Handle `TreeViewItem.DragOver`, `Drop` events
- Update config order on drop
- Rebuild menu after changes

---

## Next Steps
1. Create MainWindow.xaml with basic layout
2. Implement MenuTreeViewModel
3. Wire up "Open Editor" tray menu item
4. Test opening the editor and viewing menu tree
