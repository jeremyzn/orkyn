#!/usr/bin/env bash
# ORKYN : fonctions communes aux garde-fous, à sourcer (. lib.sh). Fonctionne sous macOS, Linux et
# Windows (Git Bash, fourni avec Git pour Windows, que Claude Code utilise pour les hooks).
#
# json_str <json> <clé> [<clé>...]  → affiche la chaîne au chemin donné, ou rien si absente / pas une chaîne.
# json_strings <json> <clé>         → affiche toutes les chaînes contenues sous <clé>, une par ligne.
# Code retour : 0 si le JSON est un objet lisible, 1 sinon (JSON invalide ou aucun lecteur disponible).
# Lecteurs essayés dans l'ordre : jq, python3, perl (JSON::PP, livré avec macOS et Git pour Windows), node,
# puis « awk » : lecteur de secours en awk POSIX seul (aucune dépendance), limité à ce que lisent les
# garde-fous (chaînes, échappements courants, \uXXXX non ASCII remplacé par ?).
# ORKYN_JSON_PARSER=<jq|python3|perl|node|awk> force un lecteur (tests). Une autre valeur = aucun lecteur.
#
# is_windows                        → vrai sous Git Bash / MSYS / Cygwin.
# to_unix_path <chemin>             → C:\Users\x ou C:/Users/x → /c/Users/x (inchangé ailleurs).

is_windows() {
  case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac
  return 1
}

to_unix_path() {
  local p="$1"
  case "$p" in
    [A-Za-z]:[\\/]*|[A-Za-z]:|\\\\*)
      if command -v cygpath >/dev/null 2>&1; then cygpath -u -- "$p" 2>/dev/null && return 0; fi
      p="${p//\\//}"
      case "$p" in
        [A-Za-z]:*) local d; d=$(printf '%s' "${p%%:*}" | tr '[:upper:]' '[:lower:]'); p="/$d${p#?:}" ;;
      esac ;;
    *\\*) is_windows && p="${p//\\//}" ;;
  esac
  printf '%s\n' "$p"
}

_json_parsers() {
  if [ -n "${ORKYN_JSON_PARSER:-}" ]; then echo "$ORKYN_JSON_PARSER"; return; fi
  echo jq python3 perl node awk
}

# _json_run <parser> <str|strings> <json> <clés...>
_json_run() {
  local parser="$1" kind="$2" json="$3"; shift 3
  case "$parser" in
    jq)
      command -v jq >/dev/null 2>&1 || return 1
      local jpath; jpath=$(printf '%s\n' "$@" | jq -Rsc 'split("\n") | map(select(length > 0))' 2>/dev/null) || return 1
      if [ "$kind" = str ]; then
        printf '%s' "$json" | jq -er --argjson p "$jpath" \
          'if type == "object" then ((try getpath($p) catch null) | if type == "string" then . else "" end) else error("x") end' 2>/dev/null
      else
        printf '%s' "$json" | jq -er --argjson p "$jpath" \
          'if type == "object" then ([(try getpath($p) catch null) | .. | strings] | join("\n")) else error("x") end' 2>/dev/null
      fi ;;
    python3|python)
      command -v "$parser" >/dev/null 2>&1 || return 1
      printf '%s' "$json" | "$parser" -I -c '
import json, sys
d = json.loads(sys.stdin.buffer.read().decode("utf-8"))
if not isinstance(d, dict): sys.exit(1)
kind, keys = sys.argv[1], sys.argv[2:]
v = d
for k in keys:
    v = v.get(k) if isinstance(v, dict) else None
def walk(x):
    if isinstance(x, str): yield x
    elif isinstance(x, dict):
        for y in x.values(): yield from walk(y)
    elif isinstance(x, list):
        for y in x: yield from walk(y)
out = (v if isinstance(v, str) else "") if kind == "str" else "\n".join(walk(v))
sys.stdout.buffer.write((out + "\n").encode("utf-8"))' "$kind" "$@" 2>/dev/null ;;
    perl)
      command -v perl >/dev/null 2>&1 || return 1
      printf '%s' "$json" | perl -MJSON::PP -e '
local $/; my $raw = <STDIN>;
my $d = eval { JSON::PP->new->utf8->allow_nonref->decode($raw) };
exit 1 unless ref($d) eq "HASH";
my ($kind, @keys) = @ARGV;
my $v = $d;
for my $k (@keys) { $v = (ref($v) eq "HASH") ? $v->{$k} : undef; }
my @out;
sub walk { my $x = shift; if (defined($x) && !ref($x)) { push @out, $x }
  elsif (ref($x) eq "HASH") { walk($_) for values %$x } elsif (ref($x) eq "ARRAY") { walk($_) for @$x } }
my $o;
if ($kind eq "str") { $o = (defined($v) && !ref($v)) ? $v : ""; }
else { walk($v); $o = join("\n", @out); }
binmode(STDOUT, ":encoding(UTF-8)"); print $o, "\n";' "$kind" "$@" 2>/dev/null ;;
    node)
      command -v node >/dev/null 2>&1 || return 1
      printf '%s' "$json" | node -e '
