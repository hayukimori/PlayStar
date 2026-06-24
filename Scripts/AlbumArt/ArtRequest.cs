using System;

namespace PlayStar.Scripts.AlbumArt;
public class ArtRequest
{
    public string SongPath { get; }
    public string Key { get; }
    public Action<ArtResult> Callback { get; }

    public ArtRequest(string songPath, string key, Action<ArtResult> callback)
    {
        SongPath = songPath;
        Key = key;
        Callback = callback;
    }
}