# Phase 4: Advanced Features — NOT STARTED 📋

## Overview
Implement advanced features: Clips (clipboard manager), Wins (window manager), Memos (quick notes), Recent items, and Folder Menus.

---

## Tasks

### 1. Clips (Clipboard Manager) 🔲
- [ ] ClipsService to monitor clipboard changes
- [ ] Store clipboard history (text, files, images)
- [ ] Dynamic submenu generation for clip items
- [ ] Hotkey to open Clips menu (#X)
- [ ] Click to paste clip
- [ ] Ctrl+Click to copy to clipboard
- [ ] Save clips on exit
- [ ] Load clips on startup
- [ ] Max clips limit (configurable)
- [ ] Clip icon handling
- [ ] Custom clips (clips 1-9 with names)

### 2. Wins (Window Manager) 🔲
- [ ] WinsService to enumerate open windows
- [ ] Filter windows (visible, has title, not toolwindow)
- [ ] Group by process name
- [ ] Dynamic submenu generation
- [ ] Click to activate window
- [ ] Hotkey to open Wins menu (#C)
- [ ] Window actions (Close, Minimize, Maximize, Always on Top)
- [ ] Right-click context menu
- [ ] Window icons from process

### 3. Memos (Quick Notes) 🔲
- [ ] MemosService for memo storage
- [ ] Memo data structure (title, content, timestamp)
- [ ] Dynamic submenu generation
- [ ] Hotkey to open Memos menu (#A)
- [ ] Click to edit memo
- [ ] Add/Edit/Delete memo UI
- [ ] Persist memos to file
- [ ] Load memos on startup

### 4. Recent Items 🔲
- [ ] RecentService to track executed commands
- [ ] Store recent items with timestamp
- [ ] Dynamic submenu generation
- [ ] Max recent limit (configurable)
- [ ] Click to re-execute
- [ ] Clear recent list
- [ ] Persist to file
- [ ] Load on startup

### 5. Folder Menus (FM) 🔲
- [ ] Folder Menu special command parsing (FOLDER:)
- [ ] Enumerate files/folders in directory
- [ ] Sort options (Name, Date, Size, Asc/Desc)
- [ ] File icons from shell
- [ ] Show Open item (opens folder in Explorer)
- [ ] Filter by extension
- [ ] Files first vs folders first
- [ ] Recursive submenu for subdirectories
- [ ] Click to open file/folder

### 6. S-Menus (External Menus) 🔲
- [ ] S-Menu special command parsing (SMENU:)
- [ ] Load menu from external config file
- [ ] Merge external menu into main menu
- [ ] Relative paths support
- [ ] Cache external configs
- [ ] Reload on file change (optional)

---

## Current Status

**Phase**: 4 of 5  
**Focus**: Advanced features (Clips, Wins, Memos, Recent, Folder Menus)  
**Not Started**: Waiting for Phase 3 completion

---

## Phase 4 Goals

By the end of Phase 4, users should be able to:
- Access clipboard history through Clips
- Switch windows quickly through Wins
- Store and access quick notes with Memos
- Re-run recently executed commands
- Browse and open files from folder menus
- Load external menus (S-Menus)

---

## Technical Approach

### Clipboard Monitoring
- Use `Clipboard.GetText()`, `Clipboard.GetFileDropList()`, `Clipboard.GetImage()`
- Hook clipboard changes with Win32 API (`AddClipboardFormatListener`)
- Store history in memory + persist to file

### Window Enumeration
- Use `EnumWindows` Win32 API
- Filter with `IsWindowVisible`, `GetWindowText`, `GetWindowLong`
- Group by process name using `GetWindowThreadProcessId`

### Dynamic Menu Building
- IMenuBuilder should support dynamic items
- MenuBuilder.RebuildAll() should include dynamic sources
- Each service provides `IEnumerable<MenuItem>` for their items

### Persistence
- Clips: `qc_clips.json` (text, file paths, custom clips)
- Memos: `qc_memos.json` (title, content, timestamp)
- Recent: `qc_recent.json` (command, name, icon, timestamp)

---

## Next Steps
1. Wait for Phase 3 to complete
2. Implement ClipsService with clipboard monitoring
3. Implement WinsService with window enumeration
4. Wire up dynamic menu generation in MenuBuilder
5. Test each feature independently before integration
