using Godot;

/// <summary>
/// Abstract class for AudioPlayer (VlcPlayer, MpvPlayer, etc.)
/// </summary>

namespace PlayStar.Scripts.Models;
public abstract partial class AudioPlayer : Node
{
    // Signals
    #region Signals
    [Signal] public delegate void MusicStartedEventHandler();
    [Signal] public delegate void MusicEndedEventHandler();
    [Signal] public delegate void VolumeChangedExternallyEventHandler(int volume);
    #endregion


    // States
    #region States
    public abstract string PlayerModel {get;}

    public abstract bool IsLoaded  { get; }
    public abstract bool IsPlaying { get; }

    /// <summary>Current position (ms).</summary>
    public abstract long Time   { get; }

    /// <summary>Complete Length (ms).</summary>
    public abstract long Length { get; }

    /// <summary>Normalized position 0.0–1.0.</summary>
    public abstract float Position { get; set; }

    public abstract string FormatedCurrentTime { get; }
    public abstract string FormatedLength      { get; }

    public abstract Godot.Texture2D CoverTexture { get; }
    #endregion

    #region Functions
    // ── Life cycle ────────────────────────────────────────────────────────

    public abstract void Initialize();

    // ── Playback ─────────────────────────────────────────────────────────────

    public abstract void Load(string path);
    public abstract void Play();
    public abstract void Pause();
    public abstract void Stop();

    // ── Volume ───────────────────────────────────────────────────────────────

    public abstract void SetVolume(int value);
    public abstract void SetVolumeFromFloat(float value);
    public abstract int  GetVolume();

    // ── Seek ─────────────────────────────────────────────────────────────────

    public abstract void SeekSeconds(double seconds);
    public abstract void SeekByPercentage(float sliderValue);

    // ── Format ───────────────────────────────────────────────────────────

    public abstract string FormatTime(long milliseconds);

    #endregion

}
