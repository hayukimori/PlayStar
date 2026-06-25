using Godot;
using System;
using System.Threading.Tasks;
using PlayStar.autoloads.ArtAutoloads;
using PlayStar.Scripts.AlbumArt;

namespace PlayStar.autoloads.ArtAutoloads;


[GlobalClass]
public partial class ArtService : Node
{
    [Signal] public delegate void ArtReadyEventHandler(string key, Texture2D texture);

    public override void _EnterTree()
    {
        AppDomain.CurrentDomain.UnhandledException += (s, e) =>
            {
                Console.WriteLine("UNHANDLED EXCEPTION:");
                Console.WriteLine(e.ExceptionObject.ToString());
            };

        TaskScheduler.UnobservedTaskException += (s, e) =>
        {
            Console.WriteLine("TASK EXCEPTION:");
            Console.WriteLine(e.Exception.ToString());
        };

        ArtDispatcher.InternalArtReady += OnInternalArtReady;
    }

    private void OnInternalArtReady(string key, Texture2D tex)
    {
        EmitSignal(SignalName.ArtReady, key, tex);
    }

    public static Texture2D GetIfCached(string key)
    {
        return AlbumArtCache.TryGet(key, out var tex) ? tex : null;
    }

    public static void Request(string key, string path)
    {
        ArtBridge.Request(key, path);
    }
}
