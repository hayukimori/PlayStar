using System;
using Godot;
using PlayStar.Scripts.Models;

namespace PlayStar.autoloads.MiscAutoloads;
public partial class GTKThemeProvider : Node
{
    [Signal]
    public delegate void ColorsLoadedEventHandler(GTKColorPalette palette);

    public bool IsAvailable { get; private set; }

    private string _bridgePath = "";
    private string _outputPath = "";

    public override void _Ready()
    {
        if (OS.GetName() != "Linux")
            return;
        var execDir = OS.GetExecutablePath().GetBaseDir();
        var isEditor = execDir.Contains("godot") || OS.HasFeature("editor");
        if (isEditor)
            {
                // fallback dev
                _bridgePath = ProjectSettings.GlobalizePath("/usr/share/playstar/PlayStarGTKBridge");
            }
            else
            {
                _bridgePath = execDir.PathJoin("PlayStarGTKBridge");
            }

        _outputPath = ProjectSettings.GlobalizePath("user://gtk_colors.json");

        IsAvailable = Godot.FileAccess.FileExists(_bridgePath);
        if (IsAvailable)
        {
            Console.WriteLine("[GTKThemeProvider] PlayStarGTKBridge is available");
        }
        else{
            Console.WriteLine("[GTKThemeProvider] PlayStarGTKBridge NOT available");
            Console.WriteLine(OS.GetExecutablePath().GetBaseDir());
        }
    }

    public Error FetchColors()
    {
        if (!IsAvailable)
        {
            Console.WriteLine("[GtkThemeProvider] Error: PlayStarGTKBridge is not available;");
            return Error.FileNotFound;
        }

        var result = OS.Execute(_bridgePath, []);
        if (result != 0)
        {
            Console.WriteLine("[GtkThemeProvider] Error: Result is not 0;");
            GD.Print(result);
            return Error.Failed;
        }

        if (!Godot.FileAccess.FileExists(_outputPath))
        {
            Console.WriteLine("[GtkThemeProvider] Error: Output file does not exists;");
            return Error.Failed;
        }


        var palette = GTKColorParser.FromJson(_outputPath);
        palette.PaletteName = "GTK Current";

        if (palette is not null)
            EmitSignal(SignalName.ColorsLoaded, palette);
        return Error.Ok;
    }
}
