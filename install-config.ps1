param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RawArgs
)

$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Forme a slashs pour substituer {{AGENTS_DIR}} : les fichiers generes affichent
# ainsi C:/Users/.../.agents (coherent avec les @import ~/ et les conventions
# markdown). $repoDir reste en backslashs pour Join-Path / operations fichier.
$repoDirFwd = $repoDir.Replace('\', '/')
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-FromTemplate {
    # Copie le template en remplacant {{AGENTS_DIR}} par le chemin du depot,
    # sans toucher aux @import : le provider les resout au demarrage de session.
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
    $content = $content.Replace("{{AGENTS_DIR}}", $repoDirFwd)

    [System.IO.File]::WriteAllText($TargetFile, $content, $utf8NoBom)

    Write-Host "$TargetFile genere"
}

function Set-RulesJunction {
    # Cree/repare une jonction de dossier <LinkDir> -> <repo>/rules/common.
    # Claude Code decouvre et charge automatiquement tout ~/.claude/rules/*.md
    # (recursivement) : aucun @import n'est necessaire. La jonction cible
    # volontairement rules/common/ SEUL, car cette decouverte est
    # inconditionnelle -- exposer rules/ en entier chargerait aussi
    # rules/internal/, reserve aux projets prives, et rules/index.md qui arbitre
    # ce choix. Ces deux-la restent lus a la demande via leur chemin absolu
    # (voir templates/CLAUDE.template.md).
    # Jonction et non symlink : ne demande NI privileges admin NI Developer Mode
    # (contrairement a New-Item -ItemType SymbolicLink).
    param(
        [string]$LinkDir
    )

    $target = (Resolve-Path (Join-Path $repoDir "rules\common")).Path

    $existing = Get-Item -LiteralPath $LinkDir -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq "Junction" -and (($existing.Target -join "") -ieq $target)) {
            Write-Host "$LinkDir -> $target (jonction deja en place)"
            return
        }
        if ($existing.LinkType -eq "Junction" -or $existing.LinkType -eq "SymbolicLink") {
            # Lien existant mais mauvaise cible : on le refait.
            Remove-Item -LiteralPath $LinkDir -Force
        }
        else {
            Write-Error "$LinkDir existe et n'est pas un lien (dossier/fichier reel) : refuse d'ecraser"
            exit 1
        }
    }

    $parent = Split-Path -Parent $LinkDir
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }

    New-Item -ItemType Junction -Path $LinkDir -Target $target | Out-Null
    Write-Host "$LinkDir -> $target (jonction creee)"
}

