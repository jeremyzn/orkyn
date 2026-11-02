#!/usr/bin/env bash
# ORKYN — change ou affiche le mode par défaut.
# Usage : set-mode.sh   (affiche le mode courant)  |  set-mode.sh <eco|balanced|deep> [project]  |  set-mode.sh clear
set -eu
mode="${1:-}"; scope="${2:-user}"
proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")}"

read_mode() { [ -f "$1" ] && sed -n 's/.*"mode"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$1" 2>/dev/null | head -n1 || true; }

if [ -z "$mode" ]; then
  cur=""; src="défaut"
  m=$(read_mode "$proj/.claude/orkyn.json"); if [ -n "$m" ]; then cur="$m"; src="projet (.claude/orkyn.json)"; fi
  if [ -z "$cur" ]; then m=$(read_mode "$HOME/.claude/orkyn/config.json"); if [ -n "$m" ]; then cur="$m"; src="utilisateur (~/.claude/orkyn/config.json)"; fi; fi
  case "$cur" in eco|balanced|deep) ;; *) [ -n "$cur" ] && src="valeur invalide '$cur' ignorée"; cur="balanced";; esac
  echo "Mode courant : $cur — source : $src"
  exit 0
fi

if [ "$mode" = "clear" ]; then
  f="$proj/.claude/orkyn.json"
  if [ -f "$f" ]; then rm "$f"; echo "Mode projet supprimé ($f). Le mode utilisateur s'applique."; else echo "Aucun mode projet défini."; fi
  exit 0
fi

case "$mode" in eco|balanced|deep) ;; *) echo "Mode invalide : '$mode'. Valeurs : eco, balanced, deep, clear." >&2; exit 1;; esac

case "$scope" in
  user)    f="$HOME/.claude/orkyn/config.json" ;;
  project) f="$proj/.claude/orkyn.json" ;;
  *) echo "Portée invalide : '$scope'. Valeurs : (vide) ou project." >&2; exit 1 ;;
esac
mkdir -p "$(dirname "$f")"
printf '{\n  "mode": "%s"\n}\n' "$mode" > "$f"
echo "Mode ORKYN = $mode (portée : $scope, fichier : $f)"
