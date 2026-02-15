using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using QuickCliq.Core;
using QuickCliq.Core.Config;
using QuickCliq.Core.Execution;
using QuickCliq.Core.Hotkeys;
using QuickCliq.Core.Menu;
using QuickCliq.Core.Models;
using QuickCliq.Core.Services;
using QC.net.Services;

namespace QC.net;

/// <summary>
/// Application entry point and service container
/// </summary>
public partial class App : System.Windows.Application
{
    private IConfigService? _configService;
    private IOptionsService? _optionsService;
    private PipeServer? _pipeServer;
    private PipeMessageRouter? _messageRouter;
    private TrayIconService? _trayIcon;
    private QuickCliq.Core.Execution.ICommandExecutor? _commandExecutor;
    private IMenuBuilder? _menuBuilder;
    private IHotkeyService? _hotkeyService;
    private static IntPtr _messageWindowHandle; // Store handle for menu system
    private MainWindow? _editorWindow; // Separate variable for editor window (don't use Application.MainWindow)
    
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        
        try
        {
            // Initialize services
            InitializeServices();
            
            // Check single instance
            if (!CheckSingleInstance())
            {
                // Another instance running, send message if needed
                if (e.Args.Length > 0)
                {
                    var message = string.Join(" ", e.Args);
                    _ = PipeServer.SendMessageAsync(message);
                }
                
                Shutdown();
                return;
            }
            
            // Setup pipe message handling
            SetupPipeMessageHandling();
            
            // Setup tray icon FIRST
            SetupTrayIcon();
            
            // Create invisible WPF window for message pump and hotkey handling
            // This approach uses RegisterHotKey (not low-level hook) - safer for AV software
            var messageWindow = new Window
            {
                Width = 1,
                Height = 1,
                Left = -10000,
                Top = -10000,
                WindowStyle = WindowStyle.None,
                ShowInTaskbar = false,
                ShowActivated = false,
                Visibility = Visibility.Hidden,
                Title = "QuickCliq Message Window"
            };
            
            // CRITICAL: Hook into window's message loop BEFORE showing
            messageWindow.SourceInitialized += (s, ev) =>
            {
                var hwndSource = PresentationSource.FromVisual(messageWindow) as HwndSource;
                
                if (hwndSource != null)
                {
                    var hwnd = hwndSource.Handle;
                    _messageWindowHandle = hwnd; // Store for menu system
                    
                    // Apply WS_EX_TOOLWINDOW to hide from taskbar (best effort)
                    const int GWL_EXSTYLE = -20;
                    const int WS_EX_TOOLWINDOW = 0x00000080;
                    const int WS_EX_NOACTIVATE = 0x08000000;
                    
                    int exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
                    exStyle |= WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
                    SetWindowLong(hwnd, GWL_EXSTYLE, exStyle);
                    
                    // Add message hook for WM_HOTKEY
                    hwndSource.AddHook((IntPtr h, int msg, IntPtr wParam, IntPtr lParam, ref bool handled) =>
                    {
                        const int WM_HOTKEY = 0x0312;
                        if (msg == WM_HOTKEY)
                        {
                            int hotkeyId = wParam.ToInt32();
                            _hotkeyService?.ProcessHotkeyMessage(hotkeyId);
                            handled = true;
                        }
                        return IntPtr.Zero;
                    });
                    
                    // Register hotkeys with this window handle
                    _hotkeyService = new HotkeyService(hwnd);
                    
                    var mainHotkey = _optionsService?.Get<string>("main_hotkey");
                    if (string.IsNullOrWhiteSpace(mainHotkey))
                        mainHotkey = "^!Z"; // Default Ctrl+Alt+Z
                    
                    var registered = _hotkeyService.Register(mainHotkey, () =>
                    {
                        Dispatcher.Invoke(() => ShowMainMenu());
                    });
                    
                    if (!registered)
                    {
                        Console.WriteLine($"WARNING: Failed to register hotkey: {mainHotkey}");
                    }
                }
            };
            
            // Show the window (this starts the message pump)
            messageWindow.Show();
            
            // DON'T show main window - app runs in background!
            // User can open editor from tray icon if needed
        }
        catch (Exception ex)
        {
            System.Windows.MessageBox.Show(
                $"Failed to start {AppConstants.AppName}:\n\n{ex.Message}",
                "Startup Error",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
            Shutdown(1);
        }
    }

