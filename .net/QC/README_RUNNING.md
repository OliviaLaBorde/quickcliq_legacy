# Quick Cliq .NET - How to Run

## 📝 Config Location
**Edit this file** to customize your menu and hotkey:
```
c:\dev\quickcliq_legacy\.net\QC\Data\qc_config.json
```

---

## 🔨 Build & Run

### Step 1: Build (do this after code changes)
```batch
c:\dev\quickcliq_legacy\.net\QC\build_qc.bat
```
Or from VS: Build Solution (Ctrl+Shift+B)

### Step 2: Run
```batch
c:\dev\quickcliq_legacy\.net\QC\run_qc.bat
```
Or from VS: Start (F5) with QC.net as startup project

---

## ✅ What Should Work

### Tray Icon
- **Left-click** → Main launcher menu (Notepad, Calculator, etc.)
- **Right-click** → App menu (Exit, Options, etc.)

### Hotkey
- **Ctrl+Alt+Z** → Main launcher menu

### Console Output
You should see:
```
>>> Window Loaded event fired! Registering hotkeys...
Window handle: 123456
✓ Hotkey registered successfully: Ctrl+Alt+Z
```

---

## 🐛 If It Doesn't Work

### Hotkey Not Working
- Check console for "✓ Hotkey registered successfully"
- If it says "FAILED to register hotkey" - another app is using Ctrl+Alt+Z
- Try changing the hotkey in `Data\qc_config.json`:
  ```json
  "settings": {
    "main_hotkey": "^!Q"  // Ctrl+Alt+Q instead
  }
  ```

### Tray Icon Not Responding
- Kill all QC.net processes in Task Manager
- Rebuild: `build_qc.bat`
- Run: `run_qc.bat`

### Menu Not Showing
- Left-click should show your menu (Notepad, Calculator)
- Right-click shows app menu (Exit, Options)
- Check console for "Tray icon LEFT clicked"

---

## 🎯 Testing Checklist

1. ✅ Build succeeds (0 errors)
2. ✅ Tray icon appears
3. ✅ Console shows "✓ Hotkey registered successfully"
4. ✅ **LEFT-click tray** → Launcher menu appears
5. ✅ **RIGHT-click tray** → App menu appears (Exit, Options)
6. ✅ **Ctrl+Alt+Z** → Launcher menu appears

---

## 📁 Files

- `build_qc.bat` - Build the solution
- `run_qc.bat` - Run the app (must build first!)
- `Data\qc_config.json` - Your editable config
- `QC.slnx` - VS solution (Data folder now visible)

---

## 🔧 Rebuild After Changes

If you modify code:
1. Close the running app
2. Run `build_qc.bat`
3. Run `run_qc.bat`

Or just use Visual Studio's Build & Run (F5)!
