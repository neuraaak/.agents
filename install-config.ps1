$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rulesIndex = Join-Path $repoDir "rules\index.md"
$targetDir = Join-Path $env:USERPROFILE ".claude"
$targetFile = Join-Path $targetDir "CLAUDE.md"

if (-not (Test-Path $rulesIndex)) {
    Write-Error "rules/index.md introuvable dans $repoDir"
    exit 1
}

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

$startMark = "<!-- agents:managed:start -->"
$endMark = "<!-- agents:managed:end -->"
$block = "$startMark`n@$rulesIndex`n$endMark"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $targetFile)) {
    [System.IO.File]::WriteAllText($targetFile, $block, $utf8NoBom)
    Write-Host "Bloc cree dans $targetFile"
    exit 0
}

$content = Get-Content -Path $targetFile -Raw
if ($null -eq $content) { $content = "" }

$startIdx = $content.IndexOf($startMark)

if ($startIdx -ge 0) {
    $endIdx = $content.IndexOf($endMark, $startIdx)
    if ($endIdx -lt 0) {
        Write-Error "Bloc mal forme dans ${targetFile}: marqueur de fin introuvable"
        exit 1
    }
    $endIdx = $endIdx + $endMark.Length
    $newContent = $content.Substring(0, $startIdx) + $block + $content.Substring($endIdx)
    Write-Host "Bloc remplace dans $targetFile"
} else {
    $trimmed = $content.TrimEnd("`r", "`n")
    $sep = if ($trimmed.Length -eq 0) { "" } else { "`n`n" }
    $newContent = $trimmed + $sep + $block + "`n"
    Write-Host "Bloc ajoute a la fin de $targetFile"
}

[System.IO.File]::WriteAllText($targetFile, $newContent, $utf8NoBom)
