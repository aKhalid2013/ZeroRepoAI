param()

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$gatesPath = Join-Path $root "docs/QUALITY_GATES.md"

if (-not (Test-Path $gatesPath)) {
  Write-Error "Missing docs/QUALITY_GATES.md"
  exit 1
}

$commands = @{}
Get-Content $gatesPath | ForEach-Object {
  if ($_ -match '^(lint|typecheck|test|build)\s*=\s*(.*)$') {
    $commands[$Matches[1]] = $Matches[2].Trim()
  }
}

$gates = @("lint", "typecheck", "test", "build")
$status = [ordered]@{}
$failedGate = $null

foreach ($gate in $gates) {
  if ($failedGate) { break }

  $cmd = $null
  if ($commands.ContainsKey($gate)) { $cmd = $commands[$gate] }

  $isMissing = [string]::IsNullOrWhiteSpace($cmd)
  $isTbd = $false
  if (-not $isMissing) { $isTbd = ($cmd -match '^(?i)TBD$') }

  if ($isMissing -or $isTbd) {
    Write-Warning ("SKIPPED " + $gate + ": not configured or TBD")
    $status[$gate] = "SKIP"
    continue
  }

  Write-Host ("RUN " + $gate + ": " + $cmd)
  cmd /c $cmd
  if ($LASTEXITCODE -ne 0) {
    Write-Host ("FAIL " + $gate + " (exit " + $LASTEXITCODE + ")")
    $status[$gate] = "FAIL"
    $failedGate = $gate
    continue
  }

  Write-Host ("PASS " + $gate)
  $status[$gate] = "PASS"
}

if ($failedGate) {
  foreach ($gate in $gates) {
    if (-not $status.Contains($gate)) {
      Write-Warning ("SKIPPED " + $gate + ": blocked by failure in " + $failedGate)
      $status[$gate] = "SKIP"
    }
  }
}

$summary = foreach ($gate in $gates) {
  [PSCustomObject]@{
    Gate   = $gate
    Status = $status[$gate]
  }
}

Write-Host ""
Write-Host "--- Doc Verification ---"
& "$PSScriptRoot/verify-docs.ps1"
Write-Host "------------------------"

Write-Host ""
Write-Host "Summary"
$summary | Format-Table -AutoSize

if ($failedGate) {
  Write-Error ("Failed gate: " + $failedGate)
  exit 1
}

Write-Host "All configured gates passed."
