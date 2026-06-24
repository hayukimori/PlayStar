using Godot;
using System;
using LibVLCSharp.Shared;
using System.Threading.Tasks;

using PlayStar.Scripts.Models;
using PlayStar.Scripts.AlbumArt;
using PlayStar.autoloads.MediaAutoloads;

namespace PlayStar.Scripts.Players;

[GlobalClass]
public partial class VlcPlayer : AudioPlayer
{
    #region Initial variables

    private MediaPlayer _mediaPlayer;
    private Media _currentMedia;

    private string _playerModel = "vlc";
    public override string PlayerModel =>  _playerModel;


    private float _timer = 0f;
    private const float CheckInterval = 0.5f;    
    private int _lastKnownVolume = -1;

    public override bool IsLoaded => _mediaPlayer != null;
    public override bool IsPlaying => _mediaPlayer?.IsPlaying ?? false;
    public override string FormatedCurrentTime => FormatTime(Time);
    public override string FormatedLength => FormatTime(Length);

    public override long Time => _mediaPlayer?.Time ?? 0;
    public override long Length => _mediaPlayer?.Length ?? 0;

    private Texture2D _coverTexture;
    public override Texture2D CoverTexture => _coverTexture;


    public override float Position
    {
        get => _mediaPlayer?.Position ?? 0f;
        set
        {
            if (_mediaPlayer != null) _mediaPlayer.Position = Mathf.Clamp(value, 0f, 1f);
        }
    }
    #endregion

    #region Init
    public override void _Ready()
    {
        base._Ready();
    }
    

    public override void Initialize()
    {
        if (_mediaPlayer != null) return;

        _mediaPlayer = new MediaPlayer(MediaBackend.Instance.LibVlc);

        _mediaPlayer.Playing += OnPlaying;
        _mediaPlayer.EndReached += OnEndReached;
    }
    #endregion

    #region Media Control
    public override async void Load(string path)
    {        
        if (!System.IO.File.Exists(path))
        {
            GD.PrintErr($"File not found error: {path}");
            return;
        }

        if (_mediaPlayer == null)
        {
            GD.PushError("Vlc not initialized. Call 'Initialize()' first");
            return;
        }

        Stop();

        _currentMedia?.Dispose();
        _currentMedia = MediaBackend.Instance.CreateMedia(path);
        _mediaPlayer.Media = _currentMedia;
    }

    public static Texture2D GetTextureFrom(string path)
    {
        var texture = AlbumArtLoader.GetAlbumArt(path);
        return texture;
    }
    #endregion

    #region Play/Pause/Stop
    public override void Play()
    {
        if (_mediaPlayer?.Media == null)
        {
            GD.PrintErr("No loaded media");
            return;
        }
        _mediaPlayer.Play();
    }

    public override void Pause()
    {
        if (_mediaPlayer == null) return;
        if (_mediaPlayer.IsPlaying) _mediaPlayer.Pause();
    }

    public override void Stop()
    {
        if (_mediaPlayer == null) return;

        if (_mediaPlayer.IsPlaying)
            _mediaPlayer.Stop();

        _mediaPlayer.Media = null;
    }
    #endregion


    #region Volume Control
    // Volume Control
    public override void SetVolumeFromFloat(float value)
    {
        GD.Print("Setting volume to: ", value);
        _mediaPlayer.Volume = (int)value;
    }

    public override void SetVolume(int value)
    {
        _mediaPlayer.Volume = value;
    }

    public override int GetVolume()
    {
        return _mediaPlayer.Volume;
    }
    #endregion


    #region Player Seek
    public override void SeekSeconds(double seconds)
    {
        if (_mediaPlayer == null) return;
        _mediaPlayer.Time = (long)(seconds * 1000.0);
    }

    public override void SeekByPercentage(float sliderValue)
    {
        if (_mediaPlayer == null) return;

        float percentage = sliderValue / 100f;
        percentage = Mathf.Clamp(percentage, 0.0f, 1.0f);

        _mediaPlayer.Position = percentage;
    }

    #endregion

    #region Signals
    public void OnPlaying(object sender, EventArgs e)
    {
        CallDeferred(nameof(EmitMusicStarted));
    }


    public void OnEndReached(object sender, EventArgs e)
    {
        CallDeferred(nameof(EmitMusicEnded));
    }

    public void EmitMusicStarted()
    {
        EmitSignal(SignalName.MusicStarted);
    }

    public void EmitMusicEnded()
    {
        EmitSignal(SignalName.MusicEnded);
    }
    #endregion

    #region Time format
    public override string FormatTime(long miliseconds)
    {
        var t = TimeSpan.FromMilliseconds(miliseconds);
        return $"{(int)t.TotalMinutes:00}:{t.Seconds:00}";
    }
    #endregion

    #region Volume System
    public override void _Process(double delta)
    {
        _timer += (float)delta;

        if (_timer >= CheckInterval)
        {
            _timer = 0f;
            CheckSystemVolume();
        }
    }

    private void CheckSystemVolume()
    {
        if (_mediaPlayer == null) return;

        int currentVol = _mediaPlayer.Volume;
        if (currentVol != _lastKnownVolume)
        {
            _lastKnownVolume = currentVol;
            EmitSignal(SignalName.VolumeChangedExternally, currentVol);
        }
    }
    #endregion

    #region Cleanup
    public override void _ExitTree()
    {
        Cleanup();
    }

    private void Cleanup()
    {
        _mediaPlayer?.Stop();

        _currentMedia?.Dispose();
        _mediaPlayer?.Dispose();

        _currentMedia = null;
        _mediaPlayer = null;
    }

    #endregion

}