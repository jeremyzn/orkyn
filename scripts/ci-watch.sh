#!/usr/bin/env bash
# ORKYN : monitor de CI (monitors/monitors.json), démarré au premier /orkyn de la session.
# Surveille les exécutions GitHub Actions de la branche courante et n'écrit QUE sur un échec
# ou un retour au vert : chaque ligne écrite devient une notification pour Claude (donc des tokens).
# Sans gh connecté, sans dépôt git ou sans remote GitHub : reste muet et ne consomme rien.
# Lecture seule : aucune action sur la CI, aucun push.
set -u
quiet_forever() { while :; do sleep 3600; done; }
command -v gh >/dev/null 2>&1 || quiet_forever
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || quiet_forever
git remote -v 2>/dev/null | grep -q 'github' || quiet_forever
gh auth status >/dev/null 2>&1 || quiet_forever

interval="${ORKYN_CI_INTERVAL:-90}"
seen=" "
failed=" "
first=1
while :; do
  branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    runs=$(gh run list --branch "$branch" --limit 5 \
      --json databaseId,status,conclusion,workflowName \
      --template '{{range .}}{{.databaseId}}|{{.status}}|{{.conclusion}}|{{.workflowName}}{{"\n"}}{{end}}' 2>/dev/null)
    while IFS='|' read -r id status conclusion name; do
      [ -n "$id" ] && [ "$status" = completed ] || continue
      case "$seen" in *" $id "*) continue ;; esac
      seen="$seen$id "
      [ "$first" = 1 ] && continue   # exécutions déjà finies au démarrage : pas d'alerte
      case "$conclusion" in
        failure|timed_out|startup_failure)
          failed="$failed$name "
          echo "CI en échec : « $name » sur la branche $branch (run $id). Détail : gh run view $id --log-failed" ;;
        success)
          case "$failed" in *" $name "*)
            failed="${failed/ $name / }"
            echo "CI revenue au vert : « $name » sur la branche $branch (run $id)." ;;
          esac ;;
      esac
    done <<< "$runs"
  fi
  first=0
  sleep "$interval"
done
