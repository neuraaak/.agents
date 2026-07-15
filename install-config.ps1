$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
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
