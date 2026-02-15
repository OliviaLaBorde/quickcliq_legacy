using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using QuickCliq.Core;
using QuickCliq.Core.Config;

namespace QC.net;

/// <summary>
/// Menu Editor - TreeView-based interface for editing Quick Cliq menus
/// </summary>
public partial class MainWindow : Window
{
    private readonly IConfigService _configService;
    private ObservableCollection<MenuItemViewModel> _menuItems;
    private MenuItemViewModel? _selectedItem;
    
    // Event to notify app when menu is saved
    public event EventHandler? MenuSaved;
    
    // Drag-and-drop support
    private MenuItemViewModel? _draggedItem;
    private System.Windows.Point _dragStartPoint;
    private DragAdorner? _dragAdorner;
    private AdornerLayer? _adornerLayer;
    
    public MainWindow(IConfigService configService)
    {
        InitializeComponent();
        _configService = configService;
        _menuItems = new ObservableCollection<MenuItemViewModel>();
        
        LoadMenuFromConfig();
        menuTreeView.ItemsSource = _menuItems;
        
        // Setup drag-and-drop
        menuTreeView.PreviewMouseLeftButtonDown += TreeView_PreviewMouseLeftButtonDown;
        menuTreeView.PreviewMouseMove += TreeView_PreviewMouseMove;
        menuTreeView.Drop += TreeView_Drop;
        menuTreeView.DragOver += TreeView_DragOver;
        
        // Prevent window from actually closing - just hide it instead
        Closing += (s, e) =>
        {
            e.Cancel = true;
            Hide();
        };
        
        // After window is fully loaded, select the root menu item by default
        Loaded += (s, e) =>
        {
            if (_menuItems.Count > 0)
            {
                // Select the root menu item (Main Menu)
                var rootItem = _menuItems[0];
                SelectTreeViewItem(rootItem);
            }
        };
    }
    
    // Public method to refresh menu from config (called when reopening editor)
    public void LoadMenuFromConfig()
    {
        Dispatcher.Invoke(() =>
        {
            _menuItems.Clear();
            var menu = _configService.GetMenu();
            
            // Create a root node representing the menu itself
            var rootViewModel = new MenuItemViewModel(new QuickCliq.Core.Models.MenuItem
            {
                Id = menu.Id,
                Name = menu.Name,
                TextColor = menu.TextColor,
                BgColor = menu.BgColor,
                IsMenu = true // Special flag to identify this as the menu root
            })
            {
                IsRootMenu = true, // Mark as root so we can handle it specially
                IsExpanded = true // Auto-expand root menu
            };
            
            // Add all menu items as children of the root
            foreach (var item in menu.Items)
            {
                rootViewModel.Children.Add(new MenuItemViewModel(item));
            }
            
            _menuItems.Add(rootViewModel);
            
            // Clear selection and property panel
            _selectedItem = null;
            ClearPropertyPanel();
        });
    }
    
    private void SelectTreeViewItem(MenuItemViewModel item)
    {
        // Set the item as selected
        item.IsSelected = true;
        
        // The TreeView's SelectedItemChanged event will fire and call LoadItemProperties
    }
    
    #region Drag and Drop
    
    private void TreeView_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        _dragStartPoint = e.GetPosition(null);
    }
    
    private void TreeView_PreviewMouseMove(object sender, System.Windows.Input.MouseEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed && _draggedItem == null)
        {
            System.Windows.Point currentPosition = e.GetPosition(null);
            
            if (Math.Abs(currentPosition.X - _dragStartPoint.X) > SystemParameters.MinimumHorizontalDragDistance ||
                Math.Abs(currentPosition.Y - _dragStartPoint.Y) > SystemParameters.MinimumVerticalDragDistance)
            {
                var treeViewItem = FindAncestor<TreeViewItem>((DependencyObject)e.OriginalSource);
                if (treeViewItem != null)
                {
                    _draggedItem = treeViewItem.DataContext as MenuItemViewModel;
                    if (_draggedItem != null && !_draggedItem.IsRootMenu) // Prevent dragging root menu
                    {
                        // Create visual feedback adorner
                        _adornerLayer = AdornerLayer.GetAdornerLayer(menuTreeView);
                        if (_adornerLayer != null)
                        {
                            _dragAdorner = new DragAdorner(menuTreeView, _draggedItem.DisplayName);
                            _adornerLayer.Add(_dragAdorner);
                        }
                        
                        DragDrop.DoDragDrop(treeViewItem, _draggedItem, System.Windows.DragDropEffects.Move);
                        
                        // Clean up adorner
                        if (_dragAdorner != null && _adornerLayer != null)
                        {
                            _adornerLayer.Remove(_dragAdorner);
                            _dragAdorner = null;
                        }
                        
                        _draggedItem = null;
                    }
                }
            }
        }
    }
    
    private void TreeView_DragOver(object sender, System.Windows.DragEventArgs e)
    {
        if (_draggedItem != null)
        {
            e.Effects = System.Windows.DragDropEffects.Move;
            e.Handled = true;
            
            // Update adorner position
            if (_dragAdorner != null)
            {
                var position = e.GetPosition(menuTreeView);
                _dragAdorner.UpdatePosition(position.X, position.Y);
            }
        }
    }
    
    private void TreeView_Drop(object sender, System.Windows.DragEventArgs e)
    {
        if (_draggedItem == null) return;
        
        var dropPosition = e.GetPosition(menuTreeView);
        var targetTreeViewItem = GetNearestTreeViewItem(dropPosition);
        var targetViewModel = targetTreeViewItem?.DataContext as MenuItemViewModel;
        
        if (targetViewModel != null && _draggedItem != targetViewModel)
        {
            // Check if we're dropping ON a menu (to add as child) or BETWEEN items (to reorder)
            bool dropOnMenu = false;
            
            if (targetViewModel.Model.IsMenu)
            {
                // Check if we're in the middle of the item (drop into menu)
                var itemRect = GetTreeViewItemBounds(targetTreeViewItem);
                var relativeY = dropPosition.Y - itemRect.Top;
                var itemHeight = itemRect.Height;
                
                // If in middle 50% of item, drop INTO menu
                if (relativeY > itemHeight * 0.25 && relativeY < itemHeight * 0.75)
                {
                    dropOnMenu = true;
                }
            }
            
            var sourceParent = FindParent(_draggedItem);
            ObservableCollection<MenuItemViewModel> sourceCollection = sourceParent?.Children ?? _menuItems;
            
            // Remove from source
            sourceCollection.Remove(_draggedItem);
            
            if (dropOnMenu)
            {
                // Add as child of target menu
                targetViewModel.Children.Add(_draggedItem);
                targetViewModel.IsExpanded = true;
                statusText.Text = $"Moved '{_draggedItem.Name}' into '{targetViewModel.Name}'";
            }
            else
            {
                // Insert at target position (same level as target)
                var targetParent = FindParent(targetViewModel);
                ObservableCollection<MenuItemViewModel> targetCollection = targetParent?.Children ?? _menuItems;
                
                int targetIndex = targetCollection.IndexOf(targetViewModel);
                
                // Determine if dropping above or below target
                if (targetTreeViewItem != null)
                {
                    var itemRect = GetTreeViewItemBounds(targetTreeViewItem);
                    var relativeY = dropPosition.Y - itemRect.Top;
                    
                    if (relativeY > itemRect.Height / 2)
                    {
                        targetIndex++; // Drop below
                    }
                }
                
                if (targetIndex >= 0 && targetIndex <= targetCollection.Count)
                {
                    targetCollection.Insert(targetIndex, _draggedItem);
                    statusText.Text = $"Moved '{_draggedItem.Name}'";
                }
                else
                {
                    targetCollection.Add(_draggedItem);
                }
            }
        }
        
        _draggedItem = null;
    }
    
    private Rect GetTreeViewItemBounds(TreeViewItem? item)
    {
        if (item == null) return Rect.Empty;
        
        var transform = item.TransformToAncestor(menuTreeView);
        var topLeft = transform.Transform(new System.Windows.Point(0, 0));
        return new Rect(topLeft.X, topLeft.Y, item.ActualWidth, item.ActualHeight);
    }
    
    private MenuItemViewModel? FindParent(MenuItemViewModel item)
    {
        return FindParentRecursive(item, _menuItems);
    }
    
    private MenuItemViewModel? FindParentRecursive(MenuItemViewModel item, ObservableCollection<MenuItemViewModel> collection)
    {
        foreach (var potentialParent in collection)
        {
            if (potentialParent.Children.Contains(item))
                return potentialParent;
            
            var found = FindParentRecursive(item, potentialParent.Children);
            if (found != null) return found;
        }
        return null;
    }
    
    private TreeViewItem? GetNearestTreeViewItem(System.Windows.Point position)
    {
        HitTestResult hitTestResult = VisualTreeHelper.HitTest(menuTreeView, position);
        if (hitTestResult != null)
        {
            return FindAncestor<TreeViewItem>(hitTestResult.VisualHit);
        }
        return null;
    }
    
    private static T? FindAncestor<T>(DependencyObject current) where T : DependencyObject
    {
        do
        {
            if (current is T ancestor)
                return ancestor;
            current = VisualTreeHelper.GetParent(current);
        }
        while (current != null);
        return null;
    }
    
    #endregion
    
    #region Toolbar Event Handlers
    
    private void AddShortcut_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new AddShortcutDialog(_configService)
        {
            Owner = this
        };
        
        if (dialog.ShowDialog() == true && dialog.NewItem != null)
        {
            var newItem = dialog.NewItem;
            
            // Add to selected submenu or root menu's children
            if (_selectedItem != null && _selectedItem.Model.IsMenu && !_selectedItem.IsRootMenu)
            {
                _selectedItem.Children.Add(new MenuItemViewModel(newItem));
                _selectedItem.IsExpanded = true;
                statusText.Text = $"Added '{newItem.Name}' to '{_selectedItem.Name}'";
            }
            else
            {
                // Add to root menu's children (if we have a root node)
                var targetCollection = (_menuItems.Count > 0 && _menuItems[0].IsRootMenu) 
                    ? _menuItems[0].Children 
                    : _menuItems;
                targetCollection.Add(new MenuItemViewModel(newItem));
                statusText.Text = $"Added '{newItem.Name}'";
            }
        }
    }
    
    private void AddMenu_Click(object sender, RoutedEventArgs e)
    {
        var newMenu = new QuickCliq.Core.Models.MenuItem
        {
            Id = _configService.NextId(),
            Name = "New Menu",
            IsMenu = true,
            Children = new List<QuickCliq.Core.Models.MenuItem>()
        };
        
        // Add to selected submenu or root menu's children
        if (_selectedItem != null && _selectedItem.Model.IsMenu && !_selectedItem.IsRootMenu)
        {
            _selectedItem.Children.Add(new MenuItemViewModel(newMenu));
            _selectedItem.IsExpanded = true;
        }
        else
        {
            // Add to root menu's children (if we have a root node)
            var targetCollection = (_menuItems.Count > 0 && _menuItems[0].IsRootMenu) 
                ? _menuItems[0].Children 
                : _menuItems;
            targetCollection.Add(new MenuItemViewModel(newMenu));
        }
        statusText.Text = "Added new submenu";
    }
    
    private void AddSeparator_Click(object sender, RoutedEventArgs e)
    {
        var newSep = new QuickCliq.Core.Models.MenuItem
        {
            Id = _configService.NextId(),
            Name = "---",
            IsSeparator = true
        };
        
        // Add to selected submenu or root menu's children
        if (_selectedItem != null && _selectedItem.Model.IsMenu && !_selectedItem.IsRootMenu)
        {
            _selectedItem.Children.Add(new MenuItemViewModel(newSep));
        }
        else
        {
            // Add to root menu's children (if we have a root node)
            var targetCollection = (_menuItems.Count > 0 && _menuItems[0].IsRootMenu) 
                ? _menuItems[0].Children 
                : _menuItems;
            targetCollection.Add(new MenuItemViewModel(newSep));
        }
        statusText.Text = "Added separator";
    }
    
    private void MoveUp_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedItem == null) return;
        
        var parent = FindParent(_selectedItem);
        var collection = parent?.Children ?? _menuItems;
        
        int index = collection.IndexOf(_selectedItem);
        if (index > 0)
        {
            collection.Move(index, index - 1);
            statusText.Text = $"Moved '{_selectedItem.Name}' up";
        }
    }
    
    private void MoveDown_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedItem == null) return;
        
        var parent = FindParent(_selectedItem);
        var collection = parent?.Children ?? _menuItems;
        
        int index = collection.IndexOf(_selectedItem);
        if (index >= 0 && index < collection.Count - 1)
        {
            collection.Move(index, index + 1);
            statusText.Text = $"Moved '{_selectedItem.Name}' down";
        }
    }
    
    private void Delete_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedItem == null)
        {
            System.Windows.MessageBox.Show("Please select an item to delete.", AppConstants.AppName);
            return;
        }
        
        // Prevent deleting the root menu node
        if (_selectedItem.IsRootMenu)
        {
            System.Windows.MessageBox.Show("Cannot delete the main menu. You can edit its properties instead.", AppConstants.AppName);
            return;
        }
        
        var result = System.Windows.MessageBox.Show(
            $"Delete '{_selectedItem.Name}'?",
            AppConstants.AppName,
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);
        
        if (result == MessageBoxResult.Yes)
        {
            var parent = FindParent(_selectedItem);
            var collection = parent?.Children ?? _menuItems;
            collection.Remove(_selectedItem);
            statusText.Text = $"Deleted '{_selectedItem.Name}'";
        }
    }
    
    private void Save_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            // Convert ViewModels back to MenuItem models recursively
            var menu = _configService.GetMenu();
            
            // Check if we have a root menu node
            if (_menuItems.Count > 0 && _menuItems[0].IsRootMenu)
            {
                var rootVm = _menuItems[0];
                // Update menu-level properties from the root node
                menu.Id = rootVm.Model.Id;
                menu.Name = rootVm.Model.Name;
                menu.TextColor = rootVm.Model.TextColor;
                menu.BgColor = rootVm.Model.BgColor;
                
                // Items are children of the root
                menu.Items = ConvertViewModelsToModels(rootVm.Children);
            }
            else
            {
                // Legacy format without root node
                menu.Items = ConvertViewModelsToModels(_menuItems);
            }
            
            // Update config and save
            _configService.SetMenu(menu);
            _configService.Save();
            
            // Notify the app to rebuild menus
            MenuSaved?.Invoke(this, EventArgs.Empty);
            
            statusText.Text = "✓ Saved and rebuilt menu";
            ShowToast("✓ Menu saved and rebuilt successfully!");
        }
        catch (Exception ex)
        {
            statusText.Text = "✗ Save failed";
            ShowToast($"✗ Error: {ex.Message}");
        }
    }
    
    private async void ShowToast(string message)
    {
        toastText.Text = message;
        toastNotification.Visibility = Visibility.Visible;
        
        // Auto-hide after 2 seconds
        await Task.Delay(2000);
        toastNotification.Visibility = Visibility.Collapsed;
    }
    
    private List<QuickCliq.Core.Models.MenuItem> ConvertViewModelsToModels(ObservableCollection<MenuItemViewModel> viewModels)
    {
        var models = new List<QuickCliq.Core.Models.MenuItem>();
        foreach (var vm in viewModels)
        {
            vm.Model.Children = ConvertViewModelsToModels(vm.Children);
            models.Add(vm.Model);
        }
        return models;
    }
    
    private void ExpandAll_Click(object sender, RoutedEventArgs e)
    {
        ExpandAllItems(_menuItems);
    }
    
    private void CollapseAll_Click(object sender, RoutedEventArgs e)
    {
        CollapseAllItems(_menuItems);
    }
    
    private void ExpandAllItems(IEnumerable<MenuItemViewModel> items)
    {
        foreach (var item in items)
        {
            item.IsExpanded = true;
            if (item.Children.Count > 0)
                ExpandAllItems(item.Children);
        }
    }
    
    private void CollapseAllItems(IEnumerable<MenuItemViewModel> items)
    {
        foreach (var item in items)
        {
            item.IsExpanded = false;
            if (item.Children.Count > 0)
                CollapseAllItems(item.Children);
        }
    }
    
    #endregion
    
    #region Properties Panel
    
    private void MenuTreeView_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
    {
        _selectedItem = e.NewValue as MenuItemViewModel;
        
        if (_selectedItem != null)
        {
            LoadItemProperties(_selectedItem);
        }
    }
    
    private void LoadItemProperties(MenuItemViewModel item)
    {
        // Determine item type
        bool isRootMenu = item.IsRootMenu;
        bool isSubmenu = item.Model.IsMenu && !isRootMenu;
        bool isShortcut = !item.Model.IsMenu && !isRootMenu;
        
        // Show/hide controls based on item type
        // Commands - only for shortcuts
        pnlCommands.Visibility = isShortcut ? Visibility.Visible : Visibility.Collapsed;
        
        // Icon - for shortcuts and submenus, but not root menu
        var iconGrid = (Grid)txtIcon.Parent; // Get the Grid containing icon controls
        iconGrid.Visibility = isRootMenu ? Visibility.Collapsed : Visibility.Visible;
        
        // Bold - for shortcuts and submenus, but not root menu
        chkBold.Visibility = isRootMenu ? Visibility.Collapsed : Visibility.Visible;
        
        // "Is submenu" checkbox - hide always (it's determined by structure, not user input)
        chkIsMenu.Visibility = Visibility.Collapsed;
        
        // Load values
        txtName.Text = item.Name;
        
        // Load commands into ListBox
        lstCommands.Items.Clear();
        foreach (var cmd in item.Model.Commands)
        {
            lstCommands.Items.Add(cmd);
        }
        
        txtIcon.Text = item.Model.Icon ?? "";
        chkBold.IsChecked = item.Model.Bold;
        chkIsMenu.IsChecked = item.Model.IsMenu;
        // Show color if set (not -1), or empty if default (-1)
        txtTextColor.Text = item.Model.TextColor >= 0 ? $"0x{item.Model.TextColor:X6}" : "";
        txtBgColor.Text = item.Model.BgColor >= 0 ? $"0x{item.Model.BgColor:X6}" : "";
        
        UpdateColorPreviewPanels();
        
        // Update status text with item type
        string itemType = isRootMenu ? "Main Menu" : (isSubmenu ? "Submenu" : "Shortcut");
        statusText.Text = $"Editing {itemType}: {item.Name}";
    }
    
    private void ClearPropertyPanel()
    {
        // Clear all input fields
        txtName.Text = "";
        txtIcon.Text = "";
        txtTextColor.Text = "";
        txtBgColor.Text = "";
        chkBold.IsChecked = false;
        chkIsMenu.IsChecked = false;
        lstCommands.Items.Clear();
        
        // Hide all panels
        pnlCommands.Visibility = Visibility.Collapsed;
        var iconGrid = (Grid)txtIcon.Parent;
        iconGrid.Visibility = Visibility.Collapsed;
        chkBold.Visibility = Visibility.Collapsed;
        chkIsMenu.Visibility = Visibility.Collapsed;
        
        // Clear color previews
        UpdateColorPreviewPanels();
        
        // Update status
        statusText.Text = "Select an item to edit";
    }
    
    private void SaveItem_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedItem == null) return;
        
        try
        {
            // Update model from UI
            _selectedItem.Model.Name = txtName.Text;
            
            // Only update commands for shortcuts (not for root menu or submenus)
            if (!_selectedItem.IsRootMenu && !_selectedItem.Model.IsMenu)
            {
                // Get commands from ListBox
                _selectedItem.Model.Commands = lstCommands.Items.Cast<string>().ToList();
            }
            
            // Only update icon for non-root items
            if (!_selectedItem.IsRootMenu)
            {
                _selectedItem.Model.Icon = string.IsNullOrWhiteSpace(txtIcon.Text) ? null : txtIcon.Text;
                _selectedItem.Model.Bold = chkBold.IsChecked ?? false;
            }
            
            // IsMenu is determined by structure, not user input
            // (Root menu and submenus already have IsMenu = true)
            
            // Parse colors - use -1 for "default/not set", allowing 0 for black
            _selectedItem.Model.TextColor = -1;
            _selectedItem.Model.BgColor = -1;
            
            if (!string.IsNullOrWhiteSpace(txtTextColor.Text))
            {
                string textColorHex = txtTextColor.Text.Replace("0x", "").Replace("#", "").Trim();
                if (int.TryParse(textColorHex, System.Globalization.NumberStyles.HexNumber, null, out int tc))
                    _selectedItem.Model.TextColor = tc;
            }
            
            if (!string.IsNullOrWhiteSpace(txtBgColor.Text))
            {
                string bgColorHex = txtBgColor.Text.Replace("0x", "").Replace("#", "").Trim();
                if (int.TryParse(bgColorHex, System.Globalization.NumberStyles.HexNumber, null, out int bc))
                    _selectedItem.Model.BgColor = bc;
            }
            
            // Refresh display
            _selectedItem.RaisePropertyChanged();
            
            statusText.Text = $"✓ Updated '{_selectedItem.Name}'";
        }
        catch (Exception ex)
        {
            System.Windows.MessageBox.Show($"Error updating item:\n\n{ex.Message}", AppConstants.AppName, MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }
    
    private void AddCommand_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new CommandBuilderDialog
        {
            Owner = this
        };
        
        if (dialog.ShowDialog() == true && !string.IsNullOrWhiteSpace(dialog.CommandText))
        {
            lstCommands.Items.Add(dialog.CommandText);
        }
    }
    
    private void EditCommand_Click(object sender, RoutedEventArgs e)
    {
        if (lstCommands.SelectedIndex < 0) return;
        
        string existingCommand = lstCommands.SelectedItem as string ?? "";
        var dialog = new CommandBuilderDialog(existingCommand)
        {
            Owner = this
        };
        
        if (dialog.ShowDialog() == true && !string.IsNullOrWhiteSpace(dialog.CommandText))
        {
            int index = lstCommands.SelectedIndex;
            lstCommands.Items[index] = dialog.CommandText;
        }
    }
    
    private void DeleteCommand_Click(object sender, RoutedEventArgs e)
    {
        if (lstCommands.SelectedIndex >= 0)
        {
            lstCommands.Items.RemoveAt(lstCommands.SelectedIndex);
        }
    }
    
    private void MoveCommandUp_Click(object sender, RoutedEventArgs e)
    {
        int index = lstCommands.SelectedIndex;
        if (index > 0)
        {
            var item = lstCommands.Items[index];
            lstCommands.Items.RemoveAt(index);
            lstCommands.Items.Insert(index - 1, item);
            lstCommands.SelectedIndex = index - 1;
        }
    }
    
    private void MoveCommandDown_Click(object sender, RoutedEventArgs e)
    {
        int index = lstCommands.SelectedIndex;
        if (index >= 0 && index < lstCommands.Items.Count - 1)
        {
            var item = lstCommands.Items[index];
            lstCommands.Items.RemoveAt(index);
            lstCommands.Items.Insert(index + 1, item);
            lstCommands.SelectedIndex = index + 1;
        }
    }
    
    private void lstCommands_DoubleClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
    {
        if (lstCommands.SelectedIndex >= 0)
        {
            EditCommand_Click(sender, e);
        }
    }
    
    private void BrowseIcon_Click(object sender, RoutedEventArgs e)
    {
        // Simple file picker for now
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select Icon File",
            Filter = "Executable files (*.exe)|*.exe|Icon files (*.ico)|*.ico|DLL files (*.dll)|*.dll|All files (*.*)|*.*"
        };
        
        if (dialog.ShowDialog() == true)
        {
            txtIcon.Text = dialog.FileName;
        }
    }
    
    private void TextColorPicker_Click(object sender, RoutedEventArgs e)
    {
        var currentColor = ParseHexColor(txtTextColor.Text);
        var dialog = new ColorPickerDialog(currentColor)
        {
            Owner = this
        };
        
        if (dialog.ShowDialog() == true)
        {
            txtTextColor.Text = $"0x{dialog.SelectedColor.R:X2}{dialog.SelectedColor.G:X2}{dialog.SelectedColor.B:X2}";
            UpdateColorPreviewPanels();
        }
    }
    
    private void BgColorPicker_Click(object sender, RoutedEventArgs e)
    {
        var currentColor = ParseHexColor(txtBgColor.Text);
        var dialog = new ColorPickerDialog(currentColor)
        {
            Owner = this
        };
        
        if (dialog.ShowDialog() == true)
        {
            txtBgColor.Text = $"0x{dialog.SelectedColor.R:X2}{dialog.SelectedColor.G:X2}{dialog.SelectedColor.B:X2}";
            UpdateColorPreviewPanels();
        }
    }
    
    private void TextColorPanel_Changed(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        UpdateColorPreviewPanels();
    }
    
    private void BgColorPanel_Changed(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        UpdateColorPreviewPanels();
    }
    
    private void UpdateColorPreviewPanels()
    {
        if (previewTextColorPanel != null)
        {
            var textColor = ParseHexColor(txtTextColor.Text);
            previewTextColorPanel.Background = new SolidColorBrush(textColor);
        }
        
        if (previewBgColorPanel != null)
        {
            var bgColor = ParseHexColor(txtBgColor.Text);
            previewBgColorPanel.Background = new SolidColorBrush(bgColor);
        }
    }
    
    private System.Windows.Media.Color ParseHexColor(string hex)
    {
        if (string.IsNullOrWhiteSpace(hex))
            return System.Windows.Media.Colors.White;
        
        try
        {
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
        
        return System.Windows.Media.Colors.White;
    }
    
    #endregion
}

