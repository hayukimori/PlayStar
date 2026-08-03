using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;
using PlayStar.Scripts.Models;

namespace PlayStar.Scripts.NetworkAPI;

/// <summary>
/// Subsonic/OpenSubsonic REST API client.
/// Uses token-based auth: MD5(password + salt) + salt in plain text.
/// Safe for LAN use; for remote access, ensure HTTPS on the server side.
/// </summary>
public sealed class SubsonicClient : IDisposable
{
    // Constants
    private const string ApiVersion = "1.16.1";
    private const string ClientName = "PlayStar";

    // Fields
    private readonly HttpClient _http;
    private readonly string _baseUrl;
    private readonly string _username;
    private readonly string _token;   // MD5(password + salt)
    private readonly string _salt;

    // Constructor
    public SubsonicClient(SubsonicConfig config)
    {
        if (string.IsNullOrWhiteSpace(config.ServerUrl))
            throw new ArgumentException("ServerUrl cannot be empty.");

        _baseUrl = config.ServerUrl.TrimEnd('/');
        _username = config.Username;
        (_token, _salt) = BuildTokenAuth(config.Password);

        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    }


    // Public API

    /// <summary>Checks server connectivity. Returns true if the server responds OK.</summary>
    public async Task<bool> PingAsync(CancellationToken ct = default)
    {
        try
        {
            var node = await GetAsync("ping", [], ct);
            return node != null;
        }
        catch { return false; }
    }

    /// <summary>Returns all artists grouped alphabetically.</summary>
    public async Task<List<ArtistModel>> GetArtistsAsync(CancellationToken ct = default)
    {
        var node = await GetAsync("getArtists", [], ct);
        var artists = new List<ArtistModel>();

        var indexes = node?["artists"]?["index"]?.AsArray();
        if (indexes == null) return artists;

        foreach (var index in indexes)
        {
            var entries = index?["artist"]?.AsArray();
            if (entries == null) continue;

            foreach (var entry in entries)
            {
                artists.Add(new ArtistModel
                {
                    ArtistIdSn = (entry?["id"].ToString()),
                    Name = entry?["name"]?.GetValue<string>() ?? "",
                    AlbumsCount = entry?["albumCount"]?.GetValue<int>() ?? 0,
                    ArtPath = entry?["artistImageUrl"]?.GetValue<string>() ?? ""
                });
            }
        }

        return artists;
    }

    /// <summary>Returns all albums for a given artist ID.</summary>
    public async Task<List<AlbumModel>> GetAlbumsByArtistAsync(string artistId, bool includeSongs = false, CancellationToken ct = default)
    {
        var node = await GetAsync("getArtist", [("id", artistId.ToString())], ct);
        var albums = new List<AlbumModel>();

        var entries = node?["artist"]?["album"]?.AsArray();
        if (entries == null) return albums;

        foreach (var entry in entries)
        {
            AlbumModel alb;
            alb = includeSongs ? await GetAlbumAsync(entry["id"].ToString()) : MapAlbum(entry);
            albums.Add(alb);
        }

        return albums;
    }

    // <summary> Reutns all albums in the server </summary>
    public async Task<List<AlbumModel>> GetAlbumListAsync(bool includeSongs, CancellationToken ct)
    {
        var page_size = 500;
        var current_offset = 0;
        var total = 0;

        List<AlbumModel> albums = [];

        while (true)
        {
            var node = await GetAsync(
                "getAlbumList2",
                [
                    ("type", "alphabeticalByArtist"),
                    ("size", page_size.ToString()),
                    ("offset", current_offset.ToString())
                ],
                ct
            );
            var entries = node?["albumList2"]?["album"]?.AsArray();
            if (entries == null) break;

            total += entries.Count;


            foreach (var alb in entries)
            {
                var album = includeSongs ? await GetAlbumAsync(alb?["id"].ToString()) : MapAlbum(alb);
                albums.Add(album);
            }

            if (entries.Count < page_size) break;
            current_offset += page_size;
        }

        return albums;
    }

    /// <summary>Returns an album with its full song list.</summary>
    public async Task<AlbumModel> GetAlbumAsync(string albumId, CancellationToken ct = default)
    {
        var node = await GetAsync("getAlbum", [("id", albumId.ToString())], ct);
        var entry = node?["album"];
        if (entry == null) return null;

        var album = MapAlbum(entry);

        var songs = entry["song"]?.AsArray();
        if (songs != null)
            foreach (var s in songs)
                album.AddSong(MapSong(s));

        return album;
    }

