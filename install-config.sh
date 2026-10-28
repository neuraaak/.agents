#!/usr/bin/env bash
# Equivalent POSIX de install-config.cmd / install-config.ps1 (Linux, macOS,
# WSL). Memes options, memes cibles, meme contrat de sortie : seul le mecanisme
# de lien change (symlink au lieu de la jonction NTFS, qui n'existe pas ici).
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")" && pwd -P)
rules_dir="$repo_dir/rules"
templates_dir="$repo_dir/templates"

# Forme substituee dans {{AGENTS_DIR}}, distincte de celle des operations
# fichier -- meme separation que $repoDir / $repoDirFwd dans le .ps1. Sous MSYS,
# pwd -P rend /c/Users/... quand le .ps1 ecrit C:/Users/... : sans alignement,
# --verify croit voir un ecart sur une installation saine, et les fichiers
# generes porteraient un chemin qu'un provider Windows ne sait pas lire.
# repo_dir lui-meme n'est PAS converti : rules_dir en derive, et le garde-fou
# des {{INCLUDE:}} compare un realpath (forme /c/...) a ce prefixe.
if command -v cygpath >/dev/null 2>&1; then
    repo_dir_sub=$(cygpath -m "$repo_dir")
else
    repo_dir_sub=$repo_dir
fi

die() {
    printf 'Erreur: %s\n' "$1" >&2
    exit 1
}

# Retire les lignes vides de debut et de fin, comme le .Trim() du script
# PowerShell : les rules inlinees doivent s'enchainer sans trous.
trim_file() {
    awk '{l[NR]=$0}
         END {
             f=1; d=NR
             while (f<=NR && l[f]~/^[[:space:]]*$/) f++
             while (d>=f && l[d]~/^[[:space:]]*$/) d--
             for (i=f; i<=d; i++) print l[i]
         }' "$1"
}

ensure_dir() {
    [ -d "$1" ] || mkdir -p "$1"
}

write_from_template() {
    # Copie le template en remplacant {{AGENTS_DIR}} par le chemin du depot.
    local template_file=$1 target_file=$2
    [ -f "$template_file" ] || die "$template_file introuvable"
    ensure_dir "$(dirname "$target_file")"
    sed "s|{{AGENTS_DIR}}|$repo_dir_sub|g" "$template_file" > "$target_file"
    printf '%s genere\n' "$target_file"
}

