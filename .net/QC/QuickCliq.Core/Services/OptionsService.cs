using System.ComponentModel;
using System.Runtime.CompilerServices;
using QuickCliq.Core.Config;

namespace QuickCliq.Core.Services;

/// <summary>
/// Options service with typed access and defaults
/// All option names from legacy OptSets.ahk
/// </summary>
public class OptionsService : IOptionsService, INotifyPropertyChanged
{
    private readonly IConfigService _config;
    private readonly Dictionary<string, object> _cache = new();
    private readonly Dictionary<string, object> _defaults;

    public event PropertyChangedEventHandler? PropertyChanged;

    public OptionsService(IConfigService config)
    {
        _config = config;
        _defaults = InitializeDefaults();
    }

    public T Get<T>(string name)
    {
        name = name.ToLowerInvariant();
        
        // Check cache first
        if (_cache.TryGetValue(name, out var cached))
            return ConvertValue<T>(cached);
        
        // Check config
        var (value, exists) = _config.GetOpt(name);
        if (exists && value != null)
        {
            var converted = ConvertValue<T>(value);
            _cache[name] = converted!;
            return converted;
        }
        
        // Return default
        if (_defaults.TryGetValue(name, out var defaultValue))
        {
            var converted = ConvertValue<T>(defaultValue);
            _cache[name] = converted!;
            return converted;
        }
        
        return default!;
    }

    public void Set<T>(string name, T value)
    {
        name = name.ToLowerInvariant();
        _cache[name] = value!;
        _config.SetOpt(name, value!);
        OnPropertyChanged(name);
    }

    public bool Exists(string name)
    {
        name = name.ToLowerInvariant();
        var (_, exists) = _config.GetOpt(name);
        return exists;
    }

    public void Reset(string name)
    {
        name = name.ToLowerInvariant();
        _cache.Remove(name);
        _config.DelOpt(name);
        OnPropertyChanged(name);
    }

    public void ResetAll()
    {
        _cache.Clear();
        foreach (var key in _defaults.Keys)
        {
            _config.DelOpt(key);
        }
    }
    
    /// <summary>
    /// Clear the cache to force reload from config
    /// Call this after config changes to ensure fresh values are read
    /// </summary>
    public void ClearCache()
    {
        _cache.Clear();
        OnPropertyChanged(string.Empty); // Notify all properties changed
    }

