using System;
using System.Runtime.InteropServices;
using Godot;

namespace PlayStar.Scripts.Utils;

[GlobalClass]
public partial class MiscTools : Node
{
    // Converts Miliseconds to Seconds as string (e.g 2:36)
    public static string MsToSec(long milliseconds)
    {
        var t = TimeSpan.FromMilliseconds(milliseconds);
        return $"{(int)t.TotalMinutes:00}:{t.Seconds:00}";
    }

    // Copies file to clipboard
    public static void CopyFileToClipboard(string path, bool asImage = false)
    {
        string globalPath = ProjectSettings.GlobalizePath(path);
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            ExecuteLinuxCopy(globalPath, asImage);
        }
    }

    public static void ExecuteLinuxCopy(string path, bool asImage)
    {
        string mimeType = asImage ? "image/png" : "text/uri-list";
        string content = asImage ? $"< '{path}'" : $"<<< 'file://{path}'";
        string command = $"wl-copy --type {mimeType} {content} || " +
                        $"xclip -selection clipboard -t {mimeType} -i '{path}'";
        string[] args = ["-c", command];
        OS.Execute("sh", args);
    }
}