    private void InitializeServices()
    {
        // Config
        _configService = ConfigMigrator.LoadConfig();
        _configService.EnsureDataDirectories();
        
        // Options
        _optionsService = new OptionsService(_configService);
        
        // Path & Icon services
        var pathService = new PathService();
        var iconService = new IconService();
        
        // Command executor
        _commandExecutor = new CommandExecutor(pathService, _optionsService);
        
        // Subscribe to special command events
        _commandExecutor.EditorRequested += (s, e) =>
        {
            Dispatcher.Invoke(() => ShowMainWindow());
        };
        
        // Menu - use Material Design WPF menu with a hidden window as parent
        // Create a hidden WPF window to host the popup menus
        var menuHostWindow = new Window
        {
            Width = 0,
            Height = 0,
            WindowStyle = WindowStyle.None,
            ShowInTaskbar = false,
            Visibility = Visibility.Hidden,
            AllowsTransparency = true,
            Background = System.Windows.Media.Brushes.Transparent
        };
        menuHostWindow.Show();
        
        var menuFactory = new QC.net.Menu.MaterialDesignPopupMenuFactory(menuHostWindow);
        _menuBuilder = new MenuBuilder(_configService, _optionsService, menuFactory);
    }

    private bool CheckSingleInstance()
    {
        _pipeServer = new PipeServer();
        
        if (!_pipeServer.TryStart())
        {
            // Another instance is running
            var result = System.Windows.MessageBox.Show(
                $"Another instance of {AppConstants.AppName} is already running.\n\n" +
                "Continue anyway? Note:\n" +
                "- Hotkeys/Gestures will only work on the last instance\n" +
                "- Some features may conflict",
                $"{AppConstants.AppName} Already Running",
                MessageBoxButton.OKCancel,
                MessageBoxImage.Warning);
            
            return result == MessageBoxResult.OK;
        }
        
        return true;
    }

    private void SetupPipeMessageHandling()
    {
        if (_pipeServer == null) return;
        
        _messageRouter = new PipeMessageRouter();
        
        _messageRouter.AddShortcutRequested += (s, e) =>
        {
            Dispatcher.Invoke(() =>
            {
                // TODO: Open Add Shortcut dialog with path
                System.Windows.MessageBox.Show($"Add shortcut requested: {e.Path}", AppConstants.AppName);
            });
        };
        
        _messageRouter.SMenuRequested += (s, e) =>
        {
            Dispatcher.Invoke(() =>
            {
                // TODO: Run S-Menu
                System.Windows.MessageBox.Show($"S-Menu requested: {e.QcmPath}", AppConstants.AppName);
            });
        };
        
        _pipeServer.MessageReceived += (s, e) =>
        {
            _messageRouter.RouteMessage(e.Message);
        };
    }

    private void SetupTrayIcon()
    {
        if (_optionsService == null) return;
        
        _trayIcon = new TrayIconService();
        _trayIcon.IsVisible = _optionsService.Get<bool>("gen_trayicon");
        
        _trayIcon.IconClicked += (s, e) => ShowMainMenu();
        _trayIcon.OpenEditorClicked += (s, e) => ShowMainWindow();
        _trayIcon.OptionsClicked += (s, e) => ShowOptions();
        _trayIcon.SuspendHotkeysClicked += (s, e) => ToggleHotkeys();
        _trayIcon.ExitClicked += (s, e) => Shutdown();
    }

    private void RegisterHotkeysWithHandle(IntPtr windowHandle, Window messageWindow)
    {
        if (_optionsService == null || _menuBuilder == null) return;
        
        Console.WriteLine("Registering hotkeys...");
        
        // Add message hook to the WPF window
        var hwndSource = HwndSource.FromHwnd(windowHandle);
        hwndSource?.AddHook((IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled) =>
        {
            const int WM_HOTKEY = 0x0312;
            if (msg == WM_HOTKEY)
            {
                int hotkeyId = wParam.ToInt32();
                Console.WriteLine($">>> WM_HOTKEY received! ID={hotkeyId}");
                
                // Find and invoke the callback
                if (_hotkeyService != null)
                {
                    Dispatcher.Invoke(() => _hotkeyService.ProcessHotkeyMessage(hotkeyId));
                }
                handled = true;
            }
            return IntPtr.Zero;
        });
        
        // Initialize hotkey service
        _hotkeyService = new HotkeyService(windowHandle);
        
        // Get main hotkey from options
        var mainHotkey = _optionsService.Get<string>("main_hotkey");
        if (string.IsNullOrWhiteSpace(mainHotkey))
            mainHotkey = "#Z"; // Default Win+Z
        
        Console.WriteLine($"Attempting to register hotkey: {mainHotkey}");
        
        // Register main hotkey to show menu
        var registered = _hotkeyService.Register(mainHotkey, () =>
        {
            Console.WriteLine(">>> HOTKEY CALLBACK FIRED! Showing menu...");
            Dispatcher.Invoke(() => ShowMainMenu());
        });
        
        if (!registered)
        {
            Console.WriteLine($"FAILED to register hotkey: {mainHotkey}");
            Dispatcher.Invoke(() =>
            {
                System.Windows.MessageBox.Show(
                    $"Failed to register main hotkey: {mainHotkey}\n\n" +
                    "The hotkey might be in use by another application.",
                    AppConstants.AppName,
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);
            });
        }
        else
        {
            var displayName = _hotkeyService.ToDisplayString(mainHotkey);
            Console.WriteLine($"✓ Hotkey registered successfully: {displayName}");
        }
        
        Console.WriteLine("Hotkey setup complete!");
    }