    private T ConvertValue<T>(object value)
    {
        if (value is T typed)
            return typed;
        
        var targetType = typeof(T);
        
        // Handle nullable types
        var underlyingType = Nullable.GetUnderlyingType(targetType);
        if (underlyingType != null)
            targetType = underlyingType;
        
        // Handle enums
        if (targetType.IsEnum)
            return (T)Enum.Parse(targetType, value.ToString()!);
        
        // Handle booleans from int (legacy XML stored as 0/1)
        if (targetType == typeof(bool) && value is int intVal)
            return (T)(object)(intVal != 0);
        
        // Handle System.Text.Json.JsonElement
        if (value.GetType().Name == "JsonElement")
        {
            var jsonElement = (System.Text.Json.JsonElement)value;
            return System.Text.Json.JsonSerializer.Deserialize<T>(jsonElement.GetRawText())!;
        }
        
        return (T)Convert.ChangeType(value, targetType);
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    /// <summary>
    /// Initialize all default option values from legacy OptSets.ahk
    /// </summary>
    private Dictionary<string, object> InitializeDefaults()
    {
        return new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase)
        {
            // Appearance
            ["aprns_iconssize"] = 16,
            ["aprns_iconstlp"] = true,
            ["aprns_lightmenu"] = false,
            ["aprns_heightadjust"] = 0,
            ["aprns_iconsonly"] = false,
            ["aprns_columns"] = false,
            ["aprns_col_mode"] = 1,
            ["aprns_colbar"] = false,
            ["aprns_colnum"] = 2,
            ["aprns_numpercol"] = 10,
            ["aprns_transp"] = 255,
            ["aprns_tform"] = 0,
            ["aprns_mainfont"] = "",
            ["aprns_fontsize"] = 10,
            ["aprns_fontqlty"] = 5,
            ["aprns_framewidth"] = 1,
            ["aprns_frameselmode"] = false,
            
            // Recent
            ["recent_logqc"] = true,
            ["recent_gesture"] = "UR",
            ["recent_hotkey"] = "#Q",
            ["recent_maxitems"] = 7,
            ["recent_logwinri"] = false,
            ["recent_logprocs"] = false,
            ["recent_logfolders"] = false,
            ["recent_on"] = true,
            ["recent_sub"] = true,
            ["recent_geston"] = true,
            
            // Main
            ["main_props_hidden"] = true,
            ["main_cmd_lvview"] = 1,
            ["main_pos"] = "",
            ["main_tv_defcolors"] = false,
            ["main_gesture"] = "D",
            ["main_hotkey"] = "#Z",
            ["main_geston"] = true,
            ["main_ctrlrbhkey"] = false,
            ["main_ctrlmbhkey"] = false,
            ["main_ctrllrbhkey"] = false,
            ["main_tv_glfont"] = true,
            ["main_tv_fontsize"] = 10,
            
            // Feedback
            ["fb_username"] = "",
            ["fb_useremail"] = "",
            
            // General
            ["gen_runonstartup"] = false,
            ["gen_contextqc"] = false,
            ["gen_notheme"] = false,
            ["gen_suspendsub"] = true,
            ["gen_helpsub"] = true,
            ["gen_cmddelay"] = 200,
            ["gen_autoupd"] = true,
            ["gen_trayicon"] = true,
            ["gen_smenuson"] = false,
            ["gen_editoritem"] = true,
            ["gen_iconrelpath"] = false,
            ["gen_cmdrelpath"] = false,
            ["gen_copy_method"] = 1,
            ["gen_paste_method"] = 1,
            ["gen_mnem_method"] = "run",
            ["gen_donated"] = false,
            
            // Clips
            ["clips_copyhk"] = "^",
            ["clips_appendhk"] = "#^",
            ["clips_pastehk"] = "!",
            ["clips_gesture"] = "U",
            ["clips_hotkey"] = "#X",
            ["clips_saveonexit"] = true,
            ["clips_on"] = true,
            ["clips_sub"] = true,
            ["clips_geston"] = true,
            
            // Gestures
            ["gest_curbut"] = "rbutton",
            ["gest_tempnotify"] = true,
            ["gest_glbon"] = true,
            ["gest_time"] = 10000,
            ["gest_butmods"] = "",
            ["gest_win_excl"] = new List<string>(),
            ["gest_win_excl_on"] = false,
            
            // Settings
            ["settings_ct"] = "",
            ["hkey_glbon"] = true,
            
            // Memos
            ["memos_gesture"] = "L",
            ["memos_hotkey"] = "#A",
            ["memos_on"] = true,
            ["memos_sub"] = true,
            ["memos_geston"] = true,
            ["memos_delconf"] = false,
            ["otm_bg_default_color"] = "",
            ["otm_t_default_color"] = "",
            ["otm_default_font"] = "",
            
            // Windows
            ["wins_hotkey"] = "#C",
            ["wins_gesture"] = "R",
            ["wins_wndhidehkey"] = "^Space",
            ["wins_on"] = true,
            ["wins_sub"] = true,
            ["wins_geston"] = true,
            ["wins_viewtransp"] = 150,
            ["wins_fade"] = true,
            
            // Folder Menu
            ["fm_refresh_on"] = true,
            ["fm_refresh_time"] = 15,
            ["fm_show_open_item"] = true,
            ["fm_extractexe"] = false,
            ["fm_showicons"] = true,
            ["fm_show_files_ext"] = true,
            ["fm_iconssize"] = "global",
            ["fm_files_first"] = false,
            ["fm_show_lnk"] = false,
            ["fm_sort_type"] = "Name",
            ["fm_sort_mode"] = "Asc"
        };
    }
}
