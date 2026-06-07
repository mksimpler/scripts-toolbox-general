param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$OrderBy = "name"
)

$json = Get-Content -Path $Path -Raw | ConvertFrom-Json
$public = @($json.identities | Where-Object { $_.public } | Sort-Object $OrderBy)
$hidden = @($json.identities | Where-Object { -not $_.public })
$json.identities = $public + $hidden

$json | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $Path -Encoding UTF8
