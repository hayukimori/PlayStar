using Godot;

namespace PlayStar2.scripts.models;

[GlobalClass]
public partial class ArtistModel : Resource
{
    [Export] public long   Id          { get; set; }
    [Export] public string Name        { get; set; }
    [Export] public int    SongsCount  { get; set; }
    [Export] public int    AlbumsCount { get; set; }
}