let raw = ""; process.stdin.setEncoding("utf8");
process.stdin.on("data", c => raw += c).on("end", () => {
  let d; try { d = JSON.parse(raw); } catch { process.exit(1); }
  if (!d || typeof d !== "object" || Array.isArray(d)) process.exit(1);
  const [kind, ...keys] = process.argv.slice(1);
  let v = d; for (const k of keys) v = (v && typeof v === "object" && !Array.isArray(v)) ? v[k] : undefined;
  const out = [];
  const walk = x => { if (typeof x === "string") out.push(x); else if (Array.isArray(x)) x.forEach(walk); else if (x && typeof x === "object") Object.values(x).forEach(walk); };
  if (kind === "str") process.stdout.write((typeof v === "string" ? v : "") + "\n");
  else { walk(v); process.stdout.write(out.join("\n") + "\n"); }
});' "$kind" "$@" 2>/dev/null ;;
    awk)
      command -v awk >/dev/null 2>&1 || return 1
      printf '%s' "$json" | awk -v kind="$kind" -v want="$(IFS=.; printf '%s' "$*")" '
function hex(c) { return index("0123456789abcdef", tolower(c)) - 1 }
# Lit la chaîne dont le guillemet ouvrant est en position i. Résultat dans str, position suivante dans i.
function readstr(   out, c, e, n, k) {
  i++; out = ""
  while (i <= len) {
    c = substr(s, i, 1)
    if (c == "\"") { i++; str = out; return 1 }
    if (c == "\\") {
      e = substr(s, i + 1, 1); i += 2
      if (e == "n") out = out "\n"; else if (e == "t") out = out "\t"; else if (e == "r") out = out "\r"
      else if (e == "b" || e == "f") out = out " "
      else if (e == "u") {
        n = 0; for (k = 0; k < 4; k++) n = n * 16 + hex(substr(s, i + k, 1)); i += 4
        out = out ((n > 0 && n < 128) ? sprintf("%c", n) : "?")
      } else out = out e
    } else { out = out c; i++ }
  }
  return 0
}
{ s = s $0 "\n" }
END {
  len = length(s); i = 1; d = 0; found = 0
  while (i <= len && substr(s, i, 1) ~ /[ \t\r\n]/) i++
  if (substr(s, i, 1) != "{") exit 1
  while (i <= len) {
    c = substr(s, i, 1)
    if (c ~ /[ \t\r\n]/) { i++ }
    else if (c == "{" || c == "[") { d++; ct[d] = c; key[d] = (c == "[") ? "#" : ""; ek[d] = (c == "{"); i++ }
    else if (c == "}" || c == "]") { d--; i++; if (d < 0) exit 1; if (d == 0) break }
    else if (c == ",") { if (ct[d] == "{") ek[d] = 1; i++ }
    else if (c == ":") { ek[d] = 0; i++ }
    else if (c == "\"") {
      if (!readstr()) exit 1
      if (ct[d] == "{" && ek[d]) key[d] = str
      else {
        path = key[1]; for (k = 2; k <= d; k++) path = path "." key[k]
        if (kind == "str") { if (path == want) { found = 1; val = str } }
        else if (path == want || index(path, want ".") == 1) outp = outp str "\n"
      }
    } else { while (i <= len && substr(s, i, 1) !~ /[ \t\r\n,}\]]/) i++ }
  }
  if (d != 0) exit 1
  if (kind == "str") print val; else printf "%s", outp
}' 2>/dev/null ;;
    *) return 1 ;;
  esac
}

_json() {
  local kind="$1" json="$2"; shift 2
  local p out
  for p in $(_json_parsers); do
    if out=$(_json_run "$p" "$kind" "$json" "$@"); then
      printf '%s' "$out"
      [ -n "$out" ] && printf '\n'
      return 0
    fi
  done
  return 1
}

json_str() { _json str "$@"; }
json_strings() { _json strings "$@"; }

# is_secret_path <chemin>           → vrai si le chemin désigne un fichier de secrets : .env (hors modèles
#                                     .example, .sample, .template, .dist), clés privées et certificats
#                                     (pem, key, p8, p12, pfx, id_rsa...), keystores Android (jks, keystore,
#                                     key.properties), jetons de gestionnaires (.npmrc, .pypirc, .netrc),
#                                     identifiants cloud (.aws/credentials, .kube/config, .docker/config.json,
#                                     gh hosts.yml, comptes de service), états Terraform, dossiers .ssh et .gnupg.
#                                     Les clés publiques (.pub) restent lisibles.
is_secret_path() {
  local p b
  p=$(to_unix_path "$1" | tr '[:upper:]' '[:lower:]')
  p="${p%/}"
  b="${p##*/}"
  case "$b" in *.pub) return 1 ;; esac
  case "$b" in
    .env.example|.env.sample|.env.template|.env.dist|.env.*.example|.env.*.sample|.env.*.template) return 1 ;;
    .env|.env.*|*.env|.dev.vars|.envrc) return 0 ;;
    *.pem|*.key|*.p8|*.p12|*.pfx|*.jks|*.keystore|*.ppk|*.asc|*.gpg) return 0 ;;
    id_rsa*|id_dsa*|id_ecdsa*|id_ed25519*) return 0 ;;
    key.properties|keystore.properties|signing.properties) return 0 ;;
    .npmrc|.yarnrc.yml|.pypirc|.netrc|_netrc|.git-credentials|.htpasswd) return 0 ;;
    credentials|credentials.json|client_secret*.json|service-account*.json|serviceaccount*.json) return 0 ;;
    secrets.json|secrets.yml|secrets.yaml|secrets.toml|.secrets|*.tfstate|*.tfstate.backup) return 0 ;;
  esac
  case "$p" in
    */.ssh/*|*/.gnupg/*|*/.aws/*|*/.azure/*|*/.config/gcloud/*|*/.kube/config|*/.docker/config.json) return 0 ;;
    */.config/gh/hosts.yml|*/.android/adbkey|*/.gradle/gradle.properties|*/.appstoreconnect/*) return 0 ;;
    */library/keychains/*|*/.password-store/*) return 0 ;;
  esac
  return 1
}