write_from_template_with_inlined_rules() {
    # Inline le contenu des rules a la place de chaque {{INCLUDE:chemin.md}},
    # pour les providers sans mecanisme d'import exploitable (Gemini, Codex,
    # Vibe, Kimi). Claude passe par un symlink + decouverte native.
    # shortcut: un seul {{INCLUDE:}} par ligne, ce que respectent les templates
    # du depot ; passer a une boucle sur la ligne si un template en met deux.
    local template_file=$1 target_file=$2
    [ -f "$template_file" ] || die "$template_file introuvable"
    ensure_dir "$(dirname "$target_file")"

    : > "$target_file"
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line//'{{AGENTS_DIR}}'/$repo_dir_sub}
        case $line in
        *'{{INCLUDE:'*)
            local prefix rest rel suffix rule_file resolved
            prefix=${line%%'{{INCLUDE:'*}
            rest=${line#*'{{INCLUDE:'}
            rel=${rest%%'}}'*}
            suffix=${rest#*'}}'}
            rule_file="$rules_dir/$rel"
            [ -f "$rule_file" ] ||
                die "Rule introuvable pour {{INCLUDE:$rel}} : $rule_file"
            resolved=$(realpath "$rule_file")
            case $resolved in
            "$rules_dir"/*) ;;
            *) die "{{INCLUDE:$rel}} sort du dossier rules/ ($resolved) : refuse" ;;
            esac
            # La substitution de commande mange le saut de ligne final de la
            # rule, pour que le suffixe reste sur sa ligne (parite avec le ps1).
            printf '%s%s%s\n' "$prefix" "$(trim_file "$resolved")" "$suffix" \
                >> "$target_file"
            ;;
        *)
            printf '%s\n' "$line" >> "$target_file"
            ;;
        esac
    done < "$template_file"

    printf '%s genere\n' "$target_file"
}

set_rules_symlink() {
    # Lie <link_dir> -> rules/common. Claude Code charge automatiquement tout
    # ~/.claude/rules/*.md : la cible est volontairement common/ SEUL, car
    # cette decouverte est inconditionnelle et exposerait sinon rules/index.md,
    # qui est une carte du depot et non une rule.
    local link_dir=$1 target
    target=$(realpath "$rules_dir/common")

    if [ -L "$link_dir" ]; then
        if [ "$(realpath "$link_dir")" = "$target" ]; then
            printf '%s -> %s (symlink deja en place)\n' "$link_dir" "$target"
            return
        fi
        rm -f "$link_dir"
    elif [ -e "$link_dir" ]; then
        die "$link_dir existe et n'est pas un lien (dossier/fichier reel) : refuse d'ecraser"
    fi

    ensure_dir "$(dirname "$link_dir")"
    ln -s "$target" "$link_dir"
    # Sous MSYS/Git Bash, `ln -s` ne cree pas de lien par defaut : il COPIE le
    # dossier et renvoie 0. Sans ce controle le script annonce un succes alors
    # que les rules sont figees et qu'aucune edition ne les atteindra plus.
    if [ ! -L "$link_dir" ]; then
        # Rien n'existait a cet emplacement avant le `ln -s` ci-dessus : les
        # branches plus haut sortent sinon. Ce qui s'y trouve est donc la copie
        # qu'il vient de creer, et elle seule : on peut la retirer sans risque.
        rm -rf "$link_dir"
        die "$link_dir n'est pas un lien apres ln -s (shell MSYS/Git Bash ?) : copie retiree, passer par install-config.cmd sous Windows"
    fi
    printf '%s -> %s (symlink cree)\n' "$link_dir" "$target"
}

install_claude() {
    set_rules_symlink "$HOME/.claude/rules"
    write_from_template "$templates_dir/CLAUDE.template.md" "$HOME/.claude/CLAUDE.md"
}

install_gemini() {
    write_from_template_with_inlined_rules \
        "$templates_dir/GEMINI.template.md" "$HOME/.gemini/GEMINI.md"
}

install_codex() {
    write_from_template_with_inlined_rules \
        "$templates_dir/AGENTS.template.md" "$HOME/.codex/AGENTS.md"
}

install_vibe() {
    write_from_template_with_inlined_rules \
        "$templates_dir/AGENTS.template.md" "$HOME/.vibe/AGENTS.md"
}

install_kimi() {
    # Kimi Code lit $KIMI_CODE_HOME/AGENTS.md, par defaut ~/.kimi-code/AGENTS.md.
    # Memes conventions que Codex/Vibe : AGENTS.md, pas de mecanisme d'import.
    write_from_template_with_inlined_rules \
        "$templates_dir/AGENTS.template.md" \
        "${KIMI_CODE_HOME:-$HOME/.kimi-code}/AGENTS.md"
}

verify() {
    # Controle d'integrite de ce qui est REELLEMENT installe, sans rien ecrire.
    # L'installation a deja echoue silencieusement trois fois avec des fichiers
    # presents et d'apparence correcte : seul un controle externe les distingue.
    local problems=0
    # tmp n'est PAS local : le trap EXIT s'evalue a la sortie du shell, quand
    # une locale de verify() n'existe plus -- il effacerait alors "" sans rien
    # nettoyer, et chaque --verify laisserait un dossier derriere lui.
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    # 1. Symlink des rules communes (Claude uniquement).
    local link_dir="$HOME/.claude/rules" expected leaked
    expected=$(realpath "$rules_dir/common")
    if [ ! -L "$link_dir" ]; then
        if [ -e "$link_dir" ]; then
            printf 'ATTENTION lien incorrect : %s existe mais n est pas un symlink\n' "$link_dir"
        else
            printf 'ATTENTION lien absent : %s (aucune rule commune ne charge dans Claude)\n' "$link_dir"
        fi
        problems=$((problems + 1))
    elif [ "$(realpath "$link_dir")" != "$expected" ]; then
        printf 'ATTENTION lien incorrect : %s -> %s (attendu %s)\n' \
            "$link_dir" "$(realpath "$link_dir")" "$expected"
        problems=$((problems + 1))
    else
        # La decouverte native est recursive : internal/ et index.md ne doivent
        # pas etre atteignables depuis le lien.
        # basename plutot que -printf : cette option est propre a GNU find et
        # manque sur macOS/BSD, ou --verify echouait avant d'afficher quoi que
        # ce soit.
        leaked=$(find -L "$link_dir" -type f -name '*.md' \
            \( -path '*/internal/*' -o -name 'index.md' \) \
            -exec basename {} ';' | tr '\n' ' ' || true)
        if [ -n "$leaked" ]; then
            printf 'ATTENTION lien : fichiers conditionnels exposes (%s)\n' "$leaked"
            problems=$((problems + 1))
        else
            printf 'OK  lien %s -> %s (%s rules communes)\n' "$link_dir" "$expected" \
                "$(find -L "$link_dir" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
        fi
    fi

    # 2. Fichiers generes : on re-rend ce que les templates produisent AUJOURD'HUI
    # et on compare au fichier installe. Un seul controle qui remplace les quatre
    # approximations precedentes (presence, taille, placeholders, fraicheur) et
    # qui attrape en plus ce qu'aucune ne voyait : fichier edite a la main,
    # {{INCLUDE:}} disparu d'un template, mauvais AGENTS_DIR. Surtout, il ne
    # repose plus sur les dates : un `git checkout` reecrit tout l'arbre et
    # rendait la comparaison de mtime arbitrairement fausse.
    # --strip-trailing-cr : le .ps1 conserve le CRLF des rules la ou l'awk de
    # MSYS l'avale, donc deux installations correctes peuvent differer d'un CR.
    local spec name file template inlines rendered
    for spec in \
        "claude|$HOME/.claude/CLAUDE.md|CLAUDE.template.md|0" \
        "gemini|$HOME/.gemini/GEMINI.md|GEMINI.template.md|1" \
        "codex|$HOME/.codex/AGENTS.md|AGENTS.template.md|1" \
        "vibe|$HOME/.vibe/AGENTS.md|AGENTS.template.md|1" \
        "kimi|${KIMI_CODE_HOME:-$HOME/.kimi-code}/AGENTS.md|AGENTS.template.md|1"; do
        IFS='|' read -r name file template inlines <<< "$spec"

        if [ ! -f "$file" ]; then
            printf -- '--  %s non installe (%s absent)\n' "$name" "$file"
            continue
        fi
        rendered="$tmp/$name"
        if [ "$inlines" = 1 ]; then
            write_from_template_with_inlined_rules \
                "$templates_dir/$template" "$rendered" >/dev/null
        else
            write_from_template "$templates_dir/$template" "$rendered" >/dev/null
        fi
        if diff -q --strip-trailing-cr "$rendered" "$file" >/dev/null; then
            printf 'OK  %s conforme aux templates\n' "$name"
        else
            printf 'ATTENTION %s : differe de ce que les templates produisent (%s). Regenerer.\n' \
                "$name" "$file"
            problems=$((problems + 1))
        fi
    done

    # 3. Regles pro externes (rules/common/internal-context.md). La variable est
    # optionnelle : non definie = aucun contexte pro installe, ce n'est pas une
    # anomalie. Definie mais invalide, en revanche, est une panne muette de plus
    # - l'agent chercherait un index.md absent et retomberait sur les defauts
    # publics sans rien signaler. Le controle "hors du projet courant" ne se fait
    # pas ici (aucun projet courant a l'installation) : il est a la charge de la
    # rule, en session.
    printf '\n'
    if [ -z "${AI_INTERNAL_RULES:-}" ]; then
        printf -- '--  AI_INTERNAL_RULES non defini (aucune regle pro externe)\n'
    elif [ "${AI_INTERNAL_RULES#/}" = "$AI_INTERNAL_RULES" ]; then
        printf 'ATTENTION AI_INTERNAL_RULES : chemin non absolu (%s)\n' "$AI_INTERNAL_RULES"
        problems=$((problems + 1))
    elif [ ! -d "$AI_INTERNAL_RULES" ]; then
        printf 'ATTENTION AI_INTERNAL_RULES : dossier introuvable (%s)\n' "$AI_INTERNAL_RULES"
        problems=$((problems + 1))
    elif [ ! -f "$AI_INTERNAL_RULES/index.md" ]; then
        printf 'ATTENTION AI_INTERNAL_RULES : index.md absent de %s (point d entree obligatoire)\n' "$AI_INTERNAL_RULES"
        problems=$((problems + 1))
    else
        printf 'OK  AI_INTERNAL_RULES -> %s (index.md present)\n' "$AI_INTERNAL_RULES"
        # Racine memoire pro. Absente = normale : elle est creee a la premiere
        # ecriture, et index.md peut la rediriger ailleurs (ce script ne lit pas
        # index.md). Presente mais non inscriptible = panne muette : l'agent
        # ecrirait dans le vide ou, pire, retomberait sur le store perso.
        mem_root="$AI_INTERNAL_RULES/memory"
        if [ ! -d "$mem_root" ]; then
            printf -- '--  memoire pro : %s absent (cree a la premiere ecriture, ou redirige par index.md)\n' "$mem_root"
        elif [ ! -w "$mem_root" ]; then
            printf 'ATTENTION memoire pro : %s non inscriptible\n' "$mem_root"
            problems=$((problems + 1))
        else
            printf 'OK  memoire pro -> %s (inscriptible)\n' "$mem_root"
        fi
    fi

    printf '\n'
    if [ "$problems" -eq 0 ]; then
        printf 'Verification : aucun probleme.\n'
    else
        printf 'Verification : %s probleme(s).\n' "$problems"
    fi
    return "$problems"
}

show_help() {
    cat <<'EOF'
Usage: install-config.sh [options]

Installe/regenere les fichiers de configuration des providers a partir
des templates de ce depot (.claude/CLAUDE.md, .gemini/GEMINI.md, etc.).

Options:
  --claude, -C   Installer la config Claude (defaut si aucune option)
  --gemini, -G   Installer la config Gemini
  --codex,  -X   Installer la config Codex
  --vibe,   -B   Installer la config Mistral Vibe
  --kimi,   -K   Installer la config Kimi Code
  --verify, -Y   Verifier l'installation existante sans rien ecrire
                 (lien, placeholders, fichiers vides, fraicheur)
  --help,   -h   Afficher cette aide

Plusieurs options peuvent etre combinees dans un meme appel.
EOF
}

targets=""
do_verify=0

for arg in "$@"; do
    case $arg in
    --help | -h)
        show_help
        exit 0
        ;;
    --claude | -C) targets="$targets claude" ;;
    --gemini | -G) targets="$targets gemini" ;;
    --codex | -X) targets="$targets codex" ;;
    --vibe | -B) targets="$targets vibe" ;;
    --kimi | -K) targets="$targets kimi" ;;
    --verify | -Y) do_verify=1 ;;
    *)
        printf 'Argument inconnu: %s. Options valides: --claude, -C, --gemini, -G, --codex, -X, --vibe, -B, --kimi, -K, --verify, -Y, --help, -h\n' "$arg" >&2
        exit 1
        ;;
    esac
done

if [ -z "$targets" ] && [ "$do_verify" -eq 0 ]; then
    targets="claude"
fi

installed=""
for target in $targets; do
    case " $installed " in
    *" $target "*) continue ;;
    esac
    installed="$installed $target"
    "install_$target"
done

if [ "$do_verify" -eq 1 ]; then
    [ -z "$installed" ] || printf '\n'
    verify
fi
