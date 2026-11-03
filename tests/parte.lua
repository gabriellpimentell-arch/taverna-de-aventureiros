-- =============================================================================
--  Joga uma das metades do jogo, conferindo tudo pelo caminho.
--    Parte 1: do início até comprar o Recrutador; grava o estado da metade.
--    Parte 2: carrega esse estado e joga até derrotar o Lorde Demônio.
--  Uso: lua tests/parte.lua <raiz> <1|2> <semente> <arquivo da metade>
-- =============================================================================
local raiz, parte, semente, arquivo = arg[1], tonumber(arg[2]), tonumber(arg[3]), arg[4]
package.path = raiz .. "/scripts/?.lua;" .. raiz .. "/tests/?.lua;" .. package.path
require("motor_falso")
dofile(raiz .. "/scripts/main.lua")
require("jogo").pular_menu = true
motor._raiz = raiz

local J = require("jogo")
local T = require("telas")
local R = require("robo")
local util = require("util")

local function ler(p)
  local f = assert(io.open(p, "rb"), "falta o estado da metade: " .. p)
  local s = f:read("a")
  f:close()
  return s
end

if parte == 2 then motor._save = ler(arquivo) end
iniciar()
math.randomseed(semente)
J.offline = nil

local ABAS = { "taverna", "arvore", "missoes", "mercadinho", "producao", "aventureiros", "invocacao" }
local proxima_aba = 1

local function finito(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
local function falha(t, msg)
  print(string.format("BUG na parte %d, aos %.1f min de jogo, semente %d: %s", parte, t / 60, semente, msg))
  os.exit(1)
end

local proxima = 0
local function conferir(t)
  if t < proxima then return end
  proxima = t + 30
  local e = J.estado
  if not finito(e.ouro) or e.ouro < 0 then falha(t, "ouro inválido: " .. tostring(e.ouro)) end
  if (J.sem_caminho or 0) > 0 then falha(t, "pessoa sem caminho") end
  for _, l in ipairs(J.lugares) do
    if l.dono and l.dono.removido then falha(t, "lugar ocupado por quem já saiu") end
  end
  for _, p in ipairs(J.pessoas) do
    if not finito(p.x) or not finito(p.z) then falha(t, "posição inválida") end
  end
  local em = {}
  for _, m in ipairs(e.missoes) do
    if m.contratado then em[m.contratado] = true end
    if not finito(m.resta) then falha(t, "missão com tempo inválido") end
  end
  for _, c in ipairs(e.contratados) do
    if c.em_missao and not em[c.id] then falha(t, c.nome .. " preso em missão que não existe") end
  end
  -- passa por todas as telas: erro de desenho também é bug
  T.aba = ABAS[proxima_aba]
  proxima_aba = proxima_aba % #ABAS + 1
  local ok, erro = pcall(function() atualizar(0.01); desenhar() end)
  if not ok then falha(t, "erro na tela " .. T.aba .. ": " .. tostring(erro)) end
  T.aba = "taverna"
end

local ok, tempo = pcall(R.jogar, parte == 1 and 12 or 60, 0.25, nil, function(t)
  conferir(t)
  return parte == 1 and J.nivel("recrutador") > 0
end)
if not ok then falha(0, tostring(tempo)) end

if parte == 1 then
  if J.nivel("recrutador") < 1 then falha(tempo, "não chegou ao Recrutador em 12 h") end
  J.salvar()
  local f = assert(io.open(arquivo .. ".tmp", "wb"))
  f:write(motor._save)
  f:close()
  os.rename(arquivo .. ".tmp", arquivo)
  print(string.format("Parte 1 ok: chegou à metade em %.1f h de jogo.", tempo / 3600))
else
  if not J.estado.fim then falha(tempo, "não derrotou o Lorde Demônio em 60 h. Objetivo: " .. J.objetivo()) end
  print(string.format("Parte 2 ok: da metade ao final em %.1f h de jogo.", tempo / 3600))
end
