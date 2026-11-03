#!/bin/bash
# Joga uma metade do jogo. Uso: tests/parte.sh <1|2> [vezes]
# A parte 2 recomeça sozinha quando tests/reiniciar_parte2.sh é chamado.
R="$(cd "$(dirname "$0")/.." && pwd)"
LUA="${LUA_BIN:-lua}"
D="$R/.testes"; mkdir -p "$D"
METADE="$D/metade.sav"
PARTE="$1"; VEZES="${2:-1}"

rodada() { cat "$D/rodada" 2>/dev/null || echo 0; }

gerar_metade() {
  [ -f "$METADE" ] && return 0
  echo "Gerando o estado da metade do jogo..."
  "$LUA" "$R/tests/parte.lua" "$R" 1 "$RANDOM" "$METADE"
}

if [ "$PARTE" = "1" ]; then
  for i in $(seq 1 "$VEZES"); do
    "$LUA" "$R/tests/parte.lua" "$R" 1 "$RANDOM" "$METADE" || exit 1
  done
  exit 0
fi

i=1
while [ "$i" -le "$VEZES" ]; do
  atual=$(rodada)
  gerar_metade || exit 1
  "$LUA" "$R/tests/parte.lua" "$R" 2 "$RANDOM" "$METADE" &
  pid=$!
  reiniciou=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 2
    if [ "$(rodada)" != "$atual" ]; then
      echo "A primeira parte mudou: recomeçando da metade."
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      reiniciou=1
      break
    fi
  done
  if [ "$reiniciou" = "1" ]; then i=1; continue; fi
  wait "$pid" || exit 1
  # só vale se ninguém mudou a primeira parte enquanto esta terminava
  if [ "$(rodada)" != "$atual" ]; then i=1; continue; fi
  i=$((i + 1))
done
