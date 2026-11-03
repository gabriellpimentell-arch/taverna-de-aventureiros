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
require("jogo").pular_menu = true
motor._raiz = raiz

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

-- Notícias que pausam, menestrel, filhos no layout, salão grande e congestionamento --------------
do
  local L, Ed, M, Cam = require("layout"), require("editor"), require("mundo"), require("caminhos")
  local function limpa_layout() motor._layout = false; novo() end
  local function tudo()
    for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e40; J.comprar_no(no.id) end end
  end

  -- notícias -----------------------------------------------------------------
  limpa_layout()
  for _, n in ipairs(J.NOTICIAS) do ok("notícia aponta para nó que existe", A.POR_ID[n.id] ~= nil, n.id) end
  J.noticia = J.NOTICIAS[1]; J.banner = { titulo = "x", texto = "y", vida = 0, duracao = 8 }
  J.apagar_progresso(); T.iniciar()
  ok("apagar progresso limpa notícia e faixa", J.noticia == nil and J.banner == nil)

  -- a fofoca número 12 apagava notícia, faixa e o medidor de travados
  novo()
  J.noticia = nil
  J.media_travados = 5; J.travados = 2
  J.fofoca_conta = C.fofoca_a_cada - 1
  J.estado.missoes[1] = { rank = 1, resta = 0.01 }
  J.atualizar(0.1)
  ok("menestrel não zera o medidor de travados", J.fofoca_conta == 0 and J.media_travados > 4, J.media_travados)

  -- save antigo, sem o campo notícias, com muito ouro: nada de fila de janelas
  for _, ruim in ipairs({ false, "x" }) do
    J.estado.ouro = 1e12; J.estado.noticias = ruim or nil
    motor._save = util.serializar(J.estado)
    iniciar(); T.iniciar()
    J.sem_noticias = false
    local t0 = J.estado.tempo
    for _ = 1, 30 do atualizar(0.1) end
    ok("save antigo não abre notícia do que já podia comprar", J.noticia == nil and J.estado.tempo > t0, J.noticia and J.noticia.id)
    J.sem_noticias = true
    J.estado.ouro = 1e12
  end

  -- pausa: nunca trava; fecha em qualquer aba, e o editor não a perde
  novo()
  J.sem_noticias = false
  J.estado.ouro = 100
  for _ = 1, 10 do J.atualizar(0.1) end
  ok("notícia abriu", J.noticia ~= nil)
  local t0 = J.estado.tempo
  for _, aba in ipairs({ "arvore", "missoes", "mercadinho", "producao", "aventureiros", "invocacao", "taverna" }) do
    T.aba = aba; quadros(2)
    ok("notícia continua na aba " .. aba, J.noticia ~= nil and J.estado.tempo == t0)
  end
  T.aba = "arvore"; desenhar()
  local z0 = T.arv.zoom
  motor._roda = 3; atualizar(0.1)
  ok("roda não mexe atrás da notícia", T.arv.zoom == z0)
  T.aba = "taverna"; desenhar()
  T.f2(); quadros(2); T.f2(); quadros(1)
  ok("editor não perde a notícia", J.noticia ~= nil and not Ed.ativo)
  ok("notícia fecha depois do editor", U.apertar("noticia_depois") and J.noticia == nil)
  J.sem_noticias = true
  quadros(3)
  ok("jogo volta a correr", J.estado.tempo > t0)

  -- a notícia que nasce no instante do final não fica por cima da tela final
  novo()
  J.sem_noticias = false
  J.estado.ouro = 1e6; J.relogio_noticia = 0.5; J.estado.final_resta = 0.01
  J.atualizar(0.1)
  ok("fim limpa a notícia", J.estado.fim and J.noticia == nil)
  J.sem_noticias = true

  -- robô com notícias ligadas não pode ficar parado para sempre
  novo()
  J.sem_noticias = false
  require("robo").jogar(0.05, 0.25)
  ok("robô fecha as notícias e o tempo corre", J.estado.tempo > 170, J.estado.tempo)
  J.sem_noticias = true

  -- menestrel ---------------------------------------------------------------
  local function menestrel()
    for _, p in ipairs(J.pessoas) do if p.menestrel then return p end end
  end
  novo()
  J.chamar_menestrel()
  J.salvar()
  ok("menestrel não vai para o save", not motor._save:find("menestrel", 1, true) and not motor._save:find("historia", 1, true))
  J.apagar_progresso(); T.iniciar()
  ok("apagar progresso tira o menestrel", menestrel() == nil and #J.pessoas == 0)
  quadros(3)
  J.buff = 0
  J.chamar_menestrel()
  J.aplicar_layout()
  ok("aplicar layout não perde a história", menestrel() == nil and J.buff > 0, J.buff)

  -- porta lotada: ele entra mesmo assim; lugar dele em cima de uma mesa: atravessa e sai
  novo()
  libera("mesa", "mesa", "mesa")
  for _ = 1, 4 do
    local c = J.novo_cliente(); J.relogio_chegada = 0
    if c then c.x, c.z, c.rota = J.PORTA.x, J.PORTA.z, {} end
  end
  J.buff = 0
  L.de("palco").x = L.POR_ID.mesa1.x - L.POR_ID.palco.x
  J.montar_mapa()
  J.chamar_menestrel()
  local cantou
  for _ = 1, 400 do
    J.atualizar(0.1)
    local m = menestrel()
    if m and m.estado == "menestrel_canta" then cantou = true end
    if cantou and not m then break end
  end
  ok("menestrel canta e sai mesmo sem caminho", cantou and menestrel() == nil and J.buff ~= 0, J.buff)
  L.dados.palco = nil

  -- salão enorme: ele chega ao palco em vez de cantar no meio do caminho
  L.tamanho.oeste = 40
  J.aplicar_layout()
  J.chamar_menestrel()
  local m = menestrel()
  for _ = 1, 400 do
    J.atualizar(0.1)
    if m.estado == "menestrel_canta" then break end
  end
  ok("menestrel chega ao palco num salão enorme", m.estado == "menestrel_canta" and util.distancia(m.x, m.z, -1.65, 0.2) < 1.5, m.x)
  L.tamanho.oeste = 0
  J.aplicar_layout()

  -- objetos filhos ------------------------------------------------------------
  limpa_layout()
  local function perto(a, b, c, e) return math.abs(a - c) < 0.001 and math.abs(b - e) < 0.001 end
  T.f2(); quadros(1)
  Ed.sel = "balcao"
  L.de("balcao").g = math.pi / 2
  L.dados.balcao.y = 1
  local g = L.dados.balcao.g
  local x1, z1 = L.t("caneca1", 1.05, -1.98)
  local x2, z2 = L.t("balcao", 1.05, -1.98)
  ok("caneca gira junto com o balcão", perto(x1, z1, x2, z2), x1 .. "," .. x2)
  ok("filho soma o giro e a altura", math.abs(L.giro("caneca1") - g) < 0.001 and L.altura("barrilete") == 1)
  local alto
  local velho = motor.peca
  motor.peca = function(f, _, y, _, _, ey, _, _, c) if c == "#e8a33d" and ey == 0.2 and y > 2 then alto = true end end
  desenhar()
  motor.peca = velho
  ok("caneca sobe junto com o balcão", alto)
  -- arrastar o filho com o pai girado
  Ed.grade = false
  Ed.mover_para("caneca2", 2, 0)
  local dx, dz = L.desloc("caneca2")
  ok("mover filho de pai girado vai ao ponto pedido", perto(L.POR_ID.caneca2.x + dx, L.POR_ID.caneca2.z + dz, 2, 0), dx)
  -- mover o pai leva o filho
  local a0 = L.desloc("caneca2")
  L.dados.balcao.x = L.dados.balcao.x + 1
  ok("filho acompanha o pai", math.abs(L.desloc("caneca2") - a0 - 1) < 0.001)
  L.dados.balcao.y = 0
  -- desfazer e restaurar
  local giro_antes = L.dados.balcao.g
  Ed.sel = "balcao"; desenhar()
  U.apertar("editor_girar_mais"); desenhar()
  ok("giro mudou", L.dados.balcao.g ~= giro_antes)
  U.apertar("editor_desfazer"); desenhar()
  ok("desfazer devolve o giro", L.dados.balcao.g == giro_antes)
  Ed.sel = "caneca2"; desenhar()
  U.apertar("editor_restaurar"); desenhar()
  ok("restaurar um filho deixa o pai como está", L.dados.caneca2 == nil and L.dados.balcao ~= nil)
  T.esc()
  limpa_layout()

  -- layout antigo: ids que sumiram viram os novos; lixo é ignorado
  motor._layout = util.serializar({
    barris_fundo = { x = 1, z = 0.5, y = 0, g = 0 }, barris_frente = { x = 0.5, z = 0, y = 0.2, g = 0 },
    garrafas = { x = -1, z = 0, y = 0, g = 0 }, nao_existe = { x = 3, z = 3 }, mesa1 = "texto", balcao = { x = 1 },
  })
  novo()
  local bx, bz = L.desloc("barril1")
  ok("layout antigo: barris do fundo continuam movidos", perto(bx, bz, 1, 0.5), bx)
  ok("layout antigo: barris da frente também", (L.desloc("barril5")) == 0.5 and L.altura("barril4") == 0.2)
  ok("layout antigo: prateleira e garrafas juntas", (L.desloc("prateleira")) == -1 and (L.desloc("garrafa3")) == -1)
  ok("layout antigo: lixo ignorado", L.dados.nao_existe == nil and L.dados.mesa1 == nil and L.dados.balcao.x == 1)
  L.salvar()
  ok("layout novo não guarda nomes velhos", not motor._layout:find("barris_fundo", 1, true))
  quadros(2)
  -- um barril editado à mão vale mais que o grupo antigo
  motor._layout = util.serializar({ barris_fundo = { x = 1, z = 0, y = 0, g = 0 }, barril2 = { x = -0.5, z = 0, y = 0, g = 0 } })
  L.carregar()
  ok("posição nova tem prioridade sobre a antiga", (L.desloc("barril2")) == -0.5 and (L.desloc("barril1")) == 1)
  -- pai longe e filho no limite: a ordem de leitura do arquivo não pode mudar o resultado
  motor._layout = util.serializar({ jardim = { x = 0, z = 3, y = 0, g = 0 }, canteiros = { x = 0, z = 2, y = 0, g = 0 } })
  L.carregar()
  local _, cz = L.desloc("canteiros")
  ok("filho é limitado já contando o pai", L.POR_ID.canteiros.z + cz <= 4.7 + 5.3 + 0.001, cz)
  limpa_layout()

  -- tamanho do salão -----------------------------------------------------------
  T.f2(); quadros(1)
  L.mudar_tamanho("dir", 20)
  Ed.grade = false
  Ed.mover_para("mesa1", 24, 0.2)
  L.mudar_tamanho("dir", -20)
  ok("encolher traz de volta quem ficou de fora", L.POR_ID.mesa1.x + (L.desloc("mesa1")) <= 6.5 + 6.5 + 0.001, (L.desloc("mesa1")))
  L.restaurar()
  T.esc()
  L.tamanho.fundo = 10
  local _, cozz = L.desloc("cozinheiro")
  local _, fogz = L.desloc("fogao")
  ok("cozinheiro acompanha o fogão quando o fundo cresce", math.abs((fogz - cozz) - (0 - (L.dados.cozinheiro and L.dados.cozinheiro.z or 0))) < 0.001, cozz)
  L.tamanho.fundo = 0

  -- a grade dos caminhos é a mesma de antes, mas sem olhar o salão inteiro por obstáculo
  local caixa = { id = "mesa2", x = 0.3, z = 0.2, ex = 2, ez = 0.6, base = L.base, mundo = L.t }
  L.de("mesa2").g = 0.7
  local circ = { x = -3, z = 2, r = 0.9 }
  Cam.montar({ -6, 6, -4, 4 }, { caixa, circ })
  local diferente = 0
  for x = -5.875, 5.875, 0.25 do
    for z = -3.875, 3.875, 0.25 do
      local bx2, bz2 = L.base("mesa2", x, z)
      local dentro = (math.abs(bx2 - 0.3) < 1.3 and math.abs(bz2 - 0.2) < 0.6) or util.distancia(x, z, -3, 2) < 1.2
      if Cam.bloqueado(x, z) ~= dentro then diferente = diferente + 1 end
    end
  end
  ok("grade rápida marca os mesmos quadradinhos", diferente == 0, diferente)
  L.dados.mesa2 = nil
  novo(); tudo()
  L.tamanho.dir, L.tamanho.oeste, L.tamanho.fundo, L.tamanho.frente = 40, 40, 40, 40
  local contas, base_velha = 0, L.base
  L.base = function(...) contas = contas + 1; return base_velha(...) end
  J.montar_mapa()
  L.base = base_velha
  ok("montar o mapa de um salão enorme é barato", contas < 20000, contas)
  ok("ninguém fica sem rota no salão enorme", J.lugares_sem_rota() == 0)
  ok("camera cabe no salão enorme", M.calcular_enquadramento(M.anim).escala > 5)
  -- com +40 m a câmera fica a mais de 170 m: o limite fixo de 200 m cortava metade do salão
  local fonte = io.open(raiz .. "/src/cena3d.h")
  if fonte then
    local txt = fonte:read("a"); fonte:close()
    ok("limite de visão acompanha a câmera", not txt:find("0.5, 200.0)", 1, true))
  end
  M.rolar(5); M.arrastar(10000, 10000)
  ok("pan fica dentro do limite", math.abs(M.pan_x) <= M.quadro.largura * 0.65 + 0.001)
  M.rolar(-20)
  ok("voltar o zoom centraliza", M.pan_x == 0 and M.pan_z == 0)
  L.tamanho.dir, L.tamanho.oeste, L.tamanho.fundo, L.tamanho.frente = 0, 0, 0, 0
  J.aplicar_layout()

  -- fazendeiro e cervejeiro acompanham as áreas ---------------------------------
  limpa_layout(); tudo(); T.iniciar()
  L.tamanho.frente = 10
  L.de("jardim").g = math.pi
  M.anim.jardim, M.anim.cerveja = 1, 1
  local enxada, avental
  motor.peca = function(_, x, _, z, ex, ey, _, _, c)
    if c == "#7b4a26" and ey == 1.3 then enxada = { x, z } end
    if c == "#efe2c4" and ex == 0.42 then avental = { x, z } end
  end
  local indices = {}
  for _ = 1, 200 do
    desenhar(); M.atualizar(0.1)
    indices[M.fazendeiro.i] = true
  end
  motor.peca = velho
  local n_i = 0
  for _ in pairs(indices) do n_i = n_i + 1 end
  ok("fazendeiro passa por vários canteiros", n_i >= 2, n_i)
  ok("fazendeiro acompanha o jardim", enxada and util.distancia(enxada[1], enxada[2], -3, 16.75) < 4.5, enxada and enxada[2])
  ok("cervejeiro acompanha a cervejaria", avental and util.distancia(avental[1], avental[2], 3.5, 16.75) < 3, avental and avental[2])
  L.restaurar()
  limpa_layout()

  -- congestionamento ------------------------------------------------------------
  novo(); tudo(); J.aplicar_layout()
  for i = 1, #J.lugares do
    for k = i + 1, #J.lugares do
      local a, b = J.lugares[i], J.lugares[k]
      ok("bancos não se sobrepõem", util.distancia(a.x, a.z, b.x, b.z) >= Cam.DISTANCIA, i .. "-" .. k)
    end
  end
  for _ = 1, 3000 do J.atualizar(0.1) end
  ok("taverna cheia quase não pede socorro", J.socorros <= 5, J.socorros)
  ok("taverna cheia quase não trava", J.media_travados < 3, J.media_travados)

  -- quem está sentado perto da porta não fecha a entrada
  novo()
  libera("mesa", "mesa", "mesa")
  for _ = 1, 3 do
    local p = J.novo_cliente(); J.relogio_chegada = 0
    p.x, p.z, p.sentado, p.andando, p.estado = J.PORTA.x + 0.5, J.PORTA.z, true, false, "esperando"
  end
  ok("sentados não lotam a porta", not J.porta_lotada())
  -- três estátuas na porta seguram a chegada só por alguns segundos
  novo()
  libera("mesa", "mesa", "mesa")
  local estatuas = {}
  for i = 1, 3 do
    local p = J.novo_cliente(); J.relogio_chegada = 0
    estatuas[i] = p
  end
  local entrou
  for i = 1, 150 do
    for _, p in ipairs(estatuas) do p.x, p.z, p.andando, p.t = J.PORTA.x + 0.3, J.PORTA.z, true, 0 end
    J.atualizar(0.1)
    if #J.pessoas > 3 then entrou = i break end
  end
  ok("porta lotada não impede a chegada para sempre", entrou ~= nil and entrou <= 120, entrou)
  limpa_layout()
end

-- Achados pelos robôs das duas metades: toda a frente da barraca é alcançável,
-- e quem for empurrado para dentro de um móvel consegue sair
do
  motor._layout = false
  novo()
  libera("prateleira", "mercadinho", "mesa", "mesa", "mesa", "mesa", "mesa")
  for x = -1.25, 1.25, 0.25 do
    local p = { x = J.PORTA.x, z = J.PORTA.z }
    J.caminho(p, J.BARRACA.x + x, J.BARRACA.z)
    ok("frente da barraca alcançável em " .. x, not p.sem_rota)
    local q = { x = J.BARRACA.x + x, z = J.BARRACA.z }
    J.caminho(q, J.PORTA.x, J.PORTA.z)
    ok("sai da frente da barraca em " .. x, not q.sem_rota)
  end
  local m = J.POS_MESAS[1]
  for _, d in ipairs({ { 0.7, -0.2 }, { -0.7, 0.2 }, { 0, 0.75 } }) do
    local p = { x = m.x + d[1], z = m.z + d[2] }
    J.caminho(p, J.QUADRO.x, J.QUADRO.z)
    ok("quem está dentro da mesa consegue sair", not p.sem_rota)
  end
  novo()
end

-- Porta principal: as folhas abrem para quem passa e ninguém atravessa a porta fechada
do
  local M = require("mundo")
  local L = require("layout")
  local Cam = require("caminhos")
  local function so_o_cliente()
    J.relogio_chegada = -1e9
  end
  -- anda quadro a quadro e devolve a abertura da porta quando a pessoa cruza a parede
  local function acompanhar(p, ate)
    local ao_cruzar, antes = nil, L.base("porta", p.x, p.z)
    for _ = 1, 400 do
      atualizar(1 / 30)
      if ate() then break end
      local bx = L.base("porta", p.x, p.z)
      if (antes < -6.5) ~= (bx < -6.5) then ao_cruzar = M.porta_aberta end
      antes = bx
    end
    return ao_cruzar
  end
  for _, giro in ipairs({ 0, -math.pi / 2 }) do
    motor._layout = false
    novo()
    libera("mesa", "mesa")
    if giro ~= 0 then
      -- porta girada e levada para a parede do fundo
      L.colocar("porta", -1, -4.4)
      L.de("porta").g = giro
      J.aplicar_layout()
    end
    J.sem_caminho = 0
    so_o_cliente()
    atualizar(0.5)
    ok("porta começa fechada", M.porta_aberta == 0, M.porta_aberta)
    local p = J.novo_cliente()
    local bx = L.base("porta", p.x, p.z)
    ok("cliente nasce atrás da parede", bx < -6.9, bx)
    ok("atrás da parede não é desenhado", J.fora_da_porta(p))
    atualizar(0.1)
    ok("porta abre aos poucos", M.porta_aberta > 0.2 and M.porta_aberta < 0.6, M.porta_aberta)
    atualizar(0.2)
    ok("porta abre em 0,25 s", M.porta_aberta == 1, M.porta_aberta)
    local cruzou = acompanhar(p, function() return not p.vao end)
    ok("cruzou a porta já aberta", cruzou == 1, cruzou)
    ok("a rota continua depois do vão", #p.rota > 0 and not p.sem_rota and not p.fantasma)
    for _ = 1, 150 do
      atualizar(1 / 30)
      if p.sentado then break end
    end
    ok("porta aberta chegou ao banco", p.sentado)
    for _ = 1, 15 do atualizar(1 / 30) end
    ok("porta fecha depois que passou", M.porta_aberta == 0, M.porta_aberta)
    -- saída: atravessa e só some depois de passar
    p.estado, p.t = "comendo", 1e9
    atualizar(1 / 30)
    ok("cliente foi embora", p.estado == "saindo", p.estado)
    local viu_vao
    cruzou = acompanhar(p, function()
      if p.vao then viu_vao = true end
      return p.removido
    end)
    ok("saída cruza a porta aberta", cruzou and cruzou > 0.99, cruzou)
    ok("saída passa pelo vão", viu_vao)
    ok("só some do lado de fora", L.base("porta", p.x, p.z) < -6.9, p.x)
    for _ = 1, 15 do atualizar(1 / 30) end
    ok("porta fecha depois da saída", M.porta_aberta == 0, M.porta_aberta)
    ok("porta não atrapalha as rotas", J.sem_caminho == 0, J.sem_caminho)
    L.restaurar()
  end
  -- animação não mexe no ouro nem no relógio do jogo
  motor._layout = false
  novo()
  libera("mesa")
  J.estado.ouro = 0
  so_o_cliente()
  local tempo = J.estado.tempo
  local p = J.novo_cliente()
  for _ = 1, 20 do M.atualizar(0.1) end
  ok("porta não mexe em ouro nem tempo", J.estado.ouro == 0 and J.estado.tempo == tempo)
  ok("sem J.atualizar a pessoa fica parada", p.vao ~= nil)
  -- menestrel também vem de fora
  novo()
  J.chamar_menestrel("uma história")
  local m = J.pessoas[#J.pessoas]
  ok("menestrel vem de fora", m.menestrel and m.vao ~= nil)
  for _ = 1, 400 do
    atualizar(0.05)
    if m.estado ~= "menestrel_indo" then break end
  end
  ok("menestrel chega ao palco", m.estado == "menestrel_canta" and not m.fantasma, m.estado)
  novo()
end

-- Tela inicial e saves ------------------------------------------------------------------------------
do
  local S = require("saves")
  motor._saves, motor._atual, motor._save = {}, false, false
  J.pular_menu = false
  iniciar()
  desenhar()
  ok("abre na tela inicial", T.tela == "titulo" and J.em_menu)
  ok("continuar desativado sem save", S.ultimo() == nil)
  atualizar(0.1); desenhar()
  J.salvar()
  ok("taverna do menu não grava nada", next(motor._saves) == nil)
  ok("esc não quebra no menu", pcall(T.esc))
  U.apertar("menu_novo"); desenhar()
  ok("tela de novo jogo", T.tela == "novo")
  U.apertar("menu_vaga_2"); desenhar()
  ok("novo jogo entra", T.tela == nil and not J.em_menu and motor._atual == "jogo2.sav")
  J.estado.ouro = 777
  J.salvar()
  T.modal = "config"; desenhar()
  U.apertar("voltar_menu"); desenhar()
  ok("volta à tela inicial", T.tela == "titulo")
  ok("guardou o último jogo", S.ultimo() == "jogo2.sav")
  U.apertar("menu_continuar"); desenhar()
  ok("continuar carrega", J.estado.ouro == 777, J.estado.ouro)
  T.modal = "config"; desenhar(); U.apertar("voltar_menu"); desenhar()
  U.apertar("menu_novo"); desenhar()
  U.apertar("menu_vaga_2"); desenhar()
  ok("vaga ocupada pede confirmação", T.tela == "novo" and T.confirmar)
  U.apertar("menu_apagar_nao"); desenhar()
  ok("cancelar mantém", S.resumo("jogo2.sav").ouro == 777)
  U.apertar("menu_vaga_2"); desenhar(); U.apertar("menu_apagar_sim"); desenhar()
  ok("confirmar recomeça", J.estado.ouro == 0)
  -- saves prontos
  for i, nome in ipairs({ "comeco", "metade", "completo" }) do
    T.modal = "config"; desenhar(); U.apertar("voltar_menu"); desenhar()
    U.apertar("menu_carregar"); desenhar()
    ok("abre save pronto " .. nome, U.apertar("menu_pronto_" .. i) and T.tela == nil and not J.em_menu)
    J.sem_noticias = true
    for _ = 1, 200 do atualizar(0.1) end
    desenhar()
    ok("save pronto joga: " .. nome, J.estado.tempo >= 10, J.estado.tempo)
    for _, id in ipairs({ "taverna", "arvore", "missoes", "mercadinho", "producao", "aventureiros", "invocacao" }) do
      T.aba = id
      ok("tela no save " .. nome .. ": " .. id, pcall(desenhar))
    end
    T.aba = "taverna"
    if nome == "metade" then ok("metade tem party aberta", J.ef("party") > 0 and J.ef("mercadinho") > 0) end
    if nome == "completo" then
      local tudo = true
      for _, no in ipairs(A.NOS) do if not J.no_maximo(no) then tudo = false end end
      ok("completo tem a árvore toda", tudo)
      ok("completo pode enfrentar o final", J.pode_final() or J.estado.final_resta ~= nil)
      ok("completo tem 4 invocados", J.estado.invocados_feitos == 4)
    end
  end
  -- recomeçar um save pronto apaga o progresso nele
  J.estado.ouro = 12345
  J.salvar()
  T.modal = "config"; desenhar(); U.apertar("voltar_menu"); desenhar()
  U.apertar("menu_carregar"); desenhar()
  U.apertar("menu_pronto_3"); desenhar()
  ok("save pronto guarda o progresso", J.estado.ouro > 10000 and J.estado.ouro < 20000, J.estado.ouro)
  T.modal = "config"; desenhar(); U.apertar("voltar_menu"); desenhar()
  U.apertar("menu_carregar"); desenhar()
  ok("recomeçar save pronto", U.apertar("menu_pronto_refazer_3") and J.estado.ouro > 1e14, J.estado.ouro)
  -- save estragado na vaga
  motor._saves["jogo3.sav"] = "lixo"
  ok("resumo de save estragado", S.resumo("jogo3.sav") == nil)
  -- tamanhos das salas
  local L = require("layout")
  L.mudar_tamanho("jardim_l", 3); L.mudar_tamanho("cerv_l", 2)
  local dx = L.desloc("cervejaria")
  ok("cervejaria anda com o jardim", dx == 3, dx)
  local cx = L.desloc("circulo")
  ok("invocação anda com as duas", cx == 5, cx)
  ok("mundo desenha salas maiores", pcall(desenhar))
  L.restaurar()
  J.pular_menu = true
  motor._saves, motor._atual, motor._save = {}, false, false
  novo()
  J.sem_noticias = true
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
