using Godot;
using System;
using System.IO;
using TagLib;
using File = System.IO.File;
using System.Collections.Generic;
using System.Linq;

using PlayStar.Scripts.Models;

namespace PlayStar.Scripts.Core;

[GlobalClass]
public partial class TagManager : GodotObject
{
    public static SongModel ReadTags(string path)
    {
        try
        {
            using var file = TagLib.File.Create(path);
            var tag = file.Tag;
            var prop = file.Properties;


            string rawArtist = tag.FirstPerformer ?? tag.FirstAlbumArtist ?? "Unknown";

            return new SongModel
            {
                FilePath = path,
                FileName = Path.GetFileName(path),
                Title = !string.IsNullOrWhiteSpace(tag.Title)
                    ? tag.Title
                    : Path.GetFileNameWithoutExtension(path),
                Artist = rawArtist,
                Album = tag.Album ?? "Unknown",
                Genre = tag.FirstGenre ?? "Unknown",
                Length = (long)prop.Duration.TotalMilliseconds,
                Year = tag.Year,
                Lyrics = tag.Lyrics ?? string.Empty,
                MusicBrainzTrackId = tag.MusicBrainzTrackId,
                MusicBrainzArtistId = tag.MusicBrainzArtistId,
                MusicBrainzReleaseId = tag.MusicBrainzReleaseId,
                MusicBrainzReleaseArtistId = tag.MusicBrainzReleaseArtistId,
                MusicBrainzReleaseGroupId = tag.MusicBrainzReleaseGroupId,
                MusicBrainzReleaseStatus = tag.MusicBrainzReleaseStatus,
                MusicBrainzReleaseType = tag.MusicBrainzReleaseType,
                MusicBrainzDiscId = tag.MusicBrainzDiscId,
                MusicIpId = tag.MusicIpId,
            };
        }
        catch (Exception ex)
        {
            GD.PrintErr($"[TagManager] Failed to read tags for {path}: {ex.Message}");
            return new SongModel
            {
                FilePath = path,
                FileName = Path.GetFileName(path),
                Title = Path.GetFileNameWithoutExtension(path),
                Artist = "Unknown",
                Album = "Unknown",
                Genre = "Unknown",
                Length = 0,
                Year = 0,
                Lyrics = string.Empty,
                MusicBrainzTrackId = string.Empty,
                MusicBrainzArtistId = string.Empty,
                MusicBrainzReleaseId = string.Empty,
                MusicBrainzReleaseArtistId = string.Empty,
                MusicBrainzReleaseGroupId = string.Empty,
                MusicBrainzReleaseStatus = string.Empty,
                MusicBrainzReleaseType = string.Empty,
                MusicBrainzDiscId = string.Empty,
                MusicIpId = string.Empty
            };
        }
    }

