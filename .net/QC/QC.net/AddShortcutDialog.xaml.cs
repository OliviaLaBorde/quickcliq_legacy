using System.Windows;
using QuickCliq.Core;
using QuickCliq.Core.Config;

namespace QC.net;

public partial class AddShortcutDialog : Window
{
    private readonly IConfigService _configService;
    public QuickCliq.Core.Models.MenuItem? NewItem { get; private set; }
    
    public AddShortcutDialog(IConfigService configService)
    {
        InitializeComponent();
        _configService = configService;
        
        // Focus the name textbox
        Loaded += (s, e) => txtName.Focus();
    }
    
    private void Browse_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select File or Executable",
            Filter = "All files (*.*)|*.*|Executable files (*.exe)|*.exe|Links (*.lnk)|*.lnk"
        };
        
        if (dialog.ShowDialog() == true)
        {
            txtCommand.Text = dialog.FileName;
            
            // Auto-fill name if empty
            if (string.IsNullOrWhiteSpace(txtName.Text))
            {
                txtName.Text = System.IO.Path.GetFileNameWithoutExtension(dialog.FileName);
            }
        }
    }
    
    private void OK_Click(object sender, RoutedEventArgs e)
    {
        var name = txtName.Text.Trim();
        var command = txtCommand.Text.Trim();
        
        if (string.IsNullOrWhiteSpace(name))
        {
            System.Windows.MessageBox.Show("Please enter a name.", AppConstants.AppName, 
                MessageBoxButton.OK, MessageBoxImage.Warning);
            txtName.Focus();
            return;
        }
        
        if (string.IsNullOrWhiteSpace(command))
        {
            System.Windows.MessageBox.Show("Please enter a command or path.", AppConstants.AppName, 
                MessageBoxButton.OK, MessageBoxImage.Warning);
            txtCommand.Focus();
            return;
        }
        
        // Create new menu item
        NewItem = new QuickCliq.Core.Models.MenuItem
        {
            Id = _configService.NextId(),
            Name = name,
            Icon = DetermineIcon(command),
            Commands = new List<string> { command }
        };
        
        DialogResult = true;
        Close();
    }
    
    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
    
    private string? DetermineIcon(string command)
    {
        // If it's a file path that exists, use it as icon
        if (System.IO.File.Exists(command) && 
            (command.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) ||
             command.EndsWith(".lnk", StringComparison.OrdinalIgnoreCase)))
        {
            return command;
        }
        
        // If it's just an executable name, use it
        if (!command.Contains('\\') && !command.Contains('/') && 
            command.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
        {
            return command;
        }
        
        return null;
    }
}
