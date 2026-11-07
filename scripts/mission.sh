#!/usr/bin/env bash
# ORKYN : verrou « pas de fin de mission sans vérification » (hooks UserPromptSubmit, PostToolUse, Stop).
# Usage : mission.sh <start|edit|bash|stop>   (entrée JSON du hook sur stdin)
#  - start : un message qui commence par /orkyn ouvre une mission pour cette session.
#  - edit  : une modification d'un fichier de code pendant la mission est comptée.
#  - bash  : une commande de test, lint, typecheck, analyse ou build pendant la mission est comptée.
#  - stop  : si du code a changé depuis la dernière vérification, bloque la fin UNE fois par modification,
#            avec la consigne de vérifier ou d'expliquer dans « Non vérifié ».
# Hors mission ORKYN : sortie immédiate, rien n'est bloqué. Zéro token tant qu'il ne bloque pas.
# Termine toujours avec le code 0 (un hook qui échoue ne doit jamais gêner la session).
set -u
type="${1:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/orkyn-data}"
dir="$data/missions"

# Chemin rapide : aucune mission ouverte nulle part, rien à faire (sauf start).
if [ "$type" != start ]; then
  [ -d "$dir" ] || exit 0
  [ -n "$(ls -A "$dir" 2>/dev/null)" ] || exit 0
fi

input=$(cat)
. "$here/lib.sh"
sid=$(json_str "$input" session_id 2>/dev/null) || exit 0
case "$sid" in ''|*/*|*..*) exit 0 ;; esac
f="$dir/$sid"

load() { edits=0 checks=0 blocked=0; [ -f "$f" ] && . "$f" 2>/dev/null; }
save() { printf 'edits=%s\nchecks=%s\nblocked=%s\n' "$edits" "$checks" "$blocked" > "$f" 2>/dev/null; }

case "$type" in
  start)
    prompt=$(json_str "$input" prompt 2>/dev/null) || exit 0
    if printf '%s' "$prompt" | head -n1 | grep -qE '^[[:space:]]*/orkyn(:orkyn)?([[:space:]]|$)'; then
      mkdir -p "$dir" 2>/dev/null || exit 0
      find "$dir" -type f -mtime +7 -delete 2>/dev/null
      edits=0 checks=0 blocked=0; save
    elif [ -f "$f" ] && ! printf '%s' "$prompt" | grep -qiE '^[[:space:]]*(ok|non)([[:space:]]|$)'; then
      rm -f "$f"   # autre demande que /orkyn ou une réponse à « À valider » : la mission est finie
    fi ;;
  edit)
    [ -f "$f" ] || exit 0
    path=$(json_str "$input" tool_input file_path 2>/dev/null)
    [ -n "$path" ] || path=$(json_str "$input" tool_input notebook_path 2>/dev/null)
    case "$path" in
      *.md|*.mdx|*.txt|*.rst|*/.claude/*|*/agent-memory*|"$data"/*|'') exit 0 ;;
    esac
    load; edits=$((edits + 1)); save ;;
  bash)
    [ -f "$f" ] || exit 0
    cmd=$(json_str "$input" tool_input command 2>/dev/null) || exit 0
    if printf '%s' "$cmd" | grep -qiE '(^|[^a-z])(test|tests|pytest|vitest|jest|mocha|rspec|phpunit|tsc|typecheck|type-check|lint|eslint|ruff|mypy|clippy|vet|analyze|golangci-lint|build|assembleDebug|xcodebuild|guards\.sh|check)([^a-z]|$)'; then
      load; checks=$edits; save
    fi ;;
  stop)
    [ -f "$f" ] || exit 0
    load
    if [ "$edits" -gt "$checks" ] && [ "$blocked" != "$edits" ]; then
      blocked=$edits; save
      printf '%s\n' '{"decision":"block","reason":"ORKYN : du code a été modifié depuis la dernière vérification. Avant de rendre le rapport, lance la vérification ciblée (voir « Commandes du projet » dans le contexte de la mission). Si aucune vérification n’est possible, dis le clairement dans « Non vérifié » avec la raison, puis termine."}'
    fi ;;
esac
exit 0
