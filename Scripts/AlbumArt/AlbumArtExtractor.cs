using Godot;
using TagLib;
using SkiaSharp;
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

            using var originalBitmap = SKBitmap.Decode(pictureData);
            if (originalBitmap == null) return null;

            float ratio = Math.Min(256f / originalBitmap.Width, 256f / originalBitmap.Height);
            int newWidth = Math.Max(1, (int)(originalBitmap.Width * ratio));
            int newHeight = Math.Max(1, (int)(originalBitmap.Height * ratio));


            var samplingOptions = new SKSamplingOptions(SKFilterMode.Linear, SKMipmapMode.Linear);
            using var resizedBitmap = originalBitmap.Resize(new SKImageInfo(newWidth, newHeight), samplingOptions);

            using var image = SKImage.FromBitmap(resizedBitmap);
            using var encodedData = image.Encode(SKEncodedImageFormat.Jpeg, 85);

            return encodedData.ToArray();
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

        foreach (var old in System.IO.Directory.GetFiles("/tmp", "playstar_cover_*.jpg"))
            System.IO.File.Delete(old);

        var tempPath = $"/tmp/playstar_cover_{Guid.NewGuid():N}.jpg";
        System.IO.File.WriteAllBytes(tempPath, bytes);
        return tempPath;
    }
}