    private void ShowMainMenu()
    {
        if (_menuBuilder == null) return;
        
        try
        {
            // Get cursor position
            GetCursorPos(out POINT pt);
            
            // Build and show menu at cursor
            var menu = _menuBuilder.GetMainMenu();
            var result = menu.Show(pt.X, pt.Y);
            
            if (result != null)
            {
                // Execute the selected menu item
                if (_configService != null && _commandExecutor != null && result.Tag is QuickCliq.Core.Models.MenuItem menuItem)
                {
                    ExecuteMenuItem(menuItem);
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR in ShowMainMenu: {ex.Message}");
            System.Windows.MessageBox.Show(
                $"Error showing menu:\n\n{ex.Message}",
                AppConstants.AppName,
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async void ExecuteMenuItem(QuickCliq.Core.Models.MenuItem menuItem)
    {
        if (_commandExecutor == null) return;
        
        try
        {
            // If it has children, it's a submenu - don't execute
            if (menuItem.Children?.Count > 0)
                return;
            
            // Skip if no commands
            if (menuItem.Commands == null || menuItem.Commands.Count == 0)
                return;
            
            // Pass commands list directly - no more string joining/splitting!
            var execParams = new QuickCliq.Core.Execution.ExecuteParams
            {
                Commands = menuItem.Commands,
                Name = menuItem.Name
            };
            
            await _commandExecutor.ExecuteAsync(execParams);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR executing menu item: {ex.Message}");
            System.Windows.MessageBox.Show(
                $"Error executing '{menuItem.Name}':\n\n{ex.Message}",
                AppConstants.AppName,
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void ShowMainWindow()
    {
        Console.WriteLine("ShowMainWindow called");
        
        if (_configService == null)
        {
            Console.WriteLine("ERROR: _configService is null");
            return;
        }
        
        try
        {
            if (_editorWindow == null)
            {
                Console.WriteLine("Creating new MainWindow...");
                _editorWindow = new MainWindow(_configService);
                
                // Subscribe to menu saved event
                _editorWindow.MenuSaved += (s, e) =>
                {
                    Console.WriteLine("Menu saved - rebuilding menus...");
                    _menuBuilder?.RebuildAll();
                    Console.WriteLine("Menu rebuilt successfully");
                };
                
                Console.WriteLine("MainWindow created successfully");
            }
            else
            {
                Console.WriteLine("MainWindow already exists (reusing)");
                // Reload the menu from config in case it changed
                _editorWindow.LoadMenuFromConfig();
            }
            
            Console.WriteLine($"MainWindow visibility: {_editorWindow.Visibility}");
            Console.WriteLine($"MainWindow state: {_editorWindow.WindowState}");
            
            Console.WriteLine("Showing MainWindow...");
            _editorWindow.Show();
            _editorWindow.Activate();
            _editorWindow.Focus();
            
            Console.WriteLine("MainWindow shown and activated");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR in ShowMainWindow: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            System.Windows.MessageBox.Show($"Error opening editor:\n\n{ex.Message}", AppConstants.AppName);
        }
    }

    private void ShowOptions()
    {
        if (_configService == null || _optionsService == null) return;
        
        var optionsWindow = new OptionsWindow(_configService, _optionsService)
        {
            Owner = _editorWindow ?? System.Windows.Application.Current.MainWindow
        };
        
        optionsWindow.OptionsChanged += (s, e) =>
        {
            Console.WriteLine("Options changed - rebuilding menus...");
            _menuBuilder?.RebuildAll();
            
            // Update tray icon visibility
            if (_trayIcon != null)
            {
                _trayIcon.IsVisible = _optionsService.Get<bool>("gen_trayicon");
            }
            
            Console.WriteLine("Options applied successfully");
        };
        
        optionsWindow.ShowDialog();
    }

    private void ToggleHotkeys()
    {
        if (_hotkeyService == null) return;
        
        // TODO: Track enabled state and toggle
        System.Windows.MessageBox.Show("Toggle hotkeys - TODO", AppConstants.AppName);
    }

    protected override void OnExit(ExitEventArgs e)
    {
        // Save config
        _configService?.Save();
        
        // Cleanup
        _hotkeyService?.Dispose();
        _pipeServer?.Dispose();
        _trayIcon?.Dispose();
        
        base.OnExit(e);
    }
    
    public static IntPtr GetMessageWindowHandle() => _messageWindowHandle;
    
    [DllImport("user32.dll")]
    private static extern bool GetCursorPos(out POINT lpPoint);
    
    [DllImport("user32.dll", SetLastError = true)]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    
    [DllImport("user32.dll", SetLastError = true)]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    
    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }
}
