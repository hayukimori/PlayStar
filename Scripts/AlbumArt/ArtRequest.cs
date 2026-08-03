using System;

namespace PlayStar.Scripts.AlbumArt;

public class ArtRequest
{
    public string SongPath { get; }
    public string Key { get; }
    public Action<ArtResult> Callback { get; }
    public string ArtUrl { get; set; }

    public ArtRequest(string songPath, string key, Action<ArtResult> callback, string artUrl = null)
    {
        SongPath = songPath;
        Key = key;
        Callback = callback;
        if (artUrl == "") ArtUrl = null; else ArtUrl = artUrl;
    }
}
