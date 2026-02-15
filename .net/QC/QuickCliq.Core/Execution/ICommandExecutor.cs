namespace QuickCliq.Core.Execution;

/// <summary>
/// Command executor interface
/// Handles running commands, files, URLs with special prefixes
/// </summary>
public interface ICommandExecutor
{
    Task ExecuteAsync(ExecuteParams parameters, CancellationToken ct = default);
    
    /// <summary>
    /// Maximum concurrent executions allowed
    /// </summary>
    int MaxConcurrentExecutions { get; }
    
    /// <summary>
    /// Current number of running executions
    /// </summary>
    int CurrentExecutions { get; }
    
    /// <summary>
    /// Raised when the EDITOR command is executed
    /// </summary>
    event EventHandler? EditorRequested;
}

/// <summary>
/// Parameters for command execution
/// </summary>
public record ExecuteParams
{
    /// <summary>
    /// Command string (may contain {N} for multi-target) - LEGACY FORMAT
    /// Use Commands list instead for new code
    /// </summary>
    public string? Command { get; init; }
    
    /// <summary>
    /// List of commands to execute sequentially - PREFERRED
    /// </summary>
    public List<string>? Commands { get; init; }
    
    /// <summary>
    /// Display name for logging/recent
    /// </summary>
    public string? Name { get; init; }
    
    /// <summary>
    /// Icon path for logging/recent
    /// </summary>
    public string? Icon { get; init; }
    
    /// <summary>
    /// Don't treat Ctrl as "copy to clipboard"
    /// </summary>
    public bool NoCtrl { get; init; }
    
    /// <summary>
    /// Don't treat Shift as "run as admin"
    /// </summary>
    public bool NoShift { get; init; }
    
    /// <summary>
    /// Don't add to Recent items
    /// </summary>
    public bool NoLog { get; init; }
    
    /// <summary>
    /// Override verb (e.g., "RUNAS")
    /// </summary>
    public string? Verb { get; init; }
    
    /// <summary>
    /// Active window handle (for window-specific commands)
    /// </summary>
    public IntPtr? ActiveWindowHandle { get; init; }
}

/// <summary>
/// Result of command execution
/// </summary>
public class ExecuteResult
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public List<string> ExecutedCommands { get; init; } = new();
    public List<string> FailedCommands { get; init; } = new();
}
