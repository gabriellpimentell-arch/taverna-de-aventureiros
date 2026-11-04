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
J_sem.auto_colocar = true    -- colocação manual tem teste próprio mais abaixo
J_sem.sem_noticias = true   -- as notícias pausam o jogo: têm teste próprio mais abaixo

-- Leva o objeto até o ponto sem conferir a regra da Loja: serve para testar o modelo de posições
Ed = {}
function Ed.mover_para(id, x, z)
  local L = require("layout")
  if id == "porta" then
    local ok, motivo = L.mover_porta(L.porta_mais_perto(x, z))
    Ed.mensagem = not ok and motivo or nil
    J_sem.aplicar_visual()
    return
  end
  local internas, externas = L.salas()
  for _, lista in ipairs({ internas, externas }) do
    for _, b in ipairs(lista) do
      if b.id == id then
        local o, dx, dz = L.POR_ID[id], L.desloc(id)
        local px, pz = L.pos_sala(id)
        L.mover_sala(id, px + x - (o.x + dx), pz + z - (o.z + dz))
        J_sem.aplicar_visual()
        return
      end
    end
  end
  L.colocar(id, x, z)
  L.limitar(id)
  L.limitar_carregados(id)
  J_sem.aplicar_visual()
end

local falhas, total = 0, 0
local function ok(nome, cond, extra)
  total = total + 1
  if not cond then
    falhas = falhas + 1
    print("FALHOU: " .. nome .. (extra and (" (" .. tostring(extra) .. ")") or ""))
  end