    public static AudioMetadataResource ExtractFullMetadata(string filePath)
    {
        if (!File.Exists(filePath)) return null;
        var metadata = new AudioMetadataResource();

        try
        {
            using var file = TagLib.File.Create(filePath);

            // File Info
            metadata.FilePath = filePath;
            metadata.MimeType = file.MimeType;
            metadata.FileSize = (int)new FileInfo(filePath).Length;
            metadata.Format = file.Name; // container extension

            // Audio Properties
            metadata.AudioBitrate = file.Properties.AudioBitrate;
            metadata.AudioSampleRate = file.Properties.AudioSampleRate;
            metadata.AudioChannels = file.Properties.AudioChannels;
            metadata.BitsPerSample = file.Properties.BitsPerSample;
            metadata.AudioCodec = file.Properties.Description;
            metadata.DurationSeconds = (int)file.Properties.Duration.TotalSeconds;
            metadata.DurationFormatted = file.Properties.Duration.ToString(@"hh\:mm\:ss");

            // Basic tags
            var tag = file.Tag;

            metadata.Title = tag.Title;
            metadata.Subtitle = tag.Subtitle;
            metadata.Description = tag.Description;
            metadata.Artists = tag.Performers;
            metadata.AlbumArtists = tag.AlbumArtists;
            metadata.Composers = tag.Composers;
            metadata.Performers = tag.Performers;
            metadata.Album = tag.Album;
            metadata.Year = tag.Year;
            metadata.Track = tag.Track;
            metadata.TrackCount = tag.TrackCount;
            metadata.Disc = tag.Disc;
            metadata.DiscCount = tag.DiscCount;
            metadata.Genres = tag.Genres;
            metadata.Comment = tag.Comment;
            metadata.Lyrics = tag.Lyrics;
            metadata.Conductor = tag.Conductor;
            metadata.Copyright = tag.Copyright;
            metadata.Publisher = tag.Publisher;

            // Audio classification
            metadata.MusicBrainzTrackId = tag.MusicBrainzTrackId;
            metadata.MusicBrainzArtistId = tag.MusicBrainzArtistId;
            metadata.MusicBrainzReleaseId = tag.MusicBrainzReleaseId;
            metadata.MusicBrainzReleaseArtistId = tag.MusicBrainzReleaseArtistId;
            metadata.MusicBrainzReleaseGroupId = tag.MusicBrainzReleaseGroupId;
            metadata.MusicBrainzReleaseStatus = tag.MusicBrainzReleaseStatus;
            metadata.MusicBrainzReleaseType = tag.MusicBrainzReleaseType;
            metadata.MusicBrainzDiscId = tag.MusicBrainzDiscId;
            metadata.MusicIpId = tag.MusicIpId;

            // Extra tags
            metadata.RemixedBy = tag.RemixedBy;
            metadata.Grouping = tag.Grouping;
            metadata.BeatsPerMinute = tag.BeatsPerMinute;
            metadata.InitialKey = tag.InitialKey;
            metadata.AmazonId = tag.AmazonId;

            // Pictures
            foreach (var picture in tag.Pictures)
            {
                if (picture == null || picture.Data == null || picture.Data.Data.Length == 0)
                    continue;

                switch (picture.Type)
                {
                    case PictureType.FrontCover:
                        metadata.PicturesFront.Add(picture.Data.Data);
                        break;
                    case PictureType.BackCover:
                        metadata.PicturesBack.Add(picture.Data.Data);
                        break;
                    case PictureType.Media:
                        metadata.PicturesMedia.Add(picture.Data.Data);
                        break;
                    case PictureType.LeafletPage:
                        metadata.PicturesLeaflet.Add(picture.Data.Data);
                        break;
                    case PictureType.Artist:
                        metadata.PicturesArtist.Add(picture.Data.Data);
                        break;
                    case PictureType.Band:
                        metadata.PicturesBand.Add(picture.Data.Data);
                        break;
                    case PictureType.Composer:
                        metadata.PicturesComposer.Add(picture.Data.Data);
                        break;
                    case PictureType.NotAPicture:
                    case PictureType.Other:
                    default:
                        metadata.PicturesOther.Add(picture.Data.Data);
                        break;
                }
            }

            // ID3v2 Specific
            if (file.GetTag(TagTypes.Id3v2) is TagLib.Id3v2.Tag id3v2Tag)
            {
                metadata.Id3v2Version = id3v2Tag.Version.ToString();
                metadata.Id3v2HasFooter = id3v2Tag.Flags.HasFlag(TagLib.Id3v2.HeaderFlags.FooterPresent);
            }

            // Extra / custom
            ExtractCustomTags(tag, metadata);

            // Tag types
            metadata.TagTypes = file.TagTypes.ToString();
        }
        catch (Exception ex)
        {
            GD.PrintErr($"Error extracting metadata: {ex.Message}");
            return null;
        }

        return metadata;
    }

    private static void ExtractCustomTags(TagLib.Tag tag, AudioMetadataResource metadata)
    {
        // For mp4 (m4a) files / QuickTime
        if (tag is TagLib.Mpeg4.AppleTag appleTag)
        {
            // Specific mp4 tags
            ExtractAppleTags(appleTag, metadata);
        }

        // For ID3v2
        if (tag is TagLib.Id3v2.Tag id3v2Tag)
        {
            foreach (var frame in id3v2Tag.GetFrames())
            {
                try
                {
                    string key = frame.FrameId.ToString();
                    string value = frame.ToString();

                    if (!string.IsNullOrEmpty(value) && !metadata.CustomTags.ContainsKey(key))
                    {
                        metadata.CustomTags[key] = value;
                    }
                }
                catch { }
            }
        }

        // FLAC/Ogg Vorbis
        if (tag is TagLib.Ogg.XiphComment xiphComment)
        {
            foreach (string key in xiphComment)
            {
                try
                {
                    if (!metadata.CustomTags.ContainsKey(key))
                    {
                        string[] values = xiphComment.GetField(key);
                        string value = values?.FirstOrDefault();
                        if (!string.IsNullOrEmpty(value))
                            metadata.CustomTags[key] = value;
                    }
                }
                catch { }
            }
        }
    }

    private static void ExtractAppleTags(TagLib.Mpeg4.AppleTag appleTag, AudioMetadataResource metadata)
    {
        try
        {
            // Rating
            var ratingBox = appleTag.GetDashBox("com.apple.iTunes", "RATING");
            if (ratingBox != null)
            {
                metadata.Mp4Rating = ratingBox;
            }

            // Compilation
            var compilationBox = appleTag.GetDashBox("com.apple.iTunes", "COMPILATION");
            if (compilationBox != null)
            {
                if (compilationBox is string str && str == "1")
                    metadata.Mp4IsCompilation = true;
            }
        }
        catch (Exception ex)
        {
            GD.PrintErr($"Error extracting apple tag: {ex.Message}");
        }
    }
}
