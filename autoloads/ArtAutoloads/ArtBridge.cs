using Godot;
using System;
using System.Collections.Generic;

using PlayStar.Scripts.AlbumArt;

namespace PlayStar.autoloads.ArtAutoloads;
public partial class ArtBridge : Node
{
    private static readonly AlbumArtWorker _worker = new();
    private static readonly HashSet<string> _inFlight = [];
    private static readonly object _lock = new();

    public static void Request(string key, string songPath)
    {
        if (AlbumArtCache.TryGet(key, out _)) return;

        lock (_lock)
        {
            if (_inFlight.Contains(key)) return;
            _inFlight.Add(key);
        }

        _worker.Enqueue(new ArtRequest(
            songPath,
            key,
            (result) =>
            {
                ArtDispatcher.PushResult(result);

                lock (_lock)
                    _inFlight.Remove(result.Key);
            }
        ));
    }
}