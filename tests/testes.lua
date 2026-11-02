-- =============================================================================
--  Testes de regressão. Todo bug corrigido ganha um teste aqui.
--  Rodar: tests/rodar.sh
-- =============================================================================
local raiz = arg[1] or "."
package.path = raiz .. "/scripts/?.lua;" .. raiz .. "/tests/?.lua;" .. package.path
require("motor_falso")
local semente = tonumber(arg[2]) or os.time()
math.randomseed(semente)
dofile(raiz .. "/scripts/main.lua")

local J = require("jogo")
local A = require("arvore")
local C = require("config")
local U = require("ui")
local T = require("telas")
local util = require("util")

local falhas, total = 0, 0
local function ok(nome, cond, extra)
  total = total + 1
  if not cond then
    falhas = falhas + 1
    print("FALHOU: " .. nome .. (extra and (" (" .. tostring(extra) .. ")") or ""))
  end
end
local function novo()
  motor._save = false
  iniciar()
end
local function quadros(n, dt)
  for _ = 1, n do atualizar(dt or 0.1); desenhar() end
end
local function libera(...)
  for _, id in ipairs({ ... }) do
    local no = A.POR_ID[id]
    for _, p in ipairs(no.pre) do if J.nivel(p) < 1 then libera(p) end end
    J.estado.ouro = J.custo_no(no) + 1
    assert(J.comprar_no(id), "não comprou " .. id)
  end
end

-- Formatação: 100 mi aparecia como "1 mi" e 120 mil como "12 mil"
ok("100 mi", util.formatar(100e6) == "100 mi", util.formatar(100e6))
ok("120 mil", util.formatar(120000) == "120 mil", util.formatar(120000))
ok("1,5 bi", util.formatar(1.5e9) == "1,5 bi", util.formatar(1.5e9))
ok("12.340 fica curto", util.formatar(12340) == "12,3 mil", util.formatar(12340))
ok("9.999", util.formatar(9999) == "9.999", util.formatar(9999))

-- Árvore -------------------------------------------------------------------------
novo()
local ids = {}
for _, no in ipairs(A.NOS) do
  ok("nó sem id repetido: " .. no.id, not ids[no.id]); ids[no.id] = true
  for _, p in ipairs(no.pre) do ok("pré-requisito existe: " .. no.id, A.POR_ID[p] ~= nil) end
  ok("ramo existe: " .. no.id, A.RAMOS[no.ramo] ~= nil)
