using System.Collections.Generic;
using System.Text.RegularExpressions;


namespace PlayStar.Scripts.Database.Parsers;
public static class ArtistParser
{
    public static List<string> SplitArtists(string rawArtist)
    {
        var artists = new List<string>();
        if (string.IsNullOrWhiteSpace(rawArtist)) return artists;

        // Separa por feat., ft., with, & ou vírgula
        string pattern = @"\s+(?:feat\.?|ft\.?|with|&)\s+|\s*,\s*";
        string[] tokens = Regex.Split(rawArtist, pattern, RegexOptions.IgnoreCase);

        foreach (var token in tokens)
        {
            string clean = token.Trim();
            if (!string.IsNullOrEmpty(clean) && !artists.Contains(clean))
            {
                artists.Add(clean);
            }
        }

        return artists;
    }
}