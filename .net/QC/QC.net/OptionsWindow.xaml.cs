using System.Windows;
using QuickCliq.Core;
using QuickCliq.Core.Config;

namespace QC.net;

public partial class OptionsWindow : Window
{
    private readonly IConfigService _configService;
    private readonly IOptionsService _optionsService;
    
    public event EventHandler? OptionsChanged;
    
    public OptionsWindow(IConfigService configService, IOptionsService optionsService)
    {
        InitializeComponent();
        _configService = configService;
        _optionsService = optionsService;
        
        LoadOptions();
        
        txtVersion.Text = $"Version {AppConstants.Version}";
    }
    
    private void LoadOptions()
    {
        // General
        chkEditorItem.IsChecked = _optionsService.Get<bool>("gen_editoritem");
        chkTrayIcon.IsChecked = _optionsService.Get<bool>("gen_trayicon");
        txtCmdDelay.Text = _optionsService.Get<int>("gen_cmddelay").ToString();
        
        // Appearance
        txtIconSize.Text = _optionsService.Get<int>("aprns_iconssize").ToString();
        chkLightMenu.IsChecked = _optionsService.Get<bool>("aprns_lightmenu");
        chkIconsOnly.IsChecked = _optionsService.Get<bool>("aprns_iconsonly");
        txtHeightAdjust.Text = _optionsService.Get<int>("aprns_heightadjust").ToString();
        
        var font = _optionsService.Get<string>("aprns_mainfont");
        foreach (System.Windows.Controls.ComboBoxItem item in cmbFont.Items)
        {
            if (item.Content.ToString() == font)
            {
                cmbFont.SelectedItem = item;
                break;
            }
        }
        
        // Hotkeys
        txtMainHotkey.Text = _optionsService.Get<string>("main_hotkey");
        chkSuspendSub.IsChecked = _optionsService.Get<bool>("gen_suspendsub");
        
        // Features
        chkClipsOn.IsChecked = _optionsService.Get<bool>("clips_on");
        chkClipsSub.IsChecked = _optionsService.Get<bool>("clips_sub");
        chkWinsOn.IsChecked = _optionsService.Get<bool>("wins_on");
        chkWinsSub.IsChecked = _optionsService.Get<bool>("wins_sub");
        chkMemosOn.IsChecked = _optionsService.Get<bool>("memos_on");
        chkMemosSub.IsChecked = _optionsService.Get<bool>("memos_sub");
        chkRecentOn.IsChecked = _optionsService.Get<bool>("recent_on");
        chkRecentSub.IsChecked = _optionsService.Get<bool>("recent_sub");
    }
    
    private void SaveOptions()
    {
        try
        {
            // General
            _optionsService.Set("gen_editoritem", chkEditorItem.IsChecked ?? true);
            _optionsService.Set("gen_trayicon", chkTrayIcon.IsChecked ?? true);
            
            if (int.TryParse(txtCmdDelay.Text, out int cmdDelay))
                _optionsService.Set("gen_cmddelay", cmdDelay);
            
            // Appearance
            if (int.TryParse(txtIconSize.Text, out int iconSize))
                _optionsService.Set("aprns_iconssize", iconSize);
            
            _optionsService.Set("aprns_lightmenu", chkLightMenu.IsChecked ?? false);
            _optionsService.Set("aprns_iconsonly", chkIconsOnly.IsChecked ?? false);
            
            if (int.TryParse(txtHeightAdjust.Text, out int heightAdjust))
                _optionsService.Set("aprns_heightadjust", heightAdjust);
            
            if (cmbFont.SelectedItem is System.Windows.Controls.ComboBoxItem selectedFont)
                _optionsService.Set("aprns_mainfont", selectedFont.Content.ToString() ?? "Segoe UI");
            
            // Hotkeys
            _optionsService.Set("main_hotkey", txtMainHotkey.Text);
            _optionsService.Set("gen_suspendsub", chkSuspendSub.IsChecked ?? true);
            
            // Features
            _optionsService.Set("clips_on", chkClipsOn.IsChecked ?? false);
            _optionsService.Set("clips_sub", chkClipsSub.IsChecked ?? false);
            _optionsService.Set("wins_on", chkWinsOn.IsChecked ?? false);
            _optionsService.Set("wins_sub", chkWinsSub.IsChecked ?? false);
            _optionsService.Set("memos_on", chkMemosOn.IsChecked ?? false);
            _optionsService.Set("memos_sub", chkMemosSub.IsChecked ?? false);
            _optionsService.Set("recent_on", chkRecentOn.IsChecked ?? false);
            _optionsService.Set("recent_sub", chkRecentSub.IsChecked ?? false);
            
            // Save to config
            _configService.Save();
            
            // Notify app to apply changes
            OptionsChanged?.Invoke(this, EventArgs.Empty);
        }
        catch (Exception ex)
        {
            System.Windows.MessageBox.Show($"Error saving options:\n\n{ex.Message}", 
                AppConstants.AppName, MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }
    
    private void OK_Click(object sender, RoutedEventArgs e)
    {
        SaveOptions();
        Close();
    }
    
    private void Apply_Click(object sender, RoutedEventArgs e)
    {
        SaveOptions();
    }
    
    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }
}
