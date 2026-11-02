#!/usr/bin/env bash
# ORKYN : contexte injecté au lancement de /orkyn.
# Lecture seule. Doit toujours se terminer avec le code 0 (un échec annulerait l'invocation du skill).
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$root/scripts/lib.sh"
proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")}"
at_home=0; [ "$(cd "$proj" 2>/dev/null && pwd -P)" = "$(cd "$HOME" 2>/dev/null && pwd -P)" ] && at_home=1
cfg_user="$HOME/.claude/orkyn/config.json"
cfg_proj="$proj/.claude/orkyn.json"

read_mode() { [ -f "$1" ] && sed -n 's/.*"mode"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$1" 2>/dev/null | head -n1; }

mode=""; src="défaut"
m=$(read_mode "$cfg_proj"); if [ -n "$m" ]; then mode="$m"; src="projet (.claude/orkyn.json)"; fi
if [ -z "$mode" ]; then m=$(read_mode "$cfg_user"); if [ -n "$m" ]; then mode="$m"; src="utilisateur (~/.claude/orkyn/config.json)"; fi; fi
case "$mode" in eco|balanced|deep) ;; *) [ -n "$mode" ] && src="valeur invalide '$mode' ignorée"; mode="balanced";; esac
echo "- Mode : $mode — source : $src"

teams="${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}"
if [ "$teams" = "1" ]; then echo "- Agent Teams : ACTIVÉES (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)"
else echo "- Agent Teams : désactivées — utiliser les sous-agents"; fi

agents=""
files=("$root"/agents/orkyn-*.md)
[ "$at_home" = 1 ] || files+=("$proj"/.claude/agents/orkyn-*.md)
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  n=$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -n1)
  mdl=$(sed -n 's/^model:[[:space:]]*//p' "$f" | head -n1)
  if ! [[ "$n" =~ ^[a-z0-9-]+$ ]]; then agents="$agents (nom invalide ignoré)"; continue; fi
  if [ -z "$mdl" ]; then mdl=inherit; elif ! [[ "$mdl" =~ ^[a-z0-9-]+$ ]]; then mdl="modèle invalide ignoré"; fi
  agents="$agents orkyn:$n($mdl)"
done
echo "- Agents (subagent_type) :${agents:- aucun agent orkyn-* trouvé}"

mem=""
dirs=("$HOME"/.claude/agent-memory/orkyn-*)
[ "$at_home" = 1 ] || dirs+=("$proj"/.claude/agent-memory/orkyn-* "$proj"/.claude/agent-memory-local/orkyn-*)
for d in "${dirs[@]}"; do
  [ -d "$d" ] || continue
  l=0; [ -f "$d/MEMORY.md" ] && l=$(wc -l < "$d/MEMORY.md" | tr -d ' ')
  case "$d" in "$HOME"/.claude/agent-memory/*) s=user;; */agent-memory-local/*) s=local;; *) s=project;; esac
  mem="$mem $(basename "$d")[$s:${l}l]"
done
echo "- Mémoire agents :${mem:- vide}"
if [ -d "$proj/.claude/agent-memory-local" ] && [ ! -f "$proj/.claude/agent-memory-local/.gitignore" ]; then
  echo "- ⚠ .claude/agent-memory-local/ n'a pas de .gitignore : crée-le avec le contenu « * » avant toute autre action (mémoire locale à ne pas commiter)"
fi

echo "- Projet : $proj"
if git -C "$proj" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  br=$(git -C "$proj" branch --show-current 2>/dev/null)
  ch=$(git -C "$proj" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "- Git : branche ${br:-détachée}, $ch fichier(s) modifié(s)"
else
  echo "- Git : pas un dépôt git"
fi

stack=""
for m in package.json tsconfig.json next.config.js next.config.mjs next.config.ts pnpm-lock.yaml yarn.lock bun.lockb bun.lock \
         pyproject.toml requirements.txt Cargo.toml go.mod Gemfile composer.json pom.xml build.gradle Package.swift \
         Dockerfile docker-compose.yml Makefile deno.json \
         default.project.json rokit.toml aftman.toml wally.toml pesde.toml selene.toml stylua.toml; do
  [ -e "$proj/$m" ] && stack="$stack $m"
done
for m in "$proj"/*.xcodeproj "$proj"/*.project.json "$proj"/*.rbxl "$proj"/*.rbxlx; do
  [ -e "$m" ] && [ "$(basename "$m")" != "default.project.json" ] && stack="$stack $(basename "$m")"
done
echo "- Marqueurs de stack :${stack:- aucun}"
if [ -n "${VIBESTARTER_AGENT_TYPE:-}" ] || [ -n "${VIBESTARTER_PROJECT_PATH:-}" ]; then
  echo "- Vibe Starter : session détectée, MCP vibestarter_mcp disponible, utiliser orkyn:orkyn-roblox"
else
  echo "- Vibe Starter : non détecté"
fi
if is_windows; then os=Windows; elif [ "$(uname -s)" = Darwin ]; then os=macOS; else os=Linux; fi
echo "- Système : $os"

mail_provider="${CLAUDE_PLUGIN_OPTION_MAIL_PROVIDER:-${ORKYN_MAIL_PROVIDER:-}}"
if [ -z "$mail_provider" ]; then
  for f in "$proj/.claude/settings.local.json" "$proj/.claude/settings.json" "$HOME/.claude/settings.json"; do
    [ -f "$f" ] || continue
    mail_provider=$(json_str "$(cat "$f" 2>/dev/null)" pluginConfigs orkyn@orkyn options mail_provider 2>/dev/null)
    [ -n "$mail_provider" ] && break
  done
fi
case "$mail_provider" in
  "") echo "- Mails : configuration non détectable depuis ce contexte (le serveur mail le dira au premier /orkyn inbox)" ;;
  none) echo "- Mails : non configurés (fournisseur : none)" ;;
  *) echo "- Mails : fournisseur $mail_provider configuré (lecture seule)" ;;
esac
[ -f "$proj/CLAUDE.md" ] || [ -f "$proj/.claude/CLAUDE.md" ] && echo "- CLAUDE.md projet présent"
exit 0
