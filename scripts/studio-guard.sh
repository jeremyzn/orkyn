#!/usr/bin/env bash
# ORKYN : outils mcp__vibestarter_mcp__* (Roblox passe uniquement par Vibe Starter), appelé par guard.sh pour l'agent orkyn-roblox.
# Usage : studio-guard.sh   (entrée JSON du hook sur stdin)
#  - tout outil : refus (exit 2) si une valeur string de tool_input contient un motif Luau dangereux
#    (DataStores, publication, achats, HttpService, loadstring, require(<nombre>)...) ;
#  - nom contenant upload, gamepass, devproduct, publish, purchase, generate_, edit_icon, split_3d,
#    multiview : décision « ask » (confirmation utilisateur) ; autres outils : exit 0 ;
#  - entrée illisible ou parseur absent : exit 2 (fail-closed).
# FILET DE SÉCURITÉ, PAS UNE GARANTIE : l'analyse est textuelle, l'obscurcissement la contourne
# (concaténation de chaînes, _G, [""], encodage...). Non garanti pour les coéquipiers d'Agent Team.

fail() {
  echo "ORKYN : outil Vibe Starter refusé (entrée du hook illisible ou parseur absent)." >&2
  exit 2
}

input=$(cat)
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
name=$(json_str "$input" tool_name) || fail
text=$(json_strings "$input" tool_input) || fail
[ -n "$name" ] || fail

pat='SavePlaceAsync|PublishAsync|DataStoreService|GetDataStore|GetOrderedDataStore|MemoryStoreService|BanAsync|:[[:space:]]*Kick[[:space:]]*\(|PromptPurchase|PromptProductPurchase|PromptGamePassPurchase|HttpService|RequestAsync|PostAsync|GetAsync|loadstring|setfenv|getfenv|require[[:space:]]*\([[:space:]]*[0-9]|TeleportService|MessagingService'

hit=$(printf '%s' "$text" | grep -oiE "$pat" | head -n1)
if [ -n "$hit" ]; then
  echo "ORKYN : outil Vibe Starter refusé (« $hit ») — action réservée à l'utilisateur." >&2
  exit 2
fi
short=$(printf '%s' "${name##*__}" | tr '[:upper:]' '[:lower:]')
case "$short" in
  *upload*|*gamepass*|*devproduct*|*publish*|*purchase*|*generate_*|*edit_icon*|*split_3d*|*multiview*)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"ORKYN : %s publie, monétise ou consomme des crédits Vibe Starter — confirmation de l’utilisateur requise."}}\n' "$short"
    exit 0 ;;
esac
exit 0
