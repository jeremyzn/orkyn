#!/usr/bin/env bash
# ORKYN : commandes Bash des agents orkyn-*, appelé par guard.sh.
# Usage : bash-guard.sh <readonly|write|raw>   (entrée JSON du hook sur stdin)
# Mode raw (appelé par guard.sh quand aucun lecteur JSON ne comprend l'entrée) : règles du mode write
# appliquées au texte brut grossièrement déséchappé. Faux positifs acceptés.
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
  echo "ORKYN : commande bloquée ($1). Action réservée au coordinateur après accord explicite de l'utilisateur." >&2
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

# GitHub : tout ce qui est public ou agit sur le dépôt distant
has "${S}gh${S}+(issue${S}+(create|comment|close|reopen|edit|delete|transfer)|pr${S}+(comment|review|close|reopen|edit|ready)|workflow${S}+(run|enable|disable)|secret${S}+(set|delete)|variable${S}+(set|delete)|run${S}+(rerun|cancel|delete)|gist${S}+(create|edit|delete)|label${S}+(create|edit|delete))${S}" && deny "gh, action publique ou distante"
has "${S}gh${S}+api${S}+(.*${S})?(-X${S}*|--method${S}+|--method=)(POST|PUT|PATCH|DELETE|post|put|patch|delete)" && deny "gh api en écriture"
has "${S}gh${S}+api${S}+(.*${S})?(-f|-F|--field|--raw-field|--input)${S}" && deny "gh api en écriture"

# Mobile : stores, distribution aux testeurs, mises à jour OTA, services Apple et Google
E_AS="${S}(npx${S}+|bunx${S}+|pnpm${S}+dlx${S}+)?eas(-cli)?(@[^[:space:]]*)?${S}+"
has "${E_AS}(submit|update|deploy|metadata:push|channel:|branch:(create|delete|rename)|build:(submit|resign)|credentials|device:create|env:(set|delete|push|pull|create|update)|project:delete|billing:|integrations:|sim:start${S}.*--public-link)" && deny "EAS (store, OTA, déploiement ou compte Expo)"
if has "${E_AS}build(${S}|\$)" && ! has "${S}--local${S}"; then deny "eas build distant (quota du compte Expo)"; fi
has "${E_AS}build${S}(.*${S})?(-s|--auto-submit|--auto-submit-with-profile(=[^[:space:]]*)?)${S}" && deny "eas build avec soumission au store"
has "${S}(npx${S}+)?expo${S}+publish" && deny "expo publish"
has "${S}(bundle${S}+exec${S}+)?fastlane${S}+(.*${S})?(deliver|supply|pilot|upload_to_[a-z_]+|testflight|match|produce|sigh|pem|cert|release|beta|deploy|publish|submit|ship|appstore|playstore|promote|nuke|firebase_app_distribution|precheck)(${S}|\$)" && deny "fastlane (store, certificats ou distribution)"
has "${S}xcrun${S}+(altool|notarytool${S}+submit|stapler${S}+staple|[iI][tT][mM][sS][tT]ransporter)" && deny "envoi vers Apple"
has "${S}-allowProvisioningUpdates${S}" && deny "xcodebuild -allowProvisioningUpdates (modifie le compte développeur Apple)"
has "${S}app-store-connect${S}+" && deny "App Store Connect"
if has "${S}([^[:space:]]*/)?(gradlew(\\.bat)?|gradle)${S}"; then
  gn="${n// publishToMavenLocal / }"
  [[ "$gn" =~ (${S}|:)(publish|promote|appDistributionUpload|uploadCrashlyticsSymbol)[A-Za-z]*${S} ]] && deny "Gradle, publication ou distribution"
fi
has "${S}(npx${S}+)?firebase(-tools)?${S}+(.*${S})?(deploy|appdistribution:|apptesters:|crashlytics:symbols:upload|functions:(delete|config:set|secrets:set)|hosting:(channel:deploy|disable|clone)|remoteconfig:rollback|database:(set|push|update|remove)|firestore:delete|auth:import)" && deny "Firebase, effet externe"
has "${S}(flutter|dart)${S}+pub${S}+publish" && deny "publication sur pub.dev"
has "${S}pod${S}+(trunk${S}+(push|delete|deprecate|add-owner|remove-owner|register)|repo${S}+push)" && deny "publication CocoaPods"

# Autres publications de paquets et d'images
has "${S}cargo${S}+(publish|yank|owner)${S}" && deny "publication crates.io"
has "${S}twine${S}+upload${S}" && deny "publication PyPI"
has "${S}(uv|poetry|hatch|flit|pdm)${S}+publish(${S}|\$)" && deny "publication de package Python"
has "${S}gem${S}+(push|yank)${S}" && deny "publication RubyGems"
has "${S}dotnet${S}+nuget${S}+(push|delete)${S}" && deny "publication NuGet"
has "${S}(docker|podman|buildah)${S}+(.*${S})?(push${S}|--push(${S}|=))" && deny "envoi d'image de conteneur"
has "${S}helm${S}+(push|install|upgrade|uninstall|rollback)${S}" && deny "helm, effet sur un cluster ou un registre"

