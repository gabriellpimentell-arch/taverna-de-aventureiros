#!/bin/bash
# Avisa que a primeira parte mudou: o estado da metade é refeito e a parte 2 recomeça.
R="$(cd "$(dirname "$0")/.." && pwd)"
D="$R/.testes"; mkdir -p "$D"
rm -f "$D/metade.sav"
echo $(( $(cat "$D/rodada" 2>/dev/null || echo 0) + 1 )) > "$D/rodada"
echo "Parte 2 avisada: vai recomeçar da metade."
