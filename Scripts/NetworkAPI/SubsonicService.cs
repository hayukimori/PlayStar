using Godot;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using PlayStar.Scripts.Models;
using System;
using System.Linq;

namespace PlayStar.Scripts.NetworkAPI;

/// <summary>
/// Autoload bridge between GDScript and SubsonicClient.
/// Add this node to your AutoLoad list in Project Settings.
///
/// GDScript usage:
///   SubsonicService.configure("http://<url>/", "admin", "password")
///   await SubsonicService.ping()
///   var artists = await SubsonicService.get_artists()
/// </summary>
[GlobalClass]
public partial class SubsonicService : Node
{
    #region Signals

    // Signals
    [Signal] public delegate void ConfiguredEventHandler();
    [Signal] public delegate void PingSucceededEventHandler();
    [Signal] public delegate void PingFailedEventHandler();
    [Signal] public delegate void ErrorEventHandler(string message);

    #endregion

    // Fields
    private SubsonicClient _client;
    private SubsonicConfig _config = null!;
    private CancellationTokenSource _cts = new();

    // Lifecycle
    public override void _Ready()
    {
        _config = SubsonicConfig.LoadOrCreate();

        if (_config.IsEnabled && !string.IsNullOrWhiteSpace(_config.ServerUrl))
            _client = new SubsonicClient(_config);
    }

    public override void _ExitTree()
    {
        _cts.Cancel();
        _client?.Dispose();
    }


    // Configuration


    /// <summary>
    /// Saves credentials and (re)initializes the client.
    /// Call this from your settings screen.
    /// </summary>
    public void Configure(string serverUrl, string username, string password)
    {
        _client?.Dispose();

        _config.ServerUrl = serverUrl;
        _config.Username = username;
        _config.Password = password;
        _config.IsEnabled = true;
        _config.Save();

        _client = new SubsonicClient(_config);
        EmitSignal(SignalName.Configured);
    }

    public SubsonicConfig ConfigureAndReturn(string serverUrl, string username, string password, bool isEnabled)
    {
        _config.ServerUrl = serverUrl;
        _config.Username = username;
        _config.Password = password;
        _config.IsEnabled = isEnabled;
        _config.Save();

        EmitSignal(SignalName.Configured);
        return _config;
    }

    /// <summary>Disables the Subsonic integration and clears credentials.</summary>
    public void Disconnect()
    {
        _client?.Dispose();
        _client = null;

        _config.IsEnabled = false;
        _config.ServerUrl = "";
        _config.Username = "";
        _config.Password = "";
        _config.Save();
    }

    /// <returns>True if a server is configured and enabled.</returns>
    public bool IsConnected() => _client != null && _config.IsEnabled;


    // Async bridge helpers


    // GDScript awaits on signals, not on Tasks directly.
    // Pattern: call method → it fires a signal with the result when done.
    // For methods that return data, we use a lightweight GDScript-friendly
    // approach: return a GodotTask-style using callables + deferred signals.
    //
    // For simplicity, each public method returns the result via a dedicated
    // signal OR falls back to the Error signal on failure.


    // Ping


    /// <summary>
    /// Pings the server. Emits PingSucceeded or PingFailed.
    /// GDScript: await SubsonicService.ping()
    /// </summary>
    public async void Ping()
    {
        if (!AssertClient()) return;
        try
        {
            var ok = await _client!.PingAsync(NewToken());
            if (ok) EmitSignal(SignalName.PingSucceeded);
            else EmitSignal(SignalName.PingFailed);
        }
        catch (System.Exception e) { EmitError(e); }
    }


    // Artists


    [Signal] public delegate void ArtistsFetchedEventHandler(Godot.Collections.Array<ArtistModel> artists);

