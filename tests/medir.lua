-- =============================================================================
--  Mede o travamento: quanto custa cada quadro de atualizar, e quanto disso é rota.
--  Uso: lua tests/medir.lua <raiz> save [segundos]   save completo, 60 quadros por segundo
--       lua tests/medir.lua <raiz> robo [horas]      jogo novo inteiro, medido do começo ao fim
--  O motor é falso: no modo save conta regras + o Lua do desenho; a placa de vídeo fica de fora.
-- =============================================================================
local raiz, modo, quanto = arg[1] or ".", arg[2] or "save", tonumber(arg[3])
package.path = raiz .. "/scripts/?.lua;" .. raiz .. "/tests/?.lua;" .. package.path
require("motor_falso")
dofile(raiz .. "/scripts/main.lua")
local J, Cam = require("jogo"), require("caminhos")
J.pular_menu, J.sem_noticias, J.auto_colocar = true, true, true
motor._raiz = raiz

-- cronômetro em volta das funções caras
local gasto, chamadas = {}, {}
local function cronometrar(t, nome)
  local f = t[nome]
  gasto[nome], chamadas[nome] = 0, 0
  t[nome] = function(...)
    local c = os.clock()
    local a, b, d = f(...)
    gasto[nome] = gasto[nome] + os.clock() - c
    chamadas[nome] = chamadas[nome] + 1
    return a, b, d
  end
end
cronometrar(Cam, "rota")
cronometrar(Cam, "separar")

local quadros = {}
local pico_gente, pico_fora, pico_rota, pico_rotas = 0, 0, 0, 0
local function medir_quadro(fn)
  local r0, n0 = gasto.rota, chamadas.rota
  local c = os.clock()
  fn()
  quadros[#quadros + 1] = (os.clock() - c) * 1000
  pico_rota = math.max(pico_rota, (gasto.rota - r0) * 1000)
  pico_rotas = math.max(pico_rotas, chamadas.rota - n0)
  if #J.pessoas > pico_gente then pico_gente = #J.pessoas end
  if J.visitantes and #J.visitantes > pico_fora then pico_fora = #J.visitantes end
end

local function relatorio(nome)
  table.sort(quadros)
  local n, soma = #quadros, 0
  for _, v in ipairs(quadros) do soma = soma + v end
  local function pct(p) return quadros[math.max(1, math.ceil(n * p))] end
  local acima = 0
  for _, v in ipairs(quadros) do if v > 16.7 then acima = acima + 1 end end
  print(string.format("%s: %d quadros  media %.3f ms  p99 %.2f ms  max %.2f ms  acima de 16,7 ms: %d  pico de gente %d",
    nome, n, soma / n, pct(0.99), quadros[n], acima, pico_gente))
  print(string.format("  pior quadro em rotas: %.2f ms, %d rotas no mesmo quadro  gente lá fora: %d", pico_rota, pico_rotas, pico_fora))
  print(string.format("  rotas: %d chamadas, %.3f s (%.0f%% do total)  separar: %.3f s (%.0f%%)  total %.3f s",
    chamadas.rota, gasto.rota, gasto.rota * 100000 / soma, gasto.separar, gasto.separar * 100000 / soma, soma / 1000))
end

if modo == "save" then
  local f = assert(io.open(raiz .. "/assets/saves/completo.sav", "rb"))
  motor._save = f:read("a")
  f:close()
  iniciar()
  J.offline, J.noticia = nil, nil
  math.randomseed(7)
  -- esquenta a lotação e só então mede
  for _ = 1, 60 * 30 do J.atualizar(1 / 60) end
  for k in pairs(gasto) do gasto[k], chamadas[k] = 0, 0 end
  for _ = 1, 60 * (quanto or 120) do
    medir_quadro(function() atualizar(1 / 60); desenhar() end)
    J.noticia = nil
  end
  relatorio("save completo")
else
  motor._save = false
  iniciar()
  J.offline = nil
  J.comecar_endividado()
  math.randomseed(11)
  local R = require("robo")
  local atual = J.atualizar
  J.atualizar = function(dt) medir_quadro(function() atual(dt) end) end
  local t = R.jogar(quanto or 60, 0.25)
  J.atualizar = atual
  relatorio("robô")
  print(string.format("  fim=%s em %.1f h de jogo", tostring(J.estado.fim), t / 3600))
end
