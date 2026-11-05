-- =============================================================================
--  Gera os saves prontos em assets/saves. Uso, na raiz do projeto:
--    lua tools/gerar_saves.lua .
--  Começo: taverna nova. Metade: o robô joga até liberar as Parties.
--  Completo: toda a árvore no máximo, com heróis e os 4 invocados prontos.
-- =============================================================================
local raiz = arg[1] or "."
package.path = raiz .. "/scripts/?.lua;" .. raiz .. "/tests/?.lua;" .. package.path
require("motor_falso")
dofile(raiz .. "/scripts/main.lua")
local J = require("jogo")
local A = require("arvore")
local C = require("config")
local util = require("util")
local R = require("robo")
J.pular_menu = true
J.sem_noticias = true
motor._raiz = raiz

local function gravar(nome)
  local e = J.estado
  e.salvo_em = nil
  e.layout = nil   -- a construção do robô não vai junto: save pronto nasce do padrão
  local f = assert(io.open(raiz .. "/assets/saves/" .. nome .. ".sav", "wb"))
  f:write(util.serializar(e))
  f:close()
  print(nome, "ouro", util.formatar(e.ouro), "tempo", math.floor(e.tempo / 60) .. " min")
end

math.randomseed(7)
motor._save = false
iniciar()
J.comecar_endividado()
J.noticia = nil
gravar("comeco")

motor._save = false
iniciar()
J.comecar_endividado(); J.noticia = nil
R.jogar(30, 0.25, nil, function() return J.nivel("party") > 0 end)
for _, n in ipairs(J.NOTICIAS) do
  if J.nivel(n.id) > 0 then J.estado.noticias[n.id] = true end
end
gravar("metade")

motor._save = false
iniciar()
J.comecar_endividado(); J.noticia = nil
local e = J.estado
e.emprestimos, e.divida = 1, 0
e.mantimentos.comida, e.mantimentos.bebida = 500, 500
for _ = 1, 3 do
  for _, no in ipairs(A.NOS) do
    while not no.em_breve and not J.no_maximo(no) and J.no_liberado(no) do
      e.ouro = J.custo_no(no)
      J.comprar_no(no.id)
    end
  end
end
-- o equivalente ao antigo máximo de cada coisa: 5 mesas e a ala leste, 4 garçons...
-- em ordem: os quartos ocupam a sala na ordem de compra
for _, par in ipairs({ { "mesa", 5 }, { "garcom", 4 }, { "quartos", 2 }, { "quarto_duplo", 1 }, { "quarto_heroi", 1 }, { "canteiro", 8 }, { "arvore", 5 }, { "vaca", 7 }, { "porco", 4 }, { "galinha", 6 }, { "fazendeiro", 3 }, { "fazendeiro_arvores", 2 }, { "fazendeiro_animais", 2 } }) do
  for _ = 1, par[2] do e.ouro = 1e16; assert(J.comprar_unidade(par[1]), par[1]) end
end
for _, n in ipairs(J.NOTICIAS) do e.noticias[n.id] = true end
e.noticias._final = true
e.ouro = 1e16
while J.num_contratos_normais() < J.vagas_contrato() do J.contratar(); e.ouro = 1e16 end
for _, c in ipairs(e.contratados) do
  -- níveis definidos direto: comprar um a um passaria de qualquer quantia de ouro
  while J.rank_contratado(c) < 8 do
    c.armadura, c.arma, c.magia = c.armadura + 5, c.arma + 5, c.magia + 5
  end
  e.ouro = 1e16
  J.promover(c)
  c.fama = 500
  e.fama = e.fama + 500
end
for _ = 1, #C.sacerdotes do e.ouro = 1e16; J.contratar_sacerdote() end
J.chegada_sacerdote = nil
for _ = 1, #C.invocados do e.ouro = 1e16; J.invocar() end
local ids = {}
for _, c in ipairs(e.contratados) do
  if c.invocado then
    while J.poder(c) < C.sss.poder * 1.1 do c.magia = c.magia + 5 end
    ids[#ids + 1] = c.id
  end
end
J.criar_party(ids)
local normais = {}
for _, c in ipairs(e.contratados) do
  if not c.party then normais[#normais + 1] = c.id end
  if #normais == 4 then J.criar_party(normais); normais = {} end
end
-- o resto da progressão que costuma aparecer em um jogo concluído
e.ouro = 1e15
e.servidos, e.feitas, e.espolios, e.brigas = 50000, 8000, 7000, 300
e.total, e.tempo, e.rps = 5e15, 30 * 3600, 2e8
for _, d in ipairs(C.estoques) do e.estoques[d.id] = 300 end
e.colhido = 100000
for r = 1, 8 do e.feitas_rank[r] = 1000 end
gravar("completo")
