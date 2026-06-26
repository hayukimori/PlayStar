using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Tmds.DBus;

// MPRIS2 Spec: https://specifications.freedesktop.org/mpris-spec/latest/

namespace PlayStar.Scripts.SystemIntegration.Mpris
{
    // org.mpris.MediaPlayer2
    [DBusInterface("org.mpris.MediaPlayer2")]
    public interface IMediaPlayer2 : IDBusObject
    {
        Task RaiseAsync();
        Task QuitAsync();

        Task<object> GetAsync(string prop);
        Task<MediaPlayer2Properties> GetAllAsync();
        Task SetAsync(string prop, object val);

        Task<IDisposable> WatchPropertiesAsync(Action<PropertyChanges> handler);
    }

    [Dictionary]
    public class MediaPlayer2Properties
    {
        public bool CanQuit = false;
        public bool CanRaise = false;
        public bool HasTrackList = false;
        public string Identity = "PlayStar";
        public string DesktopEntry = "playstar";
        public string[] SupportedUriSchemes = new[] { "file" };
        public string[] SupportedMimeTypes = new[] { "audio/mpeg", "audio/flac", "audio/ogg" };
    }


    // org.mpris.MediaPlayer2.Player

    [DBusInterface("org.mpris.MediaPlayer2.Player")]
    public interface IMediaPlayer2Player : IDBusObject
    {
        Task NextAsync();
        Task PreviousAsync();
        Task PauseAsync();
        Task PlayPauseAsync();
        Task StopAsync();
        Task PlayAsync();
        Task SeekAsync(long offset);                       // microseconds
        Task SetPositionAsync(ObjectPath trackId, long position);
        Task OpenUriAsync(string uri);

        Task<IDisposable> WatchSeekedAsync(Action<long> handler, Action<Exception> onError);

        Task<object> GetAsync(string prop);
        Task<PlayerProperties> GetAllAsync();
        Task SetAsync(string prop, object val);
        Task<IDisposable> WatchPropertiesAsync(Action<PropertyChanges> handler);
    }



    [Dictionary]
    public class PlayerProperties
    {
        // "Playing" | "Paused" | "Stopped"
        public string PlaybackStatus = "Stopped";

        // "None" | "Track" | "Playlist"
        public string LoopStatus = "None";

        public double Rate = 1.0;
        public bool Shuffle = false;

        // Metadata
        public IDictionary<string, object> Metadata = new Dictionary<string, object>
        {
            ["mpris:trackid"] = new ObjectPath("/org/playstar2/track/0"),
            ["xesam:title"] = "Unknown",
            ["xesam:artist"] = new[] { "Unknown" },
            ["xesam:album"] = "",
            ["mpris:length"] = (long)0,            // microseconds
                                                   // ["mpris:artUrl"]   = "file:///path/to/cover.png",
        };

        public double Volume = 1.0;    // 0.0 – 1.0
        public long Position = 0;      // microseconds

        public double MinimumRate = 1.0;
        public double MaximumRate = 1.0;

        public bool CanGoNext = false;
        public bool CanGoPrevious = false;
        public bool CanPlay = true;
        public bool CanPause = true;
        public bool CanSeek = true;
        public bool CanControl = true;
    }

}
