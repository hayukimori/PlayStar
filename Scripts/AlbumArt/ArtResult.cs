namespace PlayStar.Scripts.AlbumArt;
public class ArtResult
{
    public string Key { get; }
    public byte[] ImageBytes { get; }
    public bool FromCache { get; }

    public ArtResult(string key, byte[] bytes, bool fromCache)
    {
        Key = key;
        ImageBytes = bytes;
        FromCache = fromCache;
    }
}
