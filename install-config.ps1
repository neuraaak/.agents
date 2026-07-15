param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RawArgs
)

$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-FromTemplate {
    param(
        [string]$TemplateFile,
        [string]$TargetFile
    )

    if (-not (Test-Path $TemplateFile)) {
        Write-Error "$TemplateFile introuvable"
        exit 1
    }

    $targetDir = Split-Path -Parent $TargetFile
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $content = [System.IO.File]::ReadAllText($TemplateFile, $utf8NoBom)
    $content = $content.Replace("{{AGENTS_DIR}}", $repoDir)

    [System.IO.File]::WriteAllText($TargetFile, $content, $utf8NoBom)

    Write-Host "$TargetFile genere"
}

function Install-Claude {
    $templateFile = Join-Path $repoDir "templates\CLAUDE.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
    Write-FromTemplate -TemplateFile $templateFile -TargetFile $targetFile
}

function Install-Gemini {
    $templateFile = Join-Path $repoDir "templates\GEMINI.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".gemini\GEMINI.md"
    Write-FromTemplate -TemplateFile $templateFile -TargetFile $targetFile
}

function Install-Codex {
    # Codex n'a pas de mecanisme d'import : on inline le contenu des rules
    # a la place de chaque placeholder {{INCLUDE:chemin/relatif.md}}.
    $templateFile = Join-Path $repoDir "templates\AGENTS.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".codex\AGENTS.md"

    if (-not (Test-Path $templateFile)) {
        Write-Error "$templateFile introuvable"
        exit 1
    }

    $targetDir = Split-Path -Parent $targetFile
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $content = [System.IO.File]::ReadAllText($templateFile, $utf8NoBom)
    $content = $content.Replace("{{AGENTS_DIR}}", $repoDir)

    $rulesDir = (Resolve-Path (Join-Path $repoDir "rules")).Path

    $includePattern = [regex]"\{\{INCLUDE:([^}]+)\}\}"
    $content = $includePattern.Replace($content, {
        param($match)
        $relativePath = $match.Groups[1].Value
        $ruleFile = Join-Path $rulesDir $relativePath
        if (-not (Test-Path $ruleFile)) {
            Write-Error "Rule introuvable pour {{INCLUDE:$relativePath}} : $ruleFile"
            exit 1
        }
        $resolvedRuleFile = (Resolve-Path $ruleFile).Path
        if (-not $resolvedRuleFile.StartsWith($rulesDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Error "{{INCLUDE:$relativePath}} sort du dossier rules/ ($resolvedRuleFile) : refuse"
            exit 1
        }
        [System.IO.File]::ReadAllText($resolvedRuleFile, $utf8NoBom).Trim()
    })

    [System.IO.File]::WriteAllText($targetFile, $content, $utf8NoBom)

    Write-Host "$targetFile genere"
}

$knownFlags = @{
    "--claude" = "claude"
    "-C"       = "claude"
    "--gemini" = "gemini"
    "-G"       = "gemini"
    "--codex"  = "codex"
    "-X"       = "codex"
}

$targets = @()
foreach ($arg in $RawArgs) {
    if ($knownFlags.ContainsKey($arg)) {
        $targets += $knownFlags[$arg]
    } else {
        Write-Error "Argument inconnu: $arg. Options valides: --claude, -C, --gemini, -G, --codex, -X"
        exit 1
    }
}

if ($targets.Count -eq 0) {
    $targets = @("claude")
}

foreach ($target in ($targets | Select-Object -Unique)) {
    switch ($target) {
        "claude" { Install-Claude }
        "gemini" { Install-Gemini }
        "codex"  { Install-Codex }
    }
}