# Déploiements et infrastructure distante
has "${S}(npx${S}+)?wrangler${S}+(deploy|publish|secret${S}+(put|delete|bulk)|versions${S}+deploy|d1${S}+execute${S}.*--remote|r2${S}+object${S}+(put|delete))" && deny "déploiement Cloudflare"
has "${S}(npx${S}+)?netlify${S}+deploy" && deny "déploiement Netlify"
has "${S}(fly|flyctl)${S}+(deploy|secrets${S}+(set|unset|import)|apps${S}+destroy|scale)" && deny "déploiement Fly.io"
has "${S}railway${S}+(up|redeploy|down)(${S}|\$)" && deny "déploiement Railway"
has "${S}(terraform|tofu)${S}+(apply|destroy|import|state${S}+(rm|push|mv))" && deny "terraform en écriture"
has "${S}pulumi${S}+(up|destroy|refresh${S}.*--yes)" && deny "pulumi en écriture"
has "${S}kubectl${S}+(apply|delete|create|replace|patch|rollout|scale|edit|drain|cordon|set)${S}" && deny "kubectl en écriture"
has "${S}(npx${S}+)?supabase${S}+(db${S}+(push|reset${S}+(.*${S})?--linked)|functions${S}+deploy|secrets${S}+(set|unset)|link)" && deny "Supabase distant"
has "${S}(npx${S}+)?prisma${S}+migrate${S}+(deploy|reset)" && deny "prisma migrate deploy/reset"
has "${S}gcloud${S}+(.*${S})?(deploy|delete)${S}" && deny "gcloud, déploiement ou suppression"
has "${S}aws${S}+(.*${S})?(deploy|s3${S}+(rm|rb|sync)|cloudformation${S}+(create|update|delete)-stack)" && deny "aws en écriture"
has "${S}az${S}+(.*${S})?(deploy|webapp${S}+up|delete)${S}" && deny "az en écriture"

# Installations globales (hors projet) : accord de l'utilisateur requis
has "${S}npm${S}+(.*${S})?(-g|--global|--location=global)${S}" && has "${S}npm${S}+(.*${S})?(i|install|add|update|un|uninstall|rm|remove|link)${S}" && deny "installation npm globale"
has "${S}(pnpm|bun)${S}+(add|install|i|remove|update)${S}+(.*${S})?(-g|--global)${S}" && deny "installation globale"
has "${S}yarn${S}+global${S}+(add|remove|upgrade)" && deny "installation yarn globale"
has "${S}(brew|port|apt|apt-get|dnf|yum|zypper|apk|choco|winget|scoop)${S}+(install|upgrade|reinstall|uninstall|remove|add)${S}" && deny "installation système"
has "${S}pacman${S}+-S" && deny "installation système"
has "${S}(pipx|cargo|gem)${S}+install${S}" && deny "installation globale d'outil"
has "${S}go${S}+install${S}" && deny "installation globale d'outil (go install)"
has "${S}uv${S}+tool${S}+install${S}" && deny "installation globale d'outil (uv tool)"
has "${S}pip3?${S}+install${S}+(.*${S})?(--user|--break-system-packages)${S}" && deny "installation pip hors environnement du projet"
has "${S}dart${S}+pub${S}+global${S}+activate${S}" && deny "installation globale (dart pub global)"
has "${S}(sdkmanager|xcodes${S}+install|rustup${S}+(update|toolchain${S}+install|target${S}+add)|flutter${S}+(upgrade|channel${S}+[a-z]))" && deny "mise à jour de la chaîne d'outils"

# Secrets : un agent ne lit jamais la valeur d'un secret
has "${S}printenv(${S}+)\$" && deny "affichage de toutes les variables d'environnement"
has "${S}env${S}+\$" && deny "affichage de toutes les variables d'environnement"
has "${S}security${S}+find-(generic|internet)-password" && deny "lecture du trousseau"
while IFS= read -r seg; do
  set -f; set -- $seg; set +f
  [ $# -gt 0 ] || continue
  first="${1##*/}"; first=$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')
  case "$first" in
    cat|head|tail|less|more|bat|nl|strings|xxd|od|hexdump|base64|cp|mv|scp|rsync|source|.|grep|egrep|fgrep|rg|ag|awk|gawk|sed|cut|sort|uniq|tac|openssl|gpg|get-content|gc|type|select-string|jq|yq|git|dotenv|vim|vi|nano|code|open) ;;
    *) continue ;;
  esac
  if [ "$first" = git ]; then case " $* " in *" show "*|*" cat-file "*|*" log "*|*" diff "*) ;; *) continue ;; esac; fi
  shift
  # cp et mv : seule la source est lue (cp .env.example .env reste permis)
  case "$first" in cp|mv) [ $# -gt 1 ] && set -- "${@:1:$(($# - 1))}" ;; esac
  for t in "$@"; do
    t="${t//[\"\']/}"
    case "$t" in -*|"") continue ;; esac
    if is_secret_path "$t" || { case "$t" in *:*) is_secret_path "${t##*:}" ;; *) false ;; esac; }; then
      deny "lecture du fichier de secrets $t"
    fi
  done
done < <(printf '%s\n' "$cmd" | tr ';&|\n' '\n\n\n\n')

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
# PowerShell : script téléchargé puis exécuté
if [[ "$lc" =~ (iwr|irm|invoke-webrequest|invoke-restmethod|downloadstring)[^|]*\|[[:space:]]*(iex|invoke-expression) ]] \
   || [[ "$lc" =~ (iex|invoke-expression)[[:space:]]*\(?[[:space:]]*\(?[[:space:]]*(iwr|irm|invoke-webrequest|invoke-restmethod|new-object) ]]; then
  deny "script téléchargé puis exécuté (PowerShell)"
fi
# Windows : rd /s /q, del /s /q
if [[ "$lc" =~ (^|[[:space:];|&])(rd|rmdir|del|erase)[[:space:]].*/s ]] && [[ "$lc" =~ /q ]] \
   && ! [[ "$lc" =~ (%te?mp%|appdata[\\/]local[\\/]temp) ]]; then
  deny "suppression récursive forcée hors dossier temporaire"
fi

exit 0
