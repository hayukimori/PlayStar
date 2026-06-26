using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Tmds.DBus;


using PlayStar.Scripts.SystemIntegration.Mpris;
using PlayStar.Scripts.Models;

namespace PlayStar
{
    [GlobalClass]
    public partial class MprisService : Node
    {
        [Export] public NodePath PlayerPath { get; set; }

        private AudioPlayer _player;
        private Connection _connection;
        private MprisPlayerObject _playerObject;
        private bool _started = false;
        private Timer _positionTimer;
        private int _trackCounter = 0;

        public override void _Ready()
        {
            _player = GetNode<AudioPlayer>(PlayerPath);

            _player.MusicStarted += OnMusicStarted;
            _player.MusicEnded += OnMusicEnded;
            _player.VolumeChangedExternally += OnVolumeChanged;

            // Timer to emit position
            _positionTimer = new Timer();
            _positionTimer.WaitTime = 1.0;
            _positionTimer.Autostart = false;
            _positionTimer.Timeout += OnPositionTimerTimeout;
            AddChild(_positionTimer);

            _ = StartMprisAsync();
        }

        public override void _ExitTree()
        {
            _positionTimer?.Stop();
            _connection?.Dispose();
        }

        private void OnPositionTimerTimeout()
        {
            if (!_started || _playerObject == null) return;
            if (_player.IsPlaying)
                _playerObject.EmitPositionUpdate();
        }

        private async Task StartMprisAsync()
        {
            try
            {
                _connection = new Connection(Address.Session);
                await _connection.ConnectAsync();

                // registers object first, after it the service name-.
                // required
                _playerObject = new MprisPlayerObject(_player, GetNode("/root/SignalBus"));
                await _connection.RegisterObjectAsync(_playerObject);

                await _connection.RegisterServiceAsync("org.mpris.MediaPlayer2.playstar2");

                // Waits for frame to garant propagation
                await Task.Delay(50);

                _started = true;

                // Announces to mpris in a signal the with complete initial state
                GD.Print("[MprisService] MPRIS2 registered. Announcing initial state...");
                _playerObject.AnnounceToDesktop();

                GD.Print("[MprisService] MPRIS2 is registered to D-Bus.");
            }
            catch (Exception ex)
            {
                GD.PrintErr($"[MprisService] Fail to register MPRIS2: {ex.Message}");
            }
        }

        private void OnMusicStarted()
        {
            if (!_started) return;
            _playerObject?.SetPlaybackStatus("Playing");
            if (!_positionTimer.IsStopped()) _positionTimer.Start();
        }

        private void OnMusicEnded()
        {
            if (!_started) return;
            _playerObject?.SetPlaybackStatus("Stopped");
            _positionTimer.Stop();
        }

        private void OnVolumeChanged(int volume)
        {
            if (!_started) return;
            _playerObject?.SetVolume(volume / 100.0);
        }

        /// <summary>
        /// Updates metadata for new tracks;
        /// durationMs = miliseconds
        /// artFilePath = absolute path to album art (optional).
        /// </summary>
        public void UpdateMetadata(string title, string artist, string album,
                                   long durationMs, string artFilePath = null)
        {
            if (!_started || _playerObject == null) return;

            _trackCounter++;
            var trackId = $"/org/playstar2/track/{_trackCounter}";

            var meta = new Dictionary<string, object>
            {
                ["mpris:trackid"] = new ObjectPath(trackId),
                ["xesam:title"] = title,
                ["xesam:artist"] = new[] { artist },
                ["xesam:album"] = album,
                ["mpris:length"] = durationMs * 1000L,
            };

            if (!string.IsNullOrEmpty(artFilePath))
                meta["mpris:artUrl"] = $"file://{artFilePath}";

            _playerObject.SetTrack(meta);

            // Starts position timer
            _positionTimer.Start();

            GD.Print($"[MprisService] Track updated: {title} (id={trackId})");
        }

