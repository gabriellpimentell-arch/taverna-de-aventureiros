local raiz="."
package.path = raiz .. "/scripts/?.lua;" .. raiz .. "/tests/?.lua;" .. package.path
require("motor_falso")
dofile(raiz .. "/scripts/main.lua")
local J=require("jogo"); J.pular_menu=true; J.sem_noticias=true; J.auto_colocar=true
motor._raiz=raiz; motor._save=false
iniciar(); J.offline=nil; J.comecar_endividado()
local R=require("robo")
local t=R.jogar(tonumber(arg[1]) or 80,0.25,{"fornecedor","garcom","cozinha","cervejaria","prateleira","jardim","cozinheiro","pomar","fazenda","fazendeiro_animais","recrutador"})
print("fim",J.estado.fim,t/3600,"divida",J.estado.divida,"sem_caminho",J.sem_caminho,"emprestimos",J.estado.emprestimos)
