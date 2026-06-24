using Microsoft.Data.Sqlite;

namespace PlayStar.Scripts.Database.Repositories;

public class GenreRepository
{
    private readonly DatabaseManager _db;

    public GenreRepository(DatabaseManager db) => _db = db;

    // upserts genre and returns id (0 if name empty)
    public long UpsertGenre(string name, SqliteConnection connection)
    {
        if (string.IsNullOrWhiteSpace(name)) return 0;

        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO genres(name) VALUES($name)
            ON CONFLICT(name) DO UPDATE SET name = excluded.name
            RETURNING id;
        ";
        cmd.Parameters.AddWithValue("$name", name);
        var result = cmd.ExecuteScalar();
        return (long)result;
    }
}
