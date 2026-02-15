using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using QuickCliq.Core.Config;
using QuickCliq.Core.Services;
using QuickCliq.Core.Win32;

namespace QuickCliq.Core.Execution;

/// <summary>
/// Command executor implementation
/// Based on legacy QC_execute.ahk
/// </summary>
public partial class CommandExecutor : ICommandExecutor
{
    private readonly PathService _pathService;
    private readonly IOptionsService _optionsService;
    private int _currentExecutions;
    private readonly SemaphoreSlim _semaphore;

    public int MaxConcurrentExecutions { get; }
    public int CurrentExecutions => _currentExecutions;
    public event EventHandler? EditorRequested;

    public CommandExecutor(
        PathService pathService,
        IOptionsService optionsService,
        int maxConcurrent = AppConstants.MaxThreads)
    {
        _pathService = pathService;
        _optionsService = optionsService;
        MaxConcurrentExecutions = maxConcurrent;
        _semaphore = new SemaphoreSlim(maxConcurrent, maxConcurrent);
    }

    public async Task ExecuteAsync(ExecuteParams parameters, CancellationToken ct = default)
    {
        // Check for Ctrl (copy to clipboard) and Shift (run as admin)
        bool ctrlPressed = !parameters.NoCtrl && IsKeyPressed(Keys.Control);
        bool shiftPressed = !parameters.NoShift && IsKeyPressed(Keys.Shift);

        // If Ctrl pressed, copy commands to clipboard and return
        if (ctrlPressed)
        {
            CopyCommandsToClipboard(parameters.Command);
            return;
        }

        // Split by multi-target divider
        var commands = SplitCommands(parameters.Command);
        
        if (commands.Count == 0)
            return;

        // Wait for available slot
        await _semaphore.WaitAsync(ct);
        
        try
        {
            Interlocked.Increment(ref _currentExecutions);
            
            var delay = _optionsService.Get<int>("gen_cmddelay");
            var errors = new List<string>();

            for (int i = 0; i < commands.Count; i++)
            {
                if (i > 0 && delay > 0)
                    await Task.Delay(delay, ct);

                var command = commands[i];
                
                // Parse special commands
                var parsed = ParseCommand(command, shiftPressed, parameters);
                
                if (parsed.IsSpecial)
                {
                    await ExecuteSpecialCommandAsync(parsed, parameters, ct);
                }
                else
                {
                    var result = await ExecuteStandardCommandAsync(parsed, ct);
                    if (!result.Success && result.ErrorMessage != null)
                        errors.Add($"Command {i + 1}: {result.ErrorMessage}");
                }
            }

            if (errors.Count > 0)
            {
                // TODO: Show error dialog
                Console.WriteLine($"Execution errors:\n{string.Join("\n", errors)}");
            }
        }
        finally
        {
            Interlocked.Decrement(ref _currentExecutions);
            _semaphore.Release();
        }
    }

    private List<string> SplitCommands(string commandString)
    {
        // Remove comments {!...!}
        commandString = Regex.Replace(commandString, @"\{!.*?!\}", "");
        
        return commandString
            .Split(new[] { AppConstants.MultiTargetDivider }, StringSplitOptions.RemoveEmptyEntries)
            .Select(c => c.Trim())
            .Where(c => !string.IsNullOrWhiteSpace(c))
            .ToList();
    }

    private ParsedCommand ParseCommand(string command, bool forceRunAs, ExecuteParams parameters)
    {
        var parsed = new ParsedCommand { OriginalCommand = command };

        // REP{n} - repeat command
        var repMatch = Regex.Match(command, @"^\s*REP(\d+)\s+(.+)$", RegexOptions.IgnoreCase);
        if (repMatch.Success)
        {
            parsed.RepeatCount = int.Parse(repMatch.Groups[1].Value);
            command = repMatch.Groups[2].Value;
        }

        // WAIT or W{seconds}
        var waitMatch = Regex.Match(command, @"^\s*(?:WAIT|W)(\d+(?:\.\d+)?)\s*$", RegexOptions.IgnoreCase);
        if (waitMatch.Success)
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.Wait;
            parsed.WaitSeconds = double.Parse(waitMatch.Groups[1].Value);
            return parsed;
        }

