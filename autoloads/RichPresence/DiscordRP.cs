using Godot;
using DiscordRPC;
using DiscordRPC.Logging;
using System;

using PlayStar.Scripts.Models;
namespace PlayStar.autoloads.DiscordRP;

public partial class DiscordRP : Node
{
    public DiscordRpcClient Client;
    private SongModel _currentTrack;
    private bool showAlbumName;
    private GodotObject _userTools;
    private Resource _userConfig;
    public override void _Ready()
    {
        _userTools = GetNode("/root/UserTools");
        if (_userTools != null)
        {
            _userConfig = (Resource)(GodotObject)_userTools.Call("get_config");
            _userTools.Connect("discord_rp_changed", new Callable(this, nameof(OnDiscordRpChanged)));
        }

        showAlbumName = (bool)_userConfig.Get("show_album_name");
        var configStartDRP = (bool)_userConfig.Get("start_discord_rp");
        if (configStartDRP) StartDiscordRP();
    }

    private void OnDiscordRpChanged(bool enabled)
    {
        GD.Print($"DISCORD RP CHANGED: {enabled}");

        if (enabled)
        {
            if (Client == null) StartDiscordRP();
        }
        else
        {
            Client?.Dispose();
            Client = null;
        }
    }

    public void StartDiscordRP()
    {
        Client = new DiscordRpcClient("1487655456968278226")
        {
            Logger = new ConsoleLogger() { Level = LogLevel.Warning }
        };
        Client.OnReady += (sender, e) =>
        {
            GD.Print($"Discord ready for user: {e.User.DisplayName}");
        };
        Client.Initialize();
    }

    public void OnMusicStop()
    {
        Assets base_assets = new()
        {
            LargeImageKey = "cd",
            SmallImageKey = "play_icon",
            LargeImageText = showAlbumName ? "..." : "",
        };

        Client.SetPresence(new RichPresence()
        {
            Details = "Not playing.",
            State = "...",
            Type = ActivityType.Listening,
            Timestamps = new Timestamps(),
            Assets = base_assets,
            Buttons =
            [
                new DiscordRPC.Button() { Label = "GitHub", Url = "https://github.com/hayukimori" }
            ]
        });
    }

    public void OnMusicPlay(SongModel song, long currentPosition)
    {

        if (Client == null) return;

        _currentTrack = song;

        TimeSpan t = TimeSpan.FromMilliseconds(song.Length);
        TimeSpan u = TimeSpan.FromMilliseconds(currentPosition);

        double songLengthSeconds = t.TotalSeconds;
        double songPositionSeconds = u.TotalSeconds;
        double remainingSeconds = songLengthSeconds - songPositionSeconds;

        Assets base_assets = new()
        {
            LargeImageKey = "cd",
            SmallImageKey = "play_icon",
            LargeImageText = showAlbumName ? song.Album : "",
        };


        Client.SetPresence(new RichPresence()
        {
            Details = song.Title,
            State = song.Artist,
            Type = ActivityType.Listening,
            Timestamps = new Timestamps()
            {
                Start = DateTime.UtcNow.AddSeconds(-songPositionSeconds),
                End = DateTime.UtcNow.AddSeconds(remainingSeconds)
            },
            Assets = base_assets,
            Buttons =
            [
                new DiscordRPC.Button() { Label = "GitHub", Url = "https://github.com/hayukimori" }
            ]
        });
    }

    public void OnMusicPause()
    {
        if (Client == null) return;

        Client.SetPresence(new RichPresence()
        {
            Details = $"(Pause) {_currentTrack.Title}",
            State = _currentTrack.Artist,
            Type = ActivityType.Listening,
            Assets = new Assets()
            {
                LargeImageKey = "cd",
                SmallImageKey = "pause_icon"
            }
        });
    }

    public void OnMusicSeek(long newPosition)
    {
        OnMusicPlay(_currentTrack, newPosition);
    }

    public override void _Process(double delta)
    {
        Client?.Invoke();
    }

    public override void _ExitTree()
    {
        Client?.Dispose();
    }
}
