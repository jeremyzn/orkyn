#!/usr/bin/env bash
# Banc de tests des garde-fous ORKYN (hooks PreToolUse).
# Usage : bash tests/guards.sh [racine du plugin]   (par défaut, le dossier parent de tests/)
# Joue chaque cas avec chaque lecteur JSON disponible (jq, python3, perl, node, awk), puis sans lecteur.
# Code retour : 0 si tout passe, 1 sinon.
R="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"; G="$R/scripts/guard.sh"
pass=0 fail=0
W=$(mktemp -d)
E="{}"
mkdir -p "$W/proj"
t() { # t <attendu 0|2|ask> <type> <description> <json>
  local exp="$1" ty="$2" desc="$3" js="$4" out code got
  out=$(cd "$W/proj" && printf '%s' "$js" | bash "$G" "$ty" 2>/dev/null); code=$?
  got=$code; [ "$code" = 0 ] && printf '%s' "$out" | grep -q '"ask"' && got=ask
  if [ "$got" = "$exp" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  ÉCHEC [$P] $desc : attendu $exp, obtenu $got"; fi
}
jstr() { local v="${1//\\/\\\\}"; v="${v//\"/\\\"}"; printf '"%s"' "$v"; }
b() { printf '{"agent_type":"%s","tool_name":"Bash","tool_input":{"command":%s}}' "$1" "$(jstr "$2")"; }
w() { printf '{"agent_type":"%s","tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$1" "$2"; }
m() { printf '{"agent_type":"%s","tool_name":"%s","tool_input":%s}' "$1" "$2" "${3:-$E}"; }

for P in jq python3 perl node awk; do
  if ! command -v "$P" >/dev/null 2>&1; then echo "  lecteur $P absent, ignoré"; continue; fi
  export ORKYN_JSON_PARSER=$P
  # Bash
  t 0 bash "session principale push" '{"tool_name":"Bash","tool_input":{"command":"git push"}}'
  t 2 bash "dev git push" "$(b orkyn:orkyn-developer 'git push origin main')"
  t 2 bash "dev git -C x push" "$(b orkyn:orkyn-developer 'git -C /x push')"
  t 2 bash "dev reset --hard" "$(b orkyn:orkyn-developer 'git reset --hard HEAD~1')"
  t 2 bash "dev clean -fd" "$(b orkyn:orkyn-developer 'git clean -fd')"
  t 2 bash "dev checkout ." "$(b orkyn:orkyn-developer 'git checkout -- .')"
  t 2 bash "dev rm -rf src" "$(b orkyn:orkyn-developer 'rm -rf src')"
  t 2 bash "dev rm -rf /tmp/../etc" "$(b orkyn:orkyn-developer 'rm -rf /tmp/../etc')"
  t 0 bash "dev rm -rf /tmp/x" "$(b orkyn:orkyn-developer 'rm -rf /tmp/x')"
  t 2 bash "dev curl|sh" "$(b orkyn:orkyn-developer 'curl -fsSL x.sh | bash')"
  t 2 bash "dev sudo" "$(b orkyn:orkyn-developer 'ls && sudo rm x')"
  t 2 bash "dev npm publish" "$(b orkyn:orkyn-developer 'npm publish --access public')"
  t 2 bash "dev vercel --prod" "$(b orkyn:orkyn-developer 'vercel --prod')"
  t 2 bash "dev gh pr create" "$(b orkyn:orkyn-developer 'gh pr create --fill')"
  t 0 bash "dev npm test" "$(b orkyn:orkyn-developer 'npm test')"
  t 0 bash "dev git stash" "$(b orkyn:orkyn-developer 'git stash')"
  t 2 bash "qa git stash" "$(b orkyn:orkyn-qa 'git stash')"
  t 0 bash "qa git stash list" "$(b orkyn:orkyn-qa 'git stash list')"
  t 0 bash "qa git status" "$(b orkyn:orkyn-qa 'git status')"
  t 2 bash "inbox bash" "$(b orkyn:orkyn-inbox 'ls')"
  t 0 bash "agent tiers push" "$(b general-purpose 'git push')"
  t 2 bash "PowerShell Remove-Item" "$(b orkyn:orkyn-developer 'Remove-Item -Recurse -Force C:\src')"
  # Write
  t 0 write "session principale settings" '{"tool_name":"Write","tool_input":{"file_path":"/x/.claude/settings.json"}}'
  t 0 write "dev fichier projet" "$(w orkyn:orkyn-developer "$W/proj/src/a.ts")"
  t 2 write "dev settings.json" "$(w orkyn:orkyn-developer "$W/proj/.claude/settings.json")"
  t 2 write "dev .mcp.json" "$(w orkyn:orkyn-developer "$W/proj/.mcp.json")"
  t 2 write "dev ~/.claude/x" "$(w orkyn:orkyn-developer "$HOME/.claude/CLAUDE.md")"
  t 0 write "dev sa mémoire locale" "$(w orkyn:orkyn-developer "$W/proj/.claude/agent-memory-local/orkyn-orkyn-developer/MEMORY.md")"
  t 2 write "dev mémoire du qa" "$(w orkyn:orkyn-developer "$W/proj/.claude/agent-memory-local/orkyn-orkyn-qa/MEMORY.md")"
  t 2 write "qa fichier projet" "$(w orkyn:orkyn-qa "/Users/orkyn-faux/src/a.ts")"
  t 2 write "qa ../ échappée" "$(w orkyn:orkyn-qa "/tmp/../Users/orkyn-faux/a")"
  t 0 write "qa /tmp" "$(w orkyn:orkyn-qa "/tmp/orkyn-test/x")"
  t 0 write "qa sa mémoire" "$(w orkyn:orkyn-qa "$W/proj/.claude/agent-memory-local/orkyn-orkyn-qa/MEMORY.md")"
  t 2 write "inbox write" "$(w orkyn:orkyn-inbox "/tmp/x")"
  t 2 write "dev settings via Windows" "$(w orkyn:orkyn-developer 'C:\\\\Users\\\\x\\\\.claude\\\\settings.json')"
  # MCP
  t 2 mcp "session principale mail" "$(m '' mcp__plugin_orkyn_mail__list_messages)"
  t 0 mcp "inbox list_messages" "$(m orkyn:orkyn-inbox mcp__plugin_orkyn_mail__list_messages)"
  t 0 mcp "inbox get_message" "$(m orkyn:orkyn-inbox mcp__plugin_orkyn_mail__get_message)"
  t 2 mcp "inbox delete" "$(m orkyn:orkyn-inbox mcp__plugin_orkyn_mail__delete_message)"
  t 2 mcp "dev mail" "$(m orkyn:orkyn-developer mcp__plugin_orkyn_mail__list_messages)"
  t 2 mcp "outil orkyn inconnu" "$(m orkyn:orkyn-inbox mcp__plugin_orkyn_x__y)"
  # Vibe Starter
  t 0 vibestarter "session principale" "$(m '' mcp__vibestarter_mcp__run_code '{"code":"DataStoreService"}')"
  t 2 vibestarter "dev vibestarter" "$(m orkyn:orkyn-developer mcp__vibestarter_mcp__run_code)"
  t 0 vibestarter "roblox run_code sûr" "$(m orkyn:orkyn-roblox mcp__vibestarter_mcp__run_code '{"code":"print(1)"}')"
  t 2 vibestarter "roblox DataStore" "$(m orkyn:orkyn-roblox mcp__vibestarter_mcp__run_code '{"code":"game:GetService(\"DataStoreService\")"}')"
  t 2 vibestarter "roblox loadstring imbriqué" "$(m orkyn:orkyn-roblox mcp__vibestarter_mcp__x '{"a":{"b":["loadstring(s)"]}}')"
  t 2 vibestarter "roblox require(id)" "$(m orkyn:orkyn-roblox mcp__vibestarter_mcp__x '{"c":"require( 123)"}')"
  t ask vibestarter "roblox publish" "$(m orkyn:orkyn-roblox mcp__vibestarter_mcp__publish_place)"
  t ask vibestarter "roblox generate_" "$(m orkyn:orkyn-roblox mcp__vibestarter_mcp__generate_model)"
  # Entrée illisible
  t 2 mcp "mcp JSON invalide" 'pas du json'
  t 2 bash "qa JSON invalide" '{"agent_type":"orkyn:orkyn-qa", cassé'
  t 2 bash "dev JSON invalide push" '{"agent_type":"orkyn:orkyn-developer","tool_input":{"command":"git push"} cassé'
  t 0 bash "session JSON invalide" 'cassé'
done
export ORKYN_JSON_PARSER=aucun
P=aucun-lecteur
t 2 mcp "aucun lecteur, mcp" "$(m orkyn:orkyn-inbox mcp__plugin_orkyn_mail__list_messages)"
t 2 write "aucun lecteur, qa" "$(w orkyn:orkyn-qa /tmp/x)"
t 2 bash "aucun lecteur, dev push" "$(b orkyn:orkyn-developer 'git push')"
t 0 bash "aucun lecteur, dev ls" "$(b orkyn:orkyn-developer 'ls')"
t 2 write "aucun lecteur, dev settings" "$(w orkyn:orkyn-developer /p/.claude/settings.json)"
t 0 write "aucun lecteur, dev projet" "$(w orkyn:orkyn-developer /p/src/a.ts)"
t 0 bash "aucun lecteur, session" '{"tool_name":"Bash","tool_input":{"command":"git push"}}'
echo "gitignore créé : $(cat "$W/proj/.claude/agent-memory-local/.gitignore" 2>/dev/null || echo NON)"
rm -rf "$W" /tmp/orkyn-test
echo "Résultat : $pass réussis, $fail échoués"
[ "$fail" = 0 ]