    /// <summary>Returns a single song by ID.</summary>
    public async Task<SongModel> GetSongAsync(string songId, CancellationToken ct = default)
    {
        var node = await GetAsync("getSong", [("id", songId.ToString())], ct);
        var entry = node?["song"];
        return entry == null ? null : MapSong(entry);
    }

    // <summary>Returns a list of SongModel by artist </summary>
    public async Task<List<SongModel>> GetSongsByArtist(string artistId, CancellationToken ct = default)
    {
        var node = await GetAsync("getArtist", [("id", artistId.ToString())], ct);
        var entry = node?["artist"]["album"];
        var albums = entry?.AsArray();
        List<SongModel> songs = [];


        foreach (var album in albums)
        {
            var albumId = album["id"].ToString();
            var tmp_album = await GetAlbumAsync(albumId);

            foreach (var song in tmp_album.Songs)
            {
                songs.Add(song);
            }
        }

        return songs;
    }

    // <summary>Returns a list of all songs in the server</summary>
    public async Task<List<SongModel>> GetAllSongs(CancellationToken ct = default)
    {
        var pageSize = 500;
        var currentOffset = 0;
        var total = 0;

        List<SongModel> allSongs = [];

        while (true)
        {
            var node = await GetAsync(
                "search3",
                [
                    ("query", ""),
                    ("songCount", pageSize.ToString()),
                    ("songOffset", currentOffset.ToString()),
                    ("artistCount", "0"),
                    ("albumCount", "0"),
                ],
                ct
            );

            var entries = node?["searchResult3"]?["song"]?.AsArray();
            if (entries == null) break;

            total += entries.Count;

            foreach (var entry in entries)
            {
                SongModel song = MapSong(entry);
                allSongs.Add(song);
            }

            if (entries.Count < pageSize) break;
            currentOffset += pageSize;
        }

        return allSongs;
    }

    /// <summary>
    /// Returns the stream URL for a song. Pass this directly to LibVLC.
    /// LibVLC handles HTTP streaming natively — no manual downloading needed.
    /// </summary>
    public string GetStreamUrl(string songId, int? maxBitrateKbps = null)
    {
        var args = new List<(string, string)> { ("id", songId) };
        if (maxBitrateKbps.HasValue)
            args.Add(("maxBitRate", maxBitrateKbps.Value.ToString()));

        return BuildUrl("stream", args);
    }

    /// <summary>
    /// Returns the cover art URL for a song or album.
    /// Pass this to your existing art loading pipeline.
    /// </summary>
    public string GetCoverArtUrl(string id, int? sizePixels = null)
    {
        var args = new List<(string, string)> { ("id", id.ToString()) };
        if (sizePixels.HasValue)
            args.Add(("size", sizePixels.Value.ToString()));

        return BuildUrl("getCoverArt", args);
    }

    /// <summary>Searches artists, albums, and songs simultaneously.</summary>
    public async Task<(List<ArtistModel> Artists, List<AlbumModel> Albums, List<SongModel> Songs)>
        SearchAsync(string query, int artistCount = 5, int albumCount = 5, int songCount = 20, CancellationToken ct = default)
    {
        var args = new[]
        {
            ("query",       query),
            ("artistCount", artistCount.ToString()),
            ("albumCount",  albumCount.ToString()),
            ("songCount",   songCount.ToString()),
        };

        var node = await GetAsync("search3", args, ct);
        var result = node?["searchResult3"];

        var artists = result?["artist"]?.AsArray()?.Select(MapArtist).ToList() ?? [];
        var albums = result?["album"]?.AsArray()?.Select(MapAlbum).ToList() ?? [];
        var songs = result?["song"]?.AsArray()?.Select(MapSong).ToList() ?? [];

        return (artists, albums, songs);
    }

    /// <summary>
    /// Scrobbles a song play to the server (marks as played in Navidrome history).
    /// Call this when the song has been playing for a meaningful duration (e.g. 30s or 50%).
    /// </summary>
    public async Task ScrobbleAsync(string songId, CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        await GetAsync("scrobble",
        [
            ("id",         songId.ToString()),
            ("time",       now.ToString()),
            ("submission", "true"),
        ], ct);
    }

    /// <summary>Stars (favorites) a song.</summary>
    public Task StarAsync(string songId, CancellationToken ct = default) =>
        GetAsync("star", [("id", songId)], ct);

