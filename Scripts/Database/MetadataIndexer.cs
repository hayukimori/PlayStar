using Godot;
using Microsoft.Data.Sqlite;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using TagLib;
using PlayStar.Scripts.Database.Parsers;
using PlayStar.Scripts.Database.Repositories;
using PlayStar.Scripts.Models;


namespace PlayStar.Scripts.Database;

[GlobalClass]
public partial class MetadataIndexer : Node
{
    [Signal] public delegate void SongsIndexEndEventHandler();

    [Export] public int MaxParallel = 2;

    private CancellationTokenSource _cts;
    private SemaphoreSlim _throttle;

    private DatabaseManager  _db;
    private SongRepository   _songs;
    private ArtistRepository _artists;
    private AlbumRepository  _albums;
    private GenreRepository  _genres;

    public override void _Ready()
    {
        _throttle = new SemaphoreSlim(MaxParallel);
    }

    public void Initialize(DatabaseManager db, SongRepository songs, ArtistRepository artists, AlbumRepository albums)
    {
        _db      = db;
        _songs   = songs;
        _artists = artists;
        _albums  = albums;
        _genres  = new GenreRepository(db);
    }

    public void Start()
    {
        Stop();
        _cts = new CancellationTokenSource();
        _ = Task.Run(() => RunAsync(_cts.Token));
    }

    public void Stop() => _cts?.Cancel();

    public async Task RunAsync(CancellationToken token)
    {
        GD.Print("[MetadataIndexer] Started.");

        while (!token.IsCancellationRequested)
        {
            var batch = _songs.GetUnindexedPaths(8);

            if (batch.Count == 0)
            {
                GD.Print("[MetadataIndexer] All songs indexed.");
                CallDeferred(GodotObject.MethodName.EmitSignal, SignalName.SongsIndexEnd);
                Stop();
                return;
            }

            var tasks = new List<Task>();
            foreach (var path in batch)
            {
                await _throttle.WaitAsync(token);
                tasks.Add(Task.Run(async () =>
                {
                    try   { await ProcessOne(path); }
                    finally { _throttle.Release(); }
                }, token));
            }

            await Task.WhenAll(tasks);
        }
    }

    private async Task ProcessOne(string path)
    {
        GD.Print($"[MetadataIndexer] Processing: {path}");

        var song = ReadTags(path);
        if (song is null) return;

        using var connection = _db.GetConnection();

        // Extract and clear artist
        var trackArtists = ArtistParser.SplitArtists(song.Artist);
        

        string albumArtistName = trackArtists.Count > 0 ? trackArtists[0] : "Unknown";

        long albumArtistId = _artists.UpsertArtist(albumArtistName, connection);
        long genreId       = _genres.UpsertGenre(song.Genre, connection);
        long albumId       = _albums.UpsertAlbum(song.Album, albumArtistId, genreId, song.Year, song.ArtPath, connection);

        _songs.UpdateMetadata(song, albumId);

        // Clear old artists from the track
        using var clearCmd = connection.CreateCommand();
        clearCmd.CommandText = "DELETE FROM song_artists WHERE song_path = $path";
        clearCmd.Parameters.AddWithValue("$path", song.FilePath);
        clearCmd.ExecuteNonQuery();

        // Individual feat.
        for (int i = 0; i < trackArtists.Count; i++)
        {
            long trackArtistId = _artists.UpsertArtist(trackArtists[i], connection);
            
            using var insertCmd = connection.CreateCommand();
            insertCmd.CommandText = @"
                INSERT OR IGNORE INTO song_artists (song_path, artist_id, is_main)
                VALUES ($path, $artistId, $isMain)
            ";
            insertCmd.Parameters.AddWithValue("$path", song.FilePath);
            insertCmd.Parameters.AddWithValue("$artistId", trackArtistId);
            insertCmd.Parameters.AddWithValue("$isMain", i == 0 ? 1 : 0);
            insertCmd.ExecuteNonQuery();
        }
    }

    private static SongModel ReadTags(string path)
    {
        try
        {
            using var file = TagLib.File.Create(path);
            var tag  = file.Tag;
            var prop = file.Properties;


            string rawArtist = tag.FirstPerformer ?? tag.FirstAlbumArtist ?? "Unknown";

            return new SongModel
            {
                FilePath = path,
                FileName = Path.GetFileName(path),
                Title    = !string.IsNullOrWhiteSpace(tag.Title)
                               ? tag.Title
                               : Path.GetFileNameWithoutExtension(path),
                Artist   = rawArtist,
                Album    = tag.Album          ?? "Unknown",
                Genre    = tag.FirstGenre     ?? "Unknown",
                Length   = (long)prop.Duration.TotalMilliseconds,
                Year     = tag.Year,
                Lyrics   = tag.Lyrics ?? string.Empty,
            };
        }
        catch (Exception ex)
        {
            GD.PrintErr($"[MetadataIndexer] Failed to read tags for {path}: {ex.Message}");
            return new SongModel
            {
                FilePath = path,
                FileName = Path.GetFileName(path),
                Title    = Path.GetFileNameWithoutExtension(path),
                Artist   = "Unknown",
                Album    = "Unknown",
                Genre    = "Unknown",
                Length   = 0,
                Year     = 0,
                Lyrics   = string.Empty,
            };
        }
    }

}