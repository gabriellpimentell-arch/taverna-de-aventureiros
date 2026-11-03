#!/bin/bash
# Roda os testes várias vezes com sementes diferentes. Uso: tests/rodar.sh [vezes] [rapido]
R="$(cd "$(dirname "$0")/.." && pwd)"
LUA="${LUA_BIN:-lua}"
V="${1:-3}"
for i in $(seq 1 "$V"); do
  "$LUA" "$R/tests/testes.lua" "$R" "$((RANDOM + i))" ${2:-} || exit 1
done
"$LUA" "$R/tests/android.lua" "$R" || exit 1
if command -v g++ >/dev/null; then
  T="$(mktemp -d)"
  g++ -std=c++17 -o "$T/toques" "$R/tests/toques_teste.cpp" && "$T/toques" || exit 1
  rm -rf "$T"
fi
