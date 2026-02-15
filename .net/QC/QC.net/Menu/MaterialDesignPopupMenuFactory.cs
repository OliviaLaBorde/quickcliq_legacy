using System.Windows;
using QuickCliq.Core.Menu;

namespace QC.net.Menu;

public class MaterialDesignPopupMenuFactory : IPopupMenuFactory
{
    private readonly Window _parentWindow;
    
    public MaterialDesignPopupMenuFactory(Window parentWindow)
    {
        _parentWindow = parentWindow;
    }
    
    public IPopupMenu CreateMenu(MenuParams parameters)
    {
        var menu = new MaterialDesignPopupMenu(_parentWindow);
        // Store parameters for menu creation
        typeof(MaterialDesignPopupMenu)
            .GetField("_params", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)?
            .SetValue(menu, parameters);
        return menu;
    }
}
