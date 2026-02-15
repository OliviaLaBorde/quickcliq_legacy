namespace QuickCliq.Core;

/// <summary>
/// Application-wide constants from legacy Constants.ahk
/// </summary>
public static class AppConstants
{
    public const string AppName = "Quick Cliq";
    public const string Version = "3.0.0"; // New major version for .NET rewrite
    public const string LegacyVersion = "2.1.0";
    
    // Paths
    // Use fixed project directory so config persists across Debug/Release/Publish
    public static string AppDirectory => @"c:\dev\quickcliq_legacy\.net\QC";
    public static string DataPath => Path.Combine(AppDirectory, "Data");
    public static string ConfigPath => Path.Combine(DataPath, "qc_config.json");
    public static string LegacyConfigPath => Path.Combine(DataPath, "qc_conf.xml"); // Legacy XML
    public static string MemosDir => Path.Combine(DataPath, "memos");
    public static string ClipsDir => Path.Combine(DataPath, "Clips");
    public static string UserIconsPath => Path.Combine(DataPath, "user_icons");
    public static string IconsPath => Path.Combine(DataPath, "qc_icons.icl");
    
    // IPC
    public const string PipeName = @"\\.\pipe\quickcliq";
    public const int PipeTimeout = 5000; // ms
    public const int PipeBufferSize = 1024 * 1024 * 5; // 5MB
    
    // Config
    public const string MultiTargetDivider = "{N}";
    public const string Separator = "-------------<";
    public const int MaxPath = (260 + 1) * 2;
    
    // Menu
    public const int MenuIconsOffset = 8;
    public const int BlankIconNum = 20000;
    
    // Recent
    public const int RecentMaxLimit = 30;
    public const int RecentMinLimit = 2;
    public const int RecentProcTrackInterval = 3000; // ms
    public const int RecentFolderTrackInterval = 5000; // ms
    public const int RecentWinTrackInterval = 8000; // ms
    
    // Context Menu
    public const int CtxMaxCmdLen = 33;
    public const string QcCtxName = "=> " + AppName;
    
    // Registry
    public const string SMenuRegName = "QuickCliq_S_Menu";
    public const string SMenuUpdName = "Update S-Menu";
    
    // Execution
    public const int MaxThreads = 8;
    public const int DefaultCommandDelay = 200; // ms
    
    // Font
    public const string DefaultGuiFont = "Times New Roman";
    
    // Window Messages
    public const int WM_HOTKEY = 0x0312;
    public const int WM_MDITILE = 0x0226;
    
    // Show Window Commands
    public const int SW_HIDE = 0;
    public const int SW_SHOWNORMAL = 1;
    public const int SW_SHOWMAXIMIZED = 3;
    public const int SW_SHOWMINIMIZED = 6;
    
    // Gestures
    public const int GestureMinMove = 9; // pixels
    public const int GestureMaxMoves = 3;
    
    // URLs
    public const string UrlWebHelp = "http://apathysoftworks.com/help_files/qc/";
    public const string UrlHome = "http://apathysoftworks.com/software/quickcliq";
    public const string UrlDonate = "http://apathysoftworks.com/donate";
    public const string UrlChangelog = "http://apathysoftworks.com/QC/qc_update/changelog.txt";
    public const string UrlLastVer = "http://apathysoftworks.com/QC/qc_update/last_ver.txt";
    public const string UrlUpdater = "http://apathysoftworks.com/QC/qc_update/QC_updater.exe";
}
