param(
    [string]$Name,
    [string]$Description,
    [string]$TechStack,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# --- Helper: Interactive Prompt ---
function Ask($prompt, $value) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        return (Read-Host $prompt)
    }
    return $value
}

Write-Host "ZeroRepo Initialization"
Write-Host "-----------------------"

$Name = Ask "Project Name" $Name
$Description = Ask "Project Description" $Description
$TechStack = Ask "Tech Stack (e.g. Node, React, Postgres)" $TechStack

if ([string]::IsNullOrWhiteSpace($Name)) { Write-Error "Name is required."; exit 1 }
if ([string]::IsNullOrWhiteSpace($TechStack)) { Write-Error "Tech Stack is required."; exit 1 }

# --- 1. Create docs/TECH_STACK.md ---
$techStackFile = Join-Path $root "docs/TECH_STACK.md"
$techStackContent = @"
# Technology Stack

## Core
$TechStack

## Decisions
- (Add architecture decisions here or in ADRs)
"@

if ($DryRun) {
    Write-Host "[DryRun] Would write $techStackFile"
}
else {
    Set-Content -Path $techStackFile -Value $techStackContent -Encoding ascii
    Write-Host "Created $techStackFile"
}

# --- 2. Update README.md ---
$readmeFile = Join-Path $root "README.md"
if (Test-Path $readmeFile) {
    if ($DryRun) {
        Write-Host "[DryRun] Would update $readmeFile title to '$Name'"
    }
    else {
        $readmeContent = Get-Content $readmeFile -Raw
        # Replace first line if it looks like a header
        $readmeContent = $readmeContent -replace '^# .*', "# $Name"
        # Insert description after title
        $readmeContent = $readmeContent -replace '(# .*\r?\n)', "$1`n$Description`n"
        Set-Content -Path $readmeFile -Value $readmeContent -Encoding ascii
        Write-Host "Updated $readmeFile"
    }
}

# --- 3. Create Project Charter ---
$charterTemplate = Join-Path $root "docs/PROJECT_CHARTER_TEMPLATE.md"
$charterDest = Join-Path $root "docs/PROJECT_CHARTER.md"
if (Test-Path $charterTemplate) {
    if (-not (Test-Path $charterDest)) {
        if ($DryRun) {
            Write-Host "[DryRun] Would copy Charter to $charterDest"
        }
        else {
            Copy-Item $charterTemplate $charterDest
            Write-Host "Created $charterDest (Please fill it out!)"
        }
    }
}

# --- 4. Update Context Map ---
$contextMapFile = Join-Path $root ".codex/context_map.json"
if (Test-Path $contextMapFile) {
    $json = Get-Content $contextMapFile -Raw | ConvertFrom-Json
    
    # Ensure 'defaults' exists
    if (-not $json.PSObject.Properties.Match("defaults").Count) {
        $json | Add-Member -MemberType NoteProperty -Name "defaults" -Value (@{ files = @() })
    }
    
    # Check if TECH_STACK.md is already in defaults.files
    $files = $json.defaults.files
    if ($files -notcontains "docs/TECH_STACK.md") {
        if ($DryRun) {
            Write-Host "[DryRun] Would add docs/TECH_STACK.md to context_map.json"
        }
        else {
            $files += "docs/TECH_STACK.md"
            $json.defaults.files = $files
            $json | ConvertTo-Json -Depth 10 | Set-Content $contextMapFile
            Write-Host "Updated .codex/context_map.json (Agents now know your Tech Stack)"
        }
    }
}

Write-Host "-----------------------"
Write-Host "Initialization Complete!"
if (-not $DryRun) {
    Write-Host "Next Step: Run 'ZeroRepo: New Feature' to start building."
}