end
-- Jogo novo. Com um layout no arquivo antigo, faz de conta que é um save de antes da construção por save:
-- é assim que aquele arquivo continua valendo, e os testes de layout continuam passando por ele.
local function novo()
  motor._save = rawget(motor, "_layout") and '{ ["versao"] = 2 }' or false
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
for _, id in ipairs({ "taverna", "loja", "arvore", "missoes", "mercadinho", "producao", "aventureiros", "invocacao" }) do
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
ok("final e missão não ficam eternos", (J.estado.final_resta or math.huge) <= C.sss.duracao and J.estado.missoes[1].resta <= C.ranks[1].duracao and #J.estado.missoes == 1)
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

-- mercadinho fica no caminho de pedras, mesmo em save antigo
novo()
libera("prateleira", "mercadinho")
do
  local mundo = require("mundo")
  ok("mercadinho abre o caminho, não a ala", mundo.alvos().caminho == 1 and J.ef("a_leste") == 0 and mundo.alvos().leste == 0)
  motor._save = '{ ["versao"] = 2, ["nos"] = { ["merc_e"] = 1 } }'
  iniciar()
  ok("save sem a ala ainda mostra a barraca", J.mercadinho_aberto() and mundo.alvos().caminho == 1)
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
ok("número enorme cabe na tela", #util.formatar(1e300) <= 10 and #util.formatar(1e21) <= 10, util.formatar(1e300))
ok("maior sufixo continua igual", util.formatar(5e20):find("qui", 1, true) ~= nil, util.formatar(5e20))

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
  -- só quem vem comer e beber entra agora: as missões passam do lado de fora
  ok("taverna continua servindo", J.estado.servidos > 35, J.estado.servidos)
  ok("missões continuam concluindo", J.estado.feitas > 10, J.estado.feitas)

  -- pegar missão: vai ao quadro, pega o papel e sai com ele
  novo()
  libera("prateleira")
  J.relogio_aventureiro = 99
  local viu_ida, viu_pegando, viu_papel, perto = false, false, false, false
  for _ = 1, 400 do
    J.atualizar(0.1)
    for _, p in ipairs(J.visitantes) do
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

  -- posições
  novo()
  Ed.mover_para("mesa1", -2.0, 0.5)
  ok("objeto move", J.POS_MESAS[1].x == -2 and J.POS_MESAS[1].z == 0.5)
  L.restaurar()
  Ed.mover_para("mesa1", -2.0, 0.5)
  L.salvar()
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
      ok("girar não derruba o serviço: " .. caso[1], J.estado.servidos > 35, J.estado.servidos)
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
      if g.estado ~= "parada" and g.estado ~= "buscando" and util.distancia(g.x, g.z, k.x, k.z) < 0.5 then
        k.t = k.t + 0.1
        pior = math.max(pior, k.t)
      else
        k.x, k.z, k.t = g.x, g.z, 0
      end
    end
  end
  ok("garçom amontoado é socorrido", pior < 20, pior)

  -- garçom que volta de um layout novo não fica atravessando tudo
  novo()
  libera("garcom")
  J.garcons[1].fantasma = true
  J.aplicar_layout()
  ok("editor limpa o atalho do garçom", not J.garcons[1].fantasma)

  -- soltar longe de tudo não joga o objeto para fora do mundo
  motor._layout = false
  novo()
  libera("jardim")
  Ed.mover_para("mesa1", 500, -500)
  ok("arraste para fora fica na área", J.POS_MESAS[1].x <= 13.01 and J.POS_MESAS[1].z >= -5, J.POS_MESAS[1].x)
  -- sala só vai para onde cabe: fora da taverna, o jardim vai; em cima dela, não
  local jx, jz = L.pos_sala("jardim")
  Ed.mover_para("jardim", L.POR_ID.jardim.x + L.desloc("jardim"), select(2, L.desloc("jardim")) + L.POR_ID.jardim.z + 2)
  ok("jardim pode continuar lá fora", select(2, L.pos_sala("jardim")) >= jz + 2 - 0.5, select(2, L.pos_sala("jardim")))
  motor._layout = false

  -- salvar não congela as posições oficiais neste computador
  novo()
  L.salvar()
  ok("salvar sem mudança não fixa o padrão", util.desserializar(motor._save).layout.balcao == nil)
  Ed.mover_para("mesa2", 1.5, -0.5)
  L.salvar()
  ok("mudança fica salva", util.desserializar(motor._save).layout.mesa2 ~= nil)
  L.restaurar("mesa2")
  L.salvar()
  ok("restaurar tira do save", util.desserializar(motor._save).layout.mesa2 == nil)
  motor._layout = false

  -- layout salvo com números válidos porém absurdos: a porta longe deixava todos andando por minutos
  motor._layout = '{ ["porta"] = { ["x"] = 900, ["z"] = 900 }, ["mesa1"] = { ["x"] = -900, ["z"] = 900, ["y"] = 900 } }'
  novo()
  ok("layout absurdo volta para a área", J.PORTA.x <= 13 and J.PORTA.z <= 5.25, J.PORTA.x)
  ok("mesa absurda volta para a área", J.POS_MESAS[1].x >= -7 and L.de("mesa1").y <= 6, J.POS_MESAS[1].x)
  motor._layout = false

  -- o modo editor saiu do jogo: sem botão, sem tecla, sem arquivo
  novo()
  T.modal = "config"
  desenhar()
  ok("Configurações sem botão de edição", not U.apertar("editar"))
  T.modal = nil
  ok("sem tecla de edição", _G.tecla_f2 == nil and T.f2 == nil)
  ok("sem arquivo do editor", not package.searchpath("editor", package.path))
  ok("sem estado de edição", J.editando == nil and J.previa == nil)

  -- o nome do rank aparece para contratados e na batalha final
  novo()
  J.estado.ouro = 1e60
  for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e60; J.comprar_no(no.id) end end
  J.pessoas, J.visitantes = {}, {}
  J.contratar()
  J.mandar_contratados()
  local viu = nil
  for _, q in ipairs(J.visitantes) do if q.contratado then viu = q end end
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

  -- os pais de todo objeto existem
  for _, o in ipairs(L.OBJETOS) do
    if o.pai and o.pai:sub(1, 1) ~= "@" then ok("pai existe: " .. o.id, L.POR_ID[o.pai] ~= nil) end
  end

  -- tamanho
  novo()
  libera("jardim")
  atualizar(0.1); desenhar()
  for _ = 1, 45 do L.mudar_tamanho("dir", 1) end
  ok("tamanho tem limite", L.tamanho.dir == L.TAMANHO_MAX)
  L.mudar_tamanho("dir", -100)
  ok("salão não fica menor que 8 m de largura", L.tamanho.dir == -5, L.tamanho.dir)
  L.mudar_tamanho("dir", 5)
  L.mudar_tamanho("dir", 10); L.mudar_tamanho("frente", 6); L.mudar_tamanho("oeste", 4); L.mudar_tamanho("fundo", 3)
  J.aplicar_visual(); desenhar()
  -- a porta e o quadro acompanham as paredes; o jardim acompanha a frente
  local dx = L.desloc("porta")
  ok("porta acompanha a parede", dx == -4, dx)
  local _, dz = L.desloc("jardim")
  ok("jardim acompanha a frente", dz == 6, dz)
  local _, gz = L.desloc("garrafa1")
  ok("garrafa acompanha a prateleira", gz == -3, gz)
  L.salvar()
  iniciar()
  ok("tamanho sobrevive a reiniciar", L.tamanho.dir == 10 and L.tamanho.frente == 6, L.tamanho.dir)
  ok("porta real acompanha", J.PORTA.x < -10, J.PORTA.x)
  libera("prateleira", "garcom", "mesa", "mesa", "mesa")
  for _ = 1, 1500 do J.atualizar(0.1) end
  ok("funciona numa taverna grande", J.estado.servidos > 5 and (J.sem_caminho or 0) == 0, J.sem_caminho)
  ok("mundo desenha grande", pcall(desenhar))
  -- mover objeto preso a uma parede depois de crescer continua no lugar pedido
  Ed.mover_para("lampiao1", 2, -6)
  local ax, az = L.desloc("lampiao1")
  ok("mover respeita a âncora", math.abs(L.POR_ID.lampiao1.x + ax - 2) < 0.01 and math.abs(L.POR_ID.lampiao1.z + az + 6) < 0.01, ax)
  L.restaurar()
  ok("restaurar zera o tamanho", L.tamanho.dir == 0)
  L.salvar()
  motor._layout = false
  novo()
end

-- Notícias que pausam, menestrel, filhos no layout, salão grande e congestionamento --------------
do
  local L, M, Cam = require("layout"), require("mundo"), require("caminhos")
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

  -- pausa: nunca trava; fecha em qualquer aba
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
  ok("notícia fecha", U.apertar("noticia_depois") and J.noticia == nil)
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
  quadros(1)
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
  Ed.mover_para("caneca2", 2, 0)
  local dx, dz = L.desloc("caneca2")
  ok("mover filho de pai girado vai ao ponto pedido", perto(L.POR_ID.caneca2.x + dx, L.POR_ID.caneca2.z + dz, 2, 0), dx)
  -- mover o pai leva o filho
  local a0 = L.desloc("caneca2")
  L.dados.balcao.x = L.dados.balcao.x + 1
  ok("filho acompanha o pai", math.abs(L.desloc("caneca2") - a0 - 1) < 0.001)
  L.dados.balcao.y = 0
  L.restaurar("caneca2")
  ok("restaurar um filho deixa o pai como está", L.dados.caneca2 == nil and L.dados.balcao ~= nil)
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
  ok("layout novo não guarda nomes velhos", not motor._save:find("barris_fundo", 1, true))
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
  quadros(1)
  L.mudar_tamanho("dir", 20)
  Ed.mover_para("mesa1", 24, 0.2)
  L.mudar_tamanho("dir", -20)
  ok("encolher traz de volta quem ficou de fora", L.POR_ID.mesa1.x + (L.desloc("mesa1")) <= 6.5 + 6.5 + 0.001, (L.desloc("mesa1")))
  L.restaurar()
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
  L.mudar_tamanho("frente", 10)
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
  local cvx, cvz = L.t("cervejaria", 20.1, -2.05)
  ok("cervejeiro acompanha a cervejaria", avental and util.distancia(avental[1], avental[2], cvx, cvz) < 3, avental and avental[2])
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

-- Achados pelos robôs das duas metades: quem for empurrado para dentro de um móvel consegue sair
do
  motor._layout = false
  novo()
  libera("prateleira", "mercadinho", "mesa", "mesa", "mesa", "mesa", "mesa")
  local m = J.POS_MESAS[1]
  local palco_x, palco_z = require("layout").t("palco", -1.65, 0.2)
  -- o destino é o outro lado da mesa, no salão: o mural e a barraca agora ficam lá fora
  local alvo_x, alvo_z = 3, 2
  for _, d in ipairs({ { 0.7, -0.2 }, { -0.7, 0.2 }, { 0, 0.75 } }) do
    local p = { x = m.x + d[1], z = m.z + d[2] }
    J.caminho(p, alvo_x, alvo_z)
    ok("quem está dentro da mesa consegue sair", not p.sem_rota)
  end
  -- achado pelo robô: fundo na mesa, ao lado do banco, nenhum ponto a até 0,6 m estava livre
  for _, d in ipairs({ { 0.66, -0.18 }, { 0.63, 0.04 }, { -0.45, 0.35 }, { 0, 0 } }) do
    local p = { x = m.x + d[1], z = m.z + d[2] }
    J.sem_caminho = 0
    J.caminho(p, alvo_x, alvo_z)
    ok("quem está bem no fundo da mesa consegue sair", J.sem_caminho == 0 and #p.rota > 1, d[1] .. "," .. d[2])
  end
  -- sem saída de verdade (destino cercado) não repete a busca cara a cada ponto livre em volta
  do
    local Cam, rota, buscas = require("caminhos"), nil, 0
    rota = Cam.rota
    Cam.rota = function() buscas = buscas + 1 end
    local p = { x = 0, z = 1.8 }
    J.caminho(p, alvo_x, alvo_z)
    Cam.rota = rota
    ok("sem saída faz poucas buscas", p.sem_rota and buscas <= 5, buscas)
  end
  novo()
end

-- Desfazer a party no meio da batalha final deixava a luta seguir sem party nenhuma
do
  motor._layout = false
  motor._save = motor.ler_asset("saves/completo.sav")
  iniciar()
  J.offline = nil
  ok("final começa", J.iniciar_final())
  local pf = J.party_final()
  ok("party na final não se desfaz", pf and not J.desfazer_party(pf.id) and J.party_final() == pf)
  local outra
  for _, p in ipairs(J.estado.parties) do if p ~= pf then outra = p end end
  ok("as outras ainda se desfazem", outra and J.desfazer_party(outra.id))
  for _ = 1, 30 do atualizar(0.1) end
  ok("luta continua", J.estado.final_resta ~= nil and J.party_final() == pf)
  motor._save = false
  novo()
end

-- Layout salvo com itens excluídos e novos sobrevive a abrir qualquer save, antigo ou novo
do
  local L = require("layout")
  local velho = motor.ler_asset("saves/metade.sav")
  local d = util.desserializar(velho)
  d.nos.cozinha, d.nos.pomar, d.nos.fazenda = nil, nil, nil   -- de antes dessas salas
  local antigo = util.serializar(d)
  local lay = util.serializar({ barril1 = { x = 0, z = 0, y = 0, g = 0, oculto = true }, cocho = { x = 1, z = 0, y = 0, g = 0, oculto = true },
    _tamanho = { dir = 2 }, _extras = { { id = "extra_9", tipo = "barril", x = 0, z = 2 } } })
  for _, caso in ipairs({ { "antigo", antigo }, { "metade", velho }, { "completo", motor.ler_asset("saves/completo.sav") }, { "novo", false } }) do
    motor._layout, motor._save = lay, caso[2]
    iniciar()
    J.offline = nil
    local tudo_ok = pcall(function() for _ = 1, 60 do atualizar(0.1) end desenhar() end)
    if caso[2] then
      ok("layout com excluídos abre o save " .. caso[1], tudo_ok and L.oculto("barril1") and L.oculto("cocho") and L.POR_ID.extra_9 ~= nil and L.tamanho.dir == 2)
    else
      ok("jogo novo não herda o arquivo antigo", tudo_ok and not L.oculto("barril1") and L.POR_ID.extra_9 == nil and L.tamanho.dir == 0)
    end
    ok("save " .. caso[1] .. " sem caminho perdido", (J.sem_caminho or 0) == 0, J.sem_caminho)
  end
  ok("save antigo com cozinheiro ganha a cozinha", (function()
    motor._layout, motor._save = lay, antigo
    iniciar()
    return J.nivel("cozinha") == 1 and L.aberta("cozinha")
  end)())
  motor._layout, motor._save = false, false
  L.restaurar()
  novo()
end

-- O que a árvore compra não pode ser excluído (GDD), e os saves prontos mostram as paredes iguais
do
  local L, M = require("layout"), require("mundo")
  ok("canteiros vêm da árvore: só movem", not L.removivel("canteiros"))
  local velho = motor.peca
  for _, nome in ipairs({ "comeco", "metade", "completo" }) do
    motor._layout = false
    motor._save = motor.ler_asset("saves/" .. nome .. ".sav")
    iniciar()
    J.offline = nil
    for _ = 1, 60 do atualizar(0.1) end
    local alturas, maior = {}, 0
    motor.peca = function(f, _, _, _, _, ey)
      if f == "caixa" and ey >= 3.5 and ey < 6 then
        alturas[ey] = true
        maior = math.max(maior, ey)
      end
    end
    desenhar()
    motor.peca = velho
    local n = 0
    for _ in pairs(alturas) do n = n + 1 end
    ok("paredes da mesma altura: " .. nome, n == 1 and maior == 4.2, n .. " alturas, maior " .. maior)
  end
  motor._save = false
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

-- Excluir e acrescentar itens
do
  local L = require("layout")
  motor._layout = false
  novo()
  ok("mesa não pode ser excluída", not L.removivel("mesa1") and not L.excluir("mesa1"))
  ok("círculo não pode ser excluído", not L.removivel("circulo"))
  ok("barril pode", L.removivel("barril1") and L.excluir("barril1") and L.oculto("barril1"))
  ok("desenha sem o barril", pcall(desenhar))
  local o = L.adicionar("planta", 2, 2)
  ok("acrescenta item", o and L.POR_ID[o.id] and L.removivel(o.id))
  local o2 = L.adicionar("barril", 3, 3)
  L.salvar()
  iniciar()
  ok("excluído continua fora", L.oculto("barril1"))
  ok("novo continua lá", L.POR_ID[o.id] ~= nil and L.POR_ID[o2.id] ~= nil)
  J.montar_mapa()
  ok("desenha os novos", pcall(desenhar))
  ok("tipo inválido", L.adicionar("xx", 0, 0) == nil)
  ok("exclui o novo", L.excluir(o2.id) and L.POR_ID[o2.id] == nil)
  L.restaurar()
  ok("restaurar tira os novos", L.POR_ID[o.id] == nil)
  L.salvar()
  motor._layout = false
  novo()
  libera("fazenda"); libera("cozinheiro")
  ok("fazenda rende", J.renda_passiva() >= 60)
  ok("cozinheiro exige cozinha", J.nivel("cozinha") == 1)
  motor._save = '{ ["versao"] = 2, ["nos"] = { ["cozinheiro"] = 2 } }'
  iniciar()
  ok("save antigo ganha a cozinha", J.nivel("cozinha") == 1)
  novo()
end

-- Tentar quebrar paredes, salas e arquivos do layout
do
  local L, Mu = require("layout"), require("mundo")
  local function abrir_tudo()
    J.estado.ouro = 1e60
    for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e60; J.comprar_no(no.id) end end
    L.restaurar()
    J.ajustar_equipe()
    J.aplicar_layout()
  end
  motor._layout = false
  novo()
  abrir_tudo()
  atualizar(0.05); desenhar()
  local function mundo(id)
    local dx, dz = L.desloc(id)
    return L.POR_ID[id].x + dx, L.POR_ID[id].z + dz
  end
  local function dentro_sala(sala, id)
    local x0, x1, z0, z1 = L.sala_mundo(sala)
    local x, z = mundo(id)
    return x >= x0 and x <= x1 and z >= z0 - 0.2 and z <= z1, x
  end
  -- mover a sala interna não leva o que está dentro para fora das paredes dela
  local fx0 = mundo("fogao")
  Ed.mover_para("cozinha", 0, 0)
  for _, id in ipairs({ "fogao", "cozinheiro", "mesa_preparo", "despensa" }) do
    ok("sala movida: " .. id .. " continua dentro", dentro_sala("cozinha", id))
  end
  Ed.mover_para("cozinha", 14.75, 0.1)
  ok("sala de volta: fogão volta ao lugar", mundo("fogao") == fx0, mundo("fogao"))
  Ed.mover_para("circulo", 100, 100)
  for i = 1, 4 do ok("círculo movido: pilar " .. i .. " dentro", dentro_sala("circulo", "pilar" .. i)) end
  L.restaurar()
  -- layout salvo com a sala movida já vem com os filhos dentro
  motor._layout = util.serializar({ cozinha = { x = -3, z = 0, y = 0, g = 0 } })
  L.carregar()
  ok("layout com sala movida: fogão dentro", dentro_sala("cozinha", "fogao"))
  motor._layout = false
  L.restaurar()

  -- encolher a sala ao mínimo: nada entra na parede da frente nem na sala vizinha
  for _ = 1, 8 do L.mudar_tamanho("coz_l", -1) end
  local _, cx1 = L.sala_mundo("cozinha")
  for _, id in ipairs({ "fogao", "cozinheiro", "mesa_preparo", "despensa", "panelas" }) do
    ok("sala mínima: " .. id .. " longe da parede", mundo(id) <= cx1 - 0.5, mundo(id))
  end
  L.restaurar()

  -- posição original de um item num salão que encolheu não o joga para fora
  for _ = 1, 6 do L.mudar_tamanho("dir", -1); L.mudar_tamanho("frente", -1) end
  local _, xb = L.salao()
  L.restaurar("mesa3")
  ok("posição original respeita o salão menor", mundo("mesa3") <= xb, mundo("mesa3"))
  L.restaurar()

  -- sala mais funda que o salão não cobre a área da frente
  L.mudar_tamanho("coz_p", 4)
  local _, _, _, cz1 = L.sala_mundo("cozinha")
  local _, _, fz0 = L.sala_mundo("fazenda")
  ok("cozinha funda não entra na fazenda", fz0 >= cz1, fz0)
  ok("o jardim, que não fica na frente dela, não recua", select(3, L.sala_mundo("jardim")) == 4.8)
  L.restaurar()

  -- quem recebe gente não sai pela parede
  local xa, xb2, za, zb = L.salao()
  for _, alvo in ipairs({ { -100, 100 }, { 100, -100 } }) do
    for _, id in ipairs({ "mesa1", "balcao", "palco", "bardo" }) do
      Ed.mover_para(id, alvo[1], alvo[2])
      local x, z = mundo(id)
      ok("dentro da parede: " .. id, x > xa and x < xb2 + 5.6 and z > za and z < zb, x .. "," .. z)
    end
  end
  Ed.mover_para("mesa1", 100, 0)
  ok("mesa do salão não vai para a ala que pode não existir", mundo("mesa1") <= xb2, mundo("mesa1"))
  L.restaurar()
  for _, o in ipairs(L.OBJETOS) do
    if o.id:match("^mesa%d") or o.id == "balcao" or o.id == "barraca" then
      L.mudar_tamanho("dir", 0)
      ok("o padrão continua onde estava: " .. o.id, not (L.dados[o.id] and L.dados[o.id].orig))
    end
  end
  L.restaurar()

  -- arquivo de layout estragado
  motor._layout = util.serializar({
    _extras = { { tipo = "planta", id = 5, x = 1, z = 1 }, { tipo = "barril", id = {}, x = 1, z = 1 } },
    mesa1 = { oculto = true, x = 0, z = 0 }, balcao = { oculto = true },
  })
  L.carregar()
  for _, o in ipairs(L.OBJETOS) do
    if o.extra then ok("id de item novo é sempre texto", type(o.id) == "string", type(o.id)) end
  end
  ok("arquivo não esconde o que vem da árvore", not L.oculto("mesa1") and not L.oculto("balcao"))
  ok("desenha com o arquivo estragado", pcall(desenhar))
  local muitos = { _extras = {} }
  for i = 1, 500 do muitos._extras[i] = { tipo = "planta", x = 0, z = 0 } end
  motor._layout = util.serializar(muitos)
  L.carregar()
  local n = 0
  for _, o in ipairs(L.OBJETOS) do if o.extra then n = n + 1 end end
  ok("arquivo não passa do limite de itens novos", n == L.MAX_EXTRAS, n)
  motor._layout = false
  L.carregar()

  -- empurrado pelo salão menor: desfazer e recarregar não esquecem o lugar
  Ed.mover_para("mesa3", 4.5, 0.25)
  local mx = mundo("mesa3")
  L.mudar_tamanho("dir", -5)
  ok("empurrada", mundo("mesa3") < mx)
  L.carregar(L.exportar())
  L.mudar_tamanho("dir", 5)
  ok("recarregar não esquece o lugar da mesa empurrada", mundo("mesa3") == mx, mundo("mesa3"))
  L.mudar_tamanho("dir", -5)
  L.mudar_tamanho("dir", 5)
  L.restaurar()

  -- tudo o que pode ser escondido por um layout antigo some mesmo da cena
  abrir_tudo()
  for _ = 1, 100 do atualizar(0.1) end
  local conta = 0
  rawset(motor, "peca", function() conta = conta + 1 end)
  local function pecas() conta = 0; Mu.desenhar_cena(); return conta end
  local base = pecas()
  for _, o in ipairs(L.OBJETOS) do
    if L.removivel(o.id) then
      L.excluir(o.id)
      ok("excluir some da cena: " .. o.id, pecas() < base)
      if L.dados[o.id] then L.dados[o.id].oculto = nil end
    end
  end
  rawset(motor, "peca", nil)
  L.restaurar()

  -- o cozinheiro não sai da cozinha, mesmo com os móveis colados na parede (save antigo)
  motor._layout = false
  motor._save = '{ ["versao"] = 2, ["nos"] = { ["cozinheiro"] = 2 } }'
  iniciar()
  J.sem_noticias = true
  local x0, x1, z0, z1 = L.sala_mundo("cozinha")
  L.colocar("fogao", x0, z0); L.limitar("fogao")
  L.colocar("mesa_preparo", x0, z1); L.limitar("mesa_preparo")
  local dentro, ambos = true, {}
  for _ = 1, 400 do
    atualizar(0.1)
    local c = Mu.cozinheiro
    if c then
      local wx, wz = L.t("cozinheiro", c.x, c.z)
      ambos[c.posto] = true
      if wx < x0 + 0.3 or wx > x1 - 0.3 or wz < z0 + 0.3 or wz > z1 - 0.3 then dentro = false end
    end
  end
  ok("cozinheiro nunca atravessa a parede", dentro)
  ok("cozinheiro continua indo aos dois postos", ambos.fogao and ambos.mesa)
  L.restaurar()
  motor._layout = false
  novo()
  J.sem_noticias = true
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
    for _, id in ipairs({ "taverna", "loja", "arvore", "missoes", "mercadinho", "producao", "aventureiros", "invocacao" }) do
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
  -- o Modo Layout saiu junto com o editor
  T.modal = "config"; desenhar(); U.apertar("voltar_menu"); desenhar()
  ok("tela inicial sem Modo Layout", not U.apertar("menu_layout") and T.tela == "titulo")
  atualizar(3); desenhar()
  -- save estragado na vaga
  motor._saves["jogo3.sav"] = "lixo"
  ok("resumo de save estragado", S.resumo("jogo3.sav") == nil)
  -- tamanhos das salas
  local L = require("layout")
  local function aberta_em_todas(id) return (L.desloc(id)) end
  local function abrir_tudo()
    J.estado.ouro = 1e60
    for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e60; J.comprar_no(no.id) end end
    L.restaurar()
  end
  abrir_tudo()
  local cerv0, circ0, pomar0, faz0 = aberta_em_todas("cervejaria"), aberta_em_todas("circulo"), aberta_em_todas("pomar"), aberta_em_todas("fazenda")
  L.mudar_tamanho("coz_l", 3); L.mudar_tamanho("cerv_l", 2); L.mudar_tamanho("jardim_l", 1); L.mudar_tamanho("pomar_l", 4)
  ok("cervejaria anda com a cozinha", L.desloc("cervejaria") - cerv0 == 3)
  ok("invocação anda com as duas", L.desloc("circulo") - circ0 == 5)
  ok("pomar anda com o jardim", L.desloc("pomar") - pomar0 == 1)
  ok("fazenda anda com o pomar", L.desloc("fazenda") - faz0 == 5)
  ok("mundo desenha salas maiores", pcall(desenhar))
  L.restaurar()

  -- fileira de salas: mesma linha de fundo, sem buraco e sem tirar nada do lugar
  L.restaurar()
  local function sm(id) return L.sala_mundo(id) end
  local _, xb, za, zb = L.salao()
  local cx0, cx1, cz0, cz1 = sm("cozinha")
  local bx0, bx1 = sm("cervejaria")
  local ix0 = sm("circulo")
  ok("cozinha colada na ala leste", cx0 == xb + 5.5, cx0)
  ok("salas encostadas", bx0 == cx1 and ix0 == bx1)
  ok("sala com o fundo e a profundidade do salão", cz0 == za and cz1 == zb)
  motor._layout = false
  novo()
  local x_so = sm("circulo")
  ok("sem as outras compradas não fica buraco", x_so == select(2, L.salao()), x_so)
  libera("cozinha")
  ok("cozinheiro nasce dentro da cozinha", L.POR_ID.cozinheiro.pai == "cozinha")
  abrir_tudo()

  -- alças da Loja
  local alcas = {}
  for _, a in ipairs(L.paredes()) do alcas[a.id] = a end
  for _, id in ipairs({ "salao_dir", "salao_frente", "salao_fundo", "salao_oeste", "cozinha_largura", "cozinha_fundo",
    "cervejaria_largura", "circulo_fundo", "jardim_largura", "pomar_fundo", "fazenda_largura" }) do
    ok("alça existe: " .. id, alcas[id] ~= nil)
  end
  ok("alça do salão na borda", alcas.salao_dir.x == 6.5 and alcas.salao_oeste.sinal == -1)
  local a0 = alcas.cervejaria_largura.x
  L.mudar_tamanho(alcas.cervejaria_largura.chave, 1)
  local a1
  for _, a in ipairs(L.paredes()) do if a.id == "cervejaria_largura" then a1 = a end end
  ok("puxar a alça leva a borda junto", a1.x == a0 + 1, a1.x)
  L.restaurar()
  novo()
  local abertas = 0
  for _, a in ipairs(L.paredes()) do if a.id:find("cervejaria") then abertas = abertas + 1 end end
  ok("sala fechada não tem alça", abertas == 0, abertas)

  -- encolher
  abrir_tudo()
  for _ = 1, 12 do
    for _, k in ipairs({ "dir", "oeste", "frente", "fundo", "coz_l", "coz_p", "cerv_l", "cerv_p", "circ_l", "circ_p", "jardim_l", "jardim_p", "pomar_l", "pomar_p", "faz_l", "faz_p" }) do
      L.mudar_tamanho(k, -1)
    end
  end
  local xa2, xb2, za2, zb2 = L.salao()
  ok("salão tem mínimo de largura", xb2 - xa2 == 8, xb2 - xa2)
  ok("salão tem mínimo de fundo", zb2 - za2 >= 7 and zb2 - za2 < 8, zb2 - za2)
  for _, id in ipairs({ "cozinha", "cervejaria", "circulo", "jardim", "pomar", "fazenda" }) do
    local x0, x1, z0, z1 = L.sala_mundo(id)
    ok("sala tem mínimo: " .. id, x1 - x0 >= 3 and z1 - z0 >= 3 and z1 - z0 < 4, z1 - z0)
  end
  for _, o in ipairs(L.OBJETOS) do
    if o.pai ~= "@leste" and o.cat ~= "Áreas" and o.cat ~= "Jardim" and o.cat ~= "Pomar" and o.cat ~= "Fazenda" and o.cat ~= "Quartos" and o.cat ~= "Guilda" then
      local dx, dz = L.desloc(o.id)
      local dentro = o.x + dx >= xa2 - 0.51 and o.z + dz >= za2 - 0.51 and o.z + dz <= zb2 + 0.56
      if o.cat == "Cozinha" or o.cat == "Cervejaria" or o.cat == "Círculo" then dentro = true end
      if not dentro then ok("objeto fica dentro do salão menor: " .. o.id, false, o.z + dz) end
    end
  end
  ok("mundo desenha salão mínimo", pcall(desenhar))
  J.aplicar_layout()
  ok("mapa monta no salão mínimo", pcall(J.montar_mapa))
  -- salvo guarda o negativo; ao carregar o mínimo continua valendo
  L.carregar(L.exportar())
  ok("negativo sobrevive a recarregar", L.tamanho.dir + L.tamanho.oeste == -5, L.tamanho.dir)
  motor._layout = util.serializar({ _tamanho = { dir = -30, oeste = -30, jardim_l = -30 } })
  L.carregar()
  ok("salvo estragado respeita o mínimo", L.tamanho.dir + L.tamanho.oeste >= -5 and L.tamanho.jardim_l == -4, L.tamanho.dir)
  motor._layout = false
  L.restaurar()

  -- save antigo: posição do dono continua, ids antigos também
  motor._layout = util.serializar({ cervejaria = { x = 0.5, z = 0.5, y = 0, g = 0 }, tina = { x = -0.3, z = 0, y = 0, g = 0 }, barris_fundo = { x = 1, z = 0, y = 0, g = 0 } })
  L.carregar()
  ok("sala movida num save antigo continua movida", L.dados.cervejaria.x == 0.5 and L.dados.tina.x == -0.3)
  ok("id antigo continua migrando", (L.desloc("barril1")) == 1)
  motor._layout = false
  L.restaurar()
  J.pular_menu = true
  motor._saves, motor._atual, motor._save = {}, false, false
  novo()
  J.sem_noticias = true
end

-- Celular: voltar do segundo plano e pinça ----------------------------------------------------------
do
  J.em_menu = false
  novo()
  libera("garcom")
  J.estado.rps = 100
  J.salvar()
  J.estado.salvo_em = os.time() - 3600
  J.ao_voltar()
  ok("voltar do segundo plano paga o tempo parado", J.offline ~= nil and J.offline.ganho > 0)
  local g = J.offline and J.offline.ganho
  J.ao_voltar()
  ok("voltar de novo não conta duas vezes", J.offline and J.offline.ganho == g)
  J.salvar()   -- ir para o segundo plano com a janela aberta guarda o ganho
  ok("salvar recolhe o ganho", not J.offline)
  J.estado.salvo_em = os.time() - 3600
  J.em_menu = true
  J.ao_voltar()
  ok("no menu não há ganho", not J.offline)
  J.em_menu = false

  T.iniciar(); T.tela = nil; T.modal = nil; T.aba = "taverna"; J.offline = nil
  J.estado.salvo_em = os.time()
  desenhar()
  T.tocar(480, 300)
  ok("toque começou", T.toque ~= nil)
  T.cancelar_toque()
  ok("pinça cancela o toque", T.toque == nil)
  local apertou = false
  U.limpar()
  U.zona("teste_solto", { x = 400, y = 200, w = 80, h = 80 }, function() apertou = true end, true)
  T.tocar(440, 240)
  T.cancelar_toque()
  T.soltar(440, 240)
  ok("pinça não dispara o botão ao soltar", not apertou)
  ok("função da pinça existe para o motor", type(_G.cancelar_toque) == "function" and type(_G.ao_voltar) == "function")
  novo()
  J.sem_noticias = true
end

-- Loja: colocar, decoração e obras -------------------------------------------------------------------
do
  local L = require("layout")
  local Lj = require("loja")
  J.auto_colocar = false
  local function jogo_novo()
    motor._layout = nil
    novo()
    J.comecar_endividado()
    J.noticia = nil
    T.aba = "loja"
    Lj.iniciar()
    J.estado.ouro = 1e7
    quadros(1)
  end
  local function comprar(...)
    for _, id in ipairs({ ... }) do
      J.estado.ouro = 1e12
      assert(J.comprar_no(id), "não comprou " .. id)
    end
  end
  local function fechou(t) return t end

  jogo_novo()
  ok("jogo novo coloca à mão", J.manual())
  ok("a primeira mesa já vem posta", J.num_mesas() == 1)
  ok("nada pendente no começo", J.total_para_colocar() == 0)
  comprar("mesa")
  ok("mesa comprada fica para colocar", J.total_para_colocar() == 1 and J.para_colocar()[1].tipo == "mesa")
  ok("mesa comprada não conta antes de posta", J.num_mesas() == 1 and #J.lugares == 2)
  quadros(3)
  ok("sem colocar, o jogo segue com a mesa que tem", J.num_mesas() == 1)
  local ok_mal, motivo = J.por_item("mesa", -100, 0)
  ok("mesa fora da taverna é recusada com motivo", not ok_mal and type(motivo) == "string" and J.num_mesas() == 1)
  ok("mesa em cima de outra é recusada", not J.por_item("mesa", -3.6, 0.2) and J.total_para_colocar() == 1)
  ok("coloca mesa no lugar padrão", J.por_item("mesa") and J.num_mesas() == 2 and #J.lugares == 4 and J.total_para_colocar() == 0)
  ok("colocar sem ter comprado não dá", not J.por_item("mesa"))

  comprar("mesa")
  ok("coloca mesa em lugar escolhido", J.por_item("mesa", 1.5, 3.5))
  local mx, mz = L.t("mesa3", J.POS_MESAS[3].bx, J.POS_MESAS[3].bz)
  ok("mesa vai para onde foi posta", math.abs(mx - 1.5) < 0.01 and math.abs(mz - 3.5) < 0.01, mx)
  comprar("mesa")
  J.salvar()
  L.salvar()
  iniciar()
  J.noticia = nil
  ok("contador salvo: postas continuam", J.num_mesas() == 3 and J.estado.colocados.mesas == 2)
  ok("contador salvo: pendente continua", J.total_para_colocar() == 1 and J.manual())
  mx = L.t("mesa3", J.POS_MESAS[3].bx, J.POS_MESAS[3].bz)
  ok("lugar escolhido salvo", math.abs(mx - 1.5) < 0.01, mx)

  -- sala comprada espera lugar, com fantasma e motivo
  jogo_novo()
  comprar("garcom", "cozinha")
  ok("sala comprada não abre sozinha", not L.aberta("cozinha") and J.fracao_custo("comida") == C.fracao_comida.comprada)
  ok("selo conta a sala", J.total_para_colocar() == 1)
  local xa, xb, za = L.salao()
  local bom, m2 = J.por_sala("cozinha", xb + 30, za, 0)
  ok("sala solta é recusada com motivo", not bom and type(m2) == "string" and not L.aberta("cozinha"))
  U.apertar("loja_aba_itens")
  desenhar()
  ok("botão da sala pendente aparece", U.apertar("loja_item_cozinha") and Lj.colocando and Lj.colocando.id == "cozinha")
  desenhar()
  ok("fantasma nasce verde na vaga", Lj.colocando.ok == true, Lj.colocando.motivo)
  ok("nada muda antes de confirmar", not L.aberta("cozinha"))
  Lj.colocando.x, Lj.colocando.z = xb + 30, za
  desenhar()
  ok("fantasma longe fica vermelho com motivo", Lj.colocando.ok == false and Lj.colocando.motivo ~= nil)
  ok("não confirma em vermelho", not Lj.confirmar() and not L.aberta("cozinha"))
  Lj.colocando.x, Lj.colocando.z = L.vaga_sala("cozinha", 0)
  desenhar()
  ok("confirma em verde", Lj.confirmar() and L.aberta("cozinha") and J.total_para_colocar() == 0)
  ok("sala posta passa a valer nas regras", J.fracao_custo("comida") == C.fracao_comida.cozinha)
  local d = util.desserializar(motor.carregar())
  ok("sala posta fica no save", d.colocados and d.colocados.salas.cozinha == true)

  -- Itens que dependem de sala: canteiro, árvore e vaca
  jogo_novo()
  comprar("cardapio", "garcom", "cozinha", "cervejaria", "jardim", "canteiro", "pomar", "pomar", "fazenda", "fazenda")
  local x0, z0 = L.vaga_sala("jardim", 0)
  ok("canteiro espera o jardim", not J.por_item("canteiro"))
  ok("árvore espera o pomar", not J.por_item("arvore"))
  ok("jardim fechado não dá canteiros", J.ef("canteiros") == 0 and not J.jardim_aberto())
  ok("põe jardim", J.por_sala("jardim", x0, z0, 0))
  ok("jardim traz seus 2 canteiros", J.ef("canteiros") == 2)
  ok("canteiro comprado entra ao pôr", J.por_item("canteiro") and J.ef("canteiros") == 3)
  x0, z0 = L.vaga_sala("pomar", 0)
  ok("põe pomar", J.por_sala("pomar", x0, z0, 0))
  ok("pomar vem com 3 árvores e 1 fica pendente", J.ef("frutas") == 1)
  ok("árvore extra entra ao pôr", J.por_item("arvore") and J.ef("frutas") == 2)
  x0, z0 = L.vaga_sala("fazenda", 0)
  ok("põe fazenda", J.por_sala("fazenda", x0, z0, 0))
  ok("fazenda vem com 1 vaca", J.ef("vacas") == 1 and J.ef("renda_fazenda") == 60)
  ok("vaca extra conta e rende ao pôr", J.por_item("vaca") and J.ef("vacas") == 2 and J.ef("renda_fazenda") == 120)
  ok("só faltam as salas compradas no caminho", J.total_para_colocar() == 2)
  quadros(3)

  -- Segundo andar: o andar abre na hora, as salas esperam
  jogo_novo()
  comprar("mesa", "balcao", "quartos", "segundo_andar")
  J.por_item("mesa")
  ok("andar novo abre, salas dele não", L.andar_existe(1) and not L.aberta("quartos_sala") and not L.aberta("sala_guilda"))
  ok("quartos e sala do chefe pendentes", J.total_para_colocar() == 2)
  desenhar()
  ok("botão dos quartos leva ao andar deles", U.apertar("loja_item_quartos_sala") and L.andar_ativo == 1 and Lj.colocando ~= nil)
  ok("quartos entram no segundo andar", Lj.confirmar() and L.aberta("quartos_sala") and L.andar_de("quartos_sala") == 1)
  L.mudar_andar(0)
  quadros(2)

  -- Decoração
  jogo_novo()
  local e = J.estado
  local preco = C.preco_decoracao.planta
  local gx, gz = -1, 2
  e.ouro = preco - 1
  local pode, falta = J.comprar_decoracao("planta", gx, gz)
  ok("decoração sem ouro não entra e diz quanto falta", not pode and falta:find("Faltam") and #L.lista_extras() == 0, falta)
  e.ouro = preco
  ok("decoração fora de sala é recusada sem cobrar", not J.comprar_decoracao("planta", 500, 0) and e.ouro == preco)
  ok("compra decoração", J.comprar_decoracao("planta", gx, gz) and e.ouro == 0 and #L.lista_extras() == 1)
  for t in pairs(L.TIPOS_EXTRAS) do ok("decoração tem preço: " .. t, C.preco_decoracao[t] ~= nil) end
  e.ouro = 1000
  quadros(1)
  Lj.aba = "itens"; desenhar()
  ok("cartão abre o fantasma sem cobrar", U.apertar("loja_decor_banco") and Lj.colocando and e.ouro == 1000)
  desenhar()
  ok("cancelar não cobra", U.apertar("loja_cancelar") and not Lj.colocando and e.ouro == 1000)

  -- Obras: cobrar, devolver, sem ouro, sem lucro
  jogo_novo()
  e = J.estado
  local preco1 = J.preco_metro()
  ok("preço do metro vem do config", preco1 == C.obra_metro_base)
  e.ouro = 10000
  local feito, r = J.obra("dir", 3)
  local p1, p2, p3 = preco1, J.preco_metro(-1), J.preco_metro()
  ok("aumentar cobra", feito and r.metros == 3 and r.custo > 0 and e.ouro == 10000 - r.custo and L.tamanho.dir == 3)
  ok("preço cresce com o tamanho", J.preco_metro() > preco1, J.preco_metro())
  ok("guarda o pago por lado", #e.obras.dir == 3)
  local pago = r.custo
  local ultimo = e.obras.dir[3]
  local antes = e.ouro
  feito, r = J.obra("dir", -1)
  ok("diminuir devolve 50% do último metro", feito and r.devolve == math.floor(ultimo * 0.5) and e.ouro == antes + r.devolve and L.tamanho.dir == 2)
  feito, r = J.obra("dir", -2)
  ok("volta ao original", L.tamanho.dir == 0 and #e.obras.dir == 0)
  ok("aumentar e diminuir nunca dá lucro", e.ouro < 10000 and e.ouro >= 10000 - pago)
  antes = e.ouro
  feito, r = J.obra("dir", -1)
  ok("abaixo do original não devolve", feito and r.devolve == 0 and e.ouro == antes and L.tamanho.dir == -1)
  feito, r = J.obra("dir", 1)
  antes = e.ouro
  ok("metro abaixo do original não entra na conta", #e.obras.dir == 0)
  feito, r = J.obra("dir", -1)
  ok("nem depois de pago abaixo do original", e.ouro == antes)
  J.obra("dir", 1)
  for _ = 1, 200 do
    local s0 = e.ouro
    J.obra("frente", 2)
    J.obra("frente", -2)
    if e.ouro > s0 then ok("laço aumenta e diminui sem lucro", false, e.ouro - s0) break end
  end
  ok("laço aumenta e diminui sem lucro", true)

  -- Sem ouro: para no último metro pago
  e.ouro = 0
  local orc = J.orcar_obra("oeste", 2)
  ok("sem ouro nenhum, orçamento mostra quanto falta", orc.metros == 0 and orc.falta > 0)
  feito, r = J.obra("oeste", 2)
  ok("sem ouro não muda nem cobra", not feito and r.falta > 0 and e.ouro == 0 and L.tamanho.oeste == 0)
  local um = J.preco_metro()
  e.ouro = um + 1
  orc = J.orcar_obra("oeste", 5)
  ok("para no último metro pago", orc.metros == 1 and orc.custo == um and orc.falta > 0, orc.metros)
  feito, r = J.obra("oeste", 5)
  ok("cobra só o que deu", feito and r.metros == 1 and e.ouro == 1 and L.tamanho.oeste == 1)
  ok("obra fica salva no save", util.desserializar(motor.carregar()).obras.oeste[1] == um)
  L.salvar()
  iniciar()
  J.noticia = nil
  ok("pago por metro volta do save", J.estado.obras.oeste[1] == um)
  ok("save estragado não trava a obra", (function()
    J.estado.obras = { dir = { "x", -3, 5 }, sumiu = { 1 } }
    motor.salvar(util.serializar(J.estado))
    iniciar()
    J.noticia = nil
    return #J.estado.obras.dir == 1 and J.estado.obras.sumiu == nil
  end)())

  -- Arrastando com o jogo rodando: dedo, fantasma, cobra só ao soltar, ninguém expulso
  jogo_novo()
  e = J.estado
  comprar("mesa", "garcom", "cozinha")
  J.por_item("mesa")
  local vx, vz = L.vaga_sala("cozinha", 0)
  J.por_sala("cozinha", vx, vz, 0)
  -- no motor falso a tela é reta: atrás da taverna a sala fica longe do painel
  local fxa, _, fza = L.salao()
  assert(L.mover_sala("cozinha", fxa, fza - 9.2))
  local cliente = { estado = "esperando", sentado = true, x = 0, z = 0, y = 0.42, giro = 0, rota = {}, t = 0, fase = 0, tipo = { nome = "comum" }, pedido = "bebida", pele = "#ffffff" }
  local lugar = J.lugares[1]
  cliente.lugar, lugar.dono = lugar, cliente
  cliente.x, cliente.z = lugar.x, lugar.z
  J.pessoas = { cliente }
  J.relogio_chegada = -1e6
  T.aba = "loja"
  Lj.aba = "comodos"
  quadros(1)
  local t0 = J.estado.tempo
  quadros(2)
  ok("tempo segue com a Loja aberta", J.estado.tempo > t0)
  U.apertar("loja_sala_cozinha")
  ok("selecionar pela lista", Lj.sel == "cozinha")
  local ouro0 = e.ouro
  local px0, pz0 = L.pos_sala("cozinha")
  local cx0, cx1, cz0, cz1 = L.sala_mundo("cozinha")
  -- dedo na sala, arrasta para a frente da taverna
  local function chao_para_tela(x, z) return 480 + x * 30, 300 + z * 26 end
  local sx, sy = chao_para_tela((cx0 + cx1) / 2, (cz0 + cz1) / 2 + 2)
  motor._baixo = true; motor._mouse = { sx, sy }
  atualizar(0.05); desenhar()
  T.tocar(sx, sy)
  ok("toque na sala começa o arrasto", Lj.arrasto and Lj.arrasto.tipo == "sala", Lj.arrasto and Lj.arrasto.tipo)
  motor._mouse = { sx + 3000, sy }
  atualizar(0.05); desenhar()
  ok("longe: fantasma vermelho com motivo", Lj.arrasto.f and not Lj.arrasto.f.ok and Lj.arrasto.f.motivo)
  ok("durante o arrasto a sala não andou", L.pos_sala("cozinha") == px0)
  motor._baixo = false
  T.soltar(sx + 3000, sy)
  ok("soltar em vermelho não move", L.pos_sala("cozinha") == px0)
  local alvox, alvoz = select(1, L.salao()) - (cx1 - cx0), select(3, L.salao())
  ok("o destino é válido", (L.encaixe_valido("cozinha", alvox, alvoz, 0)))
  sx, sy = chao_para_tela((cx0 + cx1) / 2, (cz0 + cz1) / 2 + 2)
  motor._baixo = true; motor._mouse = { sx, sy }
  T.tocar(sx, sy)
  motor._mouse = { sx + (alvox - cx0) * 30, sy + (alvoz - cz0) * 26 }
  atualizar(0.05); desenhar()
  ok("perto: fantasma verde", Lj.arrasto.f and Lj.arrasto.f.ok, Lj.arrasto.f and Lj.arrasto.f.motivo)
  motor._baixo = false
  T.soltar(motor._mouse[1], motor._mouse[2])
  ok("mover é grátis", e.ouro <= ouro0 + 1e6 and e.ouro >= ouro0 and L.pos_sala("cozinha") ~= px0)
  ok("mover grava o layout", (motor.carregar() or ""):find("_salas", 1, true) ~= nil)
  ok("moveu sem expulsar ninguém", cliente.lugar == J.lugares[1] or cliente.lugar.dono == cliente)
  quadros(2)
  ok("cliente continua sentado depois da obra", #J.pessoas >= 1 and cliente.lugar ~= nil and cliente.lugar.dono == cliente)

  -- alça: puxa, o fantasma orça, cobra ao soltar
  Lj.selecionar("taverna")
  desenhar()
  local al
  for _, a in ipairs(Lj.alcas()) do if a.p.chave == "frente" then al = a end end
  ok("alça da taverna aparece", al ~= nil)
  e.ouro = J.preco_metro() + 5
  local ouro1 = e.ouro
  motor._baixo = true; motor._mouse = { al.x, al.y }
  T.tocar(al.x, al.y)
  ok("toque pega a alça", Lj.alca ~= nil)
  motor._mouse = { al.x, al.y + 26 * 4 }
  atualizar(0.05); desenhar()
  ok("sem ouro, fantasma para no último metro pago", Lj.alca.orc.metros == 1 and Lj.alca.orc.falta > 0, Lj.alca.orc.metros)
  ok("nada cobrado enquanto arrasta", e.ouro >= ouro1 and L.tamanho.frente == 0)
  e.ouro = 0
  atualizar(0.01)
  e.ouro = ouro1
  motor._baixo = false
  T.soltar(al.x, al.y + 26 * 4)
  ok("cobra ao soltar", L.tamanho.frente == 1 and e.ouro < ouro1 + 50, L.tamanho.frente)
  ok("cliente continua sentado depois de aumentar", cliente.lugar ~= nil and cliente.lugar.dono == cliente)

  -- gastou enquanto arrastava: confere de novo ao soltar
  desenhar()
  for _, a in ipairs(Lj.alcas()) do if a.p.chave == "dir" then al = a end end
  e.ouro = 1e6
  motor._baixo = true; motor._mouse = { al.x, al.y }
  T.tocar(al.x, al.y)
  motor._mouse = { al.x + 30 * 3, al.y }
  atualizar(0.05)
  e.ouro = 0
  motor._baixo = false
  local dir0 = L.tamanho.dir
  T.soltar(al.x + 30 * 3, al.y)
  ok("ouro conferido de novo ao soltar", L.tamanho.dir == dir0 and e.ouro == 0)

  -- Porta
  Lj.selecionar("porta")
  desenhar()
  local lado0 = L.pos_porta()
  sx, sy = motor.projetar(J.PORTA.x, 1, J.PORTA.z)
  motor._baixo = true; motor._mouse = { sx, sy }
  T.tocar(sx, sy)
  local fx0, fx1, fz0, fz1 = L.sala_mundo("taverna")
  motor._mouse = { chao_para_tela((fx0 + fx1) / 2, fz1 + 0.5) }
  atualizar(0.05); desenhar()
  ok("porta arrastada mostra o lado", Lj.arrasto and Lj.arrasto.f and Lj.arrasto.f.lado == "frente", Lj.arrasto and Lj.arrasto.f and Lj.arrasto.f.lado)
  motor._baixo = false
  T.soltar(motor._mouse[1], motor._mouse[2])
  ok("porta muda de parede de graça", L.pos_porta() == "frente" and lado0 ~= "frente")

  -- saves antigos e auto_colocar: nada muda
  J.auto_colocar = true
  motor._layout = nil
  novo()
  ok("auto: sem contador", J.estado.colocados == nil and not J.manual())
  libera("mesa")
  ok("auto: mesa conta na hora", J.num_mesas() == 2 and J.total_para_colocar() == 0)
  libera("cozinha")
  ok("auto: sala abre na hora", L.aberta("cozinha"))
  J.auto_colocar = false
  novo()
  J.estado.mantimentos = nil
  J.salvar()
  iniciar()
  ok("save antigo coloca sozinho", not J.manual())
  libera("mesa")
  ok("save antigo: mesa conta na hora", J.num_mesas() == 2)
  ok("auto também tem a aba", (function() T.aba = "loja"; quadros(1); return U.apertar("loja_aba_comodos") end)())
  J.auto_colocar = true
  T.aba = "taverna"
  motor._layout = nil
  novo()
  J.sem_noticias = true
end

-- Começo endividado ------------------------------------------------------------------------------
novo()
do
  J.comecar_endividado()
  J.noticia = nil
  local e = J.estado
  ok("começa devendo e sem ouro", e.divida == C.divida_inicial and e.ouro == 0)
  ok("primeiro empréstimo disponível", J.pode_emprestimo())
  ok("empréstimo dá ouro e aumenta a dívida", J.pegar_emprestimo() and e.ouro == C.emprestimo and e.divida > C.divida_inicial)
  ok("não dá para pegar outro à toa", not J.pode_emprestimo())
  ok("compra mantimentos pagando", J.comprar_mantimentos("comida") and e.mantimentos.comida == C.lote_mantimentos and e.ouro < C.emprestimo)
  local q = J.novo_cliente()
  q.estado, q.pedido = "esperando", "bebida"
  e.mantimentos.bebida = 0
  ok("sem bebida não serve", not J.servir(q))
  q.pedido = "comida"
  local d0, o0 = e.divida, e.ouro
  ok("com comida serve e gasta 1", J.servir(q) and e.mantimentos.comida == C.lote_mantimentos - 1)
  ok("parte do ganho paga a dívida", e.divida < d0 and e.ouro > o0)
  e.ouro = 0; e.mantimentos.comida = 0
  ok("sem nada, o agiota socorre", J.pode_emprestimo())
  local f = J.fracao_custo("comida")
  e.nos.cozinha = 1
  J.ajustar_equipe()
end
novo()
ok("save antigo não tem mantimentos: serve como antes", J.estado.mantimentos == nil)
ok("gerente existe", J.gerente ~= nil)
-- Salas em blocos: posição, encaixe, portas, paredes e andares ------------------------------------
do
  local L, Mu = require("layout"), require("mundo")
  local function zerar()
    motor._layout = false
    novo()
    J.sem_noticias = true
  end
  local function perto(a, b) return math.abs(a - b) < 0.001 end
  local function abre(...)
    for _, id in ipairs({ ... }) do libera(id) end
  end

  -- posição e primeira vaga
  zerar()
  abre("ala_leste", "cozinha", "cervejaria", "pomar")
  local _, xb, za, zb = L.salao()
  local xa = L.salao()
  local cx, cz, ca = L.pos_sala("cozinha")
  ok("primeira vaga: colada na ala leste", perto(cx, xb + 5.5) and perto(cz, za) and ca == 0, cx)
  ok("segunda vaga: colada na anterior", perto((L.pos_sala("cervejaria")), cx + 5.5))
  ok("externa na frente da taverna", perto((L.pos_sala("jardim")), xa) and perto(select(2, L.pos_sala("jardim")), 4.8))
  local tx, tz = L.pos_sala("taverna")
  ok("taverna tem posição", perto(tx, xa) and perto(tz, za))

  -- encaixe: cada regra com o motivo em português
  local function recusa(nome, trecho, ...)
    local bom, motivo = L.encaixe_valido(...)
    ok("recusa: " .. nome, not bom, motivo)
    ok("motivo de " .. nome, type(motivo) == "string" and motivo:find(trecho, 1, true) ~= nil, motivo)
  end
  recusa("em cima da taverna", "em cima", "pomar", 0, 0, 0)
  recusa("em cima de outra sala", "em cima", "pomar", cx, cz, 0)
  recusa("interna solta", "encostar", "cervejaria", 40, 40, 0)
  recusa("interna com pouca parede comum", "2 m", "cervejaria", xa - 5.5, za - 8.2)
  recusa("externa no segundo andar", "construído", "jardim", 0, 30, 1)
  recusa("andar que não existe", "construído", "cervejaria", 40, 0, -1)
  recusa("externa longe demais", "Longe", "pomar", 100, 100, 0)
  recusa("sala desconhecida", "desconhecida", "nada", 0, 0, 0)
  ok("mover recusado não muda nada", not L.mover_sala("pomar", 0, 0) and L.pos_sala("pomar") ~= 0)

  -- passo de 1 m: longe de parede, cai na grade da taverna
  local bom, _, sx = L.encaixe_valido("pomar", xa - 10.3, 7, 0)
  ok("passo de 1 m", bom and perto((sx - xa) % 1, 0), sx)
  local _, _, _, ez = L.encaixe_valido("pomar", xa - 3, zb + 0.3, 0)
  ok("a menos de meio metro, encosta", ez == zb or ez == 4.8, ez)

  -- quatro lados: interna atrás, à esquerda e na frente; os filhos vão junto e a parede comum existe
  local function dentro_da_sala(sala, filho)
    local x0, x1, z0, z1 = L.sala_mundo(sala)
    local o, dx, dz = L.POR_ID[filho], L.desloc(filho)
    return o.x + dx >= x0 and o.x + dx <= x1 and o.z + dz >= z0 - 0.3 and o.z + dz <= z1
  end
  for _, lado in ipairs({ { "atrás", xa, za - 9.2 }, { "esquerda", xa - 5.5, za }, { "frente", xa + 7, zb } }) do
    local nx, nz = lado[2], lado[3]
    -- a cervejaria tem que sair da fileira sem a jardim atrapalhar
    if lado[1] == "frente" then
      assert(L.mover_sala("pomar", xa - 9, zb + 1))
      assert(L.mover_sala("jardim", xa - 18, zb + 1))
    end
    local m1, m2 = L.mover_sala("cervejaria", nx, nz)
    ok("cervejaria vai para " .. lado[1], m1, m2)
    ok("filhos seguem " .. lado[1], dentro_da_sala("cervejaria", "tina") and dentro_da_sala("cervejaria", "bancada"))
    local px, pz = L.pos_sala("cervejaria")
    ok("posição salva " .. lado[1], perto(px, nx) and perto(pz, nz))
    local tem_porta = false
    for _, p in ipairs(L.portas(0)) do
      if (p.dono == "cervejaria" or p.vizinho == "cervejaria") and p.c >= p.a and p.c <= p.b then tem_porta = true end
    end
    ok("porta nasce em " .. lado[1], tem_porta)
    J.aplicar_obra(); desenhar()
    Mu.atualizar(0.1)
    local _, x1q, z0q, z1q = L.sala_mundo("cervejaria")
    local x0q = L.sala_mundo("cervejaria")
    local q = Mu.calcular_enquadramento(Mu.alvos())
    local alc = math.max(x1q - x0q, z1q - z0q)
    ok("enquadramento inclui a sala em " .. lado[1], q.largura >= x1q - x0q and q.fundo >= alc * 0.3, q.largura)
    assert(L.mover_sala("cervejaria", select(2, L.salao()) + 11, za))
  end

  -- parede: sala atrás deixa o trecho baixo; sem nada atrás, continua alta
  zerar()
  abre("ala_leste", "cervejaria")
  xa, xb, za, zb = L.salao()
  ok("nada atrás: fundo alto", #L.trechos_baixos("taverna", "fundo") == 0)
  assert(L.mover_sala("cervejaria", xa, za - 9.2))
  ok("sala atrás: fundo baixo", L.parede_baixa("taverna", "fundo", xa + 2), L.parede_baixa("taverna", "fundo", xa + 2))
  ok("só o trecho dela", not L.parede_baixa("taverna", "fundo", xb))
  local alturas, velho = {}, rawget(motor, "peca")
  rawset(motor, "peca", function(_, x, y, z, _, ey, _, _, c)
    if c == "#4f3522" and x > xa + 0.5 and x < xa + 3 and math.abs(z - (za - 0.2)) < 0.05 then alturas[#alturas + 1] = ey end
  end)
  Mu.desenhar_cena()
  rawset(motor, "peca", velho)
  ok("desenha parede baixa de verdade", #alturas > 0 and math.max(table.unpack(alturas)) < 2, alturas[1])
  J.aplicar_obra()

  -- porta da rua: anda só por parede livre, foge quando coberta, e as rotas seguem
  zerar()
  abre("mesa", "ala_leste")
  xa, xb, za, zb = L.salao()
  local pl, pt = L.pos_porta()
  ok("porta começa na parede de sempre", pl == "oeste" and perto(pt, 6.1), pt)
  local ao, am = L.mover_porta("fundo", 9.5)
  ok("porta recusa as prateleiras", not ao and am and am:find("Prateleiras", 1, true), am)
  ao, am = L.mover_porta("oeste", 0.2)
  ok("porta recusa canto", not ao)
  L.de("prateleira").oculto = true
  for _, c in ipairs({ { "fundo", 6.5 }, { "leste", 3 }, { "frente", 4 }, { "oeste", 6 } }) do
    ao, am = L.mover_porta(c[1], c[2])
    ok("porta na parede " .. c[1], ao, am)
    J.aplicar_obra()
    local nl = L.pos_porta()
    ok("posição da porta " .. c[1], nl == c[1], nl)
    ok("todo lugar tem rota com a porta em " .. c[1], J.lugares_sem_rota() == 0, J.lugares_sem_rota())
    local sx0, sz0 = J.PORTA.x, J.PORTA.z
    local dentro = sx0 >= xa and sx0 <= xb + 5.5 and sz0 >= za and sz0 <= zb
    ok("J.PORTA acompanha em " .. c[1], dentro, sx0 .. "," .. sz0)
  end
  -- sala cobre a parede: a porta sai sozinha, para outro lugar livre
  assert(L.mover_porta("oeste", 6))
  L.de("prateleira").oculto = nil
  J.aplicar_obra()
  abre("cervejaria")
  assert(L.mover_sala("cervejaria", xa - 5.5, za))
  local fl = L.pos_porta()
  ok("porta foge da sala que a cobre", fl ~= "oeste" or not L.porta_livre("oeste", 6), fl)
  ok("lugar novo é livre", (function() local a, b = L.pos_porta(); return (L.porta_livre(a, b)) end)())
  atualizar(0.1)
  ok("o jogo percebe a porta nova sem expulsar ninguém", perto(J.PORTA.x, (L.t("porta", -6.4, 1.6))))

  -- taverna: tudo vai junto; sala encostada não fica sem acesso
  zerar()
  abre("mesa", "balcao")
  local mesa_x = J.POS_MESAS[1].x
  xa, xb, za, zb = L.salao()
  ok("taverna move sem nada aberto", L.mover_sala("taverna", xa + 3, za + 2))
  J.aplicar_layout()
  ok("mesa foi junto", perto(J.POS_MESAS[1].x, mesa_x + 3), J.POS_MESAS[1].x)
  ok("porta foi junto", perto(J.PORTA.x, -6.4 + 3), J.PORTA.x)
  ok("garçom em casa junto", #J.garcons == 0 or perto(J.garcons[1].casa, -0.35 + 3))
  ok("rotas seguem com a taverna movida", J.lugares_sem_rota() == 0, J.lugares_sem_rota())
  zerar()
  abre("ala_leste", "cozinha")
  xa, xb, za, zb = L.salao()
  local mt, mm = L.mover_sala("taverna", xa - 30, za)
  ok("taverna não abandona a sala", not mt and mm:find("sem acesso", 1, true), mm)
  ok("sala do meio não sai e deixa a outra sem acesso", (function()
    abre("cervejaria")
    local a, b = L.mover_sala("cozinha", xa - 5.5, za)
    return not a and b:find("sem acesso", 1, true)
  end)())

  -- gente de obra: fazendeiro, cervejeiro, cozinheiro e vacas seguem as salas
  zerar()
  abre("ala_leste", "cozinheiro", "fazendeiro", "fazenda", "cervejaria")
  for _ = 1, 3 do J.estado.ouro = 1e20; J.comprar_no("fazenda") end
  J.aplicar_obra()
  xa, xb, za, zb = L.salao()
  assert(L.mover_sala("fazenda", xb + 11, za - 6))
  assert(L.mover_sala("pomar", xa - 16, za - 6))
  assert(L.mover_sala("jardim", xa - 8, za - 6))
  local mz, mo = L.mover_sala("circulo", xa - 5.5, za)
  ok("círculo fechado não importa", mz or mo)
  local fx0, fx1, fz0, fz1 = L.sala_mundo("fazenda")
  Mu.iniciar()
  local vacas_dentro, cozinheiro_dentro = true, true
  for _ = 1, 150 do
    Mu.atualizar(0.2)
    for i, v in pairs(Mu.vacas) do
      local wx, wz = L.t("fazenda", v.x, v.z)
      if wx < fx0 or wx > fx1 or wz < fz0 or wz > fz1 then vacas_dentro = false end
    end
    local c = Mu.cozinheiro
    if c then
      local wx, wz = L.t("cozinheiro", c.x, c.z)
      local ax, bx, az, bz = L.sala_mundo("cozinha")
      if wx < ax or wx > bx or wz < az or wz > bz then cozinheiro_dentro = false end
    end
  end
  ok("vacas ficam na fazenda movida", vacas_dentro)
  ok("cozinheiro fica na cozinha", cozinheiro_dentro)
  ok("desenha com tudo espalhado", pcall(Mu.desenhar_cena))

  -- andares
  zerar()
  ok("sem o nó, um andar só", #L.andares() == 1)
  ok("nó do segundo andar é filho de quartos", A.POR_ID.segundo_andar.pai == "quartos")
  ok("nó do subsolo é filho do segundo", A.POR_ID.subsolo.pai == "segundo_andar")
  ok("andar trancado não abre", not L.mudar_andar(1))
  J.estado.ouro = 0
  ok("sem botão com um andar", (function() U.limpar(); Mu.desenhar_botoes_andar(); return #U.zonas == 0 end)())
  abre("subsolo", "ala_leste", "cozinha")
  ok("nó abre os dois", #L.andares() == 3)
  ok("botões com mais de um", (function() U.limpar(); Mu.desenhar_botoes_andar(); return #U.zonas == 3 and U.zonas[1].x < 80 end)())
  ok("salas novas no segundo andar", select(3, L.pos_sala("quartos_sala")) == 1 and select(3, L.pos_sala("sala_guilda")) == 1)
  ok("hall é a base do andar: quartos encostam nele", perto((L.pos_sala("quartos_sala")), select(2, L.salao())))
  ok("quartos não descem", not L.encaixe_valido("quartos_sala", 40, 0, 0))
  local vx, vz = L.vaga_sala("cozinha", -1)
  local mb, mbm = L.mover_sala("cozinha", vx, vz, -1)
  ok("cozinha desce para o subsolo", mb, mbm)
  ok("filho sabe o andar", L.andar_de("fogao") == -1)

  local pecas = 0
  rawset(motor, "peca", function() pecas = pecas + 1 end)
  local function conta_cena() pecas = 0; Mu.desenhar_cena(); return pecas end
  local fim = {}
  for _, n in ipairs({ 0, 1, -1 }) do
    L.mudar_andar(n)
    fim[n] = conta_cena()
    ok("andar " .. n .. " desenha", fim[n] > 30, fim[n])
  end
  ok("cada andar tem o que é dele", fim[0] ~= fim[1] and fim[1] ~= fim[-1])
  rawset(motor, "peca", velho)

  -- pessoa de um andar só aparece nele
  L.mudar_andar(0)
  J.pessoas[#J.pessoas + 1] = { x = 0, y = 0, z = 0, giro = 0, fase = 0, t = 0, rota = {}, estado = "esperando", pedido = "bebida", tipo = J.TIPOS[1], pele = "#fff", andar = 1 }
  local visivel = 0
  rawset(motor, "peca", function() visivel = visivel + 1 end)
  Mu.desenhar_cena()
  local em_baixo = visivel
  L.mudar_andar(1); visivel = 0
  Mu.desenhar_cena()
  rawset(motor, "peca", velho)
  ok("cliente lá de cima só aparece lá", em_baixo < fim[0] + 1 and visivel > fim[1], visivel)
  table.remove(J.pessoas)
  L.mudar_andar(0)

  -- andar some em outro save: volta ao térreo
  L.mudar_andar(-1)
  zerar()
  ok("sem o andar, volta ao térreo", L.andar_ativo == 0)

  -- salvar e carregar: tudo o que é bloco persiste
  zerar()
  abre("ala_leste", "cozinha", "subsolo")
  xa, xb, za, zb = L.salao()
  assert(L.mover_sala("jardim", xa - 9, zb + 1))
  assert(L.mover_sala("cozinha", xa + 2, zb))
  assert(L.mover_sala("taverna", xa + 1, za))
  assert(L.mover_porta("frente", 11))
  xa, xb, za, zb = L.salao()
  local jx2, jz2 = L.pos_sala("jardim")
  local px2, pz2 = L.pos_sala("cozinha")
  L.carregar(L.exportar())
  ok("carrega posição", perto((L.pos_sala("jardim")), jx2) and perto(select(2, L.pos_sala("jardim")), jz2))
  ok("carrega taverna", perto((L.salao()), xa))
  ok("carrega porta", (L.pos_porta()) == "frente" and perto(select(2, L.pos_porta()), 11))
  ok("o salvo guarda os blocos", L.exportar()._salas ~= nil and L.exportar()._porta ~= nil)
  ok("carrega sala interna", perto((L.pos_sala("cozinha")), px2) or perto(select(2, L.pos_sala("cozinha")), pz2))
  zerar()

  -- layouts antigos: nada se perde
  motor._layout = util.serializar({ jardim = { x = 2, z = 3, y = 0, g = 0 }, cozinha = { x = 1, z = 0, y = 0, g = 0 }, mesa1 = { x = 1, z = 1, y = 0, g = 0 },
    porta = { x = 0, z = -1, y = 0, g = 0 }, _tamanho = { frente = 2, fundo = 1 } })
  novo()
  abre("cozinha", "jardim")
  ok("antigo: mesa onde estava", perto(L.dados.mesa1.x, 1))
  local aj, ajz = L.pos_sala("jardim")
  local ax, _, _, az1 = L.salao()
  ok("antigo: jardim continua deslocado", perto(aj, ax + 2), aj)
  ok("antigo: jardim fora da taverna", ajz >= az1, ajz)
  local _, _, kz0, kz1 = L.sala_mundo("cozinha")
  ok("antigo: cozinha com a mesma profundidade do salão", perto(kz1 - kz0, 9.2 + 3), kz1 - kz0)
  ok("antigo: conteúdo da cozinha deslocado", L.dados.cozinha.x == 1)
  ok("antigo: porta no mesmo lugar", perto(select(2, L.desloc("porta")), -1) and (L.pos_porta()) == "oeste")
  L.salvar()
  local salvo = util.desserializar(motor._save).layout
  ok("antigo vira novo ao salvar", type(salvo._salas) == "table" and salvo._salas.jardim ~= nil and salvo.jardim == nil)

  -- arquivo estragado não derruba
  motor._layout = util.serializar({ _salas = { jardim = "x", cozinha = { x = "a", z = {} }, nada = { x = 1, z = 1 }, pomar = { x = 1 / 0, z = 0 / 0, andar = 9 } },
    _taverna = "lixo", _porta = { lado = "nada", t = "x" } })
  novo()
  ok("arquivo estragado: abre", pcall(Mu.desenhar_cena))
  libera("jardim")
  ok("arquivo estragado: sala aberta tem lugar", type((L.pos_sala("jardim"))) == "number")

  -- recusas que continuam valendo na Loja
  zerar()
  abre("ala_leste", "cozinha", "jardim")
  local ai, aj2 = L.pos_sala("cozinha")
  ok("subir sala: nada sem o andar", not L.encaixe_valido("cozinha", ai, aj2, 1))
  local fx0, _, _, fz1 = L.sala_mundo("taverna")
  local pf, pm = L.mover_porta("frente", 2)
  ok("porta recusa parede coberta", not pf and pm and pm:find("coberta", 1, true) and (L.pos_porta()) == "oeste", pm)
  zerar()
end

-- Caminho de pedras: mural e mercadinho do lado de fora, sem ninguém entrar por causa deles -------
do
  local L, Mu, Lj, S = require("layout"), require("mundo"), require("loja"), require("saves")
  motor._layout = false
  novo()
  ok("sem mural nem mercadinho não há caminho", not L.aberta("caminho"))
  libera("prateleira")
  ok("o mural abre o caminho", L.aberta("caminho") and J.prateleira_aberta())
  ok("caminho não fica dentro da taverna", (function()
    local x0, x1, z0, z1 = L.sala_mundo("caminho")
    local a, b, c, d = L.sala_mundo("taverna")
    return x0 >= b or x1 <= a or z0 >= d or z1 <= c
  end)())
  ok("caminho sem alça de tamanho", (function()
    for _, a in ipairs(L.paredes()) do if a.id:find("caminho") then return false end end
    return L.tamanho.caminho_l == nil
  end)())
  libera("mercadinho")
  -- ninguém que vem pela missão ou pelo espólio entra na taverna
  J.relogio_aventureiro = 99
  J.relogio_chegada = -1e9
  local n_dentro, viu_fora, vendeu = 0, false, false
  local espolios = J.estado.espolios
  local x0, x1, z0, z1 = L.sala_mundo("caminho")
  local fora_da_faixa = 0
  for i = 1, 600 do
    if i % 40 == 1 then J.estado.missoes[#J.estado.missoes + 1] = { rank = 1, resta = 0.01 } end
    J.relogio_chegada = -1e9
    atualizar(0.1)
    for _, q in ipairs(J.pessoas) do if not q.menestrel then n_dentro = n_dentro + 1 end end
    for _, p in ipairs(J.visitantes) do
      viu_fora = true
      if p.z < z0 or p.z > z1 or p.x < x0 - 1 or p.x > x1 + 1 then fora_da_faixa = fora_da_faixa + 1 end
      if p.estado == "vendendo" then vendeu = true end
    end
    if i % 50 == 0 then desenhar() end
  end
  ok("quem vem de missão fica lá fora", viu_fora)
  ok("missão não põe ninguém no salão", n_dentro == 0, n_dentro)
  ok("visitantes não saem do caminho", fora_da_faixa == 0, fora_da_faixa)
  ok("espólio é vendido na barraca", vendeu and J.estado.espolios > espolios)
  ok("sem rota nenhuma lá fora", (J.sem_caminho or 0) == 0)
  ok("visitantes não vão para o save", (function()
    J.salvar()
    return not motor._save:find("visitantes", 1, true)
  end)())
  -- a comemoração passa para o próximo cliente que entra
  J.festas = 1
  J.relogio_chegada = 0
  local c = J.novo_cliente()
  ok("próximo cliente comemora a missão", c and c.festa == true and J.festas == 0)
  -- visitantes têm teto: passou dele, só o ouro entra
  J.visitantes = {}
  for _ = 1, J.MAX_VISITANTES + 5 do J.estado.missoes[#J.estado.missoes + 1] = { rank = 1, resta = 0.001 } end
  local o0 = J.estado.total
  J.atualizar(0.01)
  ok("teto de gente lá fora", #J.visitantes <= J.MAX_VISITANTES, #J.visitantes)
  ok("mesmo acima do teto o ouro entra", J.estado.total > o0)

  -- mover o caminho leva o mural, a barraca e quem está lá
  J.visitantes = {}
  J.iniciar_missao_comum(1)
  local v = J.visitantes[1]
  atualizar(0.1)
  local qx, bx = J.QUADRO.x, J.BARRACA.x
  local vx = v.x
  local cx, cz = L.pos_sala("caminho")
  local _, _, _, zb = L.salao()
  assert(L.mover_sala("caminho", cx + 2, zb + 4))
  J.atualizar(0.001)
  ok("mural anda com o caminho", math.abs(J.QUADRO.x - qx - 2) < 0.001, J.QUADRO.x)
  ok("mercadinho anda com o caminho", math.abs(J.BARRACA.x - bx - 2) < 0.001, J.BARRACA.x)
  ok("quem está lá anda junto", math.abs(v.x - vx - 2) < 0.1, v.x)
  ok("os dois ficam lado a lado", math.abs(J.QUADRO.x - J.BARRACA.x - 6) < 0.001 and math.abs(J.QUADRO.z - J.BARRACA.z) < 0.001)
  ok("caminho não vai para cima da taverna", not L.mover_sala("caminho", -6, -4))
  ok("caminho é ao ar livre", not L.encaixe_valido("caminho", 0, 30, 1))
  local xa0, _, za0 = L.salao()
  ok("caminho não vira parede coberta: taverna continua com porta", (L.porta_livre(L.pos_porta())))
  -- ala leste só com o nó dela, e as duas mesas continuam com rota
  ok("barraca não abre mais a ala", not L.leste_aberta())
  libera("ala_leste")
  ok("ala abre com o nó", L.leste_aberta())
  J.montar_mapa()
  ok("mesas da ala têm rota", J.lugares_sem_rota() == 0, J.lugares_sem_rota())
  ok("mesas da ala dentro da ala", (function()
    local a, b, c2, d = L.sala_mundo("taverna")
    for i = 7, 8 do
      local m = J.POS_MESAS[i]
      if m.x - 1.6 < select(2, L.salao()) or m.x + 1.6 > b or m.z - 0.9 < c2 or m.z + 0.9 > d then return false end
    end
    return true
  end)())

  -- Loja: o primeiro escolhe o lugar, o segundo entra ao lado
  J.auto_colocar = false
  motor._saves, motor._atual = {}, false
  motor._layout = false
  novo()
  J.comecar_endividado()
  J.noticia = nil
  local function comprar(...)
    for _, id in ipairs({ ... }) do J.estado.ouro = 1e20; ok("comprou " .. id, J.comprar_no(id)) end
  end
  local function item(id)
    for _, i in ipairs(J.para_colocar()) do if i.id == id then return i end end
  end
  J.estado.ouro = 1e20
  for _, id in ipairs(A.POR_ID.prateleira.pre) do J.estado.ouro = 1e20; J.estado.nos[id] = 1 end
  comprar("prateleira")
  ok("mural comprado espera lugar", item("mural") and not J.prateleira_aberta() and not L.aberta("caminho"))
  ok("sem mural não sai missão", (function() J.relogio_aventureiro = 99; J.atualizar(0.1); return #J.visitantes == 0 and #J.estado.missoes == 0 end)())
  T.iniciar(); T.aba = "loja"; quadros(1)
  Lj.iniciar()
  ok("botão do mural na lista", U.apertar("loja_item_mural") and Lj.colocando and Lj.colocando.id == "caminho" and Lj.colocando.fora == "mural")
  local c0 = Lj.colocando
  ok("caminho nasce em lugar livre", c0.ok, c0.motivo)
  c0.x, c0.z = 0, 0
  quadros(1)
  ok("fantasma vermelho em cima da taverna", not c0.ok and not Lj.confirmar() and not J.sala_posta("caminho"))
  local _, _, _, zb2 = L.salao()
  local xa2 = L.salao()
  c0.x, c0.z = xa2 + 2, zb2 + 3
  quadros(1)
  ok("colocar o mural", Lj.confirmar() and J.prateleira_aberta() and L.aberta("caminho"))
  local px, pz = L.pos_sala("caminho")
  ok("colocado onde foi escolhido", math.abs(px - (xa2 + 2)) < 0.6 and math.abs(pz - (zb2 + 3)) < 0.6, px)
  ok("não sobra nada do mural", not item("mural"))
  ok("mural funciona", (function() J.relogio_aventureiro = 99; J.atualizar(0.1); return #J.visitantes >= 1 end)())
  J.estado.nos.merc_x = nil
  comprar("mercadinho")
  ok("mercadinho espera na Loja", item("mercadinho") and not J.mercadinho_aberto())
  quadros(1)
  local p0x, p0z = L.pos_sala("caminho")
  ok("o segundo entra direto, sem escolher lugar", U.apertar("loja_item_mercadinho") and not Lj.colocando and J.mercadinho_aberto())
  ok("o caminho não mudou de lugar", L.pos_sala("caminho") == p0x and select(2, L.pos_sala("caminho")) == p0z)
  ok("nada mais para colocar", J.total_para_colocar() == 0, J.total_para_colocar())
  -- o contrário: mercadinho primeiro
  novo()
  J.comecar_endividado()
  J.noticia = nil
  for _, id in ipairs(A.POR_ID.prateleira.pre) do J.estado.nos[id] = 1 end
  comprar("prateleira", "mercadinho")
  ok("os dois na lista antes do caminho", item("mural") and item("mercadinho"))
  local ok1, m1 = J.por_fora("mercadinho")
  ok("mercadinho primeiro abre o caminho", ok1 and J.mercadinho_aberto() and L.aberta("caminho") and not J.prateleira_aberta(), m1)
  ok("mural depois", J.por_fora("mural") and J.prateleira_aberta())
  ok("não coloca duas vezes", not J.por_fora("mural"))
  ok("cena desenha", pcall(function() quadros(1) end))
  -- save antigo manual, com mural e mercadinho já funcionando: nada volta para a Loja
  J.estado.colocados.salas.caminho = nil
  J.estado.colocados.salas.mural = nil
  J.estado.colocados.salas.mercadinho = nil
  J.estado.colocados.com_caminho = nil
  J.salvar()
  iniciar()
  J.noticia = nil
  ok("save antigo manual mantém mural e mercadinho", J.manual() and J.prateleira_aberta() and J.mercadinho_aberto() and J.total_para_colocar() == 0, J.total_para_colocar())
  J.auto_colocar = true
  T.aba = "taverna"
  Lj.iniciar()
  -- layout antigo: o lugar de dentro do mural e da barraca não vale mais
  motor._layout = util.serializar({ quadro = { x = 5, z = 1, y = 0, g = 0 }, barraca = { x = -3, z = 2, y = 0, g = 0 }, estantes = { x = 1, z = 1, y = 0, g = 0 }, mesa1 = { x = 1, z = 0, y = 0, g = 0 } })
  L.carregar()
  ok("layout antigo larga o lugar antigo do mural", L.dados.quadro == nil and L.dados.barraca == nil and L.dados.estantes == nil)
  ok("layout antigo guarda o resto", L.dados.mesa1 and L.dados.mesa1.x == 1)
  motor._layout = false
  novo()
end

-- Mover itens pela Loja: todos, de graça, com o jogo rodando. Excluir só a decoração ---------------
do
  local L, Lj, Mu = require("layout"), require("loja"), require("mundo")
  motor._layout = false
  novo()
  J.estado.ouro = 1e60
  for _ = 1, 40 do for _, no in ipairs(A.NOS) do J.estado.ouro = 1e60; J.comprar_no(no.id) end end
  J.ajustar_equipe(); J.aplicar_obra()
  T.iniciar(); T.aba = "loja"; Lj.iniciar(); Lj.aba = "mover"
  quadros(1)
  ok("aba Mover existe", U.apertar("loja_aba_mover") and Lj.aba == "mover")
  local function centro(id)
    local x, y, n = 0, 0, 0
    for _, p in ipairs(Lj.contorno(L.POR_ID[id])) do x, y, n = x + p[1], y + p[2], n + 1 end
    return x / n, y / n
  end
  local function toque(x, y)
    -- direto na Loja: o motor falso não recua a câmera, e o item ficaria atrás do painel
    motor._mouse = { x, y }; motor._baixo = true
    Lj.tocar(x, y)
    Lj.atualizar(0.02)
    motor._baixo = false
    Lj.soltar()
  end
  J.pessoas, J.visitantes = {}, {}
  J.relogio_chegada, J.relogio_aventureiro = -1e9, -1e9
  -- qualquer item comprado responde ao toque, sem exceção
  for _, o in ipairs(L.OBJETOS) do
    if Lj.existe(o.id) then
      local ehsala = false
      local internas, externas = L.salas()
      for _, lista in ipairs({ internas, externas }) do
        for _, b in ipairs(lista) do if b.id == o.id then ehsala = true end end
      end
      if not ehsala and o.id ~= "taverna" then
        Lj.item = nil
        L.mudar_andar(L.andar_de(o.id))
        local x, y = centro(o.id)
        local achou = false
        for _ = 1, 16 do
          toque(x, y)
          if Lj.item == o.id then achou = true; break end
        end
        ok("dá para pegar " .. o.id, achou, Lj.item)
      end
    end
  end
  L.mudar_andar(0)
  -- o que está mais perto vence e sala não entra
  local px, py = centro("pilar3")
  ok("toque no pilar pega o pilar", Lj.candidatos(px, py)[1] == "pilar3", Lj.candidatos(px, py)[1])
  ok("sala não é item", (function()
    for _, c in ipairs(Lj.candidatos(centro("tina"))) do if c == "cervejaria" then return false end end
    return true
  end)())
  -- um clique sem arrastar só seleciona; soltar fora da janela não deixa o arrasto preso
  do
    Lj.item = nil
    local d0 = L.dados.mesa1 and L.dados.mesa1.x
    local mx1, my1 = centro("mesa1")
    motor._mouse = { mx1, my1 }; motor._baixo = true
    Lj.tocar(mx1, my1)
    for _ = 1, 5 do Lj.atualizar(0.1) end
    motor._baixo = false
    Lj.soltar()
    ok("clique seleciona", Lj.item == "mesa1", Lj.item)
    ok("clique não move", (L.dados.mesa1 and L.dados.mesa1.x) == d0)
    motor._baixo = true
    Lj.tocar(mx1, my1)
    motor._mouse = { mx1 + 8, my1 + 8 }
    Lj.atualizar(0.1)
    motor._baixo = false
    Lj.atualizar(0.1)
    ok("soltar fora da janela encerra o arrasto", Lj.arrasto == nil and Lj.camera == nil)
    motor._mouse = { 480, 270 }
  end
  -- caixa: tocar na ponta do balcão, longe do centro, ainda pega o balcão
  do
    local bo = L.POR_ID.balcao
    local bdx, bdz = L.desloc("balcao")
    local bx, by = motor.projetar(bo.x + bdx - 2.2, 0.5, bo.z + bdz)
    local bcx, bcy = motor.projetar(bo.x + bdx, 0.5, bo.z + bdz)
    ok("ponta longe do centro do balcão", util.distancia(bx, by, bcx, bcy) > 34)
    local pegou = false
    Lj.item = nil
    for _ = 1, 8 do
      toque(bx, by)
      pegou = pegou or Lj.item == "balcao"
    end
    ok("balcão responde pela caixa, não só pelo centro", pegou, Lj.item)
    toque(2, 530)
    ok("tocar no vazio tira a seleção", Lj.item == nil, Lj.item)
  end
  -- o que não foi comprado não existe para o toque
  novo()
  T.iniciar(); T.aba = "loja"; Lj.iniciar(); Lj.aba = "mover"
  ok("mesa não comprada não é tocada", not Lj.existe("mesa5") and Lj.existe("mesa1"))
  ok("sala fechada não é tocada", not Lj.existe("tina") and not Lj.existe("pilar1"))
  ok("mural e barraca só depois de comprados", not Lj.existe("quadro") and not Lj.existe("barraca"))
  ok("excluído não é tocado", (function()
    L.de("barril1").oculto = true
    local r = not Lj.existe("barril1")
    L.dados.barril1.oculto = nil
    return r
  end)())

  -- arrastar é de graça, com o jogo rodando, e só o fantasma anda até soltar
  libera("mesa", "mesa", "ala_leste", "cozinha", "pomar", "fazenda")
  J.estado.ouro = 123
  J.aplicar_obra()
  quadros(1)
  J.relogio_chegada = -1e9
  local t0 = J.estado.tempo
  local mx0, mz0 = L.t("mesa1", J.POS_MESAS[1].bx, J.POS_MESAS[1].bz)
  local sx, sy = centro("mesa1")
  motor._mouse = { sx, sy }; motor._baixo = true
  T.tocar(sx, sy)
  ok("toque seleciona a mesa", Lj.item == "mesa1" and Lj.arrasto and Lj.arrasto.tipo == "item", Lj.item)
  motor._mouse = { sx, sy + 13 }
  atualizar(0.05); desenhar()
  ok("jogo não pausa ao mover", J.estado.tempo > t0)
  ok("mesa não anda até soltar", L.t("mesa1", J.POS_MESAS[1].bx, J.POS_MESAS[1].bz) == mx0)
  ok("fantasma aparece", Lj.arrasto.f ~= nil)
  ok("câmera não foge", Lj.camera ~= nil)
  motor._baixo = false
  T.soltar(sx, sy + 13)
  ok("mesa foi", math.abs(J.POS_MESAS[1].z - mz0) > 0.2, Lj.arrasto and Lj.arrasto.tipo or J.aviso and J.aviso.texto)
  ok("mover é de graça", J.estado.ouro >= 123, J.estado.ouro)
  ok("salvou a posição", util.desserializar(motor._save).layout.mesa1 ~= nil)
  ok("todo lugar segue com rota", J.lugares_sem_rota() == 0, J.lugares_sem_rota())
  -- quem está sentado vai junto com a mesa
  local c = J.novo_cliente()
  local lug
  for _ = 1, 100 do
    J.relogio_chegada = -1e9
    atualizar(0.1)
    if c.sentado then lug = c.lugar; break end
  end
  ok("cliente sentou", lug ~= nil)
  local mesa_c = "mesa" .. lug.mesa
  local ax, az = L.t(mesa_c, J.POS_MESAS[lug.mesa].bx, J.POS_MESAS[lug.mesa].bz)
  local bom = false
  for _, d in ipairs({ { 0.5, 0 }, { -0.5, 0 }, { 0, 0.5 }, { 0, -0.5 }, { 0.75, 0.5 }, { -0.75, -0.5 } }) do
    if J.mover_item(mesa_c, ax + d[1], az + d[2]) then bom = true; break end
  end
  ok("a mesa ocupada anda", bom)
  atualizar(0.05)
  ok("o cliente acompanha a mesa", c.sentado and math.abs(c.x - c.lugar.x) < 0.01 and math.abs(c.z - c.lugar.z) < 0.01)

  -- os limites: fora das paredes não vai, e o motivo aparece
  local recusou, motivo = J.lugar_mover("balcao", 1000, 1000)
  ok("balcão não sai da taverna", not recusou and motivo:find("taverna", 1, true), motivo)
  recusou, motivo = J.lugar_mover("fogao", -100, 0)
  ok("fogão não sai da cozinha", not recusou and motivo:find("Cozinha", 1, true), motivo)
  ok("mesa não cola na outra", not J.lugar_mover("mesa2", J.POS_MESAS[1].x + 0.5, J.POS_MESAS[1].z))
  ok("mesa não fecha a porta", not J.lugar_mover("mesa2", J.PORTA.x + 1, J.PORTA.z))
  ok("barril não fecha a porta", not J.lugar_mover("barril4", J.PORTA.x + 0.5, J.PORTA.z))
  ok("posição inválida", not J.lugar_mover("mesa1", 0 / 0, 0) and not J.lugar_mover("nada", 0, 0))
  -- item de sala: sala movida leva o item, e o item volta ao que foi combinado
  local fx0, fz0 = L.desloc("fogao")
  local o = L.POR_ID.fogao
  ok("fogão anda dentro da cozinha", J.mover_item("fogao", o.x + fx0 + 0.5, o.z + fz0 + 0.5))
  ok("fogão andou", (L.desloc("fogao")) ~= fx0)
  ok("porta anda pela aba Mover", (function()
    Lj.item = nil
    local lado0 = L.pos_porta()
    local qx, qy = motor.projetar(J.PORTA.x, 1, J.PORTA.z)
    local xa, xb, za, zb = L.sala_mundo("taverna")
    Lj.tocar(qx, qy)
    local foi = Lj.arrasto and Lj.arrasto.tipo == "porta" or Lj.item ~= "porta"
    Lj.soltar(true)
    return foi
  end)())
  -- árvore e vaca vêm da árvore de habilidades: também andam
  ok("árvore anda", (function()
    local xz0, x1, z0, z1 = L.sala_mundo("pomar")
    return J.mover_item("arvore1", xz0 + 1, z1 - 1)
  end)())
  ok("árvore não cola na outra", (function()
    local a2 = L.POR_ID.arvore2
    local dx, dz = L.desloc("arvore2")
    return not J.lugar_mover("arvore1", a2.x + dx + 0.3, a2.z + dz)
  end)())
  -- passagem fechada volta atrás: um caixote gigante não há, então cerca o banco com o que dá
  local cruel = J.lugares_sem_rota
  local conta = 0
  J.lugares_sem_rota = function() conta = conta + 1; return conta == 1 and 0 or 1 end
  local bx0 = J.POS_MESAS[2].x
  local mover_ruim, m_ruim = J.mover_item("mesa2", bx0 + 0.25, J.POS_MESAS[2].z)
  J.lugares_sem_rota = cruel
  ok("fechar a passagem desfaz", not mover_ruim and m_ruim and math.abs(J.POS_MESAS[2].x - bx0) < 0.001, m_ruim)

  -- mercadinho e mural: tocar neles leva o caminho inteiro
  libera("prateleira", "mercadinho")
  J.aplicar_obra(); quadros(1)
  L.mudar_andar(0)
  local qx0 = L.pos_sala("caminho")
  local kx, ky = centro("barraca")
  motor._mouse = { kx, ky }; motor._baixo = true
  T.tocar(kx, ky)
  ok("barraca arrasta o caminho", Lj.arrasto and Lj.arrasto.tipo == "sala" and Lj.arrasto.id == "caminho", Lj.arrasto and Lj.arrasto.id)
  motor._baixo = false
  T.soltar(kx, ky)
  atualizar(0.02)

  -- excluir: só a decoração, com confirmação e sem devolver ouro
  J.auto_colocar = true
  J.estado.ouro = 1e6
  local xd = select(1, L.salao()) + 2
  local oks, _, did = J.comprar_decoracao("planta", xd + 3, 3)
  if not oks then oks, _, did = J.comprar_decoracao("planta", xd + 8, 0.25) end
  ok("comprou decoração", oks and did)
  Lj.aba = "mover"; Lj.item = "mesa1"; quadros(1)
  ok("mesa sem Excluir", not U.apertar("loja_excluir"))
  Lj.item = "barril1"; quadros(1)
  ok("barril da taverna sem Excluir", not U.apertar("loja_excluir"))
  ok("excluir recusa o que não é decoração", not J.excluir_decoracao("mesa1") and not J.excluir_decoracao("barril1") and not L.oculto("barril1"))
  Lj.item = did; quadros(1)
  local o0 = J.estado.ouro
  ok("decoração tem Excluir", U.apertar("loja_excluir") and Lj.excluindo)
  quadros(1)
  ok("confirma antes", L.POR_ID[did] ~= nil)
  U.apertar("loja_excluir_nao"); quadros(1)
  ok("não mantém", L.POR_ID[did] ~= nil and not Lj.excluindo)
  U.apertar("loja_excluir"); quadros(1)
  ok("sim apaga", U.apertar("loja_excluir_sim") and L.POR_ID[did] == nil and Lj.item == nil)
  ok("excluir não devolve ouro", J.estado.ouro <= o0 + J.ef("renda_quartos") * 10 + 1e6)
  -- celular continua com botões grandes
  motor.plataforma = "android"
  Lj.item = nil; quadros(1)
  for _, z in ipairs(U.zonas) do
    if z.id:find("^loja_") and z.fn then ok("alvo no celular " .. z.id, z.h >= 40, z.h) end
  end
  motor.plataforma = "desktop"
  ok("esc solta o item", (function() Lj.item = "mesa1"; T.esc(); return Lj.item == nil end)())
  T.aba = "taverna"
  Lj.iniciar()
  motor._layout = false
  novo()
end

-- Saves independentes: tamanhos, posições e decoração são de cada save --------------------------------
do
  local L, S, Lj = require("layout"), require("saves"), require("loja")
  motor._saves, motor._atual, motor._save, motor._layout = {}, false, false, false
  -- arquivo de layout antigo, de quando todos dividiam a mesma construção
  local antigo = util.serializar({ _tamanho = { dir = 3 }, mesa1 = { x = 0.5, z = 0.5, y = 0, g = 0 }, barril1 = { x = 0, z = 0, y = 0, g = 0, oculto = true },
    _extras = { { id = "extra_7", tipo = "planta", x = 2, z = 2 } } })
  motor._layout = antigo
  local function padrao()
    return L.tamanho.dir == 0 and not L.dados.mesa1 and not L.oculto("barril1") and L.POR_ID.extra_7 == nil and L.lista_extras()[1] == nil
  end
  -- jogo novo nasce do padrão, mesmo com o arquivo antigo presente
  S.novo("jogo2.sav")
  J.noticia = nil
  ok("jogo novo nasce do padrão", padrao())
  -- a construção de um save não passa para o outro
  L.mudar_tamanho("dir", 4)
  L.mudar_tamanho("frente", 2)
  Ed.mover_para("mesa2", 1, 1)
  J.estado.ouro = 1000
  local _, _, dec = J.comprar_decoracao("planta", 3, 3)
  ok("comprou decoração no save 2", dec ~= nil)
  ok("porta", L.mover_porta("frente", 6))
  J.aplicar_obra()
  J.salvar()
  local mesa2x = (L.desloc("mesa2"))
  S.novo("jogo3.sav")
  J.noticia = nil
  ok("outro jogo novo não herda nada", L.tamanho.dir == 0 and L.tamanho.frente == 0 and L.lista_extras()[1] == nil and L.pos_porta() == "oeste" and not L.dados.mesa2)
  L.mudar_tamanho("oeste", 2)
  J.salvar()
  S.abrir("jogo2.sav")
  ok("volta com a construção dele", L.tamanho.dir == 4 and L.tamanho.frente == 2 and L.tamanho.oeste == 0, L.tamanho.oeste)
  ok("volta com a decoração dele", L.POR_ID[dec] ~= nil)
  ok("volta com as posições dele", math.abs((L.desloc("mesa2")) - mesa2x) < 0.01 and L.pos_porta() == "frente")
  S.abrir("jogo3.sav")
  ok("e o outro com a dele", L.tamanho.oeste == 2 and L.tamanho.dir == 0 and L.POR_ID[dec] == nil and L.pos_porta() == "oeste")
  -- save de antes: pega a construção do arquivo antigo e passa a ter a própria
  motor._saves["progresso_v2.sav"] = util.serializar({ versao = 2, ouro = 50, nos = { mesa = 1 } })
  S.abrir("progresso_v2.sav")
  ok("save antigo herda o arquivo", L.tamanho.dir == 3 and L.dados.mesa1 and L.oculto("barril1") and L.POR_ID.extra_7 ~= nil)
  J.salvar()
  ok("agora ele guarda a própria", util.desserializar(motor._saves["progresso_v2.sav"]).layout._tamanho.dir == 3)
  L.mudar_tamanho("dir", 1)
  J.salvar()
  local arquivo_antes = motor._layout
  S.abrir("jogo3.sav")
  S.abrir("progresso_v2.sav")
  ok("depois de migrar não lê mais o arquivo", L.tamanho.dir == 4, L.tamanho.dir)
  ok("o arquivo antigo não é reescrito", motor._layout == arquivo_antes and motor._layout == antigo)
  -- mexer com o save não vaza para a tela inicial, que é sempre o padrão
  J.em_menu = true
  J.iniciar()
  ok("tela inicial mostra o padrão", padrao())
  J.em_menu = false
  -- save pronto nasce do padrão; depois guarda a dele
  ok("abre pronto", S.abrir_pronto(S.PRONTOS[2], true))
  J.offline = nil
  ok("save pronto nasce do padrão", L.tamanho.dir == 0 and not L.oculto("barril1") and L.POR_ID.extra_7 == nil)
  L.mudar_tamanho("dir", 2)
  J.salvar()
  ok("reabrir pronto guarda a construção", S.abrir_pronto(S.PRONTOS[2]) and L.tamanho.dir == 2)
  J.offline = nil
  ok("recomeçar pronto volta ao padrão", S.abrir_pronto(S.PRONTOS[2], true) and L.tamanho.dir == 0)
  J.offline = nil
  -- apagar o progresso apaga a construção daquele save, e só dela
  S.abrir("jogo2.sav")
  J.apagar_progresso()
  ok("apagar progresso volta ao padrão", padrao())
  S.abrir("jogo3.sav")
  ok("os outros saves ficam como estavam", L.tamanho.oeste == 2)
  -- layout estragado dentro do save não derruba
  for _, lixo in ipairs({ '"texto"', "12", "true", '{ ["_salas"] = "x", ["_tamanho"] = 3, ["mesa1"] = 5 }' }) do
    motor._saves["jogo3.sav"] = '{ ["versao"] = 2, ["ouro"] = 1, ["layout"] = ' .. lixo .. ' }'
    ok("layout estragado no save abre: " .. lixo, pcall(function() S.abrir("jogo3.sav"); quadros(2) end))
    ok("layout estragado não lê o arquivo antigo: " .. lixo, L.POR_ID.extra_7 == nil)
  end
  -- colocação manual: mesas, salas e caminho postos ficam no save, e o save não perde onde estão
  J.auto_colocar = false
  S.novo("jogo2.sav")
  J.noticia = nil
  for _, id in ipairs(A.POR_ID.prateleira.pre) do J.estado.nos[id] = 1 end
  J.estado.ouro = 1e9
  J.comprar_no("prateleira")
  local xa = L.salao()
  local _, _, _, zb = L.salao()
  ok("põe o mural", J.por_fora("mural", xa + 3, zb + 2))
  local cx, cz = L.pos_sala("caminho")
  J.salvar()
  S.abrir("jogo2.sav")
  ok("caminho fica onde foi posto", L.pos_sala("caminho") == cx and select(2, L.pos_sala("caminho")) == cz and L.aberta("caminho"))
  S.novo("jogo3.sav")
  ok("save novo sem caminho", not L.aberta("caminho"))
  J.auto_colocar = true
  motor._saves, motor._atual, motor._save, motor._layout = {}, false, false, false
  T.iniciar()
  J.em_menu = false
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
