using Godot;
using Microsoft.Data.Sqlite;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

using PlayStar.Scripts.Database.Repositories;

namespace PlayStar.Scripts.Database;
[GlobalClass]
public partial class LibraryScanner : Node
{
    [Signal] public delegate void SongsScanEndEventHandler();

    [Export] public string MusicFolder = "";

    private CancellationTokenSource _cts;
    private DatabaseManager  _db;
    private SongRepository   _songs;
    private MetadataIndexer  _indexer;

    private static readonly string[] SupportedExtensions =
    [
        ".mp3", ".flac", ".ogg", ".wav", ".m4a"
    ];

    public void Initialize(DatabaseManager db, SongRepository songs, MetadataIndexer indexer)
    {
        _db      = db;
        _songs   = songs;
        _indexer = indexer;
    }

    public void StartScan() => _ = ScanAsync();

    public async Task ScanAsync()
    {
        CancelScan();
        _cts = new CancellationTokenSource();
        GD.Print("[LibraryScanner] Starting scan...");

        try
        {
            await Task.Run(() => ScanFileSystem(_cts.Token));
            GD.Print("[LibraryScanner] Scan complete.");
            EmitSignal(SignalName.SongsScanEnd);
        }
        catch (OperationCanceledException)
        {
            GD.Print("[LibraryScanner] Scan canceled.");
            CallDeferred(GodotObject.MethodName.EmitSignal, SignalName.SongsScanEnd);
        }
    }

    public void CancelScan() => _cts?.Cancel();

    // -------------------------------------------------------------------------

    private void ScanFileSystem(CancellationToken token)
    {
        GD.Print("[LibraryScanner] Opening database...");

        using var connection = _db.GetConnection();
        var transaction = connection.BeginTransaction();
        int count = 0;

        foreach (var file in EnumerateMusicFiles(MusicFolder))
        {
            token.ThrowIfCancellationRequested();

            var mtime = new FileInfo(file).LastWriteTimeUtc.Ticks;
            SongRepository.UpsertScanEntry(file, mtime, connection, transaction);
            count++;

            if (count % 500 == 0)
            {
                transaction.Commit();
                transaction.Dispose();
                transaction = connection.BeginTransaction();
                GD.Print($"[LibraryScanner] Committed {count} entries...");
            }
        }

        transaction.Commit();
        transaction.Dispose();
        GD.Print($"[LibraryScanner] Finished. Total: {count} files.");
    }

    private static IEnumerable<string> EnumerateMusicFiles(string root)
    {
        var stack = new Stack<string>();
        stack.Push(root);

        while (stack.Count > 0)
        {
            var dir = stack.Pop();
            string[] subDirs = [];
            string[] files   = [];

            try
            {
                subDirs = Directory.GetDirectories(dir);
                files   = Directory.GetFiles(dir);
            }
            catch
            {
                GD.PrintErr($"[LibraryScanner] Could not read directory: {dir}");
                continue;
            }

            foreach (var sub in subDirs) stack.Push(sub);

            foreach (var file in files)
            {
                var ext = Path.GetExtension(file).ToLowerInvariant();
                if (Array.Exists(SupportedExtensions, e => e == ext))
                    yield return file;
            }
        }
    }
}
