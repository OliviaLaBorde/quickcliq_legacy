# Testing Quick Cliq .NET — Phase 2

## What You Should See

### ✅ When the app runs successfully:

1. **System Tray Icon**
   - Look in your system tray (bottom-right corner)
   - You should see the Quick Cliq icon
   - Right-click it for context menu:
     - Open Editor
     - Options
     - Suspend Hotkeys
     - Exit

2. **No Main Window**
   - The app runs in the background (no window by default)
   - This is by design - it's a launcher, not a regular app
   - Click the tray icon to show a menu

3. **Console Output** (if running from terminal)
   ```
   Main hotkey registered: Win+Z
   ```
   Or if Win+Z is taken:
   ```
   Failed to register hotkey #Z: Error 1409
   ```

### ❌ Known Issue: Win+Z Already Registered

**Error**: `Failed to register hotkey #Z: Error 1409`

**Why?**: Win+Z is already taken by another application (possibly Windows Snap or another app).

**Solutions**:
1. **Change the hotkey** in config (we'll add options UI soon)
2. **Close the app using Win+Z** (check task manager)
3. **Try a different hotkey** like Win+Q or Ctrl+Alt+Z

---

## How to Test Right Now

### Option 1: Test with Tray Icon
```bash
cd c:\dev\quickcliq_legacy\.net\QC
dotnet run --project QC.net\QC.net.csproj
```

**Then**:
- Look for tray icon (bottom-right)
- Click the tray icon → should show empty menu
- Right-click tray icon → context menu

### Option 2: Change Hotkey to Win+Q

Create a config file first:

**Create**: `c:\dev\quickcliq_legacy\.net\QC\QC.net\bin\Debug\net10.0-windows\Data\qc_config.json`

```json
{
  "version": "3.0.0",
  "lastId": 3,
  "menu": {
    "items": [
      {
        "id": 1,
        "name": "Notepad",
        "commands": ["notepad.exe"],
        "icon": "notepad.exe"
      },
      {
        "id": 2,
        "name": "Calculator",
        "commands": ["calc.exe"],
        "icon": "calc.exe"
      },
      {
        "id": 3,
        "name": "---",
        "isSeparator": true
      }
    ]
  },
  "settings": {
    "main_hotkey": "#Q"
  }
}
```

**Then restart the app** and press **Win+Q** → menu should appear!

---

## What's Working

✅ **App starts** without errors  
✅ **Tray icon** appears  
✅ **Single instance** enforcement  
✅ **Hotkey registration** (if available)  
✅ **Menu building** from config  
✅ **Menu display** at cursor  

---

## What's NOT Working Yet (Expected)

❌ **Menu item execution** — Clicking items does nothing (Phase 3)  
❌ **Options window** — Shows "TODO" message  
❌ **Editor window** — Not built yet (Phase 3)  
❌ **Clips/Wins/Memos** — Not implemented (Phase 4)  
❌ **Gestures** — Not implemented (Phase 4)  

---

## Quick Test: Manual Menu Trigger

If Win+Z doesn't work, you can still test by clicking the **tray icon** - it's wired to show the main menu!

---

## Troubleshooting

### "No tray icon visible"
- Check if `gen_trayicon` is true in config (default: true)
- Check system tray overflow (click ^ arrow)

### "Hotkey doesn't work"
- Error 1409 = hotkey already registered
- Try Win+Q or Ctrl+Alt+Z instead
- Check console output for the error

### "App closes immediately"
- Check console for error messages
- Make sure .NET 10 is installed

---

## Next Steps

To make it fully functional:

1. **Create a config file** with some menu items (see Option 2 above)
2. **Change hotkey to Win+Q** (or another free key)
3. **Press the hotkey** → menu appears at cursor
4. **Click an item** → see console output (execution not wired yet)

Or just **click the tray icon** to test the menu!
