param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RawArgs
)

$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Install-Claude {
    $templateFile = Join-Path $repoDir "templates\CLAUDE.template.md"
    $targetDir = Join-Path $env:USERPROFILE ".claude"
    $targetFile = Join-Path $targetDir "CLAUDE.md"

    if (-not (Test-Path $templateFile)) {
        Write-Error "templates/CLAUDE.template.md introuvable dans $repoDir"
        exit 1
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($templateFile, $utf8NoBom)
    $content = $content.Replace("{{AGENTS_DIR}}", $repoDir)

    [System.IO.File]::WriteAllText($targetFile, $content, $utf8NoBom)

    Write-Host "CLAUDE.md genere dans $targetFile"
}

$knownFlags = @{
    "--claude" = "claude"
    "-C"       = "claude"
}

$targets = @()
foreach ($arg in $RawArgs) {
    if ($knownFlags.ContainsKey($arg)) {
        $targets += $knownFlags[$arg]
    } else {
        Write-Error "Argument inconnu: $arg. Options valides: --claude, -C"
        exit 1
    }
}

if ($targets.Count -eq 0) {
    $targets = @("claude")
}

foreach ($target in ($targets | Select-Object -Unique)) {
    switch ($target) {
        "claude" { Install-Claude }
    }
}
