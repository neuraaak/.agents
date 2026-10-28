#!/usr/bin/env bash
# Tests de install-config.sh : rendu des templates, garde-fous {{INCLUDE:}},
# detection de --verify. Tout se joue dans un depot factice et un HOME
# temporaire : ni le depot reel ni le HOME de l'utilisateur ne sont touches.
#
# Les rules reelles ne servent pas de reference : elles changent a chaque
# commit, et un golden bati dessus echouerait a chaque edition legitime. Les
# fixtures ci-dessous testent la MECANIQUE (substitution, inline, trim,
# prefixe/suffixe), qui elle ne bouge pas.
#
# Usage : bash tests/test-install-config.sh
set -uo pipefail

# Sous MSYS, `ln -s` copie au lieu de lier et install_claude echoue par
# securite (c'est voulu) : la demande d'un vrai symlink evite ce faux echec.
export MSYS=winsymlinks:nativestrict

failures=0
# pwd -P des la creation : sous MSYS, mktemp rend /tmp/... quand le script
# installe resout C:/Users/.../Temp/... -- sans canonisation, la
# normalisation des chemins ci-dessous ne reconnaitrait pas le depot.
tmp=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$tmp"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }
assert() { # assert <libelle> <condition-deja-evaluee: 0 = ok>
    [ "$2" -eq 0 ] && pass "$1" || fail "$1"
}

# --- Depot factice -----------------------------------------------------------

repo=$tmp/repo
home=$tmp/home
mkdir -p "$repo/rules/common" "$repo/templates" "$home"
cp "$(dirname "$0")/../install-config.sh" "$repo/install-config.sh"

# Lignes vides en tete et en queue : trim_file doit les retirer.
printf '\n## Rule A\n\nLigne A.\n\n' > "$repo/rules/common/a.md"
printf '## Rule B\nLigne B.\n' > "$repo/rules/common/b.md"
printf 'carte du depot\n' > "$repo/rules/index.md"
printf 'hors du dossier rules\n' > "$repo/outside.md"

printf 'claude: {{AGENTS_DIR}}/rules/common\n' > "$repo/templates/CLAUDE.template.md"
cat > "$repo/templates/AGENTS.template.md" <<'EOF'
<!-- inline depuis {{AGENTS_DIR}}/rules/ -->
{{INCLUDE:common/a.md}}
prefixe: {{INCLUDE:common/b.md}} suffixe
EOF
cp "$repo/templates/AGENTS.template.md" "$repo/templates/GEMINI.template.md"
cp "$repo/templates/AGENTS.template.md" "$tmp/AGENTS.template.md.orig"

cat > "$tmp/golden-agents" <<'EOF'
<!-- inline depuis <REPO>/rules/ -->
## Rule A

Ligne A.
prefixe: ## Rule B
Ligne B. suffixe
EOF

# Le chemin substitue peut etre /c/... ou C:/... selon la plateforme : les deux
# formes sont acceptees ici, c'est le rendu qui est teste, pas leur alignement.
repo_alt=$repo
command -v cygpath >/dev/null 2>&1 && repo_alt=$(cygpath -m "$repo")
norm() { sed -e "s|$repo_alt|<REPO>|g" -e "s|$repo|<REPO>|g" "$1"; }

run() { HOME=$home KIMI_CODE_HOME=$home/.kimi-code bash "$repo/install-config.sh" "$@"; }

# Sans droit de creer un symlink (Windows sans Developer Mode), le volet Claude
# est ignore plutot que rapporte en echec.
link_ok=1
ln -s "$repo/rules/common" "$tmp/probe" 2>/dev/null
[ -L "$tmp/probe" ] || link_ok=0
rm -rf "$tmp/probe"
[ "$link_ok" -eq 1 ] || printf 'SKIP volet Claude (symlink indisponible sur cette plateforme)\n'

# --- 1. Installation ---------------------------------------------------------

if [ "$link_ok" -eq 1 ]; then
    run --claude --gemini --codex --vibe --kimi > "$tmp/out" 2>&1
else
    run --gemini --codex --vibe --kimi > "$tmp/out" 2>&1
fi
assert "installation sans erreur" $?

# --- 2. Rendu des templates --------------------------------------------------

