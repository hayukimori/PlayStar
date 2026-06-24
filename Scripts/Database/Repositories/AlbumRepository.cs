using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;
using PlayStar.Scripts.Models;


namespace PlayStar.Scripts.Database.Repositories;
[GlobalClass]
public partial class AlbumRepository : Node
{
    private DatabaseManager _db;

    public void Initialize(DatabaseManager db) => _db = db;

    #region Read
    public Array<AlbumModel> GetAllAlbums(int limit = 1000, bool ignoreUnknown = false)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();

        var whereClause = ignoreUnknown ? "WHERE ar.name <> 'Unknown'" : "";

        cmd.CommandText = $@"
            SELECT
                al.id, al.title, al.art_path, al.year,
                ar.id, ar.name,
                g.name,
                s.path, s.title, s.length, s.lyrics,
                (SELECT GROUP_CONCAT(name, ', ') FROM (
                    SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                    WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                )) AS track_artist
            FROM albums al
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
            LEFT JOIN songs   s  ON s.album_id   = al.id
            {whereClause}
            ORDER BY al.title ASC, s.title ASC
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        return BuildAlbumList(reader);
    }

    public Array<AlbumModel> GetAlbumsFromArtist(ArtistModel artist, int limit = 1000)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                al.id, al.title, al.art_path, al.year,
                ar.id, ar.name,
                g.name,
                s.path, s.title, s.length, s.lyrics,
                (SELECT GROUP_CONCAT(name, ', ') FROM (
                    SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                    WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                )) AS track_artist
            FROM albums al
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
            LEFT JOIN songs   s  ON s.album_id   = al.id
            WHERE ar.id = $artistId
            ORDER BY al.title ASC, s.title ASC
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$artistId", artist.Id);
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        return BuildAlbumList(reader);
    }

    public AlbumModel GetAlbum(string albumTitle, long artistId)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                al.id, al.title, al.art_path, al.year,
                ar.id, ar.name,
                g.name,
                s.path, s.title, s.length, s.lyrics,
                (SELECT GROUP_CONCAT(name, ', ') FROM (
                    SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                    WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                )) AS track_artist
            FROM albums al
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
            LEFT JOIN songs   s  ON s.album_id   = al.id
            WHERE al.title = $title AND ar.id = $artistId
            ORDER BY s.title ASC;
        ";
        cmd.Parameters.AddWithValue("$title",    albumTitle);
        cmd.Parameters.AddWithValue("$artistId", artistId);

        using var reader = cmd.ExecuteReader();
        var list = BuildAlbumList(reader);
        return list.Count > 0 ? list[0] : null;
    }
    #endregion

    #region Write
    public long UpsertAlbum(string title, long artistId, long genreId, uint year, string artPath, SqliteConnection connection)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO albums(title, artist_id, genre_id, year, art_path)
            VALUES($title, $artistId, $genreId, $year, $artPath)
            ON CONFLICT(title, artist_id) DO UPDATE SET
                genre_id = COALESCE(excluded.genre_id, albums.genre_id),
                year     = COALESCE(excluded.year,     albums.year),
                art_path = COALESCE(NULLIF(excluded.art_path, ''), albums.art_path)
            RETURNING id;
        ";
        cmd.Parameters.AddWithValue("$title",    title);
        cmd.Parameters.AddWithValue("$artistId", artistId);
        cmd.Parameters.AddWithValue("$genreId",  genreId == 0 ? (object)System.DBNull.Value : genreId);
        cmd.Parameters.AddWithValue("$year",     year == 0    ? (object)System.DBNull.Value : year);
        cmd.Parameters.AddWithValue("$artPath",  artPath ?? "");
        var result = cmd.ExecuteScalar();
        return (long)result;
    }
    #endregion

    #region Helpers
    public static Array<AlbumModel> BuildAlbumList(SqliteDataReader reader)
    {
        var albumMap = new System.Collections.Generic.Dictionary<long, AlbumModel>();
        var order    = new System.Collections.Generic.List<long>();

        while (reader.Read())
        {
            long albumId = reader.IsDBNull(0) ? -1 : reader.GetInt64(0);

            if (!albumMap.TryGetValue(albumId, out var album))
            {
                album = new AlbumModel
                {
                    Id          = albumId,
                    AlbumName   = reader.IsDBNull(1) ? "" : reader.GetString(1),
                    ArtPath     = reader.IsDBNull(2) ? "" : reader.GetString(2),
                    Year        = reader.IsDBNull(3) ? 0  : reader.GetInt32(3),
                    ArtistId    = reader.IsDBNull(4) ? 0  : reader.GetInt64(4),
                    AlbumArtist = reader.IsDBNull(5) ? "" : reader.GetString(5),
                    Genre       = reader.IsDBNull(6) ? "" : reader.GetString(6),
                };
                albumMap[albumId] = album;
                order.Add(albumId);
            }

            if (!reader.IsDBNull(7))
            {
                var song = new SongModel
                {
                    FilePath = reader.GetString(7),
                    FileName = System.IO.Path.GetFileName(reader.GetString(7)),
                    Title    = reader.IsDBNull(8)  ? "" : reader.GetString(8),
                    Length   = reader.IsDBNull(9)  ? 0  : reader.GetInt64(9),
                    Lyrics   = reader.IsDBNull(10) ? "" : reader.GetString(10),
                    AlbumId  = album.Id,
                    Album    = album.AlbumName,
                    Genre    = album.Genre,
                    ArtPath  = album.ArtPath,
                    Year     = (uint)album.Year,

                    Artist   = reader.FieldCount > 11 && !reader.IsDBNull(11) ? reader.GetString(11) : album.AlbumArtist
                };
                album.Songs.Add(song);
            }
        }

        var result = new Array<AlbumModel>();
        foreach (var id in order)
            result.Add(albumMap[id]);
        return result;
    }
    #endregion
}