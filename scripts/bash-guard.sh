#!/usr/bin/env bash
# ORKYN : commandes Bash des agents orkyn-*, appelé par guard.sh.
# Usage : bash-guard.sh <readonly|write|raw>   (entrée JSON du hook sur stdin)
# Mode raw (appelé par guard.sh quand aucun lecteur JSON ne comprend l'entrée) : règles du mode write
# appliquées au texte brut grossièrement déséchappé ; faux positifs acceptés.
# Bloque (exit 2) les commandes dont l'effet est externe ou destructif : push, reset --hard, clean -f,
# restauration de l'arbre de travail, publication, déploiement, rm -rf hors /tmp ou /var/tmp, sudo, curl|sh.
# `git stash` n'est bloqué qu'en readonly.
# FILET DE SÉCURITÉ, PAS UNE GARANTIE : l'analyse est textuelle, l'obscurcissement la contourne
# (variables, eval, base64, guillemets dans le nom de commande, script externe...). Si l'entrée est
# illisible, la commande passe (sauf mode raw). Non garanti pour les coéquipiers d'Agent Team.
mode="${1:-readonly}"

input=$(cat)
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
if [ "$mode" = raw ]; then
  mode=write
  cmd=$(printf '%s' "$input" | sed 's/\\n/ /g; s/\\\\/\\/g' | tr '"{}' '   ')
else
  cmd=$(json_str "$input" tool_input command) || exit 0
fi
[ -n "$cmd" ] || exit 0

deny() {
  echo "ORKYN : commande bloquée ($1) — action réservée au coordinateur après accord explicite de l'utilisateur." >&2
  exit 2
}

# curl|wget envoyé vers un shell (sur la commande brute, avant découpage)
if [[ "$cmd" =~ (curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$) ]] \
   || [[ "$cmd" =~ (^|[[:space:]])(ba|z|da)?sh[[:space:]]+(-[a-z]+[[:space:]]+)*\<\([[:space:]]*(curl|wget) ]]; then
  deny "curl/wget exécuté dans un shell"
fi

# Séparateurs remplacés par des espaces, bornes espace pour les motifs
n=" $(printf '%s' "$cmd" | tr '\n;&|()`' '       ') "
S='[[:space:]]'
G="${S}git${S}+(-[^[:space:]]+${S}+([^-[:space:]][^[:space:]]*${S}+)?)*"

has() { [[ "$n" =~ $1 ]]; }

has "${G}push${S}" && deny "git push"
has "${G}reset${S}+(.*${S})?--hard${S}" && deny "git reset --hard"
has "${G}clean${S}+(.*${S})?(-[a-zA-Z]*f[a-zA-Z]*|--force)${S}" && deny "git clean -f"
has "${G}checkout${S}+(.*${S})?(--${S}+)?\\.${S}" && deny "git checkout . (perte de travail)"
has "${G}restore${S}+(-[^[:space:]]+${S}+)*\\.${S}" && deny "git restore . (perte de travail)"
if [ "$mode" = "readonly" ] && has "${G}stash(${S}|\$)" && ! has "${G}stash${S}+(list|show)${S}"; then
  deny "git stash en lecture seule"
fi
has "${S}gh${S}+pr${S}+(create|merge)${S}" && deny "gh pr create/merge"
has "${S}gh${S}+release${S}" && deny "gh release"
has "${S}gh${S}+repo${S}+(create|delete)${S}" && deny "gh repo create/delete"
has "${S}(npm|pnpm|yarn|bun)${S}+([^[:space:]]+${S}+)*publish${S}" && deny "publication de package"
has "${S}vercel${S}+(.*${S})?(deploy|--prod)${S}" && deny "déploiement vercel"
has "${S}vercel${S}+\$" && deny "déploiement vercel"
has "${S}sudo${S}" && deny "sudo"

# rm récursif + forcé : seules les cibles sous /tmp ou /private/tmp sont admises
while IFS= read -r seg; do
  set -f; set -- $seg; set +f
  seen=0 rec=0 frc=0 unsafe=0
  for t in "$@"; do
    if [ "$seen" = 0 ]; then [ "${t##*/}" = "rm" ] && seen=1; continue; fi
    t="${t//[\"\']/}"
    case "$t" in
      --recursive) rec=1 ;;
      --force) frc=1 ;;
      --*) ;;
      -*) case "$t" in *[rR]*) rec=1;; esac; case "$t" in *f*) frc=1;; esac ;;
      *) t=$(to_unix_path "$t")
         case "$t" in *..*) unsafe=1;; /tmp/*|/var/tmp/*|/private/tmp/*) ;; "${TMPDIR%/}"/*) [ -n "${TMPDIR:-}" ] && [ "${TMPDIR%/}" != "$HOME" ] || unsafe=1 ;; *) unsafe=1;; esac ;;
    esac
  done
  [ "$rec" = 1 ] && [ "$frc" = 1 ] && [ "$unsafe" = 1 ] && deny "rm -rf hors /tmp"
done < <(printf '%s\n' "$cmd" | tr ';&|\n' '\n\n\n\n')

# PowerShell (Windows) : Remove-Item récursif et forcé, hors dossier temporaire
lc=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')
if [[ "$lc" =~ (remove-item|(^|[[:space:];|&])(ri|rm|rmdir|rd|del|erase)[[:space:]]) ]] \
   && [[ "$lc" =~ -r(e(c(u(r(s(e)?)?)?)?)?)?([[:space:]]|$) ]] && [[ "$lc" =~ -fo(r(c(e)?)?)?([[:space:]]|$) ]] \
   && ! [[ "$lc" =~ (\$env:te?mp|appdata[\\/]local[\\/]temp) ]]; then
  deny "suppression récursive forcée hors dossier temporaire"
fi
# Windows : rd /s /q, del /s /q
if [[ "$lc" =~ (^|[[:space:];|&])(rd|rmdir|del|erase)[[:space:]].*/s ]] && [[ "$lc" =~ /q ]] \
   && ! [[ "$lc" =~ (%te?mp%|appdata[\\/]local[\\/]temp) ]]; then
  deny "suppression récursive forcée hors dossier temporaire"
fi

exit 0
