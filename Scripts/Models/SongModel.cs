using Godot;

namespace PlayStar.Scripts.Models;
[GlobalClass]
public partial class SongModel: Resource
{
    [Export] public long   AlbumId  { get; set; }
    [Export] public string Title    { get; set; }
    [Export] public string Artist   { get; set; }
    [Export] public string Album    { get; set; }
    [Export] public string Genre    { get; set; }
    [Export] public float  Bpm      { get; set; }
    [Export] public long   Length   { get; set; } // ms
    [Export] public uint   Year     { get; set; }
    [Export] public string FilePath { get; set; }
    [Export] public string FileName { get; set; }
    [Export] public string ArtPath  { get; set; }
    [Export] public string Lyrics   { get; set; }

    [Export] public Texture2D AlbumArtTexture { get; set; }
}