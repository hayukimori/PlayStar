using Godot;
using System;
using TagLib;

using PlayStar.Scripts.Models;
using PlayStar.Scripts.AlbumArt;
namespace PlayStar.Scripts.Core;


[GlobalClass]
public partial class MetadataManager : RefCounted
{
    public static string GetLyricsFromSong(SongModel song)
    {
        if (song == null || string.IsNullOrEmpty(song.FilePath))
            return null;
        return GetLyricsFromPath(song.FilePath);
    }

    public static string GetLyricsFromPath(string filePath)
    {
        if (string.IsNullOrEmpty(filePath))
            return null;
        try
        {
            using var file = TagLib.File.Create(filePath);
            var tag = file.Tag;
            return tag.Lyrics ?? null;
        }
        catch
        {
            return null;
        }
    }

    public static Texture2D GetArtWorkFromFile(string FilePath) => AlbumArtLoader.GetAlbumArt(FilePath);
}
