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

J_sem = require("jogo")
J_sem.sem_noticias = true   -- as notícias pausam o jogo: têm teste próprio mais abaixo

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
ok("999.999 não vira 1000 mil", util.formatar(999999) == "1 mi", util.formatar(999999))
ok("9.999", util.formatar(9999) == "9.999", util.formatar(9999))

ok("arquivo com laço infinito não trava", util.desserializar("(function() while true do end end)()") == nil)

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

-- Regressões: gente, lugares, saves, tempo fora e toques -------------------------------------------
local function tudo_comprado()
  novo()
  local prog = true
  while prog do
    prog = false
    for _, no in ipairs(A.NOS) do
      J.estado.ouro = 1e60
      if not J.no_maximo(no) and J.comprar_no(no.id) then prog = true end
    end
  end
  J.estado.ouro = 1e60
end
local function tipo_nome(n)
  for _, t in ipairs(J.TIPOS) do if t.nome == n then return t end end
end
local function sentar(t, l)
  local p = { x = l.x, z = l.z, y = 0.42, giro = 0, fase = 0, t = 0, tipo = t, pele = "#ffffff", rota = {}, estado = "esperando", sentado = true, lugar = l, pedido = "bebida" }
  l.dono = p
  J.pessoas[#J.pessoas + 1] = p
  return p
end

-- comprar mesa depois do balcão embaralhava quem estava sentado
novo()
libera("balcao")
do
  local banco
  for _, l in ipairs(J.lugares) do if l.balcao then banco = l; break end end
  local p = sentar(tipo_nome("comum"), banco)
  local x, z = banco.x, banco.z
  J.estado.ouro = 1e9
  J.comprar_no("mesa")
  ok("sentado continua no próprio lugar ao abrir mesa", p.lugar.x == x and p.lugar.z == z and p.lugar.dono == p)
  local donos = 0
  for _, l in ipairs(J.lugares) do if l.dono then donos = donos + 1 end end
  ok("sem lugar fantasma ao abrir mesa", donos == 1, donos)
end

-- rodada longa com tudo aberto: ninguém fica preso em lugar, reserva ou briga
tudo_comprado()
for _ = 1, 8 do J.contratar(); J.estado.ouro = 1e60 end
do
  local presos
  local function conferir(rotulo)
    local vivos = {}
    for _, p in ipairs(J.pessoas) do vivos[p] = true end
    for _, l in ipairs(J.lugares) do
      if l.dono then
        ok("lugar com dono vivo " .. rotulo, vivos[l.dono] and l.dono.lugar == l)
      end
    end
    local alvos = {}
    for _, g in ipairs(J.garcons) do if g.alvo then alvos[g.alvo] = true end end
    for _, p in ipairs(J.pessoas) do
      if p.reservado then ok("reserva tem garçom " .. rotulo, alvos[p]) end
      if p.estado == "brigando" then ok("briga dura pouco " .. rotulo, p.t <= C.briga_espera + 1, p.t) end
      if p.estado == "esperando" then ok("espera dura pouco " .. rotulo, p.t <= J.paciencia() + 1, p.t) end
      if p.lugar then ok("quem tem lugar é dono dele " .. rotulo, p.lugar.dono == p) end
    end
  end
  for i = 1, 3000 do
    J.atualizar(0.25)
    if i % 50 == 0 then conferir("na rodada") end
    if i == 1500 then
      J.salvar(); iniciar()
      local tot = 0
      for _, c in ipairs(J.estado.contratados) do if c.em_missao then tot = tot + 1 end end
      ok("contratados continuam em missão após carregar", tot > 0, tot)
    end
  end
  -- nenhum contratado fica parado na taverna sem motivo
  for _, c in ipairs(J.estado.contratados) do ok("contratado segue trabalhando: " .. c.nome, c.em_missao ~= nil or c.party) end
end

-- saves com partes estragadas não quebram nem prendem ninguém
for nome, lixo in pairs({
  missoes_numero = '{ ["versao"] = 2, ["missoes"] = 7 }',
  contratados_numero = '{ ["versao"] = 2, ["contratados"] = 7, ["parties"] = 3 }',
  contratado_ruim = '{ ["versao"] = 2, ["contratados"] = { 5, { ["id"] = 1 }, { ["id"] = 2, ["tipo"] = "mago" } } }',
  textos = '{ ["versao"] = 2, ["tempo"] = "x", ["ouro"] = "y", ["final_resta"] = "z", ["salvo_em"] = "w", ["opcoes"] = 3, ["feitas_rank"] = { "a" } }',
  no_texto = '{ ["versao"] = 2, ["nos"] = { ["mesa"] = "x", ["garcom"] = -2 } }',
}) do
  motor._save = lixo
  local bom, erro = pcall(function()
    iniciar()
    T.aba = "aventureiros"; quadros(3)
    J.estado.ouro = 5; T.aba = "taverna"; quadros(3)
  end)
  ok("save estragado não quebra: " .. nome, bom, erro)
end
motor._save = '{ ["versao"] = 2, ["nos"] = { ["prateleira"] = 1, ["recrutador"] = 1 }, ["contratados"] = { { ["id"] = 1, ["tipo"] = "mago", ["party"] = 9 } }, ["parties"] = { { ["id"] = 9, ["membros"] = { 1, 2, 3, 4 } } } }'
iniciar()
J.atualizar(0.1)
ok("party incompleta não prende o membro", J.estado.contratados[1].em_missao == true and #J.estado.parties == 0)
motor._save = '{ ["versao"] = 2, ["final_resta"] = 1e30, ["missoes"] = { { ["rank"] = 1, ["resta"] = 1e30 }, { ["rank"] = 1, ["resta"] = -5, ["contratado"] = 40 } } }'
iniciar()
ok("final e missão não ficam eternos", J.estado.final_resta <= C.sss.duracao and J.estado.missoes[1].resta <= C.ranks[1].duracao and #J.estado.missoes == 1)
-- número inválido em um campo não pode perder o save inteiro
novo()
J.estado.ouro = 777
J.estado.fama = -1 / 0
J.salvar()
iniciar()
ok("campo infinito não perde o save", J.estado.ouro == 777 and J.estado.fama == 0, J.estado.ouro)
-- início que falha não pode gravar por cima do progresso
novo()
J.estado.ouro = 777
J.salvar()
do
  local guardado, carregar = motor._save, motor.carregar
  motor.carregar = function() error("falha simulada") end
  ok("início falha", not pcall(iniciar))
  motor.carregar = carregar
  pcall(ao_sair)
  ok("início que falhou não apaga o save", motor._save == guardado)
  iniciar()
end

-- final com tempo fora e depois de carregar
tudo_comprado()
for _ = 1, 4 do J.invocar(); J.estado.ouro = 1e60 end
ok("party final", J.formar_party_final())
for _, c in ipairs(J.estado.contratados) do
  if c.invocado then for _ = 1, 60 do J.investir(c, "magia"); J.estado.ouro = 1e60 end end
end
ok("final começa", J.iniciar_final())
J.salvar()
iniciar()
ok("final continua após carregar", J.estado.final_resta ~= nil and not J.estado.fim)
for _, id in ipairs(J.party_final().membros) do ok("membro segue na final", J.contratado_por_id(id).na_final) end
J.estado.salvo_em = os.time() - 100000
J.estado.rps = 10
motor._save = util.serializar(J.estado)
iniciar()
ok("tempo fora não termina a final sozinho", J.estado.final_resta == 1 and not J.estado.fim, J.estado.final_resta)
J.coletar_offline()
for _ = 1, 30 do J.atualizar(0.1) end
ok("final termina depois de voltar", J.estado.fim)
for _, c in ipairs(J.estado.contratados) do ok("ninguém preso na final", not c.na_final) end
J.salvar()
iniciar()
T.iniciar()
ok("final continua ganho ao carregar", J.estado.fim and not J.offline)
-- a tela final congela o mundo e não deixa tocar no que está atrás
do
  local e = J.estado
  local ouro, tempo = e.total, e.tempo
  for _ = 1, 400 do J.atualizar(0.25) end
  ok("nada corre atrás da tela final", e.total == ouro and e.tempo == tempo)
  local p = sentar(tipo_nome("comum"), J.lugares[1])
  T.aba = "taverna"; desenhar()
  local serv = e.servidos
  local x, y = require("mundo").posicao_balao(p)
  T.tocar(x, y); T.soltar(x, y)
  ok("toque na tela final não serve", e.servidos == serv and p.estado == "esperando")
  U.limpar()
  T.tocar(x, y); T.soltar(x, y)
  ok("nem no quadro em que o final aparece", e.servidos == serv)
  desenhar()
  local mundo = require("mundo")
  mundo.zoom_alvo = 1
  motor._roda = 5; T.atualizar(0.1)
  ok("roda não mexe atrás da tela final", mundo.zoom_alvo == 1)
  ok("jogar de novo", U.apertar("novo_jogo"))
  ok("recomeça do zero", J.estado.fim == false and J.estado.ouro == 0 and #J.estado.contratados == 0 and #J.garcons == 0 and J.fofoca_conta == 0)
  desenhar(); atualizar(0.1)
  ok("recomeço fica salvo vazio", motor._save == "")
end

-- janela aberta: arrastar não rola nem move o que está atrás
tudo_comprado()
for _ = 1, 16 do J.contratar(); J.estado.ouro = 1e60 end
T.aba = "aventureiros"; desenhar()
T.modal = "config"; desenhar()
T.rolagem.aventureiros = 40
T.tocar(20, 300)
motor._baixo = true; motor._mouse = { 20, 200 }
T.atualizar(0.1)
ok("arrastar não rola atrás da janela", T.rolagem.aventureiros == 40, T.rolagem.aventureiros)
motor._baixo = false; motor._mouse = { 480, 270 }
T.soltar(20, 200)
T.modal = nil

-- botões da lista rolável: tocar de verdade funciona; arrastar rola sem comprar
T.rolagem.aventureiros = 0
atualizar(0.05); desenhar()
ok("lista tem o que rolar", T.limite_rolagem > 0)
do
  local c = J.estado.contratados[1]
  local z
  for _, q in ipairs(U.zonas) do if q.id == "investir_" .. c.id .. "_arma" then z = q end end
  ok("botão visível existe", z ~= nil)
  local x, y = z.x + 5, z.y + 5
  ok("toque encontra o botão, não uma área por cima", U.achar(x, y) == z, U.achar(x, y) and U.achar(x, y).id)
  local nv = c.arma
  T.tocar(x, y); T.soltar(x, y)
  ok("tocar no botão da lista compra", c.arma == nv + 1, c.arma)
  desenhar()
  nv = c.arma
  T.tocar(x, y)
  motor._baixo = true; motor._mouse = { x, y - 60 }
  T.atualizar(0.05)
  motor._baixo = false
  T.soltar(x, y - 60)
  motor._mouse = { 480, 270 }
  ok("arrastar sobre o botão só rola", c.arma == nv and T.rolagem.aventureiros > 0, c.arma)
  -- com a lista rolada, cada botão vivo está inteiro na lista e não tapa os de cima
  for _, ro in ipairs({ 13, 37, 70, 90, 155 }) do
    T.rolagem.aventureiros = ro
    desenhar()
    for _, q in ipairs(U.zonas) do
      if q.id:find("^investir_") then ok("botão cortado não fica tocável", q.y >= 148 and q.y + q.h <= 470, q.y) end
    end
    local q = U.achar(100, 130)
    ok("Contratar não é tapado pela lista", q and q.id == "contratar", q and q.id)
  end
  T.rolagem.aventureiros = 0
end

-- árvore: nó cortado pela borda não recebe toque atrás do ouro nem das abas
novo()
T.aba = "arvore"; desenhar()
do
  T.arv.manual = true
  T.arv.y = -268 - A.POR_ID.mesa.y * T.arv.zoom + 20  -- nó "mesa" acima da área
  T.arv.x = -A.POR_ID.mesa.x * T.arv.zoom - 480 + 130
  desenhar()
  local q = U.achar(130, 20)
  ok("nó fora da área não é tocável", not (q and q.id == "no_mesa"), q and q.id)
end
T.aba = "taverna"

-- party final funciona mesmo com invocado em outra party
tudo_comprado()
for _ = 1, 4 do J.contratar(); J.estado.ouro = 1e60 end
for _ = 1, 3 do J.invocar(); J.estado.ouro = 1e60 end
ok("party mista", J.criar_party(J.melhores_sem_party()))
for _ = 1, 8 do J.contratar(); J.estado.ouro = 1e60 end
J.invocar(); J.estado.ouro = 1e60
T.aba = "invocacao"; desenhar()
ok("botão da party final", U.apertar("party_final"))
ok("party final reúne os 4 invocados", J.party_final() ~= nil)
for _, c in ipairs(J.estado.contratados) do
  if not c.invocado then ok("os outros não ficam presos", not c.party or J.party_final().id ~= c.party) end
end
T.aba = "taverna"

-- contratado mantém a mesma aparência (o círculo pisca se sortear a cada quadro)
do
  local t = J.TIPOS_POR_NOME("guerreiro")
  local igual = true
  for _ = 1, 50 do igual = igual and J.TIPOS_POR_NOME("guerreiro") == t end
  ok("mesmo visual a cada quadro", igual)
end

-- mercadinho nunca fica fora da ala, nem em save antigo
novo()
libera("prateleira", "mercadinho")
do
  local mundo = require("mundo")
  ok("mercadinho abre a ala", mundo.alvos().leste == 1)
  motor._save = '{ ["versao"] = 2, ["nos"] = { ["merc_e"] = 1 } }'
  iniciar()
  ok("save sem a ala ainda mostra a barraca", J.mercadinho_aberto() and mundo.alvos().leste == 1)
end

-- tempo fora: missões não ficam negativas, ganho não vira renda e sair sem coletar não perde
novo()
libera("garcom", "prateleira")
J.estado.missoes = { { rank = 1, resta = 5 } }
J.estado.rps = 10
J.estado.salvo_em = os.time() - 5000
motor._save = util.serializar(J.estado)
iniciar()
ok("oferta com missão", J.offline ~= nil)
ok("missão fora não fica negativa", J.estado.missoes[1].resta == 0, J.estado.missoes[1].resta)
do
  local ganho = J.offline.ganho
  local ouro = J.estado.ouro
  ao_sair()
  ok("sair sem coletar não perde o ouro", J.estado.ouro == ouro + ganho and not J.offline)
  iniciar()
  ok("ganho continua após recarregar", J.estado.ouro == ouro + ganho and not J.offline)
  ok("missão fora paga só uma vez", J.estado.missoes[1] ~= nil)
  local feitas, antes = J.estado.feitas, J.estado.total
  J.atualizar(0.1)
  ok("missão conclui uma vez", J.estado.feitas == feitas + 1, J.estado.feitas)
end
novo()
libera("garcom")
J.estado.rps = 10
J.estado.salvo_em = os.time() - 100000
motor._save = util.serializar(J.estado)
iniciar()
J.coletar_offline()
for _ = 1, 15 do J.atualizar(0.1) end
ok("coletar não infla o ouro por segundo", J.estado.rps < 50, J.estado.rps)

-- recarga: salva, recomeça do save e continua
novo()
libera("garcom", "prateleira", "balcao")
for _ = 1, 400 do J.atualizar(0.1) end
do
  local nm, total = #J.estado.missoes, J.estado.total
  ao_sair()
  iniciar()
  ok("recarga mantém ouro e missões", J.estado.total == total and #J.estado.missoes == nm and not J.offline)
  ok("recarga refaz equipe e lugares", #J.garcons == 1 and #J.lugares == 8, #J.lugares)
  quadros(20)
end

-- Números enormes
novo()
J.estado.ouro = 1e100
for _, id in ipairs({ "taverna", "arvore" }) do T.aba = id; quadros(2) end
ok("formatar número enorme", type(util.formatar(1e100)) == "string")

-- Colisões: bonecos não se atravessam nem atravessam mesas ---------------------------------------
do
  local Cam = require("caminhos")
  local L = require("layout")
  motor._layout = false
  novo()
  libera("prateleira", "balcao", "garcom", "garcom", "garcom", "mesa", "mesa", "mesa", "mesa", "vagas", "vagas", "vagas", "vagas", "vagas", "placa", "placa", "placa", "placa", "placa", "placa")
  local passos, encostos, dentro_mesa, andando = 0, 0, 0, 0
  for _ = 1, 3000 do
    J.atualizar(0.1)
    local lista = {}
    for _, p in ipairs(J.pessoas) do lista[#lista + 1] = p end
    for _, g in ipairs(J.garcons) do lista[#lista + 1] = g end
    for i = 1, #lista do
      local p = lista[i]
      if p.andando and not p.fantasma then
        andando = andando + 1
        for k = 1, J.num_mesas() do
          local m = J.POS_MESAS[k]
          if util.distancia(p.x, p.z, m.x, m.z) < 0.72 then dentro_mesa = dentro_mesa + 1 end
        end
      end
      for j = i + 1, #lista do
        local q = lista[j]
        if not p.fantasma and not q.fantasma and util.distancia(p.x, p.z, q.x, q.z) < Cam.DISTANCIA * 0.55 then
          encostos = encostos + 1
        end
      end
    end
    passos = passos + 1
  end
  ok("ninguém anda por dentro de mesa", dentro_mesa == 0, dentro_mesa)
  ok("bonecos quase nunca se sobrepõem", encostos <= passos * 0.02, encostos .. " em " .. passos)
  ok("todos acham caminho", (J.sem_caminho or 0) == 0, J.sem_caminho)
  ok("pouquíssimos pedidos de socorro", (J.socorros or 0) <= 30, J.socorros)
  ok("taverna continua servindo", J.estado.servidos > 50, J.estado.servidos)
  ok("missões continuam concluindo", J.estado.feitas > 10, J.estado.feitas)

  -- pegar missão: vai ao quadro, pega o papel e sai com ele
  novo()
  libera("prateleira")
  J.relogio_aventureiro = 99
  local viu_ida, viu_pegando, viu_papel, perto = false, false, false, false
  for _ = 1, 400 do
    J.atualizar(0.1)
    for _, p in ipairs(J.pessoas) do
      if p.estado == "indo_quadro" then viu_ida = true end
      if p.estado == "pegando" then
        viu_pegando = true
        if util.distancia(p.x, p.z, J.QUADRO.x, J.QUADRO.z) < 1.3 then perto = true end
      end
      if p.com_papel and p.estado == "saindo" then viu_papel = true end
    end
    desenhar()
  end
  ok("aventureiro vai ao quadro", viu_ida)
  ok("para no quadro para pegar", viu_pegando and perto)
  ok("sai com o papel na mão", viu_papel)

  -- editor
  novo()
  T.f2()
  ok("F2 abre o editor", require("editor").ativo)
  local Ed = require("editor")
  local o0 = J.estado.ouro
  atualizar(0.1); desenhar()
  ok("jogo pausa no editor", J.editando)
  Ed.sel = "mesa1"
  Ed.mover_para("mesa1", -2.0, 0.5)
  ok("objeto move", J.POS_MESAS[1].x == -2 and J.POS_MESAS[1].z == 0.5)
  desenhar()
  for _, z in ipairs(U.zonas) do
    if z.fn and z.id ~= "editor_sair" and z.id ~= "editor_painel" then
      local bom, erro = pcall(z.fn)
      ok("botão editor " .. z.id, bom, erro)
      atualizar(0.05); desenhar()
    end
  end
  Ed.sel = "mesa1"
  Ed.mover_para("mesa1", -2.0, 0.5)
  L.salvar()
  ok("copiar devolve texto", type(motor._copiado) == "string")
  T.esc()
  ok("esc sai do editor", not Ed.ativo and not J.editando and not J.previa)
  for _ = 1, 100 do atualizar(0.1); desenhar() end
  iniciar()
  ok("posição sobrevive a reiniciar", J.POS_MESAS[1].x == -2, J.POS_MESAS[1].x)
  local l1 = J.lugares[1]
  ok("assentos acompanham a mesa", util.distancia(l1.x, l1.z, -3.25, 0.5) < 0.01, l1.x)
  -- objeto em cima da porta não pode travar o jogo
  L.de("mesa1").x, L.de("mesa1").z = -2.8, 1.4
  J.aplicar_layout()
  for _ = 1, 400 do J.atualizar(0.1) end
  ok("mesa na porta não trava", true)
  for nome, lixo in pairs({ a = "lixo", b = "{ [\"mesa1\"] = 3 }", c = "{ [\"naoexiste\"] = { [\"x\"] = 1 } }", d = "{ [\"mesa1\"] = { [\"x\"] = 0/0 } }" }) do
    motor._layout = lixo
    local bom = pcall(function() iniciar(); quadros(3) end)
    ok("layout estragado não quebra: " .. nome, bom)
    ok("mesa continua em número válido", J.POS_MESAS[1].x == J.POS_MESAS[1].x)
  end

  -- Bugs achados na revisão de caminhos e editor -----------------------------------------------------
  local Ed = require("editor")
  local function tudo_comprado()
    novo()
    J.estado.ouro = 1e60
    for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e60; J.comprar_no(no.id) end end
  end
  local function mover(id, x, z, g)
    local b, d = L.POR_ID[id], L.de(id)
    d.x, d.z, d.g = x - b.x, z - b.z, g or 0
  end
  local function jogar_contando(n)
    J.sem_caminho = 0
    local dentro, perdido = 0, 0
    for _ = 1, n do
      J.atualizar(0.1)
      for _, g in ipairs(J.garcons) do
        if g.estado == "indo" and g.sem_rota and g.alvo and Cam.rota(J.PORTA.x, J.PORTA.z, g.alvo.x, g.alvo.z) then perdido = perdido + 1 end
        if g.andando and not g.fantasma then
          for k = 1, J.num_mesas() do
            local m = J.POS_MESAS[k]
            if util.distancia(g.x, g.z, m.x, m.z) < 0.72 then dentro = dentro + 1 end
          end
        end
      end
    end
    return dentro, perdido
  end

  -- banco direito da mesa 8 ficava fora do mapa: todos atravessavam as mesas 7 e 8 para chegar nele
  motor._layout = false
  tudo_comprado()
  for _, l in ipairs(J.lugares) do
    ok("dá para chegar em todo banco", Cam.rota(J.PORTA.x, J.PORTA.z, l.x, l.z) ~= nil, l.x .. " " .. l.z)
  end
  jogar_contando(1500)
  ok("taverna cheia sem atalho pelas mesas", J.sem_caminho == 0, J.sem_caminho)

  -- empurrado para fora da rota, ninguém segue reto por dentro da mesa
  novo()
  libera("mesa")
  local g = { x = 2.0, z = 0.2, giro = 0, fase = 0, t = 0, estado = "saindo" }
  g.rota, g.andando, g.destino_x, g.destino_z, g.origem_x, g.origem_z = { { x = -1.6, z = 0.2 } }, true, -1.6, 0.2, 9, 9
  J.pessoas[#J.pessoas + 1] = g
  for _ = 1, 40 do
    J.atualizar(0.1)
    ok("rota refeita ao ser empurrado", util.distancia(g.x, g.z, J.POS_MESAS[2].x, J.POS_MESAS[2].z) > 0.9, g.x .. " " .. g.z)
    if g.removido then break end
  end

  -- com a mesa ou o balcão girados, o garçom parava dentro do móvel
  for _, caso in ipairs({ { "mesas a 90", function() for i = 1, 8 do L.de("mesa" .. i).g = math.pi / 2 end end, sem_rota = true },
                          { "balcão a 180", function() L.de("balcao").g = math.pi end, sem_rota = true },
                          { "mesa 1 a 90", function() L.de("mesa1").g = math.pi / 2 end },
                          { "mesas a 45", function() for i = 1, 8 do L.de("mesa" .. i).g = math.pi / 4 end end } }) do
    motor._layout = false
    tudo_comprado()
    caso[2]()
    J.aplicar_layout()
    local dentro, perdido = jogar_contando(1200)
    -- sem nenhum caminho livre o atalho é permitido: ao sair dele sobra no máximo um passo de borda
    ok("garçom não entra no móvel: " .. caso[1], dentro <= (caso.sem_rota and 5 or 0), dentro)
    if caso.sem_rota then
      ok("aviso de lugar sem caminho: " .. caso[1], J.lugares_sem_rota() > 0)
    else
      ok("garçom acha onde servir: " .. caso[1], perdido == 0, perdido)
    end
      ok("girar não derruba o serviço: " .. caso[1], J.estado.servidos > 50, J.estado.servidos)
  end

  -- quem não tem rota continua atravessando até chegar, mesmo tendo andado
  motor._layout = false
  novo()
  libera("mesa")
  mover("mesa1", -5.6, 1.6)
  J.aplicar_layout()
  -- o banco colado na porta tem caminho; o que importa é quem precisa atravessar a mesa
  local p
  for _ = 1, 4 do
    local c = J.novo_cliente()
    if c and c.lugar.x > -5.5 then p = c end
  end
  ok("mesa na porta: sem rota vira atalho", p and p.fantasma == true)
  for _ = 1, 25 do J.atualizar(0.1) end
  if p and p.estado == "entrando" then ok("atalho dura até chegar", p.fantasma == true) end

  -- garçons empurrando uns aos outros no mesmo ponto tremiam para sempre, sem pedir socorro
  motor._layout = false
  tudo_comprado()
  for i = 1, 8 do mover("mesa" .. i, 0, 0) end
  J.aplicar_layout()
  local parado = {}
  local pior = 0
  for _ = 1, 1500 do
    J.atualizar(0.1)
    for _, g in ipairs(J.garcons) do
      local k = parado[g] or { x = g.x, z = g.z, t = 0 }
      parado[g] = k
      if g.estado ~= "parada" and util.distancia(g.x, g.z, k.x, k.z) < 0.5 then
        k.t = k.t + 0.1
        pior = math.max(pior, k.t)
      else
        k.x, k.z, k.t = g.x, g.z, 0
      end
    end
  end
  ok("garçom amontoado é socorrido", pior < 20, pior)

  -- garçom que volta do editor não fica atravessando tudo
  novo()
  libera("garcom")
  J.garcons[1].fantasma = true
  J.aplicar_layout()
  ok("editor limpa o atalho do garçom", not J.garcons[1].fantasma)

  -- um clique sem arrastar só seleciona: o encaixe na grade movia o objeto
  motor._layout = false
  novo()
  Ed.abrir()
  local bm = L.POR_ID.mesa1
  local sx, sy = motor.projetar(bm.x, 0.3, bm.z)
  motor._mouse = { sx, sy }
  motor._baixo = true
  Ed.tocar(sx, sy)
  for _ = 1, 5 do Ed.atualizar(0.1) end
  motor._baixo = false
  Ed.soltar()
  ok("clique seleciona", Ed.sel == "mesa1")
  ok("clique não move", L.de("mesa1").x == 0 and L.de("mesa1").z == 0, L.de("mesa1").x)
  ok("clique não enche o desfazer", #Ed.desfazer == 0, #Ed.desfazer)
  -- arrastar de verdade move; soltar fora da janela não deixa o arrasto preso
  motor._baixo = true
  Ed.tocar(sx, sy)
  motor._mouse = { sx + 60, sy + 26 }
  Ed.atualizar(0.1)
  ok("arrastar move", L.de("mesa1").x ~= 0)
  motor._baixo = false
  Ed.atualizar(0.1)
  ok("soltar fora da janela encerra o arrasto", Ed.arrasto == nil)
  ok("arrasto vira um desfazer", #Ed.desfazer == 1, #Ed.desfazer)
  motor._mouse = { 480, 270 }
  -- soltar longe de tudo não joga o objeto para fora do mundo
  Ed.mover_para("mesa1", 500, -500)
  ok("arraste para fora fica na área", J.POS_MESAS[1].x <= 13.01 and J.POS_MESAS[1].z >= -5, J.POS_MESAS[1].x)
  Ed.mover_para("jardim", 3, 9)
  ok("jardim pode continuar lá fora", L.de("jardim").z + L.POR_ID.jardim.z == 9)
  Ed.fechar()
  motor._layout = false

  -- abrir e fechar o editor não congela as posições oficiais neste computador
  novo()
  T.f2(); T.f2()
  ok("editor sem edição não fixa o padrão", not tostring(motor._layout):find("balcao"), motor._layout)
  T.f2()
  Ed.sel = "mesa2"
  Ed.mover_para("mesa2", 1.5, -0.5)
  Ed.fechar()
  ok("edição continua salva", tostring(motor._layout):find("mesa2") ~= nil)
  T.f2()
  Ed.sel = "mesa2"
  L.restaurar("mesa2")
  Ed.fechar()
  ok("restaurar tira do arquivo", not tostring(motor._layout):find("mesa2"), motor._layout)
  motor._layout = false

  -- layout salvo com números válidos porém absurdos: a porta longe deixava todos andando por minutos
  motor._layout = '{ ["porta"] = { ["x"] = 900, ["z"] = 900 }, ["mesa1"] = { ["x"] = -900, ["z"] = 900, ["y"] = 900 } }'
  novo()
  ok("layout absurdo volta para a área", J.PORTA.x <= 13 and J.PORTA.z <= 5.25, J.PORTA.x)
  ok("mesa absurda volta para a área", J.POS_MESAS[1].x >= -7 and L.de("mesa1").y <= 6, J.POS_MESAS[1].x)
  motor._layout = false

  -- botão das Configurações passava por cima da regra do F2 na tela final
  novo()
  J.estado.fim = true
  T.modal = "config"
  desenhar()
  ok("final: Configurações tem o botão", U.apertar("editar") ~= nil)
  ok("final: botão não abre o editor", not Ed.ativo and not J.previa)
  T.f2()
  ok("final: F2 não abre o editor", not Ed.ativo)
  J.estado.fim = false
  T.modal = nil
  J.offline = { ganho = 10, segundos = 100 }
  T.f2()
  ok("tempo fora: F2 não abre o editor", not Ed.ativo)
  J.offline = nil
  T.modal = "stats"
  T.f2()
  ok("F2 com janela aberta fecha a janela", Ed.ativo and T.modal == nil)
  Ed.fechar()

  -- a prévia mostra tudo aberto, mas nada disso vaza para as regras ou para o save
  novo()
  libera("garcom")
  local antes = util.serializar(J.estado)
  local lugares, mesas = #J.lugares, J.num_mesas()
  T.f2()
  ok("prévia mostra tudo", J.num_mesas() == 8 and J.mercadinho_aberto())
  for _ = 1, 20 do atualizar(0.1); desenhar() end
  ao_sair()
  ok("sair na prévia não muda o save", util.desserializar(motor._save).nos.mercadinho == nil and util.desserializar(motor._save).nos.quartos == nil)
  T.f2()
  ok("prévia acabou", not J.previa and not J.editando and J.num_mesas() == mesas and not J.mercadinho_aberto())
  ok("lugares voltam ao real", #J.lugares == lugares, #J.lugares)
  ok("ala fechada continua bloqueada", Cam.bloqueado(8, 0))
  local depois = util.desserializar(util.serializar(J.estado))
  depois.salvo_em = nil
  local ref = util.desserializar(antes)
  ref.salvo_em = nil
  ok("estado igual depois da prévia", util.serializar(depois) == util.serializar(ref))

  -- o nome do rank aparece para contratados e na batalha final
  novo()
  J.estado.ouro = 1e60
  for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e60; J.comprar_no(no.id) end end
  J.pessoas = {}
  J.contratar()
  J.mandar_contratados()
  local viu = nil
  for _, q in ipairs(J.pessoas) do if q.contratado then viu = q end end
  ok("contratado leva rank da missão", viu and type(viu.rank_missao) == "string", viu and viu.rank_missao)
  for _ = 1, 150 do
    J.atualizar(0.1)
    desenhar()
    if viu and viu.com_papel then break end
  end
  ok("contratado pega o papel", viu and viu.com_papel)
  motor._layout = false
  novo()
end

-- Notícias, menestrel, personagens novos, tamanho -----------------------------------------------
do
  local L = require("layout")
  local Ed = require("editor")
  motor._layout = false
  J.sem_noticias = false
  novo()
  J.estado.ouro = 25
  local tempo0 = J.estado.tempo
  J.atualizar(1)
  ok("notícia aparece ao poder comprar", J.noticia ~= nil)
  ok("notícia é a da mesa", J.noticia and J.noticia.id == "mesa", J.noticia and J.noticia.id)
  local t1 = J.estado.tempo
  J.atualizar(1)
  ok("notícia pausa o jogo", J.estado.tempo == t1)
  desenhar()
  ok("liberar compra", U.apertar("noticia_abrir") and J.nivel("mesa") == 1 and J.noticia == nil)
  J.estado.ouro = 25
  J.atualizar(1)
  ok("mesma notícia não repete", not (J.noticia and J.noticia.id == "mesa"))
  J.noticia = nil
  novo()
  J.estado.ouro = 25
  J.atualizar(1)
  desenhar()
  ok("depois fecha sem comprar", U.apertar("noticia_depois") and J.noticia == nil and J.nivel("mesa") == 0)
  J.salvar()
  iniciar()
  J.estado.ouro = 25
  J.atualizar(1)
  ok("notícia vista fica salva", not (J.noticia and J.noticia.id == "mesa"))
  for _, n in ipairs(J.NOTICIAS) do ok("notícia aponta para nó real: " .. n.id, A.POR_ID[n.id] ~= nil) end
  J.sem_noticias = true

  novo()
  libera("prateleira")
  J.fofoca_conta = C.fofoca_a_cada - 1
  J.estado.missoes = { { rank = 1, resta = 0.01 } }
  J.atualizar(0.1)
  local men
  for _, p in ipairs(J.pessoas) do if p.menestrel then men = p end end
  ok("menestrel entra na taverna", men ~= nil)
  ok("sem bônus antes de cantar", J.buff <= 0, J.buff)
  local p0 = J.pagamento_rank(1)
  local cantou, viu_banner = false, false
  for _ = 1, 400 do
    atualizar(0.1); desenhar()
    if men.estado == "menestrel_canta" then cantou = true end
    if J.banner then viu_banner = true end
    if cantou and J.buff > 0 then
      ok("bônus vale durante a história", J.pagamento_rank(1) > p0)
      break
    end
  end
  ok("menestrel canta", cantou)
  ok("banner aparece", viu_banner)
  for _ = 1, 400 do atualizar(0.1) end
  local ainda = false
  for _, p in ipairs(J.pessoas) do if p.menestrel then ainda = true end end
  ok("menestrel vai embora", not ainda)

  novo()
  libera("fazendeiro")
  ok("fazendeiro existe e rende mais", J.ef("fazendeiro") == 1 and J.por_colheita() > 2 * C.colheita)
  libera("canteiro")
  quadros(40)
  libera("cervejaria"); quadros(5)

  -- todo objeto do editor está na lista e os pais existem
  for _, o in ipairs(L.OBJETOS) do
    ok("categoria existe: " .. o.id, (function() for _, c in ipairs(L.CATEGORIAS) do if c == o.cat then return true end end end)())
    if o.pai and o.pai:sub(1, 1) ~= "@" then ok("pai existe: " .. o.id, L.POR_ID[o.pai] ~= nil) end
  end

  -- tamanho
  novo()
  T.f2(); atualizar(0.1); desenhar()
  for _ = 1, 45 do L.mudar_tamanho("dir", 1) end
  ok("tamanho tem limite", L.tamanho.dir == L.TAMANHO_MAX)
  L.mudar_tamanho("dir", -100)
  ok("tamanho não fica negativo", L.tamanho.dir == 0)
  L.mudar_tamanho("dir", 10); L.mudar_tamanho("frente", 6); L.mudar_tamanho("oeste", 4); L.mudar_tamanho("fundo", 3)
  J.aplicar_visual(); desenhar()
  -- a porta e o quadro acompanham as paredes; o jardim acompanha a frente
  local dx = L.desloc("porta")
  ok("porta acompanha a parede", dx == -4, dx)
  local _, dz = L.desloc("jardim")
  ok("jardim acompanha a frente", dz == 6, dz)
  local _, gz = L.desloc("garrafa1")
  ok("garrafa acompanha a prateleira", gz == -3, gz)
  -- categorias e botões do editor
  for _ = 1, #L.CATEGORIAS do
    ok("trocar categoria", U.apertar("editor_cat_prox"))
    atualizar(0.05); desenhar()
    local zonas = {}
    for _, z in ipairs(U.zonas) do zonas[#zonas + 1] = z.id end
    ok("categoria desenha", #zonas > 2)
  end
  T.esc()
  iniciar()
  ok("tamanho sobrevive a reiniciar", L.tamanho.dir == 10 and L.tamanho.frente == 6, L.tamanho.dir)
  ok("porta real acompanha", J.PORTA.x < -10, J.PORTA.x)
  libera("prateleira", "garcom", "mesa", "mesa", "mesa")
  for _ = 1, 1500 do J.atualizar(0.1) end
  ok("funciona numa taverna grande", J.estado.servidos > 5 and (J.sem_caminho or 0) == 0, J.sem_caminho)
  ok("mundo desenha grande", pcall(desenhar))
  -- mover objeto preso a uma parede depois de crescer continua no lugar pedido
  T.f2(); atualizar(0.1); desenhar()
  Ed.grade = false
  Ed.mover_para("lampiao1", 2, -6)
  local ax, az = L.desloc("lampiao1")
  ok("mover respeita a âncora", math.abs(L.POR_ID.lampiao1.x + ax - 2) < 0.01 and math.abs(L.POR_ID.lampiao1.z + az + 6) < 0.01, ax)
  U.apertar("editor_desfazer"); desenhar()
  L.restaurar()
  ok("restaurar zera o tamanho", L.tamanho.dir == 0)
  T.esc()
  L.salvar()
  motor._layout = false
  novo()
end

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