diff -u "$tmp/golden-agents" <(norm "$home/.codex/AGENTS.md") > "$tmp/d" 2>&1
assert "AGENTS.md conforme au golden (substitution, inline, trim, suffixe)" $?
[ -s "$tmp/d" ] && cat "$tmp/d"

diff -q <(norm "$home/.gemini/GEMINI.md") "$tmp/golden-agents" >/dev/null 2>&1
assert "GEMINI.md rendu par le meme chemin de code" $?

cmp -s "$home/.codex/AGENTS.md" "$home/.vibe/AGENTS.md" &&
    cmp -s "$home/.codex/AGENTS.md" "$home/.kimi-code/AGENTS.md"
assert "vibe et kimi identiques a codex (meme template)" $?

! grep -rl '{{' "$home" >/dev/null 2>&1
assert "aucun placeholder non substitue dans les fichiers generes" $?

if [ "$link_ok" -eq 1 ]; then
    [ "$(norm "$home/.claude/CLAUDE.md")" = "claude: <REPO>/rules/common" ]
    assert "CLAUDE.md substitue sans inline" $?
    [ -L "$home/.claude/rules" ] &&
        [ "$(realpath "$home/.claude/rules")" = "$(realpath "$repo/rules/common")" ]
    assert "lien des rules communes cree vers common/" $?
fi

# --- 3. --verify sur une installation saine ----------------------------------

# TMPDIR dedie : mktemp y cree le dossier de rendu, le trap doit l'avoir
# efface a la sortie (regression du trap evalue hors portee de verify()).
mkdir -p "$tmp/tmpdir"
TMPDIR=$tmp/tmpdir run --verify > "$tmp/out" 2>&1
assert "--verify sort 0 juste apres l'installation" $?
[ -z "$(ls -A "$tmp/tmpdir")" ]
assert "--verify ne laisse aucun dossier temporaire" $?

# --- 4. --verify detecte une derive ------------------------------------------

printf 'ligne ajoutee a la main\n' >> "$home/.codex/AGENTS.md"
out=$(run --verify 2>&1)
[ $? -ne 0 ]
assert "--verify signale un fichier edite a la main" $?
case $out in *"ATTENTION codex"*) pass "la derive nomme le bon provider" ;;
    *) fail "la derive nomme le bon provider" ;;
esac
run --codex >/dev/null 2>&1

# --- 5. Fuite de fichiers conditionnels par le lien --------------------------

if [ "$link_ok" -eq 1 ]; then
    # La decouverte native est recursive : un index.md sous common/ serait
    # charge comme une rule.
    printf 'carte\n' > "$repo/rules/common/index.md"
    out=$(run --verify 2>&1)
    case $out in *"conditionnels exposes"*) pass "--verify detecte index.md expose par le lien" ;;
        *) fail "--verify detecte index.md expose par le lien" ;;
    esac
    rm -f "$repo/rules/common/index.md"
fi

# --- 6. Garde-fous {{INCLUDE:}} ----------------------------------------------

printf '{{INCLUDE:../outside.md}}\n' > "$repo/templates/AGENTS.template.md"
out=$(run --codex 2>&1)
[ $? -ne 0 ]
assert "inclusion hors de rules/ refusee" $?
case $out in *"sort du dossier rules/"*) pass "le refus explique la traversee" ;;
    *) fail "le refus explique la traversee" ;;
esac

printf '{{INCLUDE:common/absente.md}}\n' > "$repo/templates/AGENTS.template.md"
out=$(run --codex 2>&1)
[ $? -ne 0 ]
assert "rule introuvable refusee" $?
case $out in *"Rule introuvable"*) pass "le refus nomme la rule manquante" ;;
    *) fail "le refus nomme la rule manquante" ;;
esac
cp "$tmp/AGENTS.template.md.orig" "$repo/templates/AGENTS.template.md"

# --- 7. Arguments ------------------------------------------------------------

run --inconnu >/dev/null 2>&1
[ $? -eq 1 ]
assert "argument inconnu refuse avec le code 1" $?

# --- Bilan -------------------------------------------------------------------

printf '\n'
if [ "$failures" -eq 0 ]; then
    printf 'Tests : tout passe.\n'
else
    printf 'Tests : %s echec(s).\n' "$failures"
fi
exit $((failures > 0))