end
ok("sem ouro não compra", J.comprar_no("mesa") == false)
J.estado.ouro = 1e30
ok("nó bloqueado não compra", J.comprar_no("rank_e") == false)
ok("id inexistente não quebra", J.comprar_no("nao_existe") == false)
local o = J.estado.ouro
ok("compra cobra o preço", J.comprar_no("mesa") and J.estado.ouro == o - 20)
for _ = 1, 20 do J.comprar_no("mesa") end
ok("não passa do máximo", J.nivel("mesa") == A.POR_ID.mesa.max)
ok("lugares acompanham mesas", #J.lugares == 12, #J.lugares)
-- todo nó é alcançável
do
  novo()
  J.estado.ouro = 1e60
  local progresso = true
  while progresso do
    progresso = false
    for _, no in ipairs(A.NOS) do
      if J.nivel(no.id) == 0 and J.comprar_no(no.id) then progresso = true end
    end
  end
  for _, no in ipairs(A.NOS) do ok("nó alcançável: " .. no.id, J.nivel(no.id) > 0) end
  ok("lugares não passam das posições", J.num_mesas() <= #J.POS_MESAS)
  quadros(30)
end

-- Clientes ---------------------------------------------------------------------------
novo()
quadros(60)
ok("clientes chegam", #J.pessoas > 0)
local achou
for _, p in ipairs(J.pessoas) do if p.estado == "esperando" then achou = p end end
if achou then
  local g = J.estado.ouro
  ok("servir paga", J.servir(achou) and J.estado.ouro > g)
  ok("servir duas vezes não paga de novo", J.servir(achou) == false)
end
-- todo cliente sem atendimento vai embora e libera o lugar
novo()
for _ = 1, 3000 do J.atualizar(0.1) end
for _, l in ipairs(J.lugares) do
  ok("lugar aponta para pessoa viva", not l.dono or not l.dono.removido)
end

-- Brigas ----------------------------------------------------------------------------
novo()
do
  local tg, ta
  for _, t in ipairs(J.TIPOS) do
    if t.nome == "guerreiro" then tg = t elseif t.nome == "arqueiro" then ta = t end
  end
  local l1, l2 = J.lugares[1], J.lugares[2]
  local function pessoa(t, l)
    local p = { x = l.x, z = l.z, y = 0.42, giro = 0, fase = 0, t = 0, tipo = t, pele = "#ffffff", rota = {}, estado = "esperando", sentado = true, lugar = l, pedido = "bebida" }
    l.dono = p
    J.pessoas[#J.pessoas + 1] = p
    return p
  end
  local a, b = pessoa(tg, l1), pessoa(ta, l2)
  for _ = 1, 40 do J.atualizar(0.1) end
  ok("guerreiro e arqueiro brigam", a.estado == "brigando" and b.estado == "brigando", a.estado)
  local g = J.estado.ouro
  ok("separar paga", J.separar_briga(a) and J.estado.ouro > g)
  ok("voltam a esperar", a.estado == "esperando" and b.estado == "esperando")
  for _ = 1, 40 do J.atualizar(0.1) end
  ok("não brigam de novo", a.estado ~= "brigando")
  desenhar()
end
-- briga ignorada termina e não deixa lugar preso
novo()
do
  local tg, ta
  for _, t in ipairs(J.TIPOS) do
    if t.nome == "guerreiro" then tg = t elseif t.nome == "arqueiro" then ta = t end
  end
  local function pessoa(t, l)
    local p = { x = l.x, z = l.z, y = 0.42, giro = 0, fase = 0, t = 0, tipo = t, pele = "#ffffff", rota = {}, estado = "esperando", sentado = true, lugar = l, pedido = "bebida" }
    l.dono = p
    J.pessoas[#J.pessoas + 1] = p
    return p
  end
  local a, b = pessoa(tg, J.lugares[1]), pessoa(ta, J.lugares[2])
  for _ = 1, 200 do J.atualizar(0.1); desenhar() end
  ok("briga ignorada termina", a.estado ~= "brigando" and b.estado ~= "brigando", a.estado)
end

-- Missões ------------------------------------------------------------------------------
novo()
libera("prateleira")
ok("aba missões aparece", J.prateleira_aberta())
local g0 = J.estado.ouro
for _ = 1, 100 do J.atualizar(0.1) end
ok("missão não paga ao partir", J.estado.feitas == 0)
ok("há missão em andamento", #J.estado.missoes > 0)
for _ = 1, 400 do J.atualizar(0.1) end
ok("missão conclui e conta", J.estado.feitas > 0)
ok("nunca falha: feitas por rank batem", (J.estado.feitas_rank[1] or 0) == J.estado.feitas)

-- rank sem reputação fica no A
novo()
J.estado.ouro = 1e40
for _, id in ipairs({ "prateleira", "rank_e", "rank_d", "rank_c", "rank_b", "rank_a", "rank_s", "rank_ss" }) do
  J.estado.ouro = 1e40
  J.comprar_no(id)
end
ok("sem reputação, comuns vão até o A", J.rank_aventureiro() == 6, J.rank_aventureiro())
J.estado.fama = 1e9
ok("com reputação, chegam ao SS", J.rank_aventureiro() == 8, J.rank_aventureiro())

-- Mercadinho -----------------------------------------------------------------------------
novo()
libera("prateleira", "mercadinho")
local lucro_sem = J.lucro_espolio(1)
libera("venda")
ok("venda aumenta lucro", J.lucro_espolio(1) > lucro_sem * 1.9)
ok("espólio rende menos que pagar tudo no início", lucro_sem < C.ranks[1].espolio)
J.estado.espolios = 0
local p = { x = 0, z = 0, leva_espolio = 1 }
J.vender_espolio(p)
ok("vender conta espólio", J.estado.espolios == 1)
J.vender_espolio(p)
ok("vender duas vezes não conta de novo", J.estado.espolios == 1)
libera("pocoes")
ok("poções geram renda", J.renda_venda() > 0)

-- Jardim ------------------------------------------------------------------------------------
novo()
libera("jardim")
for _ = 1, 500 do J.atualizar(0.1) end
ok("jardim colhe", J.estado.estoque > 0)
libera("cozinheiro")
local q = J.estado.estoque
for _, pp in ipairs(J.pessoas) do pp.pedido = "comida" end
for _ = 1, 60 do
  J.atualizar(0.1)
  for _, pp in ipairs(J.pessoas) do pp.pedido = "comida"; if pp.estado == "esperando" then J.servir(pp) end end
end
ok("cozinheiro usa estoque", J.estado.estoque < q + J.por_colheita() * 2)
ok("estoque nunca negativo", J.estado.estoque >= 0)

-- Contratados, parties e heróis -----------------------------------------------------------------
novo()
libera("recrutador", "party")
J.estado.ouro = 1e30
for _ = 1, 2 do ok("contrata", J.contratar() ~= nil) end
ok("respeita as vagas", J.contratar() == nil)
libera("alojamento"); J.estado.ouro = 1e30
J.contratar(); J.contratar()
ok("4 contratados", #J.estado.contratados == 4)
local c1 = J.estado.contratados[1]
local p0 = J.poder(c1)
ok("investir aumenta poder", J.investir(c1, "arma") and J.poder(c1) > p0)
J.estado.ouro = 0
ok("investir sem ouro falha", J.investir(c1, "arma") == false)
J.estado.ouro = 1e30
local ids4 = J.melhores_sem_party()
ok("party de 3 falha", J.criar_party({ ids4[1], ids4[2], ids4[3] }) == false)
ok("party de 4", J.criar_party(ids4))
ok("sem party dobrada", J.criar_party(ids4) == false)
ok("party aumenta poder", J.poder(c1) > p0)
J.atualizar(0.1)
local sem_missao = 0
for _, c in ipairs(J.estado.contratados) do if c.em_missao then sem_missao = sem_missao + 1 end end
ok("party parte junta", sem_missao == 0 or sem_missao == 4, sem_missao)
ok("desfazer party", J.desfazer_party(J.estado.parties[1].id) and c1.party == nil)
ok("herói exige rank A", J.promover(c1) == false)

-- Salvar e carregar ------------------------------------------------------------------------------
novo()
libera("prateleira", "mercadinho", "jardim", "recrutador")
J.estado.ouro = 1e7
J.contratar()
for _ = 1, 300 do J.atualizar(0.1) end
J.salvar()
local ouro_salvo, nos_salvos, n_contr = J.estado.ouro, J.nivel("prateleira"), #J.estado.contratados
iniciar()
ok("carrega ouro", J.estado.ouro == ouro_salvo)
ok("carrega nós", J.nivel("prateleira") == nos_salvos)
ok("carrega contratados", #J.estado.contratados == n_contr)
ok("efeitos valem após carregar", J.mercadinho_aberto())
quadros(50)
ok("lugares reconstruídos após carregar", #J.lugares >= 2)

for nome, lixo in pairs({
  vazio = "", texto = "isto não é um save", codigo = "os.exit(1)",
  versao = "{ [\"versao\"] = 1, [\"ouro\"] = 5 }",
  nan = "{ [\"versao\"] = 2, [\"ouro\"] = 0/0, [\"missoes\"] = { 7 } }",
  no_ruim = "{ [\"versao\"] = 2, [\"nos\"] = { [\"xx\"] = 3, [\"mesa\"] = 999 } }",
  contr = "{ [\"versao\"] = 2, [\"missoes\"] = { { [\"rank\"] = 99, [\"resta\"] = 1 } } }",
}) do
  motor._save = lixo
  local bom = pcall(function() iniciar(); quadros(5) end)
  ok("save estragado não quebra: " .. nome, bom)
end
motor._save = "{ [\"versao\"] = 2, [\"nos\"] = { [\"mesa\"] = 999 } }"
iniciar()
ok("nível acima do máximo é corrigido", J.nivel("mesa") == A.POR_ID.mesa.max)
motor._save = "{ [\"versao\"] = 2, [\"ouro\"] = 0/0 }"
iniciar()
ok("ouro inválido vira 0", J.estado.ouro == 0)

-- Tempo fora ------------------------------------------------------------------------------------
novo()
libera("garcom")
J.estado.rps = 10
J.estado.salvo_em = os.time() - 100000
local txt = util.serializar(J.estado)
motor._save = txt
local salvar_original = motor.salvar
iniciar()
ok("oferta ao voltar", J.offline ~= nil)
if J.offline then ok("limite de 8 h", J.offline.ganho <= 10 * C.offline_maximo * C.offline_eficiencia) end
desenhar()
local og = J.estado.ouro
ok("botão coletar existe", U.apertar("coletar"))
ok("coletar paga", J.estado.ouro > og and not J.offline)
motor.salvar = salvar_original

-- Interface: aperta todos os botões de todas as telas --------------------------------------------
novo()
J.estado.ouro = 1e60
do
  local prog = true
  while prog do
    prog = false
    for _, no in ipairs(A.NOS) do
      while not J.no_maximo(no) and J.comprar_no(no.id) do prog = true; J.estado.ouro = 1e60 end
    end
  end
end
for _ = 1, 8 do J.contratar() end
for _ = 1, 4 do J.invocar() end
for _, id in ipairs({ "taverna", "arvore", "missoes", "mercadinho", "producao", "aventureiros", "invocacao" }) do
  T.aba = id
  T.arv.sel = "mesa"
  atualizar(0.1)
  desenhar()
  ok("aba desenha: " .. id, #U.zonas > 0)
  local nomes = {}
  for _, z in ipairs(U.zonas) do nomes[#nomes + 1] = z end
  for _, z in ipairs(nomes) do
    if not (z.id == "config" or z.id == "minimizar" or z.id:find("^aba_")) and z.fn then
      local bom, erro = pcall(z.fn)
      ok("botão " .. id .. "/" .. z.id, bom, erro)
    end
    atualizar(0.05)
    desenhar()
    if J.estado.fim then break end
  end
end

novo()
for _, m in ipairs({ "config", "stats", "creditos" }) do
  T.modal = m
  desenhar()
  ok("janela desenha: " .. m, #U.zonas > 0)
end
T.modal = "config"
desenhar()
for _, id in ipairs({ "musica_menos", "musica_mais", "efeitos_menos", "efeitos_mais", "tela_cheia", "sombras", "mostrar_fps", "minimizar2" }) do
  ok("config: " .. id, U.apertar(id)); desenhar()
end
for _ = 1, 20 do U.apertar("musica_mais"); desenhar() end
ok("volume não passa de 1", J.estado.opcoes.musica <= 1)
for _ = 1, 20 do U.apertar("musica_menos"); desenhar() end
ok("volume não fica negativo", J.estado.opcoes.musica >= 0)
-- apagar pede confirmação
J.estado.ouro = 500
U.apertar("apagar"); desenhar()
ok("apagar pede confirmação", J.estado.ouro == 500 and T.confirmar)
U.apertar("apagar_nao"); desenhar()
ok("não apagou", J.estado.ouro == 500)
U.apertar("apagar"); desenhar()
U.apertar("apagar_sim"); desenhar()
ok("apagou", J.estado.ouro == 0)
-- modal bloqueia o que está atrás
T.iniciar(); T.modal = "config"; desenhar()
local serv = J.estado.servidos
for _, pp in ipairs(J.pessoas) do pp.estado = "esperando" end
T.tocar(30, 300)
ok("modal bloqueia a taverna", J.estado.servidos == serv)
T.modal = nil
-- esc
T.iniciar(); T.esc(); ok("esc abre config", T.modal == "config"); T.esc(); ok("esc fecha", T.modal == nil)
-- toques em qualquer lugar nunca quebram
novo()
for i = 1, 600 do
  local x, y = math.random(0, 960), math.random(0, 540)
  if not (util.dentro(x, y, { x = 852, y = 10, w = 96, h = 44 })) then
    local z = U.achar(x, y)
    if not (z and (z.id == "apagar_sim" or z.id == "sair" or z.id == "final_sair")) then
      local bom, erro = pcall(function() tocar(x, y); soltar(x, y) end)
      ok("toque aleatório", bom, erro)
    end
  end
  atualizar(0.05); desenhar()
end

-- Números enormes
novo()
J.estado.ouro = 1e100
for _, id in ipairs({ "taverna", "arvore" }) do T.aba = id; quadros(2) end
ok("formatar número enorme", type(util.formatar(1e100)) == "string")

-- Jogo completo: robô chega ao final ---------------------------------------------------------------
if arg[3] ~= "rapido" then
  novo()
  local R = require("robo")
  local t = R.jogar(80, 0.25, { "garcom", "prateleira", "mercadinho", "jardim", "cozinheiro", "venda", "recrutador", "party", "heroi", "propaganda", "invocacao" })
  ok("robô derrota o Lorde Demônio", J.estado.fim, string.format("após %.1f h, ouro %s, %s", t / 3600, util.formatar(J.estado.ouro), J.objetivo()))
  print(string.format("  tempo do robô até o final: %.1f horas", t / 3600))
  T.iniciar(); T.aba = "taverna"
  desenhar()
  ok("tela final tem botão", U.apertar("final_sair") ~= nil)
end

print(string.format("semente %d: %d testes, %d falhas", semente, total, falhas))
os.exit(falhas == 0 and 0 or 1)
