using System.Collections.Concurrent;
using System.Threading;
using System;

using PlayStar.Scripts.AlbumArt;

namespace PlayStar.autoloads.ArtAutoloads;
public class AlbumArtWorker
{
    private readonly BlockingCollection<ArtRequest> _queue = new();
    private readonly Thread _thread;
    private bool _running = true;

    public AlbumArtWorker()
    {
        _thread = new Thread(Process);
        _thread.IsBackground = true;
        _thread.Start();
    }

    public void Enqueue(ArtRequest request)
    {
        _queue.Add(request);
    }

    private void Process()
    {
        foreach (var req in _queue.GetConsumingEnumerable())
        {
            try
            {
                var bytes = AlbumArtExtractor.ExtractAndResize(req.SongPath);
                var result = new ArtResult(req.Key, bytes, false);
                req.Callback?.Invoke(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ArtWorker] FAILED: {req.SongPath}");
                Console.WriteLine(ex.ToString());

                req.Callback?.Invoke(new ArtResult(req.Key, null, false));
            }
        }
    }

    public void Stop()
    {
        Console.WriteLine("[AlbumArtWorker] Stopping worker");
        _running = false;
        _queue.CompleteAdding();
    }
}