using Godot;
using System.Collections.Generic;
using PlayStar.Scripts.AlbumArt;

namespace PlayStar.autoloads.ArtAutoloads;

public partial class ArtDispatcher : Node
{
    public static event System.Action<string, Texture2D> InternalArtReady;
    private static readonly Queue<ArtResult> _results = new();

    public static void PushResult(ArtResult result)
    {
        lock (_results)
            _results.Enqueue(result);
    }

    public override void _Process(double delta)
    {
        while (true)
        {
            ArtResult res;

            lock (_results)
            {
                if (_results.Count == 0) break;
                res = _results.Dequeue();
            }

            HandleResult(res);
        }
    }

    private void HandleResult(ArtResult res)
    {
        if (res.ImageBytes == null || res.ImageBytes.Length == 0)
            return;

        var img = new Image();

        var err = img.LoadJpgFromBuffer(res.ImageBytes);
        if (err != Error.Ok)
            return;

        var tex = ImageTexture.CreateFromImage(img);

        AlbumArtCache.Put(res.Key, tex);
        InternalArtReady?.Invoke(res.Key, tex);
    }

    [Signal]
    public delegate void ArtReadyEventHandler(string key, Texture2D texture);
}