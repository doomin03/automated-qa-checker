$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$destination = [IO.Path]::GetFullPath((Join-Path $repository '.local/server-tools'))
if (-not $destination.StartsWith($repository + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Tool destination is outside repository' }
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $destination | Out-Null
function Get-VerifiedArtifact([string] $url, [string] $path, [string] $checksum) {
  if (-not (Test-Path -LiteralPath $path)) { Invoke-WebRequest -Uri $url -OutFile $path }
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $checksum) { throw "Checksum mismatch: $path" }
}
Get-VerifiedArtifact $manifest.jarUrl (Join-Path $destination "openapi-generator-cli-$($manifest.generatorVersion).jar") $manifest.jarSha256
$archive = Join-Path $destination 'jre21.zip'
Get-VerifiedArtifact $manifest.javaArchiveUrl $archive $manifest.javaArchiveSha256
Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
Write-Output 'Local Java and OpenAPI generator prepared; global environment unchanged.'
