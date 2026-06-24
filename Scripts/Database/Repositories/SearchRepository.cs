using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;
using PlayStar.Scripts.Models;

namespace PlayStar.Scripts.Database.Repositories;

[GlobalClass]
public partial class SearchRepository : Node
{
    private DatabaseManager _db;

    public void Initialize(DatabaseManager db) => _db = db;

    #region General Search
    public Array<SongModel> Search(string text)
    {
        var results = new Array<SongModel>();
        if (string.IsNullOrWhiteSpace(text)) return results;

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        // Looks at feats (sa), returns album data (al/ar)
        cmd.CommandText = @"
            SELECT DISTINCT
                s.path, s.title, s.length, s.lyrics,
                al.id, al.title, al.art_path, al.year,
                ar.id, ar.name,
                g.name
            FROM songs s
            LEFT JOIN albums  al ON s.album_id  = al.id
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
            LEFT JOIN song_artists sa ON sa.song_path = s.path
            LEFT JOIN artists feat_ar ON sa.artist_id = feat_ar.id
            WHERE s.indexed = 1
              AND (
                s.title       LIKE $query OR
                ar.name       LIKE $query OR
                feat_ar.name  LIKE $query OR
                al.title      LIKE $query
              )
            ORDER BY ar.name, al.title, s.title;
        ";
        cmd.Parameters.AddWithValue("$query", $"%{text}%");

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            results.Add(SongRepository.MapSong(reader));

        return results;
    }
    #endregion

    #region Artists Search
    public Array<ArtistModel> SearchArtists(string query)
    {
        var results = new Array<ArtistModel>();
        if (string.IsNullOrWhiteSpace(query)) return results;

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                ar.id,
                ar.name,
                COUNT(DISTINCT sa.song_path) AS songs_count,
                COUNT(DISTINCT al.id) AS albums_count
            FROM artists ar
            LEFT JOIN song_artists sa ON sa.artist_id = ar.id
            LEFT JOIN albums al ON al.artist_id = ar.id
            WHERE ar.name LIKE $query
            GROUP BY ar.id
            ORDER BY ar.name;
        ";
        cmd.Parameters.AddWithValue("$query", $"%{query}%");

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            results.Add(new ArtistModel
            {
                Id          = reader.GetInt64(0),
                Name        = reader.IsDBNull(1) ? "" : reader.GetString(1),
                SongsCount  = reader.IsDBNull(2) ? 0  : reader.GetInt32(2),
                AlbumsCount = reader.IsDBNull(3) ? 0  : reader.GetInt32(3),
            });
        }

        return results;
    }
    #endregion

    #region Albums Search
    public Array<AlbumModel> SearchAlbums(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return [];

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                al.id, al.title, al.art_path, al.year,
                ar.id, ar.name,
                g.name,
                s.path, s.title, s.length, s.lyrics
            FROM albums al
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
            LEFT JOIN songs   s  ON s.album_id   = al.id
            WHERE al.title LIKE $query
            ORDER BY al.title ASC, s.title ASC;
        ";
        cmd.Parameters.AddWithValue("$query", $"%{query}%");

        using var reader = cmd.ExecuteReader();
        return AlbumRepository.BuildAlbumList(reader);
    }
    #endregion
}