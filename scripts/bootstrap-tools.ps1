param([string]$Destination = (Join-Path $env:LOCALAPPDATA 'FloridaMan/toolchain'))
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Path $Destination -Force | Out-Null
foreach ($entry in $manifest.PSObject.Properties) {
    $spec = $entry.Value
    $download = Join-Path $Destination ($entry.Name + '.download')
    Invoke-WebRequest -Uri $spec.url -OutFile $download
    $actual = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $spec.sha256) { throw "Checksum mismatch: $($entry.Name)" }
    if ($spec.file) {
        $target = Join-Path $Destination $spec.file
        New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
        Copy-Item -LiteralPath $download -Destination $target -Force
    } else {
        $archive = Join-Path $Destination ($entry.Name + '.zip')
        Copy-Item -LiteralPath $download -Destination $archive -Force
        Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $Destination $spec.directory) -Force
    }
    Write-Output "Verified $($entry.Name) $($spec.version)"
}
Write-Output "Toolchain ready: $Destination"
