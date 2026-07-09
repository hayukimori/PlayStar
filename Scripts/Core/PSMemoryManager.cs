using Godot;
using System;
using System.Diagnostics;

namespace PlayStar.Scripts.Core;

[GlobalClass]
public partial class PSMemoryManager : Node
{
    private const double MinSecondsBetweenCollections = 2.0;

    private double _lastCollectionTimeMs = -999999;

    /// <summary>
    /// Forces a full blocking GC collection. Only call this from
    /// natural transition points, never during active interaction.
    /// </summary>
    public void RequestCleanup(bool force = false)
    {
        double now = Time.GetTicksMsec();

        if (!force && (now - _lastCollectionTimeMs) < MinSecondsBetweenCollections * 1000.0)
        {
            Console.WriteLine("[PSMemoryManager] Skipped cleanup (called too soon after previous one)");
            GD.Print("[PSMemoryManager] Skipped cleanup (called too soon after previous one)");
            return;
        }

        _lastCollectionTimeMs = now;
        RunCollection();
    }

    /// <summary>
    /// Same as RequestCleanup, but reports before/after managed memory
    /// usage to the console. Useful while measuring impact; avoid calling
    /// this version in normal release flow since GC.GetTotalMemory(true)
    /// itself forces an extra collection pass.
    /// </summary>
    public void RequestCleanupWithReport(string label = "")
    {
        long before = GC.GetTotalMemory(false);

        var sw = Stopwatch.StartNew();
        RunCollection();
        sw.Stop();

        long after = GC.GetTotalMemory(false);

        string text = $"[PSMemoryManager] Cleanup{(string.IsNullOrEmpty(label) ? "" : $" ({label})")}: " +
                   $"{before / 1024.0 / 1024.0:F2} MiB -> {after / 1024.0 / 1024.0:F2} MiB " +
                   $"(freed {(before - after) / 1024.0 / 1024.0:F2} MiB) in {sw.ElapsedMilliseconds} ms";

        Console.WriteLine(text);
        GD.Print(text);

        _lastCollectionTimeMs = Time.GetTicksMsec();
    }

    private static void RunCollection()
    {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
    }
}
