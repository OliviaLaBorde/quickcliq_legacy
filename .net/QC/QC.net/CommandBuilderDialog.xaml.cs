using System.IO;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;

namespace QC.net;

public partial class CommandBuilderDialog : Window
{
    public string CommandText { get; private set; } = string.Empty;
    
    public CommandBuilderDialog()
    {
        InitializeComponent();
        cmbCommandType.SelectedIndex = 0; // Default to Program/File
    }
    
    public CommandBuilderDialog(string existingCommand) : this()
    {
        ParseExistingCommand(existingCommand);
    }
    
    private void ParseExistingCommand(string command)
    {
        if (string.IsNullOrWhiteSpace(command))
            return;
            
        command = command.Trim();
        
        // Check for special commands first
        if (command.Equals("EDITOR", StringComparison.OrdinalIgnoreCase) ||
            command.StartsWith("win_", StringComparison.OrdinalIgnoreCase) ||
            command.StartsWith("killproc", StringComparison.OrdinalIgnoreCase) ||
            Regex.IsMatch(command, @"^WAIT\d+$", RegexOptions.IgnoreCase))
        {
            cmbCommandType.SelectedIndex = 3; // Special
            SelectSpecialCommand(command);
            return;
        }
        
        // Check for Change Directory (ends with ^)
        if (command.EndsWith("^"))
        {
            cmbCommandType.SelectedIndex = 4; // Change Directory
            txtChangeDir.Text = command[..^1].Trim();
            return;
        }
        
        // Check for CopyTo command
        if (command.StartsWith("copyto", StringComparison.OrdinalIgnoreCase))
        {
            cmbCommandType.SelectedIndex = 5; // Copy To
            ParseCopyToCommand(command);
            return;
        }
        
        // Check for URL
        if (command.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            command.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
            command.StartsWith("www.", StringComparison.OrdinalIgnoreCase))
        {
            cmbCommandType.SelectedIndex = 1; // URL
            txtUrl.Text = command;
            return;
        }
        
        // Check if it's a folder path (directory exists)
        if (Directory.Exists(command))
        {
            cmbCommandType.SelectedIndex = 2; // Open Folder
            txtFolderPath.Text = command;
            return;
        }
        
        // Default to Program/File
        cmbCommandType.SelectedIndex = 0;
        ParseProgramCommand(command);
    }
    
    private void ParseProgramCommand(string command)
    {
        // Check for RUNAS prefix
        if (Regex.IsMatch(command, @"^\s*RUNAS\s+", RegexOptions.IgnoreCase))
        {
            chkRunAsAdmin.IsChecked = true;
            command = Regex.Replace(command, @"^\s*RUNAS\s+", "", RegexOptions.IgnoreCase);
        }
        
        // Check for RUN_MIN
        if (Regex.IsMatch(command, @"^\s*RUN_MIN\s+", RegexOptions.IgnoreCase))
        {
            cmbWindowStyle.SelectedIndex = 1; // Minimized
            command = Regex.Replace(command, @"^\s*RUN_MIN\s+", "", RegexOptions.IgnoreCase);
        }
        // Check for RUN_MAX
        else if (Regex.IsMatch(command, @"^\s*RUN_MAX\s+", RegexOptions.IgnoreCase))
        {
            cmbWindowStyle.SelectedIndex = 2; // Maximized
            command = Regex.Replace(command, @"^\s*RUN_MAX\s+", "", RegexOptions.IgnoreCase);
        }
        
        // Split into path and arguments
        var parts = SplitCommandAndArgs(command);
        txtProgramPath.Text = parts.path;
        txtArguments.Text = parts.args;
    }
    
    private (string path, string args) SplitCommandAndArgs(string command)
    {
        // Handle quoted paths
        if (command.StartsWith("\""))
        {
            var endQuoteIndex = command.IndexOf("\"", 1);
            if (endQuoteIndex > 0)
            {
                var path = command.Substring(1, endQuoteIndex - 1);
                var args = command.Substring(endQuoteIndex + 1).Trim();
                return (path, args);
            }
        }
        
        // Try to find first space that's not in a path
        var spaceIndex = command.IndexOf(' ');
        if (spaceIndex > 0)
        {
            var path = command.Substring(0, spaceIndex);
            var args = command.Substring(spaceIndex + 1).Trim();
            
            // Check if path exists, if not, might be part of the path
            if (!File.Exists(path) && !Directory.Exists(path))
            {
                // Maybe the whole thing is the path
                if (File.Exists(command) || Directory.Exists(command))
                {
                    return (command, "");
                }
            }
            
            return (path, args);
        }
        
        return (command, "");
    }
    
    private void ParseCopyToCommand(string command)
    {
        // Parse copyto[*^] destination
        var match = Regex.Match(command, @"^copyto([*^]*)\s+(.+)$", RegexOptions.IgnoreCase);
        if (match.Success)
        {
            var modifiers = match.Groups[1].Value;
            var dest = match.Groups[2].Value;
            
            chkMove.IsChecked = modifiers.Contains('*');
            chkOverwrite.IsChecked = modifiers.Contains('^');
            txtCopyDest.Text = dest;
        }
    }
    
    private void SelectSpecialCommand(string command)
    {
        command = command.ToLowerInvariant();
        
        foreach (ComboBoxItem item in cmbSpecialCommand.Items)
        {
            if (item.Tag?.ToString()?.ToLowerInvariant() == command)
            {
                cmbSpecialCommand.SelectedItem = item;
                return;
            }
        }
    }
    
