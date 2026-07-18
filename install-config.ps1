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

function Write-FromTemplateWithInlinedRules {
    # Pour les providers sans mecanisme d'import (Codex, Vibe) : inline le
    # contenu des rules a la place de chaque placeholder {{INCLUDE:chemin/relatif.md}}.
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
            $rulesDirPrefix = $rulesDir + [System.IO.Path]::DirectorySeparatorChar
            if (-not $resolvedRuleFile.StartsWith($rulesDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Error "{{INCLUDE:$relativePath}} sort du dossier rules/ ($resolvedRuleFile) : refuse"
                exit 1
            }
            [System.IO.File]::ReadAllText($resolvedRuleFile, $utf8NoBom).Trim()
        })

    [System.IO.File]::WriteAllText($TargetFile, $content, $utf8NoBom)

    Write-Host "$TargetFile genere"
}

function Install-Claude {
    $templateFile = Join-Path $repoDir "templates\CLAUDE.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
    Write-FromTemplate -TemplateFile $templateFile -TargetFile $targetFile
}

function Install-Gemini {
    # Gemini CLI refuse les @import en chemin absolu hors du basePath de
    # GEMINI.md (~/.gemini/) avec "Path traversal attempt". On inline donc
    # les rules, comme pour Codex/Vibe, au lieu de les referencer via @.
    $templateFile = Join-Path $repoDir "templates\GEMINI.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".gemini\GEMINI.md"
    Write-FromTemplateWithInlinedRules -TemplateFile $templateFile -TargetFile $targetFile
}

function Install-Codex {
    # Codex n'a pas de mecanisme d'import (memes conventions que Vibe : AGENTS.md, pas d'include).
    $templateFile = Join-Path $repoDir "templates\AGENTS.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".codex\AGENTS.md"
    Write-FromTemplateWithInlinedRules -TemplateFile $templateFile -TargetFile $targetFile
}

function Install-Vibe {
    # Mistral Vibe suit exactement la meme convention que Codex : fichier
    # AGENTS.md, pas de mecanisme d'import. Meme template reutilise.
    $templateFile = Join-Path $repoDir "templates\AGENTS.template.md"
    $targetFile = Join-Path $env:USERPROFILE ".vibe\AGENTS.md"
    Write-FromTemplateWithInlinedRules -TemplateFile $templateFile -TargetFile $targetFile
}

function Show-Help {
    Write-Host @"
Usage: install-config.ps1 [options]

Installe/regenere les fichiers de configuration des providers a partir
des templates de ce depot (.claude/CLAUDE.md, .gemini/GEMINI.md, etc.).

Options:
  --claude, -C   Installer la config Claude (defaut si aucune option)
  --gemini, -G   Installer la config Gemini
  --codex,  -X   Installer la config Codex
  --vibe,   -B   Installer la config Mistral Vibe
  --help,   -h   Afficher cette aide

Plusieurs options peuvent etre combinees dans un meme appel.
"@
}

$knownFlags = @{
    "--claude" = "claude"
    "-C"       = "claude"
    "--gemini" = "gemini"
    "-G"       = "gemini"
    "--codex"  = "codex"
    "-X"       = "codex"
    "--vibe"   = "vibe"
    "-B"       = "vibe"
}

# NB: certaines lettres seules (-V, -D, -W, -E, -I, -O, -P...) sont reservees
# par PowerShell comme abreviations des parametres communs (-Verbose, -Debug,
# -WarningAction, -ErrorAction...) et sont absorbees silencieusement AVANT
# d'atteindre $RawArgs, meme sans [CmdletBinding()]. Ne jamais leur associer
# un flag ici : l'argument disparaitrait sans erreur (c'est ce qui causait
# "-V" -> installation Claude au lieu de Vibe).

if ($RawArgs -contains "--help" -or $RawArgs -contains "-h") {
    Show-Help
    exit 0
}

$targets = @()
foreach ($arg in $RawArgs) {
    if ($knownFlags.ContainsKey($arg)) {
        $targets += $knownFlags[$arg]
    }
    else {
        Write-Error "Argument inconnu: $arg. Options valides: --claude, -C, --gemini, -G, --codex, -X, --vibe, -B, --help, -h"
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
        "codex" { Install-Codex }
        "vibe" { Install-Vibe }
    }
}
