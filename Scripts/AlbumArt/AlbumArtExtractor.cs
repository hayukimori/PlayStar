using Godot;
using TagLib;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;
using System.IO;
using System;

namespace PlayStar.Scripts.AlbumArt;

[GlobalClass]
public partial class AlbumArtExtractor : Resource
{
    public static byte[] ExtractAndResize(string path)
    {
        try
        {
            using var file = TagLib.File.Create(path);

            if (file.Tag.Pictures.Length == 0)
                return null;

            var pictureData = file.Tag.Pictures[0].Data.Data;

            using var image = SixLabors.ImageSharp.Image.Load(pictureData);

            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Size = new Size(256, 256),
                Mode = ResizeMode.Max
            }));

            using var ms = new MemoryStream();
            image.Save(ms, new JpegEncoder { Quality = 85 });

            return ms.ToArray();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Extractor] {path}");
            Console.WriteLine(ex.ToString());
            return null;
        }
    }

    public static string ExtractToTempFile(string songPath)
    {
        var bytes = ExtractAndResize(songPath);
        if (bytes == null) return null;


        foreach (var old in System.IO.Directory.GetFiles("/tmp", "playstar2_cover_*.jpg"))
            System.IO.File.Delete(old);

        var tempPath = $"/tmp/playstar2_cover_{Guid.NewGuid():N}.jpg";
        System.IO.File.WriteAllBytes(tempPath, bytes);
        return tempPath;
    }
}