using Godot;

namespace PlayStar.Scripts.Models;

// <summary>
// Stores subsonic credentials (.tres file)
// </summary>

[GlobalClass]
public partial class SubsonicConfig : Resource
{
    [Export] public string ServerUrl { get; set; } = "";
    [Export] public string Username { get; set; } = "";
    [Export] public string Password { get; set; } = "";
    [Export] public bool IsEnabled { get; set; } = false;

    private const string SavePath = "user://subsonic.tres";

    public static SubsonicConfig LoadOrCreate()
    {
        if (ResourceLoader.Exists(SavePath))
            return ResourceLoader.Load<SubsonicConfig>(SavePath);

        var config = new SubsonicConfig();
        config.Save();
        return config;
    }

    public void Save() => ResourceSaver.Save(this, SavePath);


}