        /// <summary>
        /// Updates loopstatus on MPRIS (call if repeat mode changes)
        /// </summary>
        public void UpdateLoopStatus(string loopStatus)
        {
            if (!_started || _playerObject == null) return;
            _playerObject.SetLoopStatus(loopStatus);
        }

        /// <summary>
        /// Updates Shuffle on MPRIS (call when shuffle mode changes).
        /// </summary>
        public void UpdateShuffle(bool shuffle)
        {
            if (!_started || _playerObject == null) return;
            _playerObject.SetShuffle(shuffle);
        }

        /// <summary>
        /// Emits Seeked signal to plasma (call after seek on main player)
        /// </summary>
        public void EmitSeeked(long positionMicroseconds)
        {
            if (!_started || _playerObject == null) return;
            _playerObject.EmitSeekedSignal(positionMicroseconds);
        }
    }

    // ============================================================
    // D-Bus Object with unique events by interface
    // ============================================================

    internal class MprisPlayerObject : IMediaPlayer2, IMediaPlayer2Player
    {
        public ObjectPath ObjectPath => new ObjectPath("/org/mpris/MediaPlayer2");

        private readonly AudioPlayer _player;

        private string _playbackStatus = "Stopped";
        private double _volume = 1.0;
        private string _loopStatus = "None";
        private bool _shuffle = false;
        private readonly GodotObject _signalBus;

        private IDictionary<string, object> _metadata = new Dictionary<string, object>
        {
            ["mpris:trackid"] = new ObjectPath("/org/playstar2/track/0"),
            ["xesam:title"] = "Unknown",
            ["xesam:artist"] = new[] { "Unknown" },
            ["xesam:album"] = "",
            ["mpris:length"] = (long)0,
        };

        public event Action<PropertyChanges> OnRootPropertiesChanged;
        public event Action<PropertyChanges> OnPlayerPropertiesChanged;


        public MprisPlayerObject(AudioPlayer player, GodotObject signalBus)
        {
            _player = player;
            _signalBus = signalBus;
        }

        // -> IMediaPlayer2 (root)

        public Task RaiseAsync() => Task.CompletedTask;
        public Task QuitAsync() => Task.CompletedTask;

        Task<MediaPlayer2Properties> IMediaPlayer2.GetAllAsync()
            => Task.FromResult(new MediaPlayer2Properties());

        Task<object> IMediaPlayer2.GetAsync(string prop)
            => Task.FromResult(GetRootProperty(prop));

        Task IMediaPlayer2.SetAsync(string prop, object val)
        {
            // Read only
            if (prop == "Identity" || prop == "DesktopEntry" ||
                prop == "CanQuit" || prop == "CanRaise" ||
                prop == "HasTrackList" || prop == "SupportedUriSchemes" ||
                prop == "SupportedMimeTypes")
            {
                throw new DBusException("org.freedesktop.DBus.Error.PropertyReadOnly",
                    $"Property '{prop}' is read-only");
            }
            return Task.CompletedTask;
        }

        Task<IDisposable> IMediaPlayer2.WatchPropertiesAsync(Action<PropertyChanges> handler)
        {
            OnRootPropertiesChanged += handler;
            return Task.FromResult<IDisposable>(
                new ActionDisposable(() => OnRootPropertiesChanged -= handler));
        }

        // -> IMediaPlayer2Player

        public Task PlayPauseAsync()
        {
            if (_player.IsPlaying) return PauseAsync();
            else return PlayAsync();
        }

        public Task PlayAsync()
        {
            _signalBus.CallDeferred("emit_signal", "play_requested");
            SetPlaybackStatus("Playing");
            return Task.CompletedTask;
        }
        public Task PauseAsync()
        {
            _signalBus.CallDeferred("emit_signal", "pause_requested");
            SetPlaybackStatus("Paused");
            return Task.CompletedTask;
        }
        public Task StopAsync()
        {
            _signalBus.CallDeferred("emit_signal", "stop_requested");
            SetPlaybackStatus("Stopped");
            return Task.CompletedTask;
        }

