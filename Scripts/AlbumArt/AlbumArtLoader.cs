using Godot;
using TagLib;
using System.IO;

namespace PlayStar.Scripts.AlbumArt;
[GlobalClass]
public partial class AlbumArtLoader : RefCounted
{
    private static readonly string[] CoverNames = ["cover.jpg", "cover.png", "folder.jpg", "album.jpg"];
    
    public static Texture2D GetAlbumArt(string songPath)
    {
        string directory = Path.GetDirectoryName(songPath);

        foreach(var name in CoverNames)
        {
            string fullPath = Path.Combine(directory, name);
            if (System.IO.File.Exists(fullPath))
            {
                return LoadTextureFromFile(fullPath);
            }
        }
        try
        {
            using var file = TagLib.File.Create(songPath);
            if (file.Tag.Pictures.Length > 0)
            {
                var bin = file.Tag.Pictures[0].Data.Data;
                return LoadTextureFromBytes(bin);
            }
        }
        catch(System.Exception e)
        {
            GD.Print("Error reading cover: " + e.Message);
        }

        return null;
    }

    // TODO: Update from Texture2D to ImageTexture
    private static Texture2D LoadTextureFromFile(string path)
    {
        var image = Image.LoadFromFile(path);
        return ImageTexture.CreateFromImage(image);
    }

    private static Texture2D LoadTextureFromBytes(byte[] data)
    {
        var image = new Image();
        Error err = image.LoadJpgFromBuffer(data);
        if (err != Error.Ok) err = image.LoadPngFromBuffer(data);
        if (err == Error.Ok) return ImageTexture.CreateFromImage(image);
        return null;
    }

}