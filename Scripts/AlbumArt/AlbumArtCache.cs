using Godot;
using System.Collections.Generic;

namespace PlayStar2.Scripts.AlbumArt;
public static class AlbumArtCache
{
    private const int MAX_ITEMS = 128;

    private static readonly Dictionary<string, Texture2D> _map = new();
    private static readonly LinkedList<string> _lru = new();

    public static bool TryGet(string key, out Texture2D tex)
    {
        if (_map.TryGetValue(key, out tex))
        {
            _lru.Remove(key);
            _lru.AddFirst(key);
            return true;
        }

        tex = null;
        return false;
    }

    public static Texture2D Get(string key)
    {
        return _map.TryGetValue(key, out var tex) ? tex : null;
    }

    public static void Put(string key, Texture2D tex)
    {
        if (_map.ContainsKey(key))
            return;

        if (_map.Count >= MAX_ITEMS)
        {
            var last = _lru.Last.Value;
            _lru.RemoveLast();
            _map.Remove(last);
        }

        _map[key] = tex;
        _lru.AddFirst(key);
    }
}