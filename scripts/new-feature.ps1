param(
  [Parameter(Mandatory = $true)][string]$Title
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$featuresDir = Join-Path $root "docs/FEATURES"
$template = Join-Path $featuresDir "_TEMPLATE.md"

if (-not (Test-Path $template)) {
  Write-Error "Template not found: $template"
  exit 1
}

$existing = @()
Get-ChildItem -Path $featuresDir -Filter "F-*.md" | ForEach-Object {
  if ($_.BaseName -match '^F-(\d{3})') {
    $existing += [int]$Matches[1]
  }
}

$next = 1
if ($existing.Count -gt 0) {
  $next = ($existing | Measure-Object -Maximum).Maximum + 1
}

$id = ("F-{0:D3}" -f $next)
$slug = ($Title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if ([string]::IsNullOrWhiteSpace($slug)) {
  Write-Error "Title must include alphanumeric characters for slug generation."
  exit 1
}

$filename = "$id-$slug.md"
$dest = Join-Path $featuresDir $filename

if (Test-Path $dest) {
  Write-Error "File exists: $dest"
  exit 1
}

$content = Get-Content $template -Raw
$content = $content -replace 'F-xxx', $id
$content = $content -replace '<title>', $Title

Set-Content -Path $dest -Value $content -Encoding ascii
Write-Host "Created $dest"