    /// <summary>
    /// Fetches all artists. Emits ArtistsFetched on success.
    /// GDScript: var result = await SubsonicService.get_artists()
    /// </summary>
    public async void GetArtists()
    {
        if (!AssertClient()) return;
        try
        {
            var list = await _client!.GetArtistsAsync(NewToken());
            var result = new Godot.Collections.Array<ArtistModel>(list);
            EmitSignal(SignalName.ArtistsFetched, result);
        }
        catch (System.Exception e) { EmitError(e); }
    }


    // Albums


    [Signal] public delegate void AlbumsFetchedEventHandler(Godot.Collections.Array<AlbumModel> albums);
    [Signal] public delegate void AlbumDetailFetchedEventHandler(AlbumModel album);

    /// <summary>Fetches albums for a given artist ID. Emits AlbumsFetched.</summary>
    public async void GetAlbumsByArtist(string artistId, bool includeSongs = false)
    {
        if (!AssertClient()) return;
        try
        {
            var list = await _client!.GetAlbumsByArtistAsync(artistId, includeSongs, NewToken());
            var result = new Godot.Collections.Array<AlbumModel>(list);
            EmitSignal(SignalName.AlbumsFetched, result);
        }
        catch (System.Exception e) { EmitError(e); }
    }

    [Signal] public delegate void AllAlbumsFetchedEventHandler(Godot.Collections.Array<AlbumModel> albums);
    // <summary> Gets all albums from the server </summary>
    public async void GetAllAlbums(bool includeSongs = false)
    {
        if (!AssertClient()) return;
        try
        {
            var list = await _client!.GetAlbumListAsync(includeSongs, NewToken());
            var result = new Godot.Collections.Array<AlbumModel>(list);
            EmitSignal(SignalName.AllAlbumsFetched, result);
        }
        catch (System.Exception e) { EmitError(e); }
    }


    [Signal] public delegate void AlbumFetchedEventHandler(AlbumModel album);
    // <summary> Gets album by id </summary>
    public async void GetAlbumById(string albumId)
    {
        if (!AssertClient()) return;
        try
        {
            var album = await _client!.GetAlbumAsync(albumId, NewToken());
            EmitSignal(SignalName.AlbumFetched, album);

        }
        catch (System.Exception e) { EmitError(e); }
    }

    /// <summary>Fetches a single album with its songs. Emits AlbumDetailFetched.</summary>
    public async void GetAlbum(string albumId)
    {
        if (!AssertClient()) return;
        try
        {
            var album = await _client!.GetAlbumAsync(albumId.ToString(), NewToken());
            if (album != null)
                EmitSignal(SignalName.AlbumDetailFetched, album);
            else
                EmitSignal(SignalName.Error, $"Album {albumId} not found.");
        }
        catch (System.Exception e) { EmitError(e); }
    }


    // Songs


    [Signal] public delegate void SongFetchedEventHandler(SongModel song);

    /// <summary>Fetches a single song by ID. Emits SongFetched.</summary>
    public async void GetSong(string songId)
    {
        if (!AssertClient()) return;
        try
        {
            var song = await _client!.GetSongAsync(songId, NewToken());
            if (song != null)
                EmitSignal(SignalName.SongFetched, song);
            else
                EmitSignal(SignalName.Error, $"Song {songId} not found.");
        }
        catch (System.Exception e) { EmitError(e); }
    }

    [Signal] public delegate void AllSongsFetchedEventHandler(Godot.Collections.Array<SongModel> songs);
    public async void GetSongs()
    {
        if (!AssertClient()) return;
        try
        {
            List<SongModel> songs = await _client!.GetAllSongs(NewToken());

            if (songs != null)
            {
                var finalSongs = new Godot.Collections.Array<SongModel>(songs);
                EmitSignal(SignalName.AllSongsFetched, finalSongs);
            }
            else
            {
                EmitSignal(SignalName.Error, $"Songs not found or error");
            }

        }
        catch (System.Exception e)
        {
            EmitError(e);
        }
    }

