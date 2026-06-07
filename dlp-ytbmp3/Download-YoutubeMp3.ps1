[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string[]] $Url,

    [Parameter()]
    [string] $OutputDir = (Join-Path $PSScriptRoot 'downloads'),

    [Parameter()]
    [ValidateSet('0','1','2','3','4','5','6','7','8','9')]
    [string] $Quality = '0',

    [Parameter()]
    [switch] $EmbedThumbnail,

    [Parameter()]
    [switch] $Playlist
)

begin {
    $ErrorActionPreference = 'Stop'

    $ToolsDir = Join-Path $PSScriptRoot 'tools'
    $YtDlpPath = Join-Path $ToolsDir 'yt-dlp.exe'

    function Initialize-YtDlp {
        if (Test-Path -LiteralPath $YtDlpPath) { return $YtDlpPath }

        $cmd = Get-Command yt-dlp.exe -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }

        Write-Host 'yt-dlp not found. Downloading latest release...' -ForegroundColor Cyan
        if (-not (Test-Path -LiteralPath $ToolsDir)) {
            New-Item -ItemType Directory -Path $ToolsDir | Out-Null
        }
        $release = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
        Invoke-WebRequest -Uri $release -OutFile $YtDlpPath -UseBasicParsing
        return $YtDlpPath
    }

    function Initialize-Ffmpeg {
        $local = Join-Path $ToolsDir 'ffmpeg.exe'
        if (Test-Path -LiteralPath $local) { return $local }

        $cmd = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }

        Write-Host 'ffmpeg not found. Downloading latest build from yt-dlp/FFmpeg-Builds...' -ForegroundColor Cyan
        if (-not (Test-Path -LiteralPath $ToolsDir)) {
            New-Item -ItemType Directory -Path $ToolsDir | Out-Null
        }

        $arch = if ([Environment]::Is64BitOperatingSystem) { 'win64' } else { 'win32' }
        $zipUrl  = "https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-$arch-gpl.zip"
        $zipPath = Join-Path $ToolsDir 'ffmpeg.zip'
        $extract = Join-Path $ToolsDir '_ffmpeg_extract'

        try {
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            if (Test-Path -LiteralPath $extract) {
                Remove-Item -LiteralPath $extract -Recurse -Force
            }
            Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force

            $bins = Get-ChildItem -LiteralPath $extract -Recurse -File -Include 'ffmpeg.exe','ffprobe.exe'
            if (-not $bins) {
                throw "Could not locate ffmpeg.exe inside downloaded archive."
            }
            foreach ($bin in $bins) {
                Copy-Item -LiteralPath $bin.FullName -Destination (Join-Path $ToolsDir $bin.Name) -Force
            }
        }
        finally {
            if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue }
        }

        if (-not (Test-Path -LiteralPath $local)) {
            throw "ffmpeg download failed. Please install ffmpeg manually (e.g. 'winget install Gyan.FFmpeg') or place ffmpeg.exe in $ToolsDir."
        }
        return $local
    }

    $ytDlp  = Initialize-YtDlp
    $ffmpeg = Initialize-Ffmpeg
    $ffmpegDir = Split-Path -Parent $ffmpeg

    if (-not (Test-Path -LiteralPath $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }

    $outTemplate = Join-Path $OutputDir '%(title)s [%(id)s].%(ext)s'
}

process {
    foreach ($u in $Url) {
        Write-Host "Downloading: $u" -ForegroundColor Green

        $ytDlpArgs = @(
            '-x',
            '--audio-format', 'mp3',
            '--audio-quality', $Quality,
            '--ffmpeg-location', $ffmpegDir,
            '-o', $outTemplate,
            '--no-overwrites',
            '--no-mtime'
        )

        if ($EmbedThumbnail) {
            $ytDlpArgs += @('--embed-thumbnail', '--add-metadata')
        }

        if (-not $Playlist) {
            $ytDlpArgs += '--no-playlist'
        }

        $ytDlpArgs += $u

        & $ytDlp @ytDlpArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "yt-dlp exited with code $LASTEXITCODE for $u"
        }
    }
}

end {
    Write-Host "Done. Files saved to: $OutputDir" -ForegroundColor Cyan
}
