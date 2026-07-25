using Godot;
using Godot.Collections;
using System.Collections.Generic;
using System.IO;

namespace PlayStar.Scripts.Core;

[GlobalClass]
public partial class FolderScanner : Node
{
    private static readonly string[] SupportedExtensions =
    [
        ".mp3", ".flac", ".ogg", ".wav", ".m4a"
    ];

    public static List<string> Scan(string root)
    {
        var result = new List<string>();
        var stack = new Stack<string>();
        stack.Push(root);

        while (stack.Count > 0)
        {
            var dir = stack.Pop();

            try
            {
                foreach (var sub in Directory.GetDirectories(dir))
                    stack.Push(sub);
                foreach (var file in Directory.GetFiles(dir))
                {
                    var ext = Path.GetExtension(file).ToLowerInvariant();
                    if (System.Array.Exists(SupportedExtensions, e => e == ext))
                        result.Add(file);
                }
            }
            catch
            {
                GD.PrintErr($"[FolderScanner] Fail reading directory: {dir}");
            }
        }

        return result;
    }
}
