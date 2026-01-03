param()

$ErrorActionPreference = "Stop"

$dryRun = $false
$argsList = New-Object System.Collections.Generic.List[string]
foreach ($arg in $args) {
  if ($arg -eq "--dry-run" -or $arg -eq "-dry-run" -or $arg -eq "-DryRun") {
    $dryRun = $true
  } else {
    $argsList.Add($arg) | Out-Null
  }
}

if ($argsList.Count -lt 1) {
  Write-Host "Usage: .\scripts\agent.ps1 <role> [message...] [--dry-run]"
  exit 1
}

$role = $argsList[0]
$message = ""
if ($argsList.Count -gt 1) {
  $message = ($argsList.GetRange(1, $argsList.Count - 1) -join " ").Trim()
}

$root = Split-Path -Parent $PSScriptRoot
$systemPromptPath = Join-Path $root ".codex/system_prompt.txt"
$agentPromptPath = Join-Path $root (".codex/agents/" + $role + ".txt")
$contextMapPath = Join-Path $root ".codex/context_map.json"

if (-not (Test-Path $systemPromptPath)) {
  Write-Error "Missing system prompt: $systemPromptPath"
  exit 1
}
if (-not (Test-Path $agentPromptPath)) {
  Write-Error "Missing agent prompt: $agentPromptPath"
  exit 1
}
if (-not (Test-Path $contextMapPath)) {
  Write-Error "Missing context map: $contextMapPath"
  exit 1
}

$systemPrompt = Get-Content $systemPromptPath -Raw
$agentPrompt = Get-Content $agentPromptPath -Raw
$contextMap = Get-Content $contextMapPath -Raw | ConvertFrom-Json

$entry = $contextMap.defaults
if ($contextMap.agents.PSObject.Properties.Name -contains $role) {
  $entry = $contextMap.agents.$role
}

$maxChars = $null
if ($entry.PSObject.Properties.Name -contains "max_chars") {
  $maxChars = [int]$entry.max_chars
}

$files = New-Object System.Collections.Generic.List[string]
$seen = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
foreach ($file in $entry.files) {
  if ($seen.Add($file)) {
    $files.Add($file) | Out-Null
  }
}

$payloadParts = New-Object System.Collections.Generic.List[string]
$payloadParts.Add("SYSTEM PROMPT") | Out-Null
$payloadParts.Add($systemPrompt) | Out-Null
$payloadParts.Add("AGENT PROMPT") | Out-Null
$payloadParts.Add($agentPrompt) | Out-Null
$payloadParts.Add("CONTEXT FILES") | Out-Null

$includedFiles = New-Object System.Collections.Generic.List[string]
$excludedDueToBudget = New-Object System.Collections.Generic.List[string]
$totalIncludedChars = 0

foreach ($file in $files) {
  $path = Join-Path $root $file
  if (-not (Test-Path $path)) {
    Write-Warning ("Missing context file: " + $file)
    continue
  }
  $content = Get-Content $path -Raw
  $contentLength = $content.Length
  if ($null -ne $maxChars -and (($totalIncludedChars + $contentLength) -gt $maxChars)) {
    $excludedDueToBudget.Add($file) | Out-Null
    continue
  }
  $payloadParts.Add("### FILE: " + $file) | Out-Null
  $payloadParts.Add($content) | Out-Null
  $includedFiles.Add($file) | Out-Null
  $totalIncludedChars += $contentLength
}

$payloadParts.Add("USER MESSAGE") | Out-Null
$payloadParts.Add($message) | Out-Null

$payload = ($payloadParts -join "`n`n")

Write-Host "Agent: $role"
Write-Host "Reminder: max 2 fix attempts before Diagnose Mode."

$budgetLabel = "none"
if ($null -ne $maxChars) {
  $budgetLabel = $maxChars
}
$includedLabel = "(none)"
if ($includedFiles.Count -gt 0) {
  $includedLabel = ($includedFiles -join ", ")
}
Write-Host "Context Pack Summary"
Write-Host ("- Agent role: " + $role)
Write-Host ("- Budget max_chars: " + $budgetLabel)
Write-Host ("- Total included chars: " + $totalIncludedChars)
Write-Host ("- Included files: " + $includedLabel)
if ($excludedDueToBudget.Count -gt 0) {
  Write-Host ("- Excluded due to budget: " + ($excludedDueToBudget -join ", "))
}

if ($dryRun) {
  Write-Host "DRY RUN: payload below (no Codex invocation)."
  Write-Host ""
  Write-Host $payload
  exit 0
}

$codexCmd = $env:CODEX_CLI
if ([string]::IsNullOrWhiteSpace($codexCmd)) {
  $codexCmd = "codex"
}

$cmdName = [System.IO.Path]::GetFileNameWithoutExtension($codexCmd)
if ($cmdName -notmatch '(?i)codex') {
  Write-Error "CODEX_CLI must reference a Codex CLI command."
  exit 1
}

$cmdInfo = Get-Command $codexCmd -ErrorAction SilentlyContinue
if (-not $cmdInfo) {
  Write-Error ("Codex CLI not found: " + $codexCmd)
  exit 1
}

Write-Output $payload | & $codexCmd
