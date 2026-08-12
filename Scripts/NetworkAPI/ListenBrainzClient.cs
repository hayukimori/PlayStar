using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

namespace PlayStar.Scripts.NetworkAPI;

/// <summary>
/// ListenBrainz REST API client.
/// Docs: https://listenbrainz.readthedocs.io/en/latest/users/api/core.html
/// </summary>
public sealed class ListenBrainzClient : IDisposable
{
    private const string BaseUrl = "https://api.listenbrainz.org";

    private readonly HttpClient _http;
    private readonly string _apiKey;

    public ListenBrainzClient(string apiKey)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
            throw new ArgumentException("ApiKey cannot be empty.");

        _apiKey = apiKey;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
        _http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Token", _apiKey);
    }

    /// <summary>
    /// Submits a single-song scrobble (listen_type = "single").
    /// Requires at minimum track_name and artist_name.
    /// MBIDs are optional but strongly recommended for correct attribution.
    /// </summary>
    public async Task SubmitListenAsync(
        string trackName,
        string artistName,
        string releaseName = null,
        string trackMbid = null,
        string artistMbid = null,
        string releaseMbid = null,
        int? durationSeconds = null,
        CancellationToken ct = default)
    {
        var listenedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        var additionalInfo = new JsonObject();
        if (!string.IsNullOrEmpty(trackMbid))
            additionalInfo["recording_mbid"] = trackMbid;
        if (!string.IsNullOrEmpty(artistMbid))
            additionalInfo["artist_mbids"] = new JsonArray(JsonValue.Create(artistMbid));
        if (!string.IsNullOrEmpty(releaseMbid))
            additionalInfo["release_mbid"] = releaseMbid;
        if (durationSeconds.HasValue)
            additionalInfo["duration"] = durationSeconds.Value;

        var trackMetadata = new JsonObject
        {
            ["track_name"] = trackName,
            ["artist_name"] = artistName,
        };

        if (!string.IsNullOrEmpty(releaseName))
            trackMetadata["release_name"] = releaseName;

        if (additionalInfo.Count > 0)
            trackMetadata["additional_info"] = additionalInfo;

        var payload = new JsonObject
        {
            ["listen_type"] = "single",
            ["payload"] = new JsonArray(
                new JsonObject
                {
                    ["listened_at"] = listenedAt,
                    ["track_metadata"] = trackMetadata,
                }
            )
        };

        await PostAsync("/1/submit-listens", payload, ct);
    }

    /// <summary>
    /// Submits a "playing now" notification (no listened_at timestamp).
    /// </summary>
    public async Task SubmitPlayingNowAsync(
        string trackName,
        string artistName,
        string releaseName = null,
        string trackMbid = null,
        string artistMbid = null,
        string releaseMbid = null,
        CancellationToken ct = default)
    {
        var additionalInfo = new JsonObject();
        if (!string.IsNullOrEmpty(trackMbid))
            additionalInfo["recording_mbid"] = trackMbid;
        if (!string.IsNullOrEmpty(artistMbid))
            additionalInfo["artist_mbids"] = new JsonArray(JsonValue.Create(artistMbid));
        if (!string.IsNullOrEmpty(releaseMbid))
            additionalInfo["release_mbid"] = releaseMbid;

        var trackMetadata = new JsonObject
        {
            ["track_name"] = trackName,
            ["artist_name"] = artistName,
        };

        if (!string.IsNullOrEmpty(releaseName))
            trackMetadata["release_name"] = releaseName;

        if (additionalInfo.Count > 0)
            trackMetadata["additional_info"] = additionalInfo;

        var payload = new JsonObject
        {
            ["listen_type"] = "playing_now",
            ["payload"] = new JsonArray(
                new JsonObject
                {
                    ["track_metadata"] = trackMetadata,
                }
            )
        };

        await PostAsync("/1/submit-listens", payload, ct);
    }

    /// <summary>Validates the API key. Returns true if valid.</summary>
    public async Task<bool> ValidateTokenAsync(CancellationToken ct = default)
    {
        try
        {
            using var response = await _http.GetAsync($"{BaseUrl}/1/validate-token", ct);
            if (!response.IsSuccessStatusCode) return false;

            var json = await response.Content.ReadAsStringAsync(ct);
            var root = JsonNode.Parse(json);
            return root?["valid"]?.GetValue<bool>() ?? false;
        }
        catch { return false; }
    }

    public void Dispose() => _http.Dispose();

    private async Task PostAsync(string path, JsonObject body, CancellationToken ct)
    {
        var content = new StringContent(body.ToJsonString(), Encoding.UTF8, "application/json");
        using var response = await _http.PostAsync($"{BaseUrl}{path}", content, ct);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync(ct);
            throw new ListenBrainzException($"HTTP {(int)response.StatusCode}: {error}");
        }
    }
}

public sealed class ListenBrainzException(string message) : Exception(message);
