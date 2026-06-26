using Godot;
using DiscordRPC;
using DiscordRPC.Logging;
using System;

using PlayStar.Scripts.Models;
namespace PlayStar.autoloads.DiscordRP;

public partial class DiscordRP : Node
{
    // Var
    public DiscordRpcClient Client;
    private SongModel _currentTrack;
    private GodotObject _userGlobals;
    private GodotObject _signalBus;

    // Config
    private Resource _userConfig;
    private bool showAlbumName;

    // const
    private const string _rpClientId = "1487655456968278226";
    public enum PlayerStatus { Off, Playing, Pause, Stop };


    public override void _Ready()
    {
        _userGlobals = GetNode("/root/UserGlobals");
        _signalBus = GetNode("/root/SignalBus");

        if (_userGlobals != null)
        {
            _userConfig = (Resource)(GodotObject)_userGlobals.Call("get_config");

            _signalBus.Connect("discord_rp_changed", new Callable(this, nameof(OnDiscordRpChanged)));
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
        Client = new DiscordRpcClient(_rpClientId)
        {
            Logger = new ConsoleLogger() { Level = LogLevel.Warning }
        };
        Client.OnReady += (sender, e) =>
        {
            GD.Print($"Discord ready for user: {e.User.DisplayName}");
        };
        Client.Initialize();
    }


    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private Assets GetAssets(PlayerStatus status, SongModel song = null)
    {
        string smallIcon = status switch
        {
            PlayerStatus.Playing => "play_icon",
            PlayerStatus.Pause => "pause_icon",
            _ => "play_icon"
        };

        string largeText = showAlbumName ? (song?.Album ?? "...") : "";

        return new Assets()
        {
            LargeImageKey = "cd",
            SmallImageKey = smallIcon,
            LargeImageText = largeText,
        };
    }

    private void ApplyPresence(RichPresence presence)
    {
        if (Client == null) return;
        Client.SetPresence(presence);
    }


    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    public void OnMusicStop()
    {
        ApplyPresence(new RichPresence()
        {
            Details = "Not playing.",
            State = "...",
            Type = ActivityType.Listening,
            Timestamps = new Timestamps(),
            Assets = GetAssets(PlayerStatus.Stop),
            Buttons = [new DiscordRPC.Button() { Label = "PlayStar", Url = "https://github.com/hayukimori/PlayStar" }]
        });
    }

    public void OnMusicPlay(SongModel song, long currentPosition)
    {
        if (Client == null) return;

        _currentTrack = song;

        double songLengthSeconds = TimeSpan.FromMilliseconds(song.Length).TotalSeconds;
        double songPositionSeconds = TimeSpan.FromMilliseconds(currentPosition).TotalSeconds;
        double remainingSeconds = songLengthSeconds - songPositionSeconds;

        ApplyPresence(new RichPresence()
        {
            Details = song.Title,
            State = song.Artist,
            Type = ActivityType.Listening,
            Timestamps = new Timestamps()
            {
                Start = DateTime.UtcNow.AddSeconds(-songPositionSeconds),
                End = DateTime.UtcNow.AddSeconds(remainingSeconds)
            },
            Assets = GetAssets(PlayerStatus.Playing, song),
            Buttons = [new DiscordRPC.Button() { Label = "PlayStar", Url = "https://github.com/hayukimori/PlayStar" }]
        });
    }

    public void OnMusicPause()
    {
        if (Client == null) return;

        ApplyPresence(new RichPresence()
        {
            Details = $"(Pause) {_currentTrack.Title}",
            State = _currentTrack.Artist,
            Type = ActivityType.Listening,
            Assets = GetAssets(PlayerStatus.Pause, _currentTrack),
        });
    }

    public void OnMusicSeek(long newPosition)
    {
        OnMusicPlay(_currentTrack, newPosition);
    }


    // -------------------------------------------------------------------------
    // Godot
    // -------------------------------------------------------------------------

    public override void _Process(double delta)
    {
        Client?.Invoke();
    }

    public override void _ExitTree()
    {
        Client?.Dispose();
    }
}