/// <summary>
/// ViewModel for TreeView binding
/// </summary>
public class MenuItemViewModel : INotifyPropertyChanged
{
    public QuickCliq.Core.Models.MenuItem Model { get; }
    public ObservableCollection<MenuItemViewModel> Children { get; }
    
    private bool _isExpanded;
    private bool _isSelected;
    
    // Flag to identify this as the root menu node
    public bool IsRootMenu { get; set; }
    
    public MenuItemViewModel(QuickCliq.Core.Models.MenuItem model)
    {
        Model = model;
        Children = new ObservableCollection<MenuItemViewModel>();
        
        if (model.Children != null)
        {
            foreach (var child in model.Children)
            {
                Children.Add(new MenuItemViewModel(child));
            }
        }
    }
    
    public string Name => Model.Name;
    
    public string DisplayName
    {
        get
        {
            if (IsRootMenu) return $"🎯 {Model.Name} (Main Menu)";
            if (Model.IsSeparator) return "--- (Separator)";
            if (Model.IsMenu) return $"📁 {Model.Name}";
            return Model.Name;
        }
    }
    
    public FontWeight FontWeight => Model.Bold ? FontWeights.Bold : FontWeights.Normal;
    
    public bool IsExpanded
    {
        get => _isExpanded;
        set
        {
            _isExpanded = value;
            OnPropertyChanged(nameof(IsExpanded));
        }
    }
    