        public Task NextAsync()
        {
            _signalBus.CallDeferred("emit_signal", "next_track_requested");
            return Task.CompletedTask;
        }
        public Task PreviousAsync()
        {
            _signalBus.CallDeferred("emit_signal", "previous_track_requested");
            return Task.CompletedTask;
        }

        public Task SeekAsync(long offsetMicroseconds)
        {
            long offsetMs = offsetMicroseconds / 1000;
            _signalBus.CallDeferred("emit_signal", "seek_requested", offsetMs);
            return Task.CompletedTask;
        }

        public Task SetPositionAsync(ObjectPath trackId, long positionMicroseconds)
        {
            _signalBus.CallDeferred("emit_signal", "seek_ms_requested", positionMicroseconds / 1000);
            return Task.CompletedTask;
        }

        public Task OpenUriAsync(string uri) => Task.CompletedTask;

        private event Action<long> OnSeekedHandlers;

        public Task<IDisposable> WatchSeekedAsync(Action<long> handler, Action<Exception> onError)
        {
            OnSeekedHandlers += handler;
            return Task.FromResult<IDisposable>(
                new ActionDisposable(() => OnSeekedHandlers -= handler));
        }

        Task<PlayerProperties> IMediaPlayer2Player.GetAllAsync()
        {
            return Task.FromResult(new PlayerProperties
            {
                PlaybackStatus = _playbackStatus,
                LoopStatus = _loopStatus,
                Shuffle = _shuffle,
                Volume = _volume,
                Metadata = _metadata,
                Position = _player.Time * 1000L,
                CanPlay = _player.IsLoaded,
                CanPause = _player.IsLoaded,
                CanSeek = _player.IsLoaded,
                CanControl = true,
                CanGoNext = true,
                CanGoPrevious = true,
            });
        }

        Task<object> IMediaPlayer2Player.GetAsync(string prop)
            => Task.FromResult(GetPlayerProperty(prop));

        Task IMediaPlayer2Player.SetAsync(string prop, object val)
        {
            // writeable properties
            if (prop == "Volume" && val is double v)
            {
                double clamped = Math.Clamp(v, 0.0, 1.0);
                _player.SetVolume((int)(clamped * 100));
                _volume = clamped;
                return Task.CompletedTask;
            }
            if (prop == "LoopStatus" && val is string ls)
            {
                _loopStatus = ls;
                _signalBus.CallDeferred("emit_signal", "set_loop_status", ls);
                return Task.CompletedTask;
            }
            if (prop == "Shuffle" && val is bool sh)
            {
                _shuffle = sh;
                _signalBus.CallDeferred("emit_signal", "set_shuffle", sh);
                return Task.CompletedTask;
            }
            if (prop == "Rate" && val is double r)
            {
                // Rate always 1.0 - ignore
                return Task.CompletedTask;
            }

            // read-only
            throw new DBusException("org.freedesktop.DBus.Error.PropertyReadOnly",
                $"Property '{prop}' is read-only");
        }

        Task<IDisposable> IMediaPlayer2Player.WatchPropertiesAsync(Action<PropertyChanges> handler)
        {
            OnPlayerPropertiesChanged += handler;
            return Task.FromResult<IDisposable>(
                new ActionDisposable(() => OnPlayerPropertiesChanged -= handler));
        }

        // -> Internal API

        public void SetPlaybackStatus(string status)
        {
            _playbackStatus = status;
            NotifyPlayer("PlaybackStatus", status);
        }

        public void SetVolume(double v)
        {
            _volume = v;
            NotifyPlayer("Volume", v);
        }

        public void SetLoopStatus(string loopStatus)
        {
            _loopStatus = loopStatus;
            NotifyPlayer("LoopStatus", loopStatus);
        }

