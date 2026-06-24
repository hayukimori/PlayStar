using Godot;


namespace PlayStar.Scripts.Models;
[GlobalClass]
public partial class ArtistModel : Resource
{
    [Export] public long   Id          { get; set; }
    [Export] public string Name        { get; set; }
    [Export] public int    SongsCount  { get; set; }
    [Export] public int    AlbumsCount { get; set; }
}
