using System;
using System.IO;
using Godot;
using LibVLCSharp.Shared;
using TagLib;

using PlayStar.Scripts.Models;
namespace PlayStar.autoloads.MediaAutoloads;

public partial class MediaBackend : Node{

    public static MediaBackend Instance { get; private set; }
    private LibVLC _libVlc;
    private readonly object _mediaLock = new();
    
    public LibVLC LibVlc => _libVlc;

    public override void _EnterTree()
    {
        if (Instance != null) throw new Exception("MediaBackend already exists!");
        Instance = this;
    }

    public override void _Ready()
    {
        GD.Print("Initializing LibVLC backend...");

        Core.Initialize();
        _libVlc = new LibVLC(
            "--no-video",
            "--quiet",
            "--no-xlib"
        );

        GD.Print("LibVLC initalized.");
    }

    public Media CreateMedia(string path)
    {
        lock (_mediaLock)
        {
            return new Media(LibVlc, new Uri(path));
        }
    }

    public void ParseMedia(Media media)
    {
        media.Parse(MediaParseOptions.ParseLocal);
    }

    public void ParseMediaFully(Media media)
    {
        media.Parse(MediaParseOptions.ParseLocal);

        while (media.ParsedStatus == 0) // Avoiding using MediaParsedStatus.Done
        {
            System.Threading.Thread.Sleep(5);
        }
    }


    // usage: var title = MediaBackend.Instance.SafeMediaAction(() => media.Meta(MetadataType.Title));

    public T SafeMediaAction<T>(Func<T> action)
    {
        lock (_mediaLock)
        {
            return action();
        }
    }

    public static SongModel GetSongModelFromPath(string path)
        {
                try
                {
                        using var file = TagLib.File.Create(path);

                        var tag = file.Tag;
                        var properties = file.Properties;

                        return new SongModel
                        {
                                Title = !string.IsNullOrWhiteSpace(tag.Title) 
                                        ? tag.Title
                                        : Path.GetFileNameWithoutExtension(path),

                                Artist = tag.FirstPerformer ?? "Unknown",
                                Album = tag.Album ?? "Unknown",
                                Genre = tag.FirstGenre ?? "Unknown",

                                Length = (long)properties.Duration.TotalMilliseconds,
                                Year = tag.Year,
                                Lyrics = tag.Lyrics ?? string.Empty,
                                FilePath = path
                        };
                }
                catch (Exception)
                {
                        return new SongModel
                        {
                                Title = Path.GetFileNameWithoutExtension(path),
                                Artist = "Unknown",
                                Album = "Unknown",
                                Length = 0,
                                Year = 0,
                                Lyrics = string.Empty,
                                FilePath = path,
                                FileName = Path.GetFileName(path)
                        };
                }
        }


    public static string GetLyricsFromSong(SongModel song)
    {
        if (song.FilePath == null) return null;
        using var file = TagLib.File.Create(song.FilePath);

        var tag = file.Tag;
        return tag.Lyrics ?? null;
    }

    public override void _ExitTree()
    {
        GD.Print("Shutting down LibVLC...");

        _libVlc?.Dispose();
        _libVlc = null;

        Instance = null;
    }

}