        public void SetShuffle(bool shuffle)
        {
            _shuffle = shuffle;
            NotifyPlayer("Shuffle", shuffle);
        }

        /// <summary>
        /// Emits Seeked signal to D-Bus connected clients
        /// </summary>
        public void EmitSeekedSignal(long positionMicroseconds)
        {
            OnSeekedHandlers?.Invoke(positionMicroseconds);
        }

        /// <summary>
        /// Emits periodical updates via PropertiesChanged
        /// Called by Timer each 1s while playing
        /// </summary>
        public void EmitPositionUpdate()
        {
            NotifyPlayer("Position", _player.Time * 1000L);
        }

        // Emits Metadata + PlaybackStatus + Can* + Position in an unique PropertiesChanged
        public void SetTrack(IDictionary<string, object> meta, string status = "Playing")
        {
            _metadata = meta;
            _playbackStatus = status;
            EmitPlayerState();
        }

        // Announce player to the desktop environment
        public void AnnounceToDesktop()
        {
            EmitPlayerState();
        }


        // -> Helpers
        // Emits complete state (unique signal) including Position
        private void EmitPlayerState()
        {
            GD.Print($"[Mpris] EmitPlayerState: status={_playbackStatus}, loop={_loopStatus}, shuffle={_shuffle}");
            var changes = new PropertyChanges(
                new[]
                {
                    new KeyValuePair<string, object>("Metadata",       _metadata),
                    new KeyValuePair<string, object>("PlaybackStatus", _playbackStatus),
                    new KeyValuePair<string, object>("LoopStatus",     _loopStatus),
                    new KeyValuePair<string, object>("Shuffle",        _shuffle),
                    new KeyValuePair<string, object>("Position",       _player.Time * 1000L),
                    new KeyValuePair<string, object>("Volume",         _volume),
                    new KeyValuePair<string, object>("CanPlay",        true),
                    new KeyValuePair<string, object>("CanPause",       true),
                    new KeyValuePair<string, object>("CanSeek",        true),
                    new KeyValuePair<string, object>("CanGoNext",      true),
                    new KeyValuePair<string, object>("CanGoPrevious",  true),
                    new KeyValuePair<string, object>("Rate",           1.0),
                },
                Array.Empty<string>());
            OnPlayerPropertiesChanged?.Invoke(changes);
        }

        private void NotifyPlayer(string propName, object value)
        {
            var changes = new PropertyChanges(
                new[] { new KeyValuePair<string, object>(propName, value) },
                Array.Empty<string>());
            OnPlayerPropertiesChanged?.Invoke(changes);
        }

        private object GetRootProperty(string prop) => prop switch
        {
            "CanQuit" => false,
            "CanRaise" => false,
            "HasTrackList" => false,
            "Identity" => "PlayStar2",
            "DesktopEntry" => "playstar2",
            "SupportedUriSchemes" => new[] { "file" },
            "SupportedMimeTypes" => new[] { "audio/mpeg", "audio/flac", "audio/ogg" },
            _ => null
        };

        private object GetPlayerProperty(string prop) => prop switch
        {
            "PlaybackStatus" => _playbackStatus,
            "LoopStatus" => _loopStatus,
            "Rate" => 1.0,
            "Shuffle" => _shuffle,
            "Metadata" => _metadata,
            "Volume" => _volume,
            "Position" => _player.Time * 1000L,
            "MinimumRate" => 1.0,
            "MaximumRate" => 1.0,
            "CanGoNext" => true,
            "CanGoPrevious" => true,
            "CanPlay" => _player.IsLoaded,
            "CanPause" => _player.IsLoaded,
            "CanSeek" => _player.IsLoaded,
            "CanControl" => true,
            _ => null
        };
    }

    internal sealed class ActionDisposable : IDisposable
    {
        private readonly Action _action;
        public ActionDisposable(Action action) { _action = action; }
        public void Dispose() => _action?.Invoke();
    }
}
