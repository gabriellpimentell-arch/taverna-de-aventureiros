#!/bin/bash
# Roda o jogo de verdade e salva uma imagem de cada tela.
# Uso: tests/capturar.sh <pasta_de_saida>   (variável JOGO_BIN = executável compilado)
R="$(cd "$(dirname "$0")/.." && pwd)"
O="${1:-/tmp/capturas}"; mkdir -p "$O/app"
BIN="${JOGO_BIN:-/tmp/claude-0/-home-claude/8105bdde-9303-5813-9aa0-ce5145915ba4/scratchpad/build/TavernaDeAventureiros}"
cp "$BIN" "$O/app/"; rm -rf "$O/app/scripts" "$O/app/assets"; cp -r "$R/scripts" "$R/assets" "$O/app/"
cd "$O"; rm -f ./*.png ./s.sav
TAVERNA_SAVE="$O/s.sav" TAVERNA_TESTE="$R/tests/cenas.lua" LIBGL_ALWAYS_SOFTWARE=1 timeout 170 xvfb-run -a -s "-screen 0 1280x720x24" "$O/app/TavernaDeAventureiros" 2>&1 | grep -E 'Erro|attempt|traceback|CENA3D|SHADER.*(rror|ail)' | head -20
ls "$O" | grep -c png
