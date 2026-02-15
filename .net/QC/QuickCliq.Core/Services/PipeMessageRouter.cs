using System.Text;

namespace QuickCliq.Core.Services;

/// <summary>
/// Parses and routes pipe messages
/// Handles command-line arguments from secondary instances
/// </summary>
public class PipeMessageRouter
{
    public event EventHandler<AddShortcutEventArgs>? AddShortcutRequested;
    public event EventHandler<SMenuEventArgs>? SMenuRequested;
    public event EventHandler<string>? UnknownCommand;

    /// <summary>
    /// Parse and route pipe message
    /// Format: -command [args]
    /// </summary>
    public void RouteMessage(string message)
    {
        if (string.IsNullOrWhiteSpace(message))
            return;

        var args = ParseArgs(message);
        if (args.Length == 0)
            return;

        var command = args[0].ToLowerInvariant();

        switch (command)
        {
            case "-a": // Add shortcut
                if (args.Length > 1)
                    OnAddShortcutRequested(new AddShortcutEventArgs(args[1]));
                break;

            case "-sm": // S-Menu
                if (args.Length > 1)
                    OnSMenuRequested(new SMenuEventArgs(args[1]));
                break;

            case "-smupd": // Update S-Menu
                if (args.Length > 1)
                    OnSMenuRequested(new SMenuEventArgs(args[1], update: true));
                break;

            default:
                OnUnknownCommand(message);
                break;
        }
    }

    private string[] ParseArgs(string message)
    {
        var args = new List<string>();
        var current = new StringBuilder();
        bool inQuotes = false;

        for (int i = 0; i < message.Length; i++)
        {
            var c = message[i];

            if (c == '"')
            {
                inQuotes = !inQuotes;
            }
            else if (c == ' ' && !inQuotes)
            {
                if (current.Length > 0)
                {
                    args.Add(current.ToString());
                    current.Clear();
                }
            }
            else
            {
                current.Append(c);
            }
        }

        if (current.Length > 0)
            args.Add(current.ToString());

        return args.ToArray();
    }

    protected virtual void OnAddShortcutRequested(AddShortcutEventArgs e)
    {
        AddShortcutRequested?.Invoke(this, e);
    }

    protected virtual void OnSMenuRequested(SMenuEventArgs e)
    {
        SMenuRequested?.Invoke(this, e);
    }

    protected virtual void OnUnknownCommand(string message)
    {
        UnknownCommand?.Invoke(this, message);
    }
}

public class AddShortcutEventArgs : EventArgs
{
    public string Path { get; }

    public AddShortcutEventArgs(string path)
    {
        Path = path;
    }
}

public class SMenuEventArgs : EventArgs
{
    public string QcmPath { get; }
    public bool Update { get; }

    public SMenuEventArgs(string qcmPath, bool update = false)
    {
        QcmPath = qcmPath;
        Update = update;
    }
}
