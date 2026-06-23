using Godot;

namespace PlayStar.Scripts.Models;
[GlobalClass]
public partial class AlbumModel : Resource
{
    [Export] public long   Id          { get; set; }
    [Export] public long   ArtistId    { get; set; }
    [Export] public long   GenreId     { get; set; }
    [Export] public string AlbumName   { get; set; }
    [Export] public string AlbumArtist { get; set; } // populado via JOIN
    [Export] public string Genre       { get; set; } // populado via JOIN
    [Export] public string ArtPath     { get; set; }
    [Export] public int    Year        { get; set; }

    [Export] public Godot.Collections.Array<SongModel> Songs { get; set; } = [];

    public void AddSong(SongModel song) => Songs.Add(song);
    public void RemoveSong(SongModel song) => Songs.Remove(song);
}
