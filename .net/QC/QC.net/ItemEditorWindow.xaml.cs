using System.Windows;
using System.Windows.Media;
using QuickCliq.Core.Models;

namespace QC.net;

public partial class ItemEditorWindow : Window
{
    private QuickCliq.Core.Models.MenuItem _item;
    private bool _isNewItem;
    
    public QuickCliq.Core.Models.MenuItem? EditedItem { get; private set; }
    
    // Constructor for editing existing item
    public ItemEditorWindow(QuickCliq.Core.Models.MenuItem item)
    {
        InitializeComponent();
        _item = item;
        _isNewItem = false;
        
        Title = "Edit Menu Item - Quick Cliq";
        LoadItem(item);
    }
    
    // Constructor for creating new item
    public ItemEditorWindow()
    {
        InitializeComponent();
        _item = new QuickCliq.Core.Models.MenuItem();
        _isNewItem = true;
        
        Title = "Add Menu Item - Quick Cliq";
        
        // Set defaults
        txtName.Text = "New Item";
        txtCommands.Text = "";
        txtIcon.Text = "";
        chkBold.IsChecked = false;
        chkIsMenu.IsChecked = false;
        txtTextColor.Text = "";
        txtBgColor.Text = "";
        
        UpdateColorPreviews();
    }
    
    private void LoadItem(QuickCliq.Core.Models.MenuItem item)
    {
        txtName.Text = item.Name ?? "";
        txtCommands.Text = item.Commands != null ? string.Join("\n", item.Commands) : "";
        txtIcon.Text = item.Icon ?? "";
        chkBold.IsChecked = item.Bold;
        chkIsMenu.IsChecked = item.IsMenu;
        
        // Convert color integers to hex strings
        txtTextColor.Text = item.TextColor > 0 ? $"0x{item.TextColor:X6}" : "";
        txtBgColor.Text = item.BgColor > 0 ? $"0x{item.BgColor:X6}" : "";
        
        UpdateColorPreviews();
    }
    
    private void BrowseIcon_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select Icon File",
            Filter = "Icon Files|*.ico;*.exe;*.dll;*.icl|All Files|*.*",
            CheckFileExists = true
        };
        
        if (dialog.ShowDialog() == true)
        {
            txtIcon.Text = dialog.FileName;
        }
    }
    
    private void PickIcon_Click(object sender, RoutedEventArgs e)
    {
        // TODO: Open IconPickerWindow when implemented
        System.Windows.MessageBox.Show(
            "Advanced icon picker coming soon!\n\nFor now, use Browse to select an icon file, or enter a path manually.",
            "Icon Picker",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }
    
    private void TextColor_Click(object sender, RoutedEventArgs e)
    {
        var color = PickColor(ParseHexColor(txtTextColor.Text));
        if (color.HasValue)
        {
            txtTextColor.Text = $"0x{color.Value.R:X2}{color.Value.G:X2}{color.Value.B:X2}";
        }
    }
    
    private void BgColor_Click(object sender, RoutedEventArgs e)
    {
        var color = PickColor(ParseHexColor(txtBgColor.Text));
        if (color.HasValue)
        {
            txtBgColor.Text = $"0x{color.Value.R:X2}{color.Value.G:X2}{color.Value.B:X2}";
        }
    }
    
    private System.Windows.Media.Color? PickColor(System.Windows.Media.Color initialColor)
    {
        var dialog = new ColorPickerDialog(initialColor)
        {
            Owner = this
        };
        
        if (dialog.ShowDialog() == true)
        {
            return dialog.SelectedColor;
        }
        
        return null;
    }
    
    private System.Windows.Media.Color ParseHexColor(string hex)
    {
        if (string.IsNullOrWhiteSpace(hex))
            return Colors.White;
        
        try
        {
            // Remove 0x prefix if present
            hex = hex.Trim().Replace("0x", "").Replace("#", "");
            
            if (hex.Length == 6)
            {
                byte r = Convert.ToByte(hex.Substring(0, 2), 16);
                byte g = Convert.ToByte(hex.Substring(2, 2), 16);
                byte b = Convert.ToByte(hex.Substring(4, 2), 16);
                return System.Windows.Media.Color.FromRgb(r, g, b);
            }
        }
        catch { }
        
        return Colors.White;
    }
    
    private void TextColor_Changed(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        UpdateColorPreviews();
    }
    
    private void BgColor_Changed(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        UpdateColorPreviews();
    }
    
    private void UpdateColorPreviews()
    {
        // Update text color preview
        var textColor = ParseHexColor(txtTextColor.Text);
        previewTextColor.Background = new SolidColorBrush(textColor);
        
        // Update bg color preview
        var bgColor = ParseHexColor(txtBgColor.Text);
        previewBgColor.Background = new SolidColorBrush(bgColor);
    }
    
    private void IsMenu_Changed(object sender, RoutedEventArgs e)
    {
        // When IsMenu is checked, disable commands field
        bool isMenu = chkIsMenu.IsChecked ?? false;
        txtCommands.IsEnabled = !isMenu;
        
        if (isMenu)
        {
            txtCommands.Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(240, 240, 240));
        }
        else
        {
            txtCommands.Background = System.Windows.Media.Brushes.White;
        }
    }
    
    private void OK_Click(object sender, RoutedEventArgs e)
    {
        // Validate
        if (string.IsNullOrWhiteSpace(txtName.Text))
        {
            System.Windows.MessageBox.Show(
                "Please enter a name for the menu item.",
                "Validation Error",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            txtName.Focus();
            return;
        }
        
        bool isMenu = chkIsMenu.IsChecked ?? false;
        
        // If not a menu, validate commands
        if (!isMenu && string.IsNullOrWhiteSpace(txtCommands.Text) && !txtName.Text.StartsWith("---"))
        {
            var result = System.Windows.MessageBox.Show(
                "This item has no commands. It will be disabled in the menu.\n\nContinue?",
                "No Commands",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);
            
            if (result == MessageBoxResult.No)
            {
                txtCommands.Focus();
                return;
            }
        }
        
        // Create edited item
        EditedItem = new QuickCliq.Core.Models.MenuItem
        {
            Id = _item.Id,
            Name = txtName.Text.Trim(),
            Commands = isMenu ? new List<string>() : ParseCommands(txtCommands.Text),
            Icon = string.IsNullOrWhiteSpace(txtIcon.Text) ? null : txtIcon.Text.Trim(),
            Bold = chkBold.IsChecked ?? false,
            IsMenu = isMenu,
            TextColor = ParseColorInt(txtTextColor.Text),
            BgColor = ParseColorInt(txtBgColor.Text),
            Children = _item.Children ?? new List<QuickCliq.Core.Models.MenuItem>() // Preserve children if editing
        };
        
        DialogResult = true;
        Close();
    }
    
    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
    
    private List<string> ParseCommands(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            return new List<string>();
        
        return text.Split('\n')
            .Select(line => line.Trim())
            .Where(line => !string.IsNullOrEmpty(line))
            .ToList();
    }
    
    private int ParseColorInt(string hex)
    {
        if (string.IsNullOrWhiteSpace(hex))
            return 0;
        
        try
        {
            hex = hex.Trim().Replace("0x", "").Replace("#", "");
            
            if (hex.Length == 6)
            {
                return Convert.ToInt32(hex, 16);
            }
        }
        catch { }
        
        return 0;
    }
}