    [Signal] public delegate void ArtistSongsFetchedEventHandler(Godot.Collections.Array<SongModel> songs);
    [Signal] public delegate void ArtistSongsFetchErrorEventHandler();
    public async void GetSongsByArtist(string artistId)
    {
        try
        {
            List<SongModel> songs = await _client!.GetSongsByArtist(artistId, NewToken());
            if (songs != null)
            {
                var finalSongs = new Godot.Collections.Array<SongModel>(songs);

                EmitSignal(SignalName.ArtistSongsFetched, finalSongs);
            }
            else
            {
                EmitSignal(SignalName.Error, "$Songs not found");
            }
        }
        catch (System.Exception e)
        {
            EmitSignal(SignalName.ArtistSongsFetchError);
            EmitError(e);
        }
    }

    /// <summary>
    /// Returns the stream URL for a song synchronously.
    /// Pass directly to LibVLC — no await needed.
    /// </summary>
    public string GetStreamUrl(string songId, int maxBitrateKbps = 0)
    {
        if (_client == null) return "";
        return maxBitrateKbps > 0
            ? _client.GetStreamUrl(songId, maxBitrateKbps)
            : _client.GetStreamUrl(songId);
    }

    /// <summary>Returns the cover art URL synchronously.</summary>
    public string GetCoverArtUrl(string id, int sizePixels = 0)
    {
        if (_client == null) return "";
        return sizePixels > 0
            ? _client.GetCoverArtUrl(id, sizePixels)
            : _client.GetCoverArtUrl(id);
    }


    // Search
    [Signal]
    public delegate void SearchCompletedEventHandler(
        Godot.Collections.Array<ArtistModel> artists,
        Godot.Collections.Array<AlbumModel> albums,
        Godot.Collections.Array<SongModel> songs);

    /// <summary>
    /// Searches the remote library. Emits SearchCompleted.
    /// GDScript: await SubsonicService.search("daft punk")
    /// </summary>
    public async void Search(string query, int artistCount = 5, int albumCount = 5, int songCount = 20)
    {
        if (!AssertClient()) return;
        try
        {
            var (artists, albums, songs) = await _client!.SearchAsync(query, artistCount, albumCount, songCount, NewToken());
            EmitSignal(SignalName.SearchCompleted,
                new Godot.Collections.Array<ArtistModel>(artists),
                new Godot.Collections.Array<AlbumModel>(albums),
                new Godot.Collections.Array<SongModel>(songs));
        }
        catch (System.Exception e) { EmitError(e); }
    }


    // Scrobble / Star

    /// <summary>
    /// Scrobbles a song as played. Fire-and-forget — no signal emitted.
    /// Call when the song has been playing for ~30s or 50% of its duration.
    /// </summary>
    public async void Scrobble(string songId)
    {
        if (_client == null) return;
        try { await _client.ScrobbleAsync(songId, NewToken()); }
        catch { /* scrobble failure is non-critical, swallow silently */ }
    }

    /// <summary>Stars a song. Fire-and-forget.</summary>
    public async void Star(string songId)
    {
        if (_client == null) return;
        try { await _client.StarAsync(songId, NewToken()); }
        catch (System.Exception e) { EmitError(e); }
    }

    /// <summary>Removes star from a song. Fire-and-forget.</summary>
    public async void Unstar(string songId)
    {
        if (_client == null) return;
        try { await _client.UnstarAsync(songId, NewToken()); }
        catch (System.Exception e) { EmitError(e); }
    }

    // Internals
    //
    private bool AssertClient()
    {
        if (_client != null) return true;
        EmitSignal(SignalName.Error, "Subsonic client is not configured. Call Configure() first.");
        return false;
    }

    private void EmitError(System.Exception e) =>
        EmitSignal(SignalName.Error, e.Message);

    /// <summary>
    /// Returns a fresh linked token so _ExitTree() cancels all in-flight requests.
    /// </summary>
    private CancellationToken NewToken() => _cts.Token;
}
