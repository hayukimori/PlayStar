using Godot;
using System;
using System.IO;
using TagLib;

using PlayStar.Scripts.Models;

namespace PlayStar.Scripts.Core;

[GlobalClass]
public partial class TagManager : GodotObject
{
    public static SongModel ReadTags(string path)
    {
        try
        {
            using var file = TagLib.File.Create(path);
            var tag = file.Tag;
            var prop = file.Properties;


            string rawArtist = tag.FirstPerformer ?? tag.FirstAlbumArtist ?? "Unknown";

            return new SongModel
            {
                FilePath = path,
                FileName = Path.GetFileName(path),
                Title = !string.IsNullOrWhiteSpace(tag.Title)
                               ? tag.Title
                               : Path.GetFileNameWithoutExtension(path),
                Artist = rawArtist,
                Album = tag.Album ?? "Unknown",
                Genre = tag.FirstGenre ?? "Unknown",
                Length = (long)prop.Duration.TotalMilliseconds,
                Year = tag.Year,
                Lyrics = tag.Lyrics ?? string.Empty,
            };
        }
        catch (Exception ex)
        {
            GD.PrintErr($"[MetadataIndexer] Failed to read tags for {path}: {ex.Message}");
            return new SongModel
            {
                FilePath = path,
                FileName = Path.GetFileName(path),
                Title = Path.GetFileNameWithoutExtension(path),
                Artist = "Unknown",
                Album = "Unknown",
                Genre = "Unknown",
                Length = 0,
                Year = 0,
                Lyrics = string.Empty,
            };
        }
    }
}