    public bool IsSelected
    {
        get => _isSelected;
        set
        {
            _isSelected = value;
            OnPropertyChanged(nameof(IsSelected));
        }
    }
    
    public event PropertyChangedEventHandler? PropertyChanged;
    
    public void OnPropertyChanged(string propertyName)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
    
    public void RaisePropertyChanged()
    {
        OnPropertyChanged(nameof(Name));
        OnPropertyChanged(nameof(DisplayName));
        OnPropertyChanged(nameof(FontWeight));
    }
}

/// <summary>
/// Visual adorner that follows the cursor during drag operations
/// </summary>
public class DragAdorner : Adorner
{
    private readonly ContentControl _content;
    private double _left;
    private double _top;
    
    public DragAdorner(UIElement adornedElement, string text) : base(adornedElement)
    {
        IsHitTestVisible = false;
        
        _content = new ContentControl
        {
            Content = new Border
            {
                Background = new SolidColorBrush(System.Windows.Media.Color.FromArgb(200, 70, 130, 180)),
                BorderBrush = System.Windows.Media.Brushes.White,
                BorderThickness = new Thickness(2),
                CornerRadius = new CornerRadius(4),
                Padding = new Thickness(8, 4, 8, 4),
                Child = new TextBlock
                {
                    Text = $"↔ {text}",
                    Foreground = System.Windows.Media.Brushes.White,
                    FontWeight = FontWeights.Bold
                }
            }
        };
    }
    
    public void UpdatePosition(double left, double top)
    {
        _left = left + 10; // Offset from cursor
        _top = top + 10;
        InvalidateArrange();
    }
    
    protected override System.Windows.Size MeasureOverride(System.Windows.Size constraint)
    {
        _content.Measure(constraint);
        return _content.DesiredSize;
    }
    
    protected override System.Windows.Size ArrangeOverride(System.Windows.Size finalSize)
    {
        _content.Arrange(new Rect(_left, _top, _content.DesiredSize.Width, _content.DesiredSize.Height));
        return finalSize;
    }
    
    protected override Visual GetVisualChild(int index)
    {
        return _content;
    }
    
    protected override int VisualChildrenCount => 1;
}