        // CHK - custom hotkeys GUI
        if (Regex.IsMatch(command, @"^\s*CHK\s*$", RegexOptions.IgnoreCase))
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.CustomHotkeys;
            return parsed;
        }

        // EDITOR - open menu editor
        if (Regex.IsMatch(command, @"^\s*EDITOR\s*$", RegexOptions.IgnoreCase))
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.OpenEditor;
            return parsed;
        }

        // RUNAS prefix
        if (Regex.IsMatch(command, @"^\s*RUNAS\s+", RegexOptions.IgnoreCase))
        {
            command = Regex.Replace(command, @"^\s*RUNAS\s+", "", RegexOptions.IgnoreCase);
            parsed.Verb = "runas";
        }
        else if (forceRunAs || !string.IsNullOrEmpty(parameters.Verb))
        {
            parsed.Verb = parameters.Verb ?? "runas";
        }

        // RUN_MIN
        if (Regex.IsMatch(command, @"^\s*RUN_MIN\s+", RegexOptions.IgnoreCase))
        {
            command = Regex.Replace(command, @"^\s*RUN_MIN\s+", "", RegexOptions.IgnoreCase);
            parsed.WindowStyle = ProcessWindowStyle.Minimized;
        }

        // RUN_MAX
        if (Regex.IsMatch(command, @"^\s*RUN_MAX\s+", RegexOptions.IgnoreCase))
        {
            command = Regex.Replace(command, @"^\s*RUN_MAX\s+", "", RegexOptions.IgnoreCase);
            parsed.WindowStyle = ProcessWindowStyle.Maximized;
        }

        // {clip} or {clip0-9} - clipboard expansion
        command = ExpandClipboardVariables(command);

        // Window commands (win_casc, win_tileh, etc.)
        if (Regex.IsMatch(command, @"^\s*(win_casc|win_tasksw|win_tileh|win_min|win_unmin|win_togd|win_tilev)\s*$", RegexOptions.IgnoreCase))
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.WindowCommand;
            parsed.Command = command.Trim().ToLowerInvariant();
            return parsed;
        }

        // copyto command
        if (Regex.IsMatch(command, @"^\s*copyto[*^]*\s+", RegexOptions.IgnoreCase))
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.CopyTo;
            parsed.Command = command;
            return parsed;
        }

        // Change folder (ends with ^)
        if (command.EndsWith("^"))
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.ChangeFolder;
            parsed.Command = command[..^1].Trim();
            return parsed;
        }

        // killproc
        var killMatch = Regex.Match(command, @"^\s*killproc(?:\s+(.+))?\s*$", RegexOptions.IgnoreCase);
        if (killMatch.Success)
        {
            parsed.IsSpecial = true;
            parsed.SpecialType = SpecialCommandType.KillProcess;
            parsed.Command = killMatch.Groups[1].Success ? killMatch.Groups[1].Value : "";
            return parsed;
        }

        parsed.Command = command;
        return parsed;
    }

    private string ExpandClipboardVariables(string command)
    {
        // TODO: Integrate with ClipsService when available
        // For now, just replace with empty string
        return Regex.Replace(command, @"\{clip\d?\}", "");
    }

    private async Task<ExecuteResult> ExecuteStandardCommandAsync(ParsedCommand parsed, CancellationToken ct)
    {
        var result = new ExecuteResult { Success = true };
        
        for (int rep = 0; rep < parsed.RepeatCount; rep++)
        {
            try
            {
                var (path, args, workDir) = _pathService.Split(parsed.Command);
                path = _pathService.ExpandEnvVars(path);
                path = _pathService.UnquoteSpaces(path);

                var startInfo = new ProcessStartInfo
                {
                    FileName = path,
                    Arguments = args,
                    WorkingDirectory = workDir,
                    UseShellExecute = true,
                    WindowStyle = parsed.WindowStyle
                };

                if (!string.IsNullOrEmpty(parsed.Verb))
                    startInfo.Verb = parsed.Verb;

                Process.Start(startInfo);
                result.ExecutedCommands.Add(parsed.Command);
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.ErrorMessage = $"Failed to execute: {ex.Message}";
                result.FailedCommands.Add(parsed.Command);
            }
        }

        return result;
    }

    private async Task ExecuteSpecialCommandAsync(ParsedCommand parsed, ExecuteParams parameters, CancellationToken ct)
    {
        switch (parsed.SpecialType)
        {
            case SpecialCommandType.Wait:
                await Task.Delay(TimeSpan.FromSeconds(parsed.WaitSeconds), ct);
                break;

            case SpecialCommandType.CustomHotkeys:
                // TODO: Open custom hotkeys GUI
                break;

            case SpecialCommandType.OpenEditor:
                OnEditorRequested();
                break;

            case SpecialCommandType.WindowCommand:
                // TODO: Execute window command (tile, cascade, etc.)
                break;

            case SpecialCommandType.CopyTo:
                // TODO: Execute CopyTo command
                break;

            case SpecialCommandType.ChangeFolder:
                // TODO: Change active window folder
                break;

            case SpecialCommandType.KillProcess:
                // TODO: Kill process
                break;
        }
    }

    private void OnEditorRequested()
    {
        EditorRequested?.Invoke(this, EventArgs.Empty);
    }

    private void CopyCommandsToClipboard(string commands)
    {
        var commandList = SplitCommands(commands);
        var text = string.Join("\r\n", commandList);
        
        // TODO: Use ClipsService when available
        // For now, just log (Core library can't reference WPF Clipboard directly)
        Console.WriteLine($"Would copy {commandList.Count} command(s) to clipboard:\n{text}");
    }

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    private bool IsKeyPressed(Keys key)
    {
        return (GetAsyncKeyState((int)key) & 0x8000) != 0;
    }
}

internal class ParsedCommand
{
    public string OriginalCommand { get; set; } = string.Empty;
    public string Command { get; set; } = string.Empty;
    public int RepeatCount { get; set; } = 1;
    public string? Verb { get; set; }
    public ProcessWindowStyle WindowStyle { get; set; } = ProcessWindowStyle.Normal;
    public bool IsSpecial { get; set; }
    public SpecialCommandType SpecialType { get; set; }
    public double WaitSeconds { get; set; }
}

internal enum SpecialCommandType
{
    None,
    Wait,
    CustomHotkeys,
    OpenEditor,
    WindowCommand,
    CopyTo,
    ChangeFolder,
    KillProcess
}

// Windows Forms Keys enum subset for key detection
internal enum Keys
{
    Control = 0x11,
    Shift = 0x10,
    Alt = 0x12
}
