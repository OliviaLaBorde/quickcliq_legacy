using System.IO.Pipes;
using System.Text;

namespace QuickCliq.Core.Services;

/// <summary>
/// Named pipe server for single-instance and IPC
/// Handles messages from secondary instances
/// </summary>
public class PipeServer : IDisposable
{
    private readonly string _pipeName;
    private readonly CancellationTokenSource _cts = new();
    private NamedPipeServerStream? _pipeServer;
    private Task? _listenerTask;
    
    public event EventHandler<PipeMessageReceivedEventArgs>? MessageReceived;
    
    public bool IsRunning { get; private set; }

    public PipeServer(string? pipeName = null)
    {
        _pipeName = pipeName ?? AppConstants.PipeName.Replace(@"\\.\pipe\", "");
    }

    /// <summary>
    /// Try to create pipe server (single instance check)
    /// Returns true if this is the first instance
    /// </summary>
    public bool TryStart()
    {
        try
        {
            _pipeServer = new NamedPipeServerStream(
                _pipeName,
                PipeDirection.InOut,
                1, // Max instances
                PipeTransmissionMode.Message,
                PipeOptions.Asynchronous,
                AppConstants.PipeBufferSize,
                AppConstants.PipeBufferSize);
            
            IsRunning = true;
            _listenerTask = Task.Run(ListenForConnections, _cts.Token);
            return true;
        }
        catch (IOException)
        {
            // Pipe already exists - another instance is running
            return false;
        }
    }

    /// <summary>
    /// Send message to existing instance
    /// </summary>
    public static async Task<bool> SendMessageAsync(string message, string? pipeName = null, int timeoutMs = 5000)
    {
        pipeName ??= AppConstants.PipeName.Replace(@"\\.\pipe\", "");
        
        try
        {
            using var client = new NamedPipeClientStream(".", pipeName, PipeDirection.InOut);
            using var cts = new CancellationTokenSource(timeoutMs);
            
            await client.ConnectAsync(cts.Token);
            
            var bytes = Encoding.UTF8.GetBytes(message);
            await client.WriteAsync(bytes, cts.Token);
            await client.FlushAsync(cts.Token);
            
            return true;
        }
        catch
        {
            return false;
        }
    }

    private async Task ListenForConnections()
    {
        while (!_cts.Token.IsCancellationRequested && IsRunning)
        {
            try
            {
                if (_pipeServer == null) break;
                
                await _pipeServer.WaitForConnectionAsync(_cts.Token);
                
                var message = await ReadMessageAsync(_pipeServer);
                
                if (!string.IsNullOrEmpty(message))
                {
                    OnMessageReceived(new PipeMessageReceivedEventArgs(message));
                }
                
                _pipeServer.Disconnect();
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                // Log error but continue listening
                Console.WriteLine($"Pipe error: {ex.Message}");
            }
        }
    }

    private async Task<string> ReadMessageAsync(NamedPipeServerStream pipe)
    {
        using var ms = new MemoryStream();
        var buffer = new byte[4096];
        
        do
        {
            var bytesRead = await pipe.ReadAsync(buffer, _cts.Token);
            ms.Write(buffer, 0, bytesRead);
        }
        while (!pipe.IsMessageComplete);
        
        return Encoding.UTF8.GetString(ms.ToArray());
    }

    protected virtual void OnMessageReceived(PipeMessageReceivedEventArgs e)
    {
        MessageReceived?.Invoke(this, e);
    }

    public void Stop()
    {
        IsRunning = false;
        _cts.Cancel();
        _pipeServer?.Dispose();
    }

    public void Dispose()
    {
        Stop();
        _cts.Dispose();
        GC.SuppressFinalize(this);
    }
}

public class PipeMessageReceivedEventArgs : EventArgs
{
    public string Message { get; }
    public DateTime ReceivedAt { get; }

    public PipeMessageReceivedEventArgs(string message)
    {
        Message = message;
        ReceivedAt = DateTime.Now;
    }
}
