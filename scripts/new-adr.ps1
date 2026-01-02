param(
  [Parameter(Mandatory = $true)][string]$Title
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$adrDir = Join-Path $root "docs/ADR"
$template = Join-Path $adrDir "0000-adr-template.md"

if (-not (Test-Path $template)) {
  Write-Error "Template not found: $template"
  exit 1
}

$existing = @()
Get-ChildItem -Path $adrDir -Filter "*.md" | ForEach-Object {
  if ($_.BaseName -match '^(\d{4})') {
    $existing += [int]$Matches[1]
  }
}

$next = 1
if ($existing.Count -gt 0) {
  $next = ($existing | Measure-Object -Maximum).Maximum + 1
}

$id = ("{0:D4}" -f $next)
$slug = ($Title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if ([string]::IsNullOrWhiteSpace($slug)) {
  Write-Error "Title must include alphanumeric characters for slug generation."
  exit 1
}

$filename = "$id-$slug.md"
$dest = Join-Path $adrDir $filename

if (Test-Path $dest) {
  Write-Error "File exists: $dest"
  exit 1
}

$content = Get-Content $template -Raw
$content = $content -replace 'ADR 0000', ("ADR " + $id)
$content = $content -replace '<title>', $Title

Set-Content -Path $dest -Value $content -Encoding ascii
Write-Host "Created $dest"