    /// <summary>Removes star from a song.</summary>
    public Task UnstarAsync(string songId, CancellationToken ct = default) =>
        GetAsync("unstar", [("id", songId)], ct);

    public void Dispose() => _http.Dispose();

    // Mapping helpers
    private ArtistModel MapArtist(JsonNode node) => new()
    {
        Id = ParseLong(node?["id"]),
        Name = node?["name"]?.GetValue<string>() ?? "",
        AlbumsCount = node?["albumCount"]?.GetValue<int>() ?? 0,
    };

    private AlbumModel MapAlbum(JsonNode node) => new()
    {
        IdSn = node?["id"].ToString(),
        ArtistIdSn = node?["artistId"].ToString(),
        AlbumName = node?["name"]?.GetValue<string>() ?? "",
        AlbumArtist = node?["artist"]?.GetValue<string>() ?? "",
        Genre = node?["genre"]?.GetValue<string>() ?? "",
        Year = node?["year"]?.GetValue<int>() ?? 0,
        ArtPath = GetCoverArtUrl(node?["id"].ToString()),
    };


    private SongModel MapSong(JsonNode node)
    {
        var songId = node["id"].ToString();
        return new SongModel
        {
            SongId = songId,
            AlbumId = ParseLong(node?["albumId"]),
            Title = node?["title"]?.GetValue<string>() ?? "",
            Artist = node?["artist"]?.GetValue<string>() ?? "",
            Album = node?["album"]?.GetValue<string>() ?? "",
            Genre = node?["genre"]?.GetValue<string>() ?? "",
            Year = (uint)(node?["year"]?.GetValue<int>() ?? 0),
            Length = (long)(node?["duration"]?.GetValue<int>() ?? 0) * 1000L, // s → ms
            FilePath = GetStreamUrl(songId),
            ArtPath = GetCoverArtUrl(songId),
        };
    }

    // HTTP / auth internals
    private async Task<JsonNode> GetAsync(
        string endpoint,
        IEnumerable<(string Key, string Value)> extraParams,
        CancellationToken ct)
    {
        var url = BuildUrl(endpoint, extraParams);

        using var response = await _http.GetAsync(url, ct);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync(ct);
        var root = JsonNode.Parse(json);

        var wrapper = root?["subsonic-response"];
        if (wrapper?["status"]?.GetValue<string>() != "ok")
        {
            var errorMsg = wrapper?["error"]?["message"]?.GetValue<string>() ?? "Unknown error";
            throw new SubsonicException(errorMsg);
        }

        return wrapper;
    }

    private string BuildUrl(string endpoint, IEnumerable<(string Key, string Value)> extraParams)
    {
        var sb = new StringBuilder();
        sb.Append(_baseUrl);
        sb.Append("/rest/");
        sb.Append(endpoint);
        sb.Append("?u="); sb.Append(Uri.EscapeDataString(_username));
        sb.Append("&t="); sb.Append(_token);
        sb.Append("&s="); sb.Append(_salt);
        sb.Append("&v="); sb.Append(ApiVersion);
        sb.Append("&c="); sb.Append(ClientName);
        sb.Append("&f=json");

        foreach (var (key, value) in extraParams)
        {
            sb.Append('&');
            sb.Append(Uri.EscapeDataString(key));
            sb.Append('=');
            sb.Append(Uri.EscapeDataString(value));
        }

        return sb.ToString();
    }

    /// <summary>
    /// Generates token-based auth credentials.
    /// token = MD5(password + salt), salt = random 8-char hex string.
    /// </summary>
    private static (string Token, string Salt) BuildTokenAuth(string password)
    {
        var salt = Guid.NewGuid().ToString("N")[..8]; // 8 random hex chars
        var input = Encoding.UTF8.GetBytes(password + salt);
        var hash = MD5.HashData(input);
        var token = Convert.ToHexString(hash).ToLowerInvariant();
        return (token, salt);
    }

    private static long ParseLong(JsonNode node)
    {
        if (node == null) return 0;
        // Subsonic IDs can come as string or number depending on the server
        if (node.GetValueKind() == System.Text.Json.JsonValueKind.String)
            return long.TryParse(node.GetValue<string>(), out var v) ? v : 0;
        return node.GetValue<long>();
    }
}

/// <summary>Thrown when the Subsonic server returns status="failed".</summary>
public sealed class SubsonicException(string message) : Exception(message);
