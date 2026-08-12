# Privacy Policy

**PlayStar** — Last updated: 2026

## Overview

PlayStar is a local-first music player. It does not collect, transmit, or sell any personal data on its own. All data stays on your device unless you explicitly enable optional integrations described below.

---

## Data stored locally

PlayStar stores the following data on your device only, inside your user directory:

- **Music library index** (`songs.db`) — file paths, tags (title, artist, album, genre, year, lyrics), and MusicBrainz IDs read from your local audio files.
- **Play history** (`songs.db`) — timestamps of songs you have played, used to power the "Most Played" views.
- **Starred songs** (`songs.db`) — songs you have marked as favorites.
- **Credentials** (`subsonic.tres`, `listenbrainz.tres`) — server URL, username, and password for Subsonic/Navidrome; API key for ListenBrainz. Stored in plain text on your device. PlayStar never transmits these to any server other than the ones you configure.

This data never leaves your device unless you enable one of the optional integrations below.

---

## Optional integrations

### Subsonic / Navidrome

If you connect PlayStar to a Subsonic-compatible server (such as Navidrome), the following data is sent to **that server**:

- Song playback events (scrobbles), including track ID, timestamp, and playback duration.
- Star/unstar actions for songs in the server library.
- Search queries.

The server you connect to is operated by you or a third party of your choosing. PlayStar has no control over how that server handles your data. If your server is connected to Last.fm or ListenBrainz, scrobbles may be forwarded there as well — refer to your server's own privacy policy.

### ListenBrainz

If you configure a ListenBrainz API key, PlayStar will send the following data directly to **ListenBrainz** (`api.listenbrainz.org`) for local songs that have MusicBrainz IDs in their tags:

- Track name, artist name, and album name.
- MusicBrainz recording ID, artist ID, and release ID (when available in the file tags).
- Playback timestamp and duration.
- "Playing now" notifications when a song starts.

ListenBrainz is operated by the MetaBrainz Foundation. Their privacy policy is available at [listenbrainz.org](https://listenbrainz.org).

Songs without a MusicBrainz Track ID are **never** sent to ListenBrainz.

---

## What PlayStar does NOT do

- Does not collect analytics or telemetry.
- Does not send crash reports to any server.
- Does not display advertisements.
- Does not share your data with third parties beyond the integrations you explicitly configure.
- Does not access your files beyond the music folders you configure.

---

## Third-party services

When you use optional integrations, you are subject to the privacy policies of those services:

- **ListenBrainz / MetaBrainz Foundation** — [metabrainz.org/privacy](https://metabrainz.org/privacy)
- **Last.fm** (if forwarded by your Navidrome server) — [last.fm/legal/privacy](https://www.last.fm/legal/privacy)

---

## Contact

If you have questions about this policy, you can reach out via:

- **Email:** hayukimori@programmer.net
- **Repository:** [github.com/hayukimori/PlayStar](https://github.com/hayukimori/PlayStar)
