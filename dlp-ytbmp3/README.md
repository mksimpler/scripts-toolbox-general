# Download-YoutubeMp3

PowerShell script that downloads YouTube videos as MP3 using [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [ffmpeg](https://ffmpeg.org/).

## Requirements

- **PowerShell 5.1+** (Windows PowerShell or PowerShell 7+).
- Internet access on first run. Both `yt-dlp.exe` and `ffmpeg.exe` are auto-downloaded into `tools\` if they aren't already present on `PATH` or in that folder.
  - `yt-dlp.exe` is fetched from the latest [yt-dlp release](https://github.com/yt-dlp/yt-dlp/releases/latest).
  - `ffmpeg.exe` (and `ffprobe.exe`) are fetched from the latest [yt-dlp/FFmpeg-Builds release](https://github.com/yt-dlp/FFmpeg-Builds/releases/latest) (architecture-aware: `win64` or `win32`).
- You can still pre-install either tool yourself (e.g. `winget install Gyan.FFmpeg`) and the script will use the version on `PATH`.

## Usage

```powershell
# Single video
.\Download-YoutubeMp3.ps1 -Url 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'

# Multiple URLs
.\Download-YoutubeMp3.ps1 -Url 'URL1','URL2'

# Pipe URLs in
Get-Content urls.txt | .\Download-YoutubeMp3.ps1

# Custom output folder + best quality + thumbnail/metadata
.\Download-YoutubeMp3.ps1 -Url 'URL' -OutputDir 'D:\Music' -Quality 0 -EmbedThumbnail

# Download the whole playlist (otherwise only the single video is fetched)
.\Download-YoutubeMp3.ps1 -Url 'PLAYLIST_URL' -Playlist

# Convenience wrapper: always embeds thumbnail + metadata
.\DL-Mp3.ps1 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
```

## Parameters

| Parameter         | Description                                                    | Default                 |
| ----------------- | -------------------------------------------------------------- | ----------------------- |
| `-Url`            | One or more YouTube URLs. Accepts pipeline input.              | (required)              |
| `-OutputDir`      | Folder to save MP3 files.                                      | `.\downloads`           |
| `-Quality`        | MP3 quality `0` (best) to `9` (worst), per yt-dlp.             | `0`                     |
| `-EmbedThumbnail` | Embed cover art and metadata tags into the MP3.                | off                     |
| `-Playlist`       | Allow downloading entire playlists if the URL points to one.   | off (single video only) |

## Notes

- Files are named `Title [VideoId].mp3` to keep them unique.
- The script passes `--ffmpeg-location` to yt-dlp so the bundled `tools\ffmpeg.exe` is always used when present.
- Only download content you have the right to download.
