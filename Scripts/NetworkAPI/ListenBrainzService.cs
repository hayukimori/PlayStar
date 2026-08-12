using Godot;
using System.Threading;
using PlayStar.Scripts.Models;

namespace PlayStar.Scripts.NetworkAPI;

/// <summary>
/// Autoload bridge between GDScript and ListenBrainzClient.
/// Add this node to your AutoLoad list in Project Settings.
///
/// GDScript usage:
///   ListenBrainzService.configure("your-api-key")
///   ListenBrainzService.scrobble(audio_metadata_resource)
/// </summary>
[GlobalClass]
public partial class ListenBrainzService : Node
{
    #region Signals

    [Signal] public delegate void ConfiguredEventHandler();
    [Signal] public delegate void TokenValidEventHandler();
    [Signal] public delegate void TokenInvalidEventHandler();
    [Signal] public delegate void ErrorEventHandler(string message);

    #endregion

    private ListenBrainzClient _client;
    private ListenBrainzConfig _config = null!;
    private CancellationTokenSource _cts = new();

    public override void _Ready()
    {
        _config = ListenBrainzConfig.LoadOrCreate();

        if (_config.IsEnabled && !string.IsNullOrWhiteSpace(_config.ApiKey))
            _client = new ListenBrainzClient(_config.ApiKey);
    }

    public override void _ExitTree()
    {
        _cts.Cancel();
        _client?.Dispose();
    }

    // Configuration

    /// <summary>Saves the API key and (re)initializes the client.</summary>
    public void Configure(string apiKey)
    {
        _client?.Dispose();

        _config.ApiKey = apiKey;
        _config.IsEnabled = true;
        _config.Save();

        _client = new ListenBrainzClient(_config.ApiKey);
        EmitSignal(SignalName.Configured);
    }

    /// <summary>Disables the integration and clears the API key.</summary>
    public void Disconnect()
    {
        _client?.Dispose();
        _client = null;

        _config.ApiKey = "";
        _config.IsEnabled = false;
        _config.Save();
    }

    public ListenBrainzConfig ConfigureAndReturn(string apiKey, bool isEnabled)
    {
        _config.ApiKey = apiKey;
        _config.IsEnabled = isEnabled;
        _config.Save();

        if (isEnabled && !string.IsNullOrWhiteSpace(apiKey))
        {
            _client?.Dispose();
            _client = new ListenBrainzClient(apiKey);
        }

        EmitSignal(SignalName.Configured);
        return _config;
    }

    public bool IsConnected() => _client != null && _config.IsEnabled;

    // Validate

    /// <summary>Validates the current API key. Emits TokenValid or TokenInvalid.</summary>
    public async void ValidateToken()
    {
        if (!AssertClient()) return;
        try
        {
            var valid = await _client!.ValidateTokenAsync(NewToken());
            EmitSignal(valid ? SignalName.TokenValid : SignalName.TokenInvalid);
        }
        catch (System.Exception e) { EmitError(e); }
    }

    // Scrobble

    /// <summary>
    /// Scrobbles a song from an AudioMetadataResource.
    /// Only submits if MusicBrainzTrackId is present.
    /// Fire-and-forget — no signal emitted on success.
    /// </summary>
    public async void Scrobble(AudioMetadataResource meta)
    {
        if (_client == null || !_config.IsEnabled) return;
        if (string.IsNullOrWhiteSpace(meta?.MusicBrainzTrackId)) return;

        try
        {
            await _client.SubmitListenAsync(
                trackName:       meta.Title ?? "",
                artistName:      meta.Artists?.Length > 0 ? meta.Artists[0] : "",
                releaseName:     meta.Album,
                trackMbid:       meta.MusicBrainzTrackId,
                artistMbid:      meta.MusicBrainzArtistId,
                releaseMbid:     meta.MusicBrainzReleaseId,
                durationSeconds: meta.DurationSeconds > 0 ? meta.DurationSeconds : null,
                ct:              NewToken()
            );
        }
        catch { /* scrobble failure is non-critical, swallow silently */ }
    }

    /// <summary>
    /// Submits a "playing now" notification from an AudioMetadataResource.
    /// Only submits if MusicBrainzTrackId is present.
    /// Fire-and-forget.
    /// </summary>
    public async void SubmitPlayingNow(AudioMetadataResource meta)
    {
        if (_client == null || !_config.IsEnabled) return;
        if (string.IsNullOrWhiteSpace(meta?.MusicBrainzTrackId)) return;

        try
        {
            await _client.SubmitPlayingNowAsync(
                trackName:   meta.Title ?? "",
                artistName:  meta.Artists?.Length > 0 ? meta.Artists[0] : "",
                releaseName: meta.Album,
                trackMbid:   meta.MusicBrainzTrackId,
                artistMbid:  meta.MusicBrainzArtistId,
                releaseMbid: meta.MusicBrainzReleaseId,
                ct:          NewToken()
            );
        }
        catch { /* non-critical, swallow silently */ }
    }

    // Internals

    private bool AssertClient()
    {
        if (_client != null) return true;
        EmitSignal(SignalName.Error, "ListenBrainz client is not configured. Call Configure() first.");
        return false;
    }

    private void EmitError(System.Exception e) =>
        EmitSignal(SignalName.Error, e.Message);

    private CancellationToken NewToken() => _cts.Token;
}
