using Godot;

namespace PlayStar.Scripts.Models;

[GlobalClass]
public partial class ListenBrainzConfig : Resource
{
    [Export] public string ApiKey { get; set; } = "";
    [Export] public bool IsEnabled { get; set; } = false;

    private const string SavePath = "user://listenbrainz.tres";

    public static ListenBrainzConfig LoadOrCreate()
    {
        if (ResourceLoader.Exists(SavePath))
            return ResourceLoader.Load<ListenBrainzConfig>(SavePath);

        var config = new ListenBrainzConfig();
        config.Save();
        return config;
    }

    public void Save() => ResourceSaver.Save(this, SavePath);
}
