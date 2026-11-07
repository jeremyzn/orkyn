#!/usr/bin/env bash
# ORKYN : carte du projet (commandes de vérification et dossiers clés), injectée par context.sh.
# Usage : project-map.sh <dossier projet> [dossier de cache]
# Calcul en shell, sans token. Mise en cache par projet, recalculée seulement si un manifeste change.
# Lecture seule dans le projet. Termine toujours avec le code 0.
set -u
proj="${1:-$PWD}"
cache_dir="${2:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/lib.sh"

manifests="package.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb package-lock.json Makefile justfile pyproject.toml \
setup.cfg tox.ini requirements.txt Cargo.toml go.mod pubspec.yaml build.gradle build.gradle.kts settings.gradle.kts \
Package.swift deno.json composer.json Gemfile .golangci.yml .golangci.yaml"

signature() {
  local m out=""
  for m in $manifests; do
    [ -f "$proj/$m" ] && out="$out $m:$(wc -c < "$proj/$m" | tr -d ' '):$(cksum < "$proj/$m" | cut -d' ' -f1)"
  done
  ls -1 "$proj" 2>/dev/null | tr '\n' ' ' | cksum | cut -d' ' -f1 | sed "s/^/$out dirs:/"
}

compute() {
  local cmds="" pm=npm run="npm run" s
  add() { cmds="$cmds${cmds:+, }$1 \`$2\`"; }
  if [ -f "$proj/package.json" ]; then
    if [ -f "$proj/pnpm-lock.yaml" ]; then pm=pnpm; run="pnpm"
    elif [ -f "$proj/yarn.lock" ]; then pm=yarn; run="yarn"
    elif [ -f "$proj/bun.lock" ] || [ -f "$proj/bun.lockb" ]; then pm=bun; run="bun run"; fi
    pkg=$(cat "$proj/package.json" 2>/dev/null)
    has_script() { [ -n "$(json_str "$pkg" scripts "$1" 2>/dev/null)" ]; }
    has_script test && add test "$run test"
    for s in typecheck type-check tsc check-types; do has_script "$s" && { add typecheck "$run $s"; break; }; done
    has_script lint && add lint "$run lint"
    for s in format fmt; do has_script "$s" && { add format "$run $s"; break; }; done
    has_script build && add build "$run build"
    ! has_script typecheck && ! has_script type-check && [ -f "$proj/tsconfig.json" ] && add typecheck "npx tsc --noEmit"
    echo "- Gestionnaire JS : $pm"
  fi
  if [ -f "$proj/Makefile" ]; then
    for s in test check lint fmt format build; do
      grep -qE "^$s:" "$proj/Makefile" 2>/dev/null && add "make" "make $s"
    done
  fi
  if [ -f "$proj/pyproject.toml" ] || [ -f "$proj/requirements.txt" ] || [ -f "$proj/setup.cfg" ]; then
    if grep -qsE '\[tool\.pytest|pytest' "$proj/pyproject.toml" "$proj/requirements.txt" "$proj/setup.cfg" "$proj/tox.ini" || [ -d "$proj/tests" ]; then add test "python3 -m pytest -q"; fi
    grep -qs '\[tool\.ruff' "$proj/pyproject.toml" && add lint "ruff check ."
    grep -qs '\[tool\.mypy' "$proj/pyproject.toml" && add typecheck "mypy ."
  fi
  [ -f "$proj/Cargo.toml" ] && { add test "cargo test -q"; add lint "cargo clippy -q"; add build "cargo build -q"; }
  if [ -f "$proj/go.mod" ]; then
    add test "go test ./..."; add lint "go vet ./..."
    { [ -f "$proj/.golangci.yml" ] || [ -f "$proj/.golangci.yaml" ]; } && add lint "golangci-lint run"
  fi
  if [ -f "$proj/pubspec.yaml" ]; then
    if grep -q flutter "$proj/pubspec.yaml" 2>/dev/null; then add test "flutter test"; add lint "flutter analyze"
    else add test "dart test"; add lint "dart analyze"; fi
  fi
  if [ -f "$proj/build.gradle" ] || [ -f "$proj/build.gradle.kts" ]; then
    g="gradle"; [ -x "$proj/gradlew" ] && g="./gradlew"
    add test "$g test -q"; add lint "$g lint -q"; add build "$g assembleDebug -q"
  fi
  [ -f "$proj/Package.swift" ] && { add test "swift test"; add build "swift build"; }
  [ -f "$proj/deno.json" ] && { add test "deno test"; add lint "deno lint"; }
  [ -f "$proj/composer.json" ] && grep -q phpunit "$proj/composer.json" 2>/dev/null && add test "vendor/bin/phpunit"
  [ -f "$proj/Gemfile" ] && grep -q rspec "$proj/Gemfile" 2>/dev/null && add test "bundle exec rspec"
  [ -f "$proj/tests/guards.sh" ] && add test "bash tests/guards.sh"
  if [ -n "$cmds" ]; then echo "- Commandes du projet : $cmds"; else echo "- Commandes du projet : aucune détectée, cherche dans le README"; fi

  local dirs="" d n=0
  for d in "$proj"/*/; do
    d=$(basename "$d")
    case "$d" in node_modules|dist|build|out|target|vendor|coverage|tmp|__pycache__|Pods|DerivedData) continue ;; esac
    dirs="$dirs $d"; n=$((n + 1)); [ "$n" -ge 12 ] && { dirs="$dirs …"; break; }
  done
  echo "- Dossiers clés :${dirs:- aucun}"
}

if [ -n "$cache_dir" ] && mkdir -p "$cache_dir/cartes" 2>/dev/null; then
  key=$(printf '%s' "$proj" | cksum | cut -d' ' -f1)
  file="$cache_dir/cartes/$key.txt"
  sig=$(signature)
  if [ -f "$file" ] && [ "$(head -n1 "$file")" = "# $sig" ]; then
    tail -n +2 "$file"
  else
    out=$(compute)
    { printf '# %s\n' "$sig"; printf '%s\n' "$out"; } > "$file" 2>/dev/null
    printf '%s\n' "$out"
  fi
else
  compute
fi
exit 0