function Write-FromTemplateWithInlinedRules {
    # Inline le contenu des rules a la place de chaque placeholder
    # {{INCLUDE:chemin/relatif.md}}. Utilise pour les providers sans @import
    # exploitable (Codex, Vibe : pas de mecanisme d'import ; Gemini : refuse les
    # @import hors basePath en "path traversal"). Claude, lui, passe par une
    # jonction + decouverte native (voir Set-RulesJunction / Install-Claude).
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
    $content = $content.Replace("{{AGENTS_DIR}}", $repoDirFwd)

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
    # ~/.claude/rules est une jonction vers .agents/rules/common : Claude Code
    # y decouvre et charge les rules communes tout seul, sans @import. Elles
    # restent une source unique, modifiables sans regenerer ce fichier ; seul
    # CLAUDE.md est produit depuis le template.
    Set-RulesJunction -LinkDir (Join-Path $env:USERPROFILE ".claude\rules")

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

function Invoke-Verify {
    # Controle d'integrite de ce qui est REELLEMENT installe, sans rien ecrire.
    # Motif : l'installation a deja echoue silencieusement trois fois (CLAUDE.md
    # perime un mois, GEMINI.md a 0 octet, AGENTS.md de Vibe porteur d'un ancien
    # chemin memoire pendant six semaines). Dans les trois cas le fichier
    # existait et paraissait correct a la lecture : seul un controle externe
    # - fraicheur, placeholders, cible de la jonction - les distingue.
    $problems = 0

    # Reference de fraicheur : la plus recente modification des sources.
    $newestSource = Get-ChildItem -Path (Join-Path $repoDir "rules"), (Join-Path $repoDir "templates") -Recurse -File |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "Source la plus recente : $($newestSource.Name) ($($newestSource.LastWriteTime))"
    Write-Host ""

    # 1. Jonction des rules communes (Claude uniquement).
    $linkDir = Join-Path (Join-Path $env:USERPROFILE ".claude") "rules"
    $expected = (Resolve-Path (Join-Path $repoDir "rules\common")).Path
    $link = Get-Item -LiteralPath $linkDir -ErrorAction SilentlyContinue
    if (-not $link) {
        Write-Warning "jonction absente : $linkDir (aucune rule commune ne charge dans Claude)"
        $problems++
    }
    elseif ($link.LinkType -ne "Junction" -or (($link.Target -join "") -ine $expected)) {
        Write-Warning "jonction incorrecte : $linkDir -> $($link.Target -join '') (attendu $expected)"
        $problems++
    }
    else {
        # La decouverte native est recursive et inconditionnelle : internal/ et
        # index.md ne doivent pas etre atteignables depuis la jonction.
        $leaked = Get-ChildItem -Path $linkDir -Recurse -File -Filter *.md |
            Where-Object { $_.FullName -match '[\/]internal[\/]' -or $_.Name -ieq 'index.md' }
        if ($leaked) {
            Write-Warning "jonction : fichiers conditionnels exposes ($($leaked.Name -join ', '))"
            $problems++
        }
        else {
            Write-Host "OK  jonction $linkDir -> $expected ($((Get-ChildItem -Path $linkDir -File -Filter *.md).Count) rules communes)"
        }
    }

    # 2. Fichiers generes : presents, non vides, sans placeholder, a jour.
    $generated = [ordered]@{
        "claude" = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
        "gemini" = Join-Path $env:USERPROFILE ".gemini\GEMINI.md"
        "codex"  = Join-Path $env:USERPROFILE ".codex\AGENTS.md"
        "vibe"   = Join-Path $env:USERPROFILE ".vibe\AGENTS.md"
    }

    foreach ($name in $generated.Keys) {
        $file = $generated[$name]
        $item = Get-Item -LiteralPath $file -ErrorAction SilentlyContinue
        if (-not $item) {
            Write-Host "--  $name non installe ($file absent)"
            continue
        }
        if ($item.Length -eq 0) {
            Write-Warning "$name : fichier vide ($file)"
            $problems++
            continue
        }
        # Placeholders non substitues. Cible {{AGENTS_DIR}} et {{INCLUDE:...}}
        # seulement : les rules CI/CD contiennent du YAML ${{ secrets.X }}
        # legitime, qui ne doit pas declencher d'alerte.
        $content = [System.IO.File]::ReadAllText($file, $utf8NoBom)
        if ($content -match "\{\{AGENTS_DIR\}\}" -or $content -match "\{\{INCLUDE:") {
            Write-Warning "$name : placeholder non substitue dans $file"
            $problems++
            continue
        }
        if ($item.LastWriteTime -lt $newestSource.LastWriteTime) {
            Write-Warning "$name : PERIME ($($item.LastWriteTime)) - anterieur a $($newestSource.Name). Regenerer."
            $problems++
            continue
        }
        Write-Host "OK  $name a jour ($($item.LastWriteTime), $($item.Length) octets)"
    }

    Write-Host ""
    if ($problems -eq 0) {
        Write-Host "Verification : aucun probleme."
    }
    else {
        Write-Host "Verification : $problems probleme(s)."
    }
    # Compteur en portee script : un `return` depuis une fonction PowerShell
    # part dans le pipeline et peut arriver sous forme de tableau a l'appelant.
    $script:verifyProblems = $problems
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
  --verify, -Y   Verifier l'installation existante sans rien ecrire
                 (jonction, placeholders, fichiers vides, fraicheur)
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
    "--verify" = "verify"
    "-Y"       = "verify"
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
        Write-Error "Argument inconnu: $arg. Options valides: --claude, -C, --gemini, -G, --codex, -X, --vibe, -B, --verify, -Y, --help, -h"
        exit 1
    }
}

# --verify n'est pas une cible d'installation : on le sort de la liste pour le
# jouer apres les installations eventuelles (`-C -Y` = installe puis verifie).
$verify = $targets -contains "verify"
$targets = @($targets | Where-Object { $_ -ne "verify" })

if ($targets.Count -eq 0 -and -not $verify) {
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

if ($verify) {
    if ($targets.Count -gt 0) { Write-Host "" }
    $script:verifyProblems = 0
    Invoke-Verify
    if ($script:verifyProblems -gt 0) { exit 1 }
    exit 0
}
