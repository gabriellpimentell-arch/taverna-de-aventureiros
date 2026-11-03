local raiz = arg[1] or "."
package.path = raiz .. "/scripts/?.lua;" .. raiz .. "/tests/?.lua;" .. package.path
require("motor_falso"); math.randomseed(tonumber(arg[3]) or 1)
dofile(raiz .. "/scripts/main.lua")
require("jogo").pular_menu = true
motor._raiz = raiz; iniciar()
local J, util = require("jogo"), require("util")
local R = require("robo")
local t = R.jogar(tonumber(arg[2]) or 80, 0.25, { "mesa","garcom", "prateleira", "mercadinho", "jardim", "cozinheiro", "venda", "recrutador", "rank_c","rank_a", "party", "heroi", "propaganda", "rank_ss", "invocacao" })
print(string.format("fim=%s  %.1f h  ouro/s %s  ouro %s  rep %d  obj: %s", tostring(J.estado.fim), t/3600, util.formatar(J.estado.rps), util.formatar(J.estado.ouro), (J.nivel_reputacao()), J.objetivo()))
