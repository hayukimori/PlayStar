using Godot;
using PlayStar.Scripts.Models;

public static class GTKColorParser
{
    public static GTKColorPalette? FromJson(string jsonPath)
    {
        if (!FileAccess.FileExists(jsonPath))
            return null;

        var raw = FileAccess.GetFileAsString(jsonPath);
        var data = Json.ParseString(raw).AsGodotDictionary();

        return new GTKColorPalette
        {
            DarkMode = data["dark_mode"].AsBool(),
            AccentColor = ParseColor(data, "accent_color"),
            AccentBgColor = ParseColor(data, "accent_bg_color"),
            AccentFgColor = ParseColor(data, "accent_fg_color"),
            WindowBgColor = ParseColor(data, "window_bg_color"),
            WindowFgColor = ParseColor(data, "window_fg_color"),
            ViewBgColor = ParseColor(data, "view_bg_color"),
            ViewFgColor = ParseColor(data, "view_fg_color"),
            HeaderbarBgColor = ParseColor(data, "headerbar_bg_color"),
            CardBgColor = ParseColor(data, "card_bg_color"),
            DestructiveColor = ParseColor(data, "destructive_color"),
            SuccessColor = ParseColor(data, "success_color"),
            WarningColor = ParseColor(data, "warning_color"),
        };
    }

    private static Color ParseColor(Godot.Collections.Dictionary data, string key)
    {
        var arr = data[key].AsFloat32Array();
        return new Color(arr[0], arr[1], arr[2], arr[3]);
    }
}
