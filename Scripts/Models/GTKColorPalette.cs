using Godot;

namespace PlayStar.Scripts.Models;

[GlobalClass]
public partial class GTKColorPalette : Resource
{
    [Export] public string PaletteName { get; set; } = "";
    [Export] public bool DarkMode { get; set; }
    [Export] public Color AccentColor { get; set; }
    [Export] public Color AccentBgColor { get; set; }
    [Export] public Color AccentFgColor { get; set; }
    [Export] public Color WindowBgColor { get; set; }
    [Export] public Color WindowFgColor { get; set; }
    [Export] public Color ViewBgColor { get; set; }
    [Export] public Color ViewFgColor { get; set; }
    [Export] public Color HeaderbarBgColor { get; set; }
    [Export] public Color CardBgColor { get; set; }
    [Export] public Color DestructiveColor { get; set; }
    [Export] public Color SuccessColor { get; set; }
    [Export] public Color WarningColor { get; set; }
}