    private void CommandType_Changed(object sender, SelectionChangedEventArgs e)
    {
        // Null check - controls might not be initialized yet
        if (pnlProgram == null || pnlUrl == null || pnlOpenFolder == null || 
            pnlSpecial == null || pnlChangeDir == null || pnlCopyTo == null)
            return;
            
        // Hide all panels
        pnlProgram.Visibility = Visibility.Collapsed;
        pnlUrl.Visibility = Visibility.Collapsed;
        pnlOpenFolder.Visibility = Visibility.Collapsed;
        pnlSpecial.Visibility = Visibility.Collapsed;
        pnlChangeDir.Visibility = Visibility.Collapsed;
        pnlCopyTo.Visibility = Visibility.Collapsed;
        
        // Show selected panel
        var selected = cmbCommandType.SelectedItem as ComboBoxItem;
        switch (selected?.Tag?.ToString())
        {
            case "program":
                pnlProgram.Visibility = Visibility.Visible;
                break;
            case "url":
                pnlUrl.Visibility = Visibility.Visible;
                break;
            case "openfolder":
                pnlOpenFolder.Visibility = Visibility.Visible;
                break;
            case "special":
                pnlSpecial.Visibility = Visibility.Visible;
                break;
            case "changedir":
                pnlChangeDir.Visibility = Visibility.Visible;
                break;
            case "copyto":
                pnlCopyTo.Visibility = Visibility.Visible;
                break;
        }
        
        UpdatePreview();
    }
    
    private void Input_Changed(object sender, EventArgs e)
    {
        UpdatePreview();
    }
    
    private void UpdatePreview()
    {
        if (txtPreview == null) return;
        
        txtPreview.Text = BuildCommand();
    }
    
    private string BuildCommand()
    {
        var selected = cmbCommandType.SelectedItem as ComboBoxItem;
        var command = "";
        
        switch (selected?.Tag?.ToString())
        {
            case "program":
                command = BuildProgramCommand();
                break;
            case "url":
                command = txtUrl?.Text ?? "";
                break;
            case "openfolder":
                command = txtFolderPath?.Text ?? "";
                break;
            case "special":
                var specialItem = cmbSpecialCommand?.SelectedItem as ComboBoxItem;
                command = specialItem?.Tag?.ToString() ?? "";
                break;
            case "changedir":
                var dir = txtChangeDir?.Text ?? "";
                command = string.IsNullOrWhiteSpace(dir) ? "" : $"{dir}^";
                break;
            case "copyto":
                command = BuildCopyToCommand();
                break;
        }
        
        return command;
    }
    
    private string BuildProgramCommand()
    {
        var path = txtProgramPath?.Text ?? "";
        if (string.IsNullOrWhiteSpace(path))
            return "";
            
        var command = path;
        
        // Add arguments if present
        var args = txtArguments?.Text ?? "";
        if (!string.IsNullOrWhiteSpace(args))
        {
            // Add quotes around path if it contains spaces
            if (path.Contains(' ') && !path.StartsWith("\""))
                command = $"\"{path}\"";
            command += $" {args}";
        }
        
        // Add window style prefix if not Normal
        var windowStyle = (cmbWindowStyle?.SelectedItem as ComboBoxItem)?.Tag?.ToString();
        if (windowStyle == "minimized")
            command = $"RUN_MIN {command}";
        else if (windowStyle == "maximized")
            command = $"RUN_MAX {command}";
        
        // Add RUNAS prefix if checked
        if (chkRunAsAdmin?.IsChecked == true)
            command = $"RUNAS {command}";
        
        return command;
    }
    
    private string BuildCopyToCommand()
    {
        var dest = txtCopyDest?.Text ?? "";
        if (string.IsNullOrWhiteSpace(dest))
            return "";
            
        var modifiers = "";
        if (chkMove?.IsChecked == true)
            modifiers += "*";
        if (chkOverwrite?.IsChecked == true)
            modifiers += "^";
            
        return $"copyto{modifiers} {dest}";
    }
    
    private void BrowseProgram_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select Program or File",
            Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
        };
        
        if (dialog.ShowDialog() == true)
        {
            txtProgramPath.Text = dialog.FileName;
        }
    }
    
    private void BrowseFolder_Click(object sender, RoutedEventArgs e)
    {
        using var dialog = new System.Windows.Forms.FolderBrowserDialog
        {
            Description = "Select folder to open",
            ShowNewFolderButton = true
        };
        
        if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
        {
            txtFolderPath.Text = dialog.SelectedPath;
        }
    }
    
    private void BrowseChangeDir_Click(object sender, RoutedEventArgs e)
    {
        using var dialog = new System.Windows.Forms.FolderBrowserDialog
        {
            Description = "Select working directory",
            ShowNewFolderButton = true
        };
        
        if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
        {
            txtChangeDir.Text = dialog.SelectedPath;
        }
    }
    
    private void BrowseCopyDest_Click(object sender, RoutedEventArgs e)
    {
        using var dialog = new System.Windows.Forms.FolderBrowserDialog
        {
            Description = "Select destination folder",
            ShowNewFolderButton = true
        };
        
        if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
        {
            txtCopyDest.Text = dialog.SelectedPath;
        }
    }
    
    private void OK_Click(object sender, RoutedEventArgs e)
    {
        CommandText = BuildCommand();
        
        if (string.IsNullOrWhiteSpace(CommandText))
        {
            System.Windows.MessageBox.Show(
                "Please enter a valid command.",
                "Command Builder",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }
        
        DialogResult = true;
        Close();
    }
    
    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
