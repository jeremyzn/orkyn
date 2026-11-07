#!/usr/bin/env bash
# Banc de tests du verrou de fin de mission (scripts/mission.sh) et de la carte du projet.
# Usage : bash tests/mission.sh [racine du plugin]. Code retour : 0 si tout passe, 1 sinon.
R="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"; M="$R/scripts/mission.sh"
pass=0 fail=0
export CLAUDE_PLUGIN_DATA; CLAUDE_PLUGIN_DATA=$(mktemp -d)
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  ÉCHEC $3 : attendu « $2 », obtenu « $1 »"; fi; }
run() { printf '%s' "$2" | bash "$M" "$1"; }
blocks() { run stop "{\"session_id\":\"$1\",\"stop_hook_active\":false}" | grep -c '"block"'; }
p() { printf '{"session_id":"%s","prompt":"%s"}' "$1" "$2"; }
e() { printf '{"session_id":"%s","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1" "$2"; }
b() { printf '{"session_id":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" "$2"; }

ok "$(blocks s0)" 0 "aucune mission : jamais bloqué"
run start "$(p s1 'corrige le bug')"; run edit "$(e s1 /p/src/a.ts)"
ok "$(blocks s1)" 0 "session sans /orkyn : jamais bloquée"

run start "$(p s2 '/orkyn ajoute un bouton')"
ok "$(blocks s2)" 0 "mission sans modification : pas de blocage"
run edit "$(e s2 /p/README.md)"
ok "$(blocks s2)" 0 "modification de doc seule : pas de blocage"
run edit "$(e s2 /p/src/a.ts)"
ok "$(blocks s2)" 1 "code modifié sans vérification : bloqué"
ok "$(blocks s2)" 0 "bloqué une seule fois pour la même modification"
run edit "$(e s2 /p/src/b.ts)"
run bash "$(b s2 'git checkout main')"
ok "$(blocks s2)" 1 "git checkout ne compte pas comme vérification"
run edit "$(e s2 /p/src/c.ts)"
run bash "$(b s2 'pnpm test -- src/c.test.ts')"
ok "$(blocks s2)" 0 "test lancé après la modification : pas de blocage"
run edit "$(e s2 /p/src/d.ts)"; run bash "$(b s2 'npx tsc --noEmit')"
ok "$(blocks s2)" 0 "typecheck compte comme vérification"

run start "$(p s3 '/orkyn:orkyn fais X')"; run edit "$(e s3 /p/x.py)"
run start "$(p s3 'ok 1')"
ok "$(blocks s3)" 1 "réponse « ok 1 » : la mission continue"
run edit "$(e s3 /p/y.py)"; run start "$(p s3 'autre chose sans orkyn')"
ok "$(blocks s3)" 0 "nouvelle demande hors ORKYN : mission fermée"
run start "$(p '../x' '/orkyn a')"
ok "$(ls "$CLAUDE_PLUGIN_DATA" | grep -c x)" 0 "identifiant de session dangereux ignoré"

# Carte du projet
T=$(mktemp -d); printf '{"scripts":{"test":"vitest","build":"next build"}}' > "$T/package.json"; : > "$T/yarn.lock"; mkdir "$T/src" "$T/node_modules"
out=$(bash "$R/scripts/project-map.sh" "$T" "$CLAUDE_PLUGIN_DATA")
ok "$(printf '%s' "$out" | grep -c 'test `yarn test`, build `yarn build`')" 1 "carte : commandes yarn"
ok "$(printf '%s' "$out" | grep -c 'node_modules')" 0 "carte : node_modules ignoré"
ok "$(bash "$R/scripts/project-map.sh" "$T" "$CLAUDE_PLUGIN_DATA")" "$out" "carte : relue depuis le cache"
printf '{"scripts":{"test":"vitest","lint":"eslint ."}}' > "$T/package.json"
ok "$(bash "$R/scripts/project-map.sh" "$T" "$CLAUDE_PLUGIN_DATA" | grep -c 'lint `yarn lint`')" 1 "carte : recalculée quand le manifeste change"

rm -rf "$CLAUDE_PLUGIN_DATA" "$T"
echo "Résultat : $pass réussis, $fail échoués"
[ "$fail" = 0 ]
