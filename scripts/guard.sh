#!/usr/bin/env bash
# ORKYN : point d'entrée unique des hooks PreToolUse du plugin (hooks/hooks.json).
# Usage : guard.sh <write|read|bash|mcp|vibestarter>   (entrée JSON du hook sur stdin)
# Les hooks de plugin s'appliquent à toutes les sessions et à tous les sous-agents : le rôle de l'appelant
# vient du champ agent_type (« orkyn:orkyn-<rôle> » pour un agent du plugin, absent pour la session principale).
#  - architect, researcher, qa, reviewer, security : lecture seule (memory-guard.sh readonly, bash-guard.sh readonly).
#  - developer, mobile, roblox : memory-guard.sh write, bash-guard.sh write.
#  - tout agent ORKYN, sur Read et Grep : secret-guard.sh (aucun fichier de secrets lu).
#  - inbox : refuse Write, Edit et Bash. Seuls ses outils mail de lecture passent.
#  - mcp__plugin_orkyn_mail__* : refusé hors agent inbox, liste blanche list_mailboxes, list_messages, get_message.
#  - tout autre outil mcp__plugin_orkyn_* : refusé.
#  - mcp__vibestarter_mcp__* (Roblox passe uniquement par Vibe Starter) : libres hors agents ORKYN.
#    parmi eux seul orkyn-roblox y a accès, via studio-guard.sh.
#  - toute autre session ou agent, sur Write, Edit et Bash : exit 0 (usage normal de Claude Code inchangé).
#  - entrée illisible (aucun lecteur JSON, voir lib.sh) : refus (exit 2) pour mcp, vibestarter et les agents ORKYN
#    lecture seule. Pour developer et roblox, contrôle grossier du texte brut (bash-guard.sh raw, écriture :
#    config ou .claude/ hors mémoire de l'agent). Sinon exit 0 (session principale et agents tiers jamais gênés).
# FILET DE SÉCURITÉ, PAS UNE GARANTIE : non garanti pour les coéquipiers d'Agent Team.
type="${1:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input=$(cat)

deny() { echo "ORKYN : $1" >&2; exit 2; }

. "$here/lib.sh"
agent="" tool="" ok=1
agent=$(json_str "$input" agent_type) || ok=0
tool=$(json_str "$input" tool_name) || ok=0

if [ "$ok" = 0 ]; then
  case "$type" in mcp) deny "outil refusé (entrée du hook illisible ou parseur absent)." ;; esac
  if [ "$type" = vibestarter ] && printf '%s' "$input" | grep -q 'orkyn:orkyn-'; then
    deny "outil refusé (entrée du hook illisible) pour un agent ORKYN."
  fi
  if printf '%s' "$input" | grep -qE 'orkyn:orkyn-(architect|researcher|qa|reviewer|security|inbox)'; then
    deny "action refusée (entrée du hook illisible) pour un agent ORKYN en lecture seule."
  fi
  if printf '%s' "$input" | grep -qE 'orkyn:orkyn-(developer|mobile|roblox)'; then
    case "$type" in
      bash) printf '%s' "$input" | bash "$here/bash-guard.sh" raw; exit $? ;;
      write)
        rest=$(printf '%s' "$input" | sed -E 's#\\/#/#g; s#"transcript_path" *: *"[^"]*"##; s#\.claude/agent-memory(-local)?/(orkyn-)?orkyn-(developer|mobile|roblox)/##g')
        if printf '%s' "$rest" | grep -qE 'settings(\.local)?\.json|\.mcp\.json|\.claude\.json|\.claude[/\\]'; then
          deny "écriture refusée (entrée du hook illisible) : fichier de configuration ou .claude/ hors mémoire de l'agent."
        fi ;;
    esac
  fi
  exit 0
fi

name="${agent#orkyn:}"
case "$name" in
  orkyn-architect|orkyn-researcher|orkyn-qa|orkyn-reviewer|orkyn-security) role=ro ;;
  orkyn-developer|orkyn-mobile|orkyn-roblox) role=rw ;;
  orkyn-inbox) role=inbox ;;
  *) role=none ;;
esac

relay() { printf '%s' "$input" | bash "$here/$1" "${@:2}"; exit $?; }

case "$type" in
  read)
    [ "$role" = none ] && exit 0
    relay secret-guard.sh ;;
  write|bash)
    script=memory-guard.sh; [ "$type" = bash ] && script=bash-guard.sh
    case "$role" in
      ro) if [ "$type" = bash ]; then relay "$script" readonly; else relay "$script" readonly "$name"; fi ;;
      rw) if [ "$type" = bash ]; then relay "$script" write; else relay "$script" write "$name"; fi ;;
      inbox) deny "l'agent orkyn-inbox n'a droit qu'à ses outils de lecture de mails." ;;
    esac
    exit 0 ;;
  mcp)
    [ -n "$tool" ] || deny "outil refusé (nom d'outil absent)."
    case "$tool" in
      mcp__plugin_orkyn_mail__*)
        [ "$name" = orkyn-inbox ] || deny "outil mail refusé : réservé à l'agent orkyn-inbox (appelant : ${agent:-session principale})."
        case "${tool##*__}" in
          list_mailboxes|list_messages|get_message) exit 0 ;;
        esac
        deny "outil mail « ${tool##*__} » hors liste blanche (lecture seule : list_mailboxes, list_messages, get_message)." ;;
      mcp__plugin_orkyn_*) deny "outil MCP ORKYN inconnu refusé." ;;
    esac
    exit 0 ;;
  vibestarter)
    # Outils de Vibe Starter : ORKYN ne gêne jamais la session principale ni les agents tiers
    # (c'est le fonctionnement normal de Vibe Starter). Seuls les agents ORKYN sont encadrés.
    case "$role" in
      none) exit 0 ;;
      rw) [ "$name" = orkyn-roblox ] && relay studio-guard.sh ;;
    esac
    deny "outil Vibe Starter refusé : parmi les agents ORKYN, seul orkyn-roblox peut l'utiliser (appelant : $agent)." ;;
esac
exit 0
