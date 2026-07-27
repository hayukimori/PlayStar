using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class AudioMetadataResource : Resource
{
    // File properties
    [Export] public string FilePath { get; set; }
    [Export] public string MimeType { get; set; }
    [Export] public int FileSize { get; set; } // bytes

    // Audio Properties

    [Export] public int AudioBitrate { get; set; } // kbps
    [Export] public int AudioSampleRate { get; set; } // Hz
    [Export] public int AudioChannels { get; set; }
    [Export] public int BitsPerSample { get; set; }
    [Export] public string AudioCodec { get; set; }
    [Export] public int DurationSeconds { get; set; }
    [Export] public string DurationFormatted { get; set; } // hh:mm:ss


    // Basic tags

    [Export] public string Title { get; set; }
    [Export] public string Subtitle { get; set; }
    [Export] public string Description { get; set; }
    [Export(PropertyHint.ArrayType)] public string[] Artists { get; set; }
    [Export(PropertyHint.ArrayType)] public string[] AlbumArtists { get; set; }
    [Export(PropertyHint.ArrayType)] public string[] Composers { get; set; }
    [Export(PropertyHint.ArrayType)] public string[] Performers { get; set; }
    [Export] public string Album { get; set; }
    [Export] public uint Year { get; set; }
    [Export] public uint Track { get; set; }
    [Export] public uint TrackCount { get; set; }
    [Export] public uint Disc { get; set; }
    [Export] public uint DiscCount { get; set; }
    [Export(PropertyHint.ArrayType)] public string[] Genres { get; set; }
    [Export] public string Comment { get; set; }
    [Export] public string Lyrics { get; set; }
    [Export] public string Conductor { get; set; }
    [Export] public string Copyright { get; set; }
    [Export] public string Publisher { get; set; }

    // Classification tags
    [Export] public string MusicBrainzTrackId { get; set; }
    [Export] public string MusicBrainzArtistId { get; set; }
    [Export] public string MusicBrainzReleaseId { get; set; }
    [Export] public string MusicBrainzReleaseArtistId { get; set; }
    [Export] public string MusicBrainzReleaseGroupId { get; set; }
    [Export] public string MusicBrainzReleaseStatus { get; set; }
    [Export] public string MusicBrainzReleaseType { get; set; }
    [Export] public string MusicBrainzDiscId { get; set; }
    [Export] public string MusicIpId { get; set; }

    // Media tags
    [Export] public bool IsCompilation { get; set; }
    [Export] public string RemixedBy { get; set; }
    [Export] public string Grouping { get; set; }
    [Export] public float BeatsPerMinute { get; set; }
    [Export] public string InitialKey { get; set; }
    [Export] public string AmazonId { get; set; }

    // Images
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesFront { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesBack { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesMedia { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesLeaflet { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesArtist { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesBand { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesComposer { get; set; }
    [Export(PropertyHint.ArrayType)] public Godot.Collections.Array<byte[]> PicturesOther { get; set; }

    [Export(PropertyHint.ArrayType)] public string[] PicturesDescriptions { get; set; }
    [Export(PropertyHint.ArrayType)] public string[] PicturesMimeTypes { get; set; }

    // Additional Tags

    [Export] public Godot.Collections.Dictionary<string, string> CustomTags { get; set; }

    // Format metadata
    [Export] public string Format { get; set; } // MP3, FLAC, MP4.
    [Export] public string TagTypes { get; set; } // ID3v1, ID3v2, APE.

    // ID3v2 specific
    [Export] public string Id3v2Version { get; set; }
    [Export] public bool Id3v2HasFooter { get; set; }

    // MP4 specific
    [Export] public string Mp4Rating { get; set; }
    [Export] public bool Mp4IsCompilation { get; set; }

    // FLAC specific
    [Export] public int FlacBlockSize { get; set; }

    // ASF/WMA specific
    [Export] public string AsfContentDescription { get; set; }

    public AudioMetadataResource()
    {
        Artists = System.Array.Empty<string>();
        AlbumArtists = System.Array.Empty<string>();
        Composers = System.Array.Empty<string>();
        Performers = System.Array.Empty<string>();
        Genres = System.Array.Empty<string>();

        PicturesFront = new Godot.Collections.Array<byte[]>();
        PicturesBack = new Godot.Collections.Array<byte[]>();
        PicturesMedia = new Godot.Collections.Array<byte[]>();
        PicturesLeaflet = new Godot.Collections.Array<byte[]>();
        PicturesArtist = new Godot.Collections.Array<byte[]>();
        PicturesBand = new Godot.Collections.Array<byte[]>();
        PicturesComposer = new Godot.Collections.Array<byte[]>();
        PicturesOther = new Godot.Collections.Array<byte[]>();

        PicturesDescriptions = System.Array.Empty<string>();
        PicturesMimeTypes = System.Array.Empty<string>();

        CustomTags = new Godot.Collections.Dictionary<string, string>();
    }
}
