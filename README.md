![banner](readme_assets/banner_playstar.png)
 
# PlayStar
 
[![License: BUSL-1.1](https://img.shields.io/badge/license-BUSL--1.1-blue)](./LICENSE)
[![Platform: Linux x86_64](https://img.shields.io/badge/platform-Linux%20x86__64-lightgrey)]()
[![Platform: Windows x86_64](https://img.shields.io/badge/platform-Windows%20x86__64-lightgrey)]()
[![Godot 4](https://img.shields.io/badge/engine-Godot%204-informational)]()
 
PlayStar is a personal music player for Linux and Windows, built with Godot 4 and C# (.NET 8). It uses a local SQLite library, synchronized lyrics, MPRIS integration (Linux), and Discord Rich Presence.
 
![preview](readme_assets/preview.png)
 
---
 
## Features
 
**Currently available**
 
- Music playback via LibVLC
- Keyboard shortcuts
- MPRIS media controls (D-Bus)
- Discord Rich Presence
- Settings panel
- Album art display with lazy loading
- Shuffle and repeat modes
- Full library scanning with multi-folder support and progress tracking
**Planned**
 
- Synchronized lyrics (`.lrc`) with auto-scroll
- Now Playing thumbnail generator with clipboard export
- Genre, artist and album browsing
---
 
## Services
 
Synchronized lyrics are fetched from [LRCLIB](https://lrclib.net), a free and open lyrics database with no profit intention, built for FOSS music players.
 
 
## Requirements
 
**Linux**
 
- Linux x86_64
- VLC (`libvlc`) installed on the system
- `vlc-plugin-pipewire` recommended for PipeWire setups
**Windows**
 
- Windows x86_64
- No external dependencies — `libvlc`, `libvlccore` and the required VLC plugins are bundled with the release
**To build from source (both platforms)**
 
- [Godot 4.7](https://godotengine.org/)
- .NET 8 SDK
> MPRIS media controls are Linux-only (D-Bus dependent) and are not available on Windows.
 
---
 
## Dependencies
 
PlayStar uses the following NuGet packages:
 
| Package | Version |
|---|---|
| Godot.NET.Sdk | 4.7.0 |
| DiscordRichPresence | 1.6.1.70 |
| LibVLCSharp | 3.10.0 |
| VideoLAN.LibVLC.Windows | 3.0.21 |
| Microsoft.Data.Sqlite | 10.0.9 |
| SkiaSharp | 4.148.0 |
| SkiaSharp.NativeAssets.Linux | 4.148.0 |
| TagLibSharp | 2.3.0 |
| Tmds.DBus | 0.94.2 |
 
`VideoLAN.LibVLC.Windows` and `SkiaSharp.NativeAssets.Linux` provide the native binaries for each platform and are pulled in automatically by Godot's export process — no manual DLL handling required.
 
Some of these packages carry their own licensing terms, separate from this project's BUSL-1.1 license. See [`THIRD_PARTY_LICENSES.txt`](./THIRD_PARTY_LICENSES.txt) for details — this applies in particular to **LibVLCSharp** (LGPL) and **TagLibSharp** (LGPL).
 
---
 
## Installation
 
Pre-built releases are available on the [Releases](../../releases) page for Linux x86_64 (`.tar`) and Windows x86_64 (`.exe` installer). Each release includes the necessary native DLLs.
 
**Linux**
 
```sh
tar -xf playstar-<version>-linux-x86_64.tar
cd playstar
./PlayStar
```
 
**Windows**
 
Run the installer and follow the setup wizard.
 
> Releases are intended for **personal use only**, as defined by the BUSL-1.1 license. Commercial use is not permitted.
 
---
 
## Building from Source
 
```sh
git clone https://github.com/hayukimori/PlayStar.git
cd PlayStar
dotnet restore
```
 
Then open the project in Godot 4.7 and export or run from the editor. Both the `Linux` and `Windows Desktop` export presets are included in `export_presets.cfg`.
 
---
 
## License
 
This project is licensed under the [Business Source License 1.1](./LICENSE).  
It is made available for personal use only. The license terms include restrictions on commercial use.
 
Third-party components are subject to their own licenses. See [`THIRD_PARTY_LICENSES.txt`](./THIRD_PARTY_LICENSES.txt) for the full list.
