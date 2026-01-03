param()

$root = Split-Path -Parent $PSScriptRoot
$docsDir = Join-Path $root "docs"
$featuresDir = Join-Path $docsDir "FEATURES"

Write-Host "Verifying Documentation Integrity..."
$warnings = 0

function Warn($msg) {
    Write-Warning $msg
    $script:warnings++
}

# 1. Check Feature Specs
if (Test-Path $featuresDir) {
    $featureFiles = Get-ChildItem -Path $featuresDir -Filter "*.md"
    foreach ($file in $featureFiles) {
        # skip template
        if ($file.Name -eq "_TEMPLATE.md") { continue }

        # Check Filename Format
        if ($file.Name -notmatch '^F-\d{3}-[a-z0-9-]+\.md$') {
            Warn "File $($file.Name) does not match naming convention F-XXX-slug.md"
        }

        $content = Get-Content $file.FullName -Raw
        
        # Check Status
        if ($content -match 'Status:\s*(.*)') {
            $status = $Matches[1].Trim()
            $validStatuses = "Identifying", "Questions Open", "Plan Proposed", "Plan Approved", "Implementing", "Verifying", "Completed", "Deferred"
            if ($validStatuses -notcontains $status) {
                Warn "$($file.Name): Invalid status '$status'"
            }

            # Check for Open Questions if Approved+
            $approvedStates = "Plan Approved", "Implementing", "Verifying", "Completed"
            if ($approvedStates -contains $status) {
                if ($content -match '(?-i)Question:.*(?-i)\?.*(?-i)Answer:.*TBD') {
                    Warn "$($file.Name): Contains unanswered questions but is in state '$status'"
                }
            }
        }
        else {
            Warn "$($file.Name): Missing 'Status:' field"
        }
    }
}

# 2. Check PRD
$prd = Join-Path $docsDir "PRD.md"
if (Test-Path $prd) {
    $content = Get-Content $prd -Raw
    if ($content -match 'TBD') {
        Warn "PRD.md contains 'TBD' placeholders."
    }
}

# 3. Check Dead Links (Simple Regex)
$allDocs = Get-ChildItem -Path $docsDir -Recurse -Filter "*.md"
foreach ($file in $allDocs) {
    $content = Get-Content $file.FullName -Raw
    # Match [text](link)
    # Very basic regex, might catch false positives/negatives but good for V1
    $links = [regex]::Matches($content, '\[.*?\]\((.*?)\)')
    foreach ($match in $links) {
        $link = $match.Groups[1].Value
        
        # Skip external links
        if ($link -match '^http') { continue }
        # Skip anchors
        if ($link -match '^#') { continue }
        # Skip mailto
        if ($link -match '^mailto:') { continue }

        # Resolve path
        # If it starts with /, it's relative to repo root (maybe) or absolute? 
        # Markdown links usually relative to file.
        # Let's handle relative links.
        
        $targetPath = $null
        try {
            if ($link -match '^\/') {
                # Root relative
                $targetPath = Join-Path $root $link.Substring(1)
            }
            else {
                # Relative to file
                $targetPath = Join-Path $file.DirectoryName $link
            }
            
            # Remove anchors for file check
            if ($targetPath -match '#') {
                $targetPath = $targetPath -split '#' | Select-Object -First 1
            }

            if (-not (Test-Path $targetPath)) {
                Warn "$($file.Name): Broken link to '$link'"
            }
        }
        catch {
            Warn "$($file.Name): Could not resolve link '$link'"
        }
    }
}

Write-Host "Doc verification complete. $warnings warnings found."
# Always return 0 as requested (WARN only)
exit 0
