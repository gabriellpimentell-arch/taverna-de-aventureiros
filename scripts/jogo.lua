-- =============================================================================
--  REGRAS DO JOGO: ouro, árvore, clientes, missões, mercadinho, jardim,
--  contratados, parties, heróis, propaganda, invocação e final.
--  Nada aqui desenha: assim os testes conseguem jogar sem abrir janela.
-- =============================================================================

local C = require("config")
local A = require("arvore")
local util = require("util")
local L = require("layout")
local Cam = require("caminhos")

local J = {}

J.VERSAO_ARVORE = 3      -- sobe quando a forma da árvore muda: o save antigo passa pela migração

J.PORTA = { x = -6.4, z = 1.6 }
J.RUA_Z = 1.6
-- onde quem vem de fora para diante do mural e do mercadinho, na faixa de pedras
J.QUADRO = { x = 79, z = 0.1 }
J.BARRACA = { x = 73, z = 0.1 }

local POS_MESAS = {}
for i = 1, L.MESAS_MAX do
  local o = L.POR_ID["mesa" .. i]
  POS_MESAS[i] = { x = o.x, z = o.z, id = o.id, bx = o.x, bz = o.z }
end
J.POS_MESAS = POS_MESAS
J.BANCOS_BALCAO = { 1.4, 2.5, 3.6, 4.7 }

J.TIPOS = {
  { nome = "comum",     corpo = "#b58a5a", perna = "#4b3b2c", braco = "#a57a4e", temperamento = "calmo" },
  { nome = "comum",     corpo = "#6f8f6a", perna = "#3e3a2e", braco = "#607f5b", temperamento = "calmo" },
  { nome = "comum",     corpo = "#b76f62", perna = "#3f3734", braco = "#a7625a", temperamento = "calmo" },
  { nome = "guerreiro", corpo = "#a8b4bf", perna = "#4d5560", braco = "#8e99a4", temperamento = "bravo" },
  { nome = "guerreiro", corpo = "#a8b4bf", perna = "#6d3f2a", braco = "#b5483a", temperamento = "bravo" },
  { nome = "mago",      corpo = "#6d4bb3", perna = "#4a2f86", braco = "#5e3fa0", temperamento = "sabio" },
  { nome = "mago",      corpo = "#3e6db3", perna = "#27487f", braco = "#355f9e", temperamento = "sabio" },
  { nome = "arqueiro",  corpo = "#4f8a3c", perna = "#4b3b2c", braco = "#437531", temperamento = "orgulhoso" },
  { nome = "clerigo",   corpo = "#eadfca", perna = "#c9b98f", braco = "#ddd0b6", temperamento = "sabio" },
}
local PELES = { "#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a36" }
local CHAPEUS = { "#6b4a2f", "#3e5a4b", false, "#7a3a3a" }
local NOMES = { "Bruno", "Lia", "Tomás", "Iara", "Caio", "Nina", "Davi", "Rosa", "Otávio", "Maia",
  "Heitor", "Clara", "Igor", "Luna", "Rui", "Vera", "Joel", "Alma" }

-- histórias do menestrel: incentivam os aventureiros a pegar missões
local FOFOCAS = {
  "do dragão que dorme sobre uma montanha de ouro ao norte",
  "da guilda que derrotou um exército de goblins com uma única emboscada",
  "do nobre que paga em ouro a quem escoltar a sua caravana",
  "da espada encantada escondida nas ruínas além da floresta",
  "dos heróis antigos que começaram com uma simples missão de rank F",
  "do rei que oferece recompensas por cada monstro derrotado",
}

-- O que merece parar o jogo: "agora você pode liberar isto"
J.NOTICIAS = {
  { id = "mesa", titulo = "Mais espaço na taverna!", texto = "Agora você pode comprar uma Nova mesa. Mais lugares significam mais clientes ao mesmo tempo e mais ouro." },
  { id = "garcom", titulo = "Contrate um garçom!", texto = "Agora você pode contratar um Garçom. Ele serve os clientes sozinho e a taverna continua rendendo mesmo quando você não toca." },
  { id = "prateleira", titulo = "O mural de missões!", texto = "Agora você pode construir o Mural de missões. Aventureiros vão pegar missões e pagar quando voltarem." },
  { id = "bardo", titulo = "Um bardo na taverna!", texto = "Agora você pode chamar um Bardo. A música faz cada pedido render mais." },
  { id = "mercadinho", titulo = "O mercadinho!", texto = "Agora você pode abrir o Mercadinho. Os aventureiros voltam com espólios, você compra e revende com lucro." },
  { id = "jardim", titulo = "A fazenda de sementes!", texto = "Agora você pode abrir a Fazenda de sementes. Ela produz alimentos que abastecem a cozinha e a cervejaria." },
  { id = "fazendeiro", titulo = "Um fazendeiro!", texto = "Agora você pode contratar um Fazendeiro. Ele só cuida da fazenda de sementes e cada colheita rende mais." },
  { id = "cozinha", titulo = "A cozinha!", texto = "Agora você pode construir a Cozinha, uma sala só para preparar a comida. Ela abre espaço para o cozinheiro trabalhar." },
  { id = "pomar", titulo = "A fazenda de árvores frutíferas!", texto = "Agora você pode abrir a Fazenda de árvores frutíferas. Frutas viram tortas e sucos, e os pedidos passam a render mais." },
  { id = "fazenda", titulo = "A fazenda de animais!", texto = "Agora você pode abrir a Fazenda de animais e criar vacas, porcos e galinhas. Carne e ovos da casa fazem os pedidos renderem mais, e entra ouro todo segundo." },
  { id = "cozinheiro", titulo = "Um cozinheiro!", texto = "Agora você pode contratar um Cozinheiro. Ele usa o que você colhe e a comida passa a render bem mais." },
  { id = "cervejaria", titulo = "A cervejaria!", texto = "Agora você pode abrir a Cervejaria, com um cervejeiro próprio. As bebidas da casa rendem bem mais." },
  { id = "ala_leste", titulo = "Uma ala nova!", texto = "Agora você pode construir a Ala leste. A taverna cresce e ganha mais duas mesas." },
  { id = "sala_guilda", titulo = "A sala da guilda!", texto = "Agora você pode construir a Sala da guilda no segundo andar. O gerente sobe e passa a chefiar os aventureiros." },
  { id = "venda", titulo = "A aba de venda!", texto = "Agora você pode vender poções, armaduras e armas. O lucro do mercadinho também dobra." },
  { id = "recrutador", titulo = "O recrutador chegou!", texto = "Agora você pode trazer o Recrutador e contratar aventureiros próprios, que evoluem e trazem mais ouro." },
  { id = "party", titulo = "Parties!", texto = "Agora você pode juntar quatro aventureiros em uma party, um grupo mais forte que vai junto nas missões." },
  { id = "heroi", titulo = "O caminho do herói!", texto = "Agora seus contratados de rank A podem virar heróis e ganhar muito mais." },
  { id = "propaganda", titulo = "Propaganda!", texto = "Agora você pode divulgar seus heróis. A fama traz reputação, e a reputação atrai aventureiros de rank mais alto." },
  { id = "invocacao", titulo = "O círculo de invocação!", texto = "Agora você pode construir o Círculo e invocar heróis de outro mundo, os únicos capazes de enfrentar o Lorde Demônio." },
}
for _, r in ipairs({ { "rank_e", "E" }, { "rank_d", "D" }, { "rank_c", "C" }, { "rank_b", "B" }, { "rank_a", "A" }, { "rank_s", "S" }, { "rank_ss", "SS" } }) do
  J.NOTICIAS[#J.NOTICIAS + 1] = { id = r[1], titulo = "Missões rank " .. r[2] .. "!", texto = "Agora você pode abrir as missões rank " .. r[2] .. ". Elas pagam muito mais do que as anteriores." }
end

function J.procurar_noticia()
  local e = J.estado
  if J.noticia or J.em_menu or J.sem_noticias or J.offline or e.fim then return end
  for _, n in ipairs(J.NOTICIAS) do
    local no = A.POR_ID[n.id]
    if not e.noticias[n.id] and J.nivel(n.id) == 0 and J.no_liberado(no) and e.ouro >= J.custo_no(no) then
      e.noticias[n.id] = true
      J.noticia = n
      J.som("missao")
      return
    end
  end
  if J.pode_final() and not e.noticias._final then
    e.noticias._final = true
    J.noticia = { final = true, titulo = "Chegou a hora!", texto = "A party dos quatro heróis invocados está pronta para enfrentar o Lorde Demônio. Quando quiser, envie-os na aba Invocação." }
    J.som("invocar")
  end
end

-- O menestrel aparece, canta no meio da taverna e as missões passam a render mais
function J.chamar_menestrel()
  J.indice_fofoca = (J.indice_fofoca or 0) % #FOFOCAS + 1
  local historia = FOFOCAS[J.indice_fofoca]
  for _, p in ipairs(J.pessoas) do
    if p.menestrel then
      -- já tem um na taverna: emenda outra história
      J.comecar_historia(historia)
      return
    end
  end
  if #J.pessoas >= J.MAX_PESSOAS then
    J.comecar_historia(historia)
    return
  end
  local p = {
    x = J.PORTA.x, y = 0, z = J.PORTA.z, giro = math.pi / 2, fase = 0, t = 0, rota = {},
    tipo = { nome = "comum", corpo = "#c0562f", perna = "#3b2a3a", braco = "#a94a29", temperamento = "calmo" },
    pele = "#e0ac7e", chapeu = "#3a7a55", menestrel = true, estado = "menestrel_indo", historia = historia, pedido = "bebida",
  }
  local x, z = L.t("palco", -1.65, 0.2)
  J.vir_de_fora(p, 0)
  J.pessoas[#J.pessoas + 1] = p
  J.caminho(p, x, z)
  -- num salão enorme a caminhada é longa; o limite só existe para ele não ficar preso
  p.limite_palco = math.max(15, 3 * util.distancia(p.x, p.z, x, z) / C.velocidade_pessoa)
  J.flutuar(J.PORTA.x + 0.8, 2.5, J.PORTA.z, "Um menestrel chegou!", util.cores.verde, 18)
end

function J.comecar_historia(historia)
  J.buff = C.fofoca_duracao
  J.banner = {
    titulo = "O menestrel contou uma história",
    texto = "Ele cantou " .. historia .. ". Animados, os aventureiros correm atrás de missões: elas ficam mais rentáveis por " .. C.fofoca_duracao .. " segundos!",
    vida = 0, duracao = 8,
  }
  J.som("missao")
end


local function tipo_de(nome)
  local l = {}
  for _, t in ipairs(J.TIPOS) do if t.nome == nome then l[#l + 1] = t end end
  return util.escolher(l)
end

local function estado_inicial()
  return {
    versao = 2,
    arvore_v = J.VERSAO_ARVORE,
    compras = {},           -- tipo da Loja -> quantas unidades foram compradas
    ouro = 0, total = 0, servidos = 0, rps = 0, tempo = 0,
    nos = {},
    missoes = {},           -- { rank, resta, contratado = id }
    feitas = 0, feitas_rank = {},
    espolios = 0, lucro_espolios = 0,
    contratados = {},
    parties = {},
    prox_id = 1,
    invocados_feitos = 0,
    fama = 0,
    estoques = { trigo = 0, lupulo = 0, frutas = 0, carne_vaca = 0, carne_porco = 0, ovos = 0 },
    sementes = { lupulo = 0, fruta = 0 },
    ciclo = 0, colhido = 0,
    carroca = { presente = true, resta = C.carroca_fica, visitas = 1, vendidos = {} },
    raros = { comida = 0, bebida = 0 },   -- usos que sobram dos itens raros da carroça
    brigas = 0,
    final_resta = nil, fim = false,
    opcoes = { musica = 0.4, efeitos = 0.7, sombras = true, fps = false, fluxo = false },
    noticias = {},
    obras = {},             -- chave da parede -> preço pago em cada metro acima do tamanho original
  }
end

-- Efeitos da árvore -----------------------------------------------------------------

local ef = {}

-- Colocação manual: só no jogo novo. e.colocados nil (save antigo) ou J.auto_colocar (testes, robô)
-- põem tudo sozinho no lugar padrão, como sempre foi.
function J.manual()
  return not J.auto_colocar and J.estado ~= nil and J.estado.colocados ~= nil
end

-- sala -> nó da árvore que a compra
local NO_DA_SALA = { cozinha = "cozinha", cervejaria = "cervejaria", circulo = "invocacao", jardim = "jardim", pomar = "pomar",
  fazenda = "fazenda", quartos_sala = "quartos", sala_guilda = "sala_guilda",
  caminho = "prateleira", mercadinho = "mercadinho", mural = "prateleira" }
local ORDEM_SALAS = { "cozinha", "cervejaria", "jardim", "pomar", "fazenda", "quartos_sala", "sala_guilda", "circulo" }

-- Quantos níveis do nó já valem: o que precisa de lugar só conta depois de posto.
-- O primeiro nível de Pomar e Fazenda vem com a própria sala.
local function nivel_valendo(no, nv)
  if not J.manual() then return nv end
  local c = J.estado.colocados
  local id = no.id
  if id == "cozinha" or id == "cervejaria" or id == "jardim" or id == "pomar" or id == "fazenda" then
    if not c.salas[id] then return 0 end
  end
  if id == "cerveja_melhor" and not c.salas.cervejaria then return 0 end
  return nv
end

local recalcular
function J.recalcular() recalcular() end
local CONTADOR = { canteiro = "canteiros", arvore = "frutas", vaca = "vacas", porco = "porcos", galinha = "galinhas" }
function J.unidades_valendo(tipo)
  local n = J.estado.compras[tipo] or 0
  local c = J.manual() and CONTADOR[tipo] and J.estado.colocados[CONTADOR[tipo]]
  return c and math.min(n, c) or n
end

function recalcular()
  ef = {}
  for _, no in ipairs(A.NOS) do
    local nv = nivel_valendo(no, J.estado.nos[no.id] or 0)
    if nv > 0 then
      for k, v in pairs(no.ef) do
        if k:sub(1, 2) == "x_" then ef[k] = (ef[k] or 1) * v ^ nv
        else ef[k] = (ef[k] or 0) + v * nv end
      end
    end
  end
  -- unidades vendidas na Loja: valem as já postas; o que ainda espera lugar não conta
  for _, d in ipairs(C.loja) do
    local n = J.unidades_valendo(d.id)
    if n > 0 then
      for k, v in pairs(d.ef) do
        if k:sub(1, 2) == "x_" then ef[k] = (ef[k] or 1) * v ^ n
        else ef[k] = (ef[k] or 0) + v * n end
      end
    end
  end
  if J.manual() then
    local c = J.estado.colocados
    ef.mesas = math.min(ef.mesas or 0, c.mesas)
    if not c.salas.circulo then ef.a_circulo = nil end
    -- comprado na árvore e ainda sem lugar no caminho de pedras: não funciona
    if not c.salas.mercadinho then ef.mercadinho = nil end
    if not c.salas.mural then ef.prateleira = nil end
  end
end

function J.sala_posta(id)
  if not J.manual() then return true end
  return J.estado.colocados.salas[id] == true
end

function J.ef(k)
  return ef[k] or (k:sub(1, 2) == "x_" and 1 or 0)
end
function J.nivel(id)
  return J.estado.nos[id] or 0
end

function J.custo_no(no) return math.floor(no.custo * no.mult ^ J.nivel(no.id)) end

function J.no_liberado(no)
  for _, p in ipairs(no.pre) do
    if J.nivel(p) < 1 then return false end
  end
  return true
end

function J.no_maximo(no) return J.nivel(no.id) >= no.max end

function J.pode_comprar_no(no)
  return not no.em_breve and J.no_liberado(no) and not J.no_maximo(no) and J.estado.ouro >= J.custo_no(no)
end

-- O que a árvore mostra de cada nó, sempre derivado das compras:
-- "comprado"; "revelado" (todos os pré-requisitos comprados: nome, preço e efeito); "pista" (só um "?");
-- "oculto" (não aparece; quando muito, um toco de linha no nó de onde ele sai).
function J.estado_no(no)
  if J.nivel(no.id) > 0 then return "comprado" end
  if no.em_breve then return J.no_liberado(no) and "pista" or "oculto" end
  if J.no_liberado(no) then return "revelado" end
  local algum = false
  for _, p in ipairs(no.pre) do
    if J.nivel(p) > 0 then algum = true end
  end
  -- falta só outro pré-requisito: o jogador já sabe que existe algo aqui
  if algum then return "pista" end
  -- o nó disponível insinua um dos seus passos seguintes, nunca todos
  local pai = no.pai and A.POR_ID[no.pai]
  if pai and J.nivel(pai.id) == 0 and J.no_liberado(pai) then
    for _, f in ipairs(pai.filhos) do
      local filho = A.POR_ID[f]
      if filho.pai == pai.id then return filho == no and "pista" or "oculto" end
    end
  end
  return "oculto"
end

-- continuações do nó ainda totalmente escondidas: cada uma vira um toco de linha
function J.continuacoes_ocultas(no)
  local r = {}
  for _, f in ipairs(no.filhos) do
    local filho = A.POR_ID[f]
    if filho.pai == no.id and J.estado_no(filho) == "oculto" then r[#r + 1] = filho end
  end
  return r
end

local AVISOS = {
  cozinha = "A cozinha está pronta!",
  pomar = "A fazenda de árvores frutíferas foi plantada!",
  fazenda = "A fazenda de animais abriu as porteiras!",
  prateleira = "O mural de missões abriu! Aba Missões liberada.",
  mercadinho = "O mercadinho abriu! Os aventureiros vão vender espólios.",
  venda = "Aba de venda liberada no Mercadinho!",
  jardim = "A fazenda de sementes abriu! Aba Produção liberada.",
  recrutador = "O recrutador chegou! Aba Aventureiros liberada.",
  propaganda = "Propaganda liberada: seus heróis podem ficar famosos!",
  invocacao = "O círculo de invocação foi construído!",
}

function J.comprar_no(id)
  local no = A.POR_ID[id]
  if not no or not J.pode_comprar_no(no) then return false end
  local antes = J.total_para_colocar()
  J.estado.ouro = J.estado.ouro - J.custo_no(no)
  J.estado.nos[id] = J.nivel(id) + 1
  local mesas_antes = J.num_mesas()
  recalcular()
  -- colocando sozinho: mesa de presente (ala leste) também precisa de um lugar livre
  if not J.manual() and J.num_mesas() > mesas_antes then
    local alvo_mesas = ef.mesas
    for i = mesas_antes + 1, J.num_mesas() do
      ef.mesas = i - 2
      local x, z, cheio = J.lugar_padrao("mesa")
      if x and not cheio then L.colocar("mesa" .. i, x, z) end
    end
    ef.mesas = alvo_mesas
  end
  J.ajustar_equipe()
  if AVISOS[id] then J.avisar(AVISOS[id]) end
  if J.manual() and J.total_para_colocar() > antes then J.avisar(A.POR_ID[id].nome .. ": escolha o lugar na aba Loja") end
  return true
end

function J.tem_compra()
  for _, no in ipairs(A.NOS) do if J.pode_comprar_no(no) then return true end end
  return false
end

function J.avisar(texto, duracao)
  J.aviso = { texto = texto, vida = 0, duracao = duracao or 3.5 }
end

function J.flutuar(x, y, z, texto, cor, tam)
  J.efeitos[#J.efeitos + 1] = { x = x, y = y, z = z, texto = texto, cor = cor or util.cores.ouro, tam = tam or 22, vida = 0 }
end

function J.ganhar(v, x, y, z)
  local e = J.estado
  e.ouro = e.ouro + v
  e.total = e.total + v
  J.ganho_segundo = J.ganho_segundo + v
  -- uma parte de tudo que entra vai direto para o agiota
  if (e.divida or 0) > 0 then
    J.pagar_divida(math.min(e.divida, v * C.parcela_divida))
  end
  if x then J.flutuar(x, y, z, "+" .. util.formatar(v)) end
end

-- Começo endividado ---------------------------------------------------------------
-- Só vale em jogo novo: e.mantimentos nil (saves antigos) mantém as regras de antes.

function J.comecar_endividado()
  local e = J.estado
  e.mantimentos = { comida = 0, bebida = 0 }
  e.divida, e.emprestimos = C.divida_inicial, 0
  if not J.auto_colocar then
    e.colocados = { mesas = 0, canteiros = 0, frutas = 0, vacas = 0, porcos = 0, galinhas = 0, salas = {}, com_caminho = true }
    recalcular()
  end
  J.noticia = { id = "historia", titulo = "A taverna do seu tio",
    texto = "Você herdou esta taverna, e com ela " .. C.divida_inicial .. " de ouro em dívidas e uma despensa vazia. Bartolo, o agiota da vila, empresta um pouco para recomeçar. Pegue o empréstimo, toque na carroça do comerciante, lá na estrada, compre comida e bebida e revenda por um preço maior." }
end

function J.fracao_custo(tipo)
  local f = tipo == "comida" and C.fracao_comida or C.fracao_bebida
  if J.ef("a_jardim") > 0 then return f.jardim end
  if tipo == "comida" and L.aberta("cozinha") then return f.cozinha end
  if tipo == "bebida" and J.ef("a_cerveja") > 0 then return f.cervejaria end
  return f.comprada
end

function J.preco_mantimento(tipo) return J.valor_pedido() * J.fracao_custo(tipo) end

function J.comprar_mantimentos(tipo, qtd)
  local e = J.estado
  if not e.mantimentos then return false end
  if not J.carroca_presente() then J.avisar("A carroça não está na estrada."); return false end
  qtd = qtd or C.lote_mantimentos
  local custo = J.preco_mantimento(tipo) * qtd
  if e.ouro < custo then J.avisar("Falta ouro para comprar."); return false end
  e.ouro = e.ouro - custo
  e.mantimentos[tipo] = (e.mantimentos[tipo] or 0) + qtd
  J.som("moeda")
  return true
end

-- Carroça do comerciante ------------------------------------------------------------------

J.CARROCA = {}
for _, d in ipairs(C.carroca) do J.CARROCA[d.id] = d end

function J.carroca_presente() return J.estado.carroca.presente end
-- segundos até ela ir embora (presente) ou até chegar (longe)
function J.carroca_resta() return math.max(0, J.estado.carroca.resta) end
function J.carroca_tardia() return J.nivel(C.carroca_tardio) > 0 end

local function atualizar_carroca(dt)
  local c = J.estado.carroca
  c.resta = c.resta - dt
  if c.resta > 0 then return end
  if c.presente then
    c.presente, c.resta = false, C.carroca_intervalo - C.carroca_fica
    J.avisar("A carroça do comerciante foi embora.")
  else
    c.presente, c.resta, c.visitas, c.vendidos = true, C.carroca_fica, c.visitas + 1, {}
    J.avisar("A carroça do comerciante chegou! Toque nela para comprar.")
    J.som("moeda")
  end
end

function J.preco_carroca(id)
  local d = J.CARROCA[id]
  if d.tipo == "mantimento" then return J.preco_mantimento(d.mantimento) * d.lote end
  if d.tipo == "semente" then return J.valor_pedido() * C.semente_preco * d.lote end
  if d.tipo == "filhote" then
    local k = J.carroca_tardia() and C.carroca_desconto_tardio or C.carroca_desconto
    return math.floor(J.preco_unidade(d.unidade) * k)
  end
  if d.tipo == "raro" then return J.valor_pedido() * C.raro_preco * C.raro_usos end
  return math.huge
end

-- Dá para comprar? Devolve o motivo se não der; sumir = nem aparece na lista (ainda).
function J.estado_carroca(id)
  local d = J.CARROCA[id]
  local c = J.estado.carroca
  local r = { preco = J.preco_carroca(id) }
  if d.tipo == "mantimento" and not J.estado.mantimentos then r.sumir = true end
  if d.tipo == "raro" and not J.carroca_tardia() then r.sumir = true end
  if d.tipo == "filhote" then
    local est = J.estado_unidade(d.unidade)
    if est.motivo == "Libere na Árvore" then r.motivo = "Libere a Fazenda de animais"
    elseif est.motivo then r.motivo = est.motivo end
  end
  if d.tipo == "semente" and not L.aberta(d.sala) then r.motivo = "Antes: " .. select(2, L.nome_sala(d.sala)) end
  if (d.tipo == "filhote" or d.tipo == "raro") and c.vendidos[id] then r.motivo = "Só um por visita: acabou" end
  return r
end

-- mult: quantos lotes (só para quem tem lote)
function J.comprar_carroca(id, mult)
  local d = J.CARROCA[id]
  if not d then return false, "Item desconhecido" end
  if not J.carroca_presente() then return false, "A carroça não está na estrada" end
  local est = J.estado_carroca(id)
  if est.sumir then return false, "Não está à venda" end
  if est.motivo then return false, est.motivo end
  local e = J.estado
  mult = mult or 1
  local preco = est.preco * mult
  if e.ouro < preco then return false, "Falta ouro" end
  if d.tipo == "mantimento" then
    return J.comprar_mantimentos(d.mantimento, d.lote * mult)
  elseif d.tipo == "semente" then
    e.ouro = e.ouro - preco
    e.sementes[d.semente] = e.sementes[d.semente] + d.lote * mult
  elseif d.tipo == "filhote" then
    -- mesmo caminho da Loja: cai no primeiro lugar livre e pode ser movido depois
    local ouro = e.ouro
    e.ouro = e.ouro + J.preco_unidade(d.unidade) - preco
    local ok, motivo = J.comprar_unidade(d.unidade)
    if not ok then e.ouro = ouro; return false, motivo end
    e.carroca.vendidos[id] = true
  elseif d.tipo == "raro" then
    e.ouro = e.ouro - preco
    e.raros[d.raro] = e.raros[d.raro] + C.raro_usos
    e.carroca.vendidos[id] = true
  end
  J.som("moeda")
  return true
end

-- Bartolo: o primeiro empréstimo é o começo do jogo. Depois, só socorre quem ficou sem nada.
function J.sem_nada()
  local e = J.estado
  if not e.mantimentos then return false end
  local m = e.mantimentos
  return m.comida < 1 and m.bebida < 1 and not J.tem_caseiro("comida") and not J.tem_caseiro("bebida")
end

function J.pode_emprestimo()
  local e = J.estado
  if not e.mantimentos then return false end
  if (e.emprestimos or 0) == 0 then return true end
  if not J.sem_nada() then return false end
  if J.ef("fornecedor") > 0 and e.ouro >= J.preco_mantimento("bebida") * C.fornecedor_mult then return false end
  -- carroça longe: não adianta ter ouro, ele traz uma cesta. Carroça aqui: só falta ouro.
  if not J.carroca_presente() then return true end
  return e.ouro < J.preco_mantimento("bebida") * C.lote_mantimentos
end

function J.pegar_emprestimo()
  if not J.pode_emprestimo() then return false end
  local e = J.estado
  e.ouro = e.ouro + C.emprestimo
  e.divida = (e.divida or 0) + C.emprestimo * C.juros_emprestimo
  e.emprestimos = (e.emprestimos or 0) + 1
  if e.emprestimos > 1 and not J.carroca_presente() then
    e.mantimentos.comida = e.mantimentos.comida + C.socorro_cesta
    e.mantimentos.bebida = e.mantimentos.bebida + C.socorro_cesta
    J.avisar("Bartolo trouxe uma cesta e um pouco de ouro. Vai cobrar depois.", 4)
  end
  J.som("moeda")
  return true
end

function J.pagar_divida(v)
  local e = J.estado
  v = math.min(v, e.divida or 0, e.ouro)
  if v <= 0 then return end
  e.ouro, e.divida = e.ouro - v, e.divida - v
  if e.divida < 0.01 then
    e.divida = 0
    J.avisar("Dívida paga! Bartolo não vai mais bater à sua porta.", 5)
  end
end

-- Produção de casa: a cozinha transforma o que há em estoque em comida, e a cervejaria em bebida.
local function bonus_caseiro(pedido)
  if pedido == "comida" then
    local n = J.ef("cozinheiro")
    return n > 0 and C.bonus_cozinheiro + C.bonus_cozinheiro_nivel * (n - 1) or 1
  end
  local n = J.ef("bebida_casa")
  return n > 0 and C.bonus_bebida_casa + C.bonus_bebida_nivel * (n - 1) or 1
end

-- O ingrediente que atende o pedido: o de maior estoque, para nenhum encalhar. nil = nada serve.
function J.ingrediente_para(pedido)
  local e = J.estado
  if pedido == "comida" then
    if not L.aberta("cozinha") then return nil end
  elseif J.ef("a_cerveja") < 1 then return nil end
  -- save de antes da despensa: servir já é de graça, então só gasta se render mais
  if not e.mantimentos and bonus_caseiro(pedido) <= 1 then return nil end
  local melhor, q = nil, 0
  for _, d in ipairs(C.estoques) do
    if d.usa[pedido] and (e.estoques[d.id] or 0) >= 1 and e.estoques[d.id] > q then melhor, q = d.id, e.estoques[d.id] end
  end
  return melhor
end
function J.tem_caseiro(pedido) return J.ingrediente_para(pedido) ~= nil end
function J.total_estoques()
  local t = 0
  for _, d in ipairs(C.estoques) do t = t + (J.estado.estoques[d.id] or 0) end
  return t
end

-- tem como atender este pedido agora?
function J.tem_mantimento(p)
  local e = J.estado
  if not e.mantimentos or J.tem_caseiro(p.pedido) then return true end
  if (e.mantimentos[p.pedido] or 0) >= 1 then return true end
  return J.ef("fornecedor") > 0 and e.ouro >= J.preco_mantimento(p.pedido) * C.fornecedor_mult
end

-- gasta o que serve o pedido e devolve quanto ele rende a mais por ser feito em casa
local function gastar_mantimento(p)
  local e = J.estado
  local id = J.ingrediente_para(p.pedido)
  if id then
    e.estoques[id] = e.estoques[id] - 1
    return bonus_caseiro(p.pedido)
  end
  if not e.mantimentos then return 1 end
  if (e.mantimentos[p.pedido] or 0) >= 1 then
    e.mantimentos[p.pedido] = e.mantimentos[p.pedido] - 1
  else
    e.ouro = e.ouro - J.preco_mantimento(p.pedido) * C.fornecedor_mult
  end
  return 1
end

-- O gerente: serve sozinho no começo; com garçom fica atrás do balcão; com a sala da guilda, sobe
function J.gerente_na_guilda() return J.ef("prateleira") > 0 and L.aberta("sala_guilda") end

-- a escada do térreo: sobe ao segundo andar; save antigo pode ter quartos de antes de ele existir
function J.tem_escada() return L.andar_existe(1) or J.nivel("quartos") > 0 end

-- Lugares ---------------------------------------------------------------------------

function J.num_mesas() return math.min(1 + J.ef("mesas"), #POS_MESAS) end

-- Quantos canteiros cabem à vista na fazenda de sementes: passou disso, rendem sem desenho novo
function J.canteiros_visiveis()
  local x0, x1, z0, z1 = L.sala_mundo("jardim")
  local cols = math.max(1, math.floor((x1 - x0 - 1.4) / 1.1))
  local lins = math.max(1, math.floor((z1 - z0 - 0.6) / 1.45))
  return math.min(J.ef("canteiros"), cols * lins)
end

function J.reconstruir_lugares()
  local velhos = J.lugares or {}
  local l = {}
  for i = 1, J.num_mesas() do
    local m = POS_MESAS[i]
    local g = L.giro(m.id)
    local ax, az = L.t(m.id, m.bx - 1.25, m.bz)
    local bx, bz = L.t(m.id, m.bx + 1.25, m.bz)
    l[#l + 1] = { x = ax, z = az, giro = math.pi / 2 + g, y = 0.42, mesa = i, chave = "m" .. i .. "a" }
    l[#l + 1] = { x = bx, z = bz, giro = -math.pi / 2 + g, y = 0.42, mesa = i, chave = "m" .. i .. "b" }
  end
  if J.ef("balcao") > 0 then
    for _, x in ipairs(J.BANCOS_BALCAO) do
      local bx, bz = L.t("balcao", x, -1.42)
      l[#l + 1] = { x = bx, z = bz, giro = math.pi + L.giro("balcao"), y = 0.42, balcao = true, chave = "b" .. x }
    end
  end
  -- quem está sentado continua no mesmo lugar: se a mesa andou numa obra, vai junto com ela
  for _, v in ipairs(velhos) do
    if v.dono then
      for _, n in ipairs(l) do
        if n.chave == v.chave then
          n.dono = v.dono
          v.dono.lugar = n
          if v.dono.sentado then v.dono.x, v.dono.z, v.dono.giro = n.x, n.z, n.giro end
          break
        end
      end
    end
  end
  J.lugares = l
end

-- enche do fundo para a frente: quem chega não precisa passar pelo meio de quem já sentou
local function lugar_livre()
  local melhor, md
  for _, l in ipairs(J.lugares) do
    if not l.dono then
      local d = util.distancia(l.x, l.z, J.PORTA.x, J.PORTA.z) + math.random() * 3
      if not md or d > md then melhor, md = l, d end
    end
  end
  return melhor
end

local CASAS_GARCOM = { { -0.35, -1.6 }, { -0.35, -2.4 }, { -0.35, -3.2 }, { -1.1, -2.4 }, { -1.1, -3.2 }, { -1.1, -1.6 } }

function J.ajustar_equipe()
  local n = math.min(J.ef("garcons"), C.limite_garcons)
  for i = #J.garcons + 1, n do
    -- ficam ao lado do balcão, longe de quem está sentado
    local c = CASAS_GARCOM[(i - 1) % #CASAS_GARCOM + 1]
    local ox, oz = L.origem.x, L.origem.z
    J.garcons[i] = { x = c[1] + ox, z = c[2] + oz, casa = c[1] + ox, casa_z = c[2] + oz, giro = 0, fase = 0, estado = "parada", recarga = 1 + i * 0.5, rota = {} }
  end
  if #J.lugares < J.num_mesas() * 2 + (J.ef("balcao") > 0 and 4 or 0) then J.reconstruir_lugares() end
  J.montar_mapa()
end

-- Mapa de colisão: tudo que ocupa o chão, já nas posições editadas
function J.montar_mapa()
  local obs = {}
  local function circulo(id, x, z, r)
    if L.oculto(id) then return end
    local wx, wz = L.t(id, x, z)
    obs[#obs + 1] = { x = wx, z = wz, r = r }
  end
  local function caixa(id, x, z, ex, ez)
    if L.oculto(id) then return end
    obs[#obs + 1] = { id = id, x = x, z = z, ex = ex, ez = ez, base = L.base, mundo = L.t }
  end
  for i = 1, J.num_mesas() do
    local m = POS_MESAS[i]
    circulo(m.id, m.bx, m.bz, 0.88)
    circulo(m.id, m.bx - 1.25, m.bz, 0.03)
    circulo(m.id, m.bx + 1.25, m.bz, 0.03)
  end
  -- decoração comprada na Loja também ocupa o chão
  for _, o in ipairs(L.OBJETOS) do
    if o.extra then
      local r = L.TIPOS_EXTRAS[o.extra].raio
      if r then circulo(o.id, o.x, o.z, r) end
    end
  end
  caixa("balcao", 3.05, -2.15, 5.5, 0.95)
  if J.ef("balcao") > 0 then
    for _, x in ipairs(J.BANCOS_BALCAO) do circulo("balcao", x, -1.42, 0.03) end
  end
  caixa("lareira", -5.9, -3.2, 1.3, 2.6)
  caixa("lenha", -6.05, -1.95, 0.7, 0.95)
  caixa("prateleira", 3.05, -4.3, 5.4, 0.5)
  for i = 1, 5 do
    local o = L.POR_ID["barril" .. i]
    circulo(o.id, o.x, o.z, 0.43)
  end
  caixa("carga", 5.5, 4.1, 1.4, 0.8)
  if J.ef("bardo") > 0 then circulo("bardo", -5.1, -1.25, 0.32) end
  if J.tem_escada() then caixa("quartos", -4.65, -3.9, 1.4, 0.8) end
  local sa, sb, sc, sd = L.salao()
  local xmax = sb - 0.2
  if J.ef("a_leste") > 0 then
    xmax = sb + 5.6   -- o banco direito da mesa 8 fica perto do fim da ala: precisa dar para chegar nele
    caixa("carga_leste", 11.2, -3.6, 1.4, 0.8)
  end
  Cam.montar({ sa + 0.2, xmax, sc + 0.25, sd - 0.2 }, obs)
end

-- bancos que a pessoa só alcança atravessando móveis
function J.lugares_sem_rota()
  local n = 0
  for _, l in ipairs(J.lugares) do
    if not Cam.rota(J.PORTA.x, J.PORTA.z, l.x, l.z) then n = n + 1 end
  end
  return n
end

-- A porta em coordenadas de origem (a parede fica entre x = -6.9 e -6.5): L.t acompanha onde ela está.
-- soleira é o primeiro ponto livre dentro do salão; fora é atrás da parede, longe do mapa de colisões.
local function soleira_da_porta(dz)
  local x, z = L.t("porta", -5.9, 1.6 + dz)
  -- móvel na frente da porta: a rota começa na própria porta, como sempre foi
  if Cam.bloqueado(x, z) then return J.PORTA.x, J.PORTA.z end
  return x, z
end

-- Coloca a pessoa atrás da parede: ela atravessa o vão em linha reta e só então segue a rota
function J.vir_de_fora(p, dz)
  local sx, sz = soleira_da_porta(dz)
  p.x, p.z = L.t("porta", -7.7, 1.6 + dz)
  p.giro = math.pi / 2 + L.giro("porta")
  p.vao = { { x = sx, z = sz } }
end

-- Quem está andando perto da porta (ou no vão) a mantém aberta; sentados e garçons não contam
function J.alguem_na_porta()
  for _, p in ipairs(J.pessoas or {}) do
    if p.vao or (p.andando and not p.sentado and util.distancia(p.x, p.z, J.PORTA.x, J.PORTA.z) < 1.5) then return true end
  end
  return false
end

-- Está atrás da parede? (o boneco tem 0,3 de raio: aqui ele ainda fica todo dentro dela)
function J.fora_da_porta(p)
  if not p.vao then return false end
  return (L.base("porta", p.x, p.z)) < -6.85
end

-- Cálculo de rotas espalhado: cada quadro faz só algumas buscas; quem passa disso espera o próximo.
-- Fora de J.atualizar (J.limite_buscas nil) não há limite: a rota sai na hora.
local BUSCAS_POR_SEGUNDO = 180   -- 3 por quadro a 60 quadros por segundo

local function sem_folga_de_rotas()
  return J.limite_buscas ~= nil and Cam.buscas >= J.limite_buscas
end

-- Monta os caminhos desviando dos objetos; se não houver saída, a pessoa atravessa
function J.caminho(p, x, z)
  if sem_folga_de_rotas() then
    p.rota_pendente = { x = x, z = z }
    p.rota, p.andando, p.destino_x, p.destino_z = {}, true, x, z
    p.origem_x, p.origem_z = p.x, p.z
    return
  end
  p.rota_pendente = nil
  -- quem ainda vem pelo vão está fora do mapa: a rota começa no fim do vão
  local vao, fx, fz = p.vao, p.x, p.z
  if vao then p.x, p.z = vao[#vao].x, vao[#vao].z end
  local r, fundo = Cam.rota(p.x, p.z, x, z), false
  if not r then
    -- empurrado para dentro de um móvel: sai pelo ponto livre mais próximo e segue a rota dali
    -- (a mesa e os bancos bloqueiam até 1,5 m do centro; sem saída de verdade cada busca custa caro, por isso são poucas)
    local tentativas = 4
    for raio = 0.3, 1.8, 0.3 do
      for k = 0, 7 do
        local a = k * math.pi / 4
        local ax, az = p.x + math.cos(a) * raio, p.z + math.sin(a) * raio
        if tentativas > 0 and not Cam.bloqueado(ax, az) then
          tentativas = tentativas - 1
          r = Cam.rota(ax, az, x, z)
          if r then
            table.insert(r, 1, { x = ax, z = az })
            fundo = raio > 0.6   -- longe demais para sair sem cruzar o móvel: atravessa, como o atalho
            break
          end
        end
      end
      if r or tentativas == 0 then break end
    end
  end
  p.sem_rota = not r or fundo
  p.fantasma = p.sem_rota or nil
  if not r then
    r = { { x = x, z = z } }
    J.sem_caminho = (J.sem_caminho or 0) + 1
  end
  p.rota, p.andando, p.preso, p.destino_x, p.destino_z = r, true, 0, x, z
  p.origem_x, p.origem_z = p.x, p.z
  if vao then p.x, p.z, p.fantasma = fx, fz, true end
end

-- Só atualiza onde as coisas estão
function J.aplicar_visual()
  for _, m in ipairs(POS_MESAS) do m.x, m.z = L.t(m.id, m.bx, m.bz) end
end

-- Coloca em uso as posições editadas: quem estava na taverna sai, o resto continua
function J.aplicar_layout()
  for _, m in ipairs(POS_MESAS) do m.x, m.z = L.t(m.id, m.bx, m.bz) end
  J.PORTA.x, J.PORTA.z = L.t("porta", -6.4, 1.6)
  J.QUADRO.x, J.QUADRO.z = L.t("quadro", 79, 0.1)
  J.BARRACA.x, J.BARRACA.z = L.t("barraca", 73, 0.1)
  J.visitantes = {}
  for _, l in ipairs(J.lugares or {}) do l.dono = nil end
  -- o menestrel que ainda não tinha cantado não leva a história embora
  for _, p in ipairs(J.pessoas) do
    if p.estado == "menestrel_indo" then J.comecar_historia(p.historia) end
  end
  J.pessoas = {}
  J.reconstruir_lugares()
  J.montar_mapa()
  J.versao_layout, J.origem_x, J.origem_z = L.versao, L.origem.x, L.origem.z
  for i, g in ipairs(J.garcons or {}) do
    local c = CASAS_GARCOM[(i - 1) % #CASAS_GARCOM + 1]
    g.casa, g.casa_z = c[1] + L.origem.x, c[2] + L.origem.z
    g.x, g.z, g.estado, g.rota, g.alvo, g.levando, g.andando = g.casa, g.casa_z, "parada", {}, nil, false, false
    g.fantasma, g.sem_rota, g.preso = nil, nil, 0
  end
end

-- Salas ou porta mudaram com o jogo rodando: ninguém é expulso. Sentados e quem anda acompanham a
-- taverna, o mapa e as rotas são refeitos, e quem ficou dentro de um móvel sai no próximo passo.
function J.aplicar_obra()
  local dx, dz = L.origem.x - (J.origem_x or 0), L.origem.z - (J.origem_z or 0)
  J.versao_layout, J.origem_x, J.origem_z = L.versao, L.origem.x, L.origem.z
  for _, l in ipairs(J.lugares or {}) do l.x, l.z = l.x + dx, l.z + dz end
  local function leva(p)
    p.x, p.z = p.x + dx, p.z + dz
    if p.destino_x then p.destino_x, p.destino_z = p.destino_x + dx, p.destino_z + dz end
    if p.rota_pendente then p.rota_pendente.x, p.rota_pendente.z = p.rota_pendente.x + dx, p.rota_pendente.z + dz end
    for _, r in ipairs(p.rota or {}) do r.x, r.z = r.x + dx, r.z + dz end
    for _, r in ipairs(p.vao or {}) do r.x, r.z = r.x + dx, r.z + dz end
  end
  for _, p in ipairs(J.pessoas or {}) do leva(p) end
  for i, g in ipairs(J.garcons or {}) do
    leva(g)
    local c = CASAS_GARCOM[(i - 1) % #CASAS_GARCOM + 1]
    g.casa, g.casa_z = c[1] + L.origem.x, c[2] + L.origem.z
  end
  for _, m in ipairs(POS_MESAS) do m.x, m.z = L.t(m.id, m.bx, m.bz) end
  J.PORTA.x, J.PORTA.z = L.t("porta", -6.4, 1.6)
  -- quem está lá fora anda junto com o caminho de pedras
  local qx, qz = L.t("quadro", 79, 0.1)
  local fx, fz = qx - J.QUADRO.x, qz - J.QUADRO.z
  for _, p in ipairs(J.visitantes or {}) do
    p.x, p.z = p.x + fx, p.z + fz
    for _, r in ipairs(p.rota) do r.x, r.z = r.x + fx, r.z + fz end
  end
  J.QUADRO.x, J.QUADRO.z = qx, qz
  J.BARRACA.x, J.BARRACA.z = L.t("barraca", 73, 0.1)
  J.reconstruir_lugares()
  J.montar_mapa()
end

function J.ocupados()
  local n = 0
  for _, l in ipairs(J.lugares) do if l.dono then n = n + 1 end end
  return n, #J.lugares
end

-- Loja: o que foi comprado e ainda não tem lugar --------------------------------------------------

local function bruto(id) return J.estado.nos[id] or 0 end

-- Lista do que falta pôr: { tipo = "sala"|"mesa"|"canteiro"|"arvore"|"vaca", id, nome, n, requer = sala que precisa vir antes }
function J.para_colocar()
  local r = {}
  if not J.manual() then return r end
  local c = J.estado.colocados
  local internas, externas = L.salas()
  local nomes = {}
  for _, lista in ipairs({ internas, externas }) do
    for _, b in ipairs(lista) do nomes[b.id] = b.nome end
  end
  for _, id in ipairs(ORDEM_SALAS) do
    if bruto(NO_DA_SALA[id]) > 0 and not c.salas[id] then
      -- quartos e sala da guilda só cabem no segundo andar; save antigo pode ter os quartos antes dele
      local b = id == "quartos_sala" or id == "sala_guilda"
      r[#r + 1] = { tipo = "sala", id = id, nome = nomes[id], n = 1, requer = b and not L.andar_existe(1) and "Segundo andar" or nil }
    end
  end
  -- mercadinho e mural: o primeiro a ser posto escolhe o lugar do caminho; o segundo só entra ao lado
  if bruto("mercadinho") > 0 and not c.salas.mercadinho then r[#r + 1] = { tipo = "fora", id = "mercadinho", nome = "Mercadinho", n = 1 } end
  if bruto("prateleira") > 0 and not c.salas.mural then r[#r + 1] = { tipo = "fora", id = "mural", nome = "Mural de missões", n = 1 } end
  local comp = J.estado.compras
  local mesas = (comp.mesa or 0) + bruto("ala_leste") * 2 - c.mesas
  if mesas > 0 then r[#r + 1] = { tipo = "mesa", nome = "Mesa", n = mesas } end
  local cant = (comp.canteiro or 0) - c.canteiros
  if cant > 0 then r[#r + 1] = { tipo = "canteiro", nome = "Canteiro", n = cant, requer = not c.salas.jardim and "Fazenda de sementes" or nil } end
  local arv = (comp.arvore or 0) - c.frutas
  if arv > 0 then r[#r + 1] = { tipo = "arvore", nome = "Árvore frutífera", n = arv, requer = not c.salas.pomar and "Fazenda de árvores frutíferas" or nil } end
  local vac = (comp.vaca or 0) - c.vacas
  if vac > 0 then r[#r + 1] = { tipo = "vaca", nome = "Vaca", n = vac, requer = not c.salas.fazenda and "Fazenda de animais" or nil } end
  local por = (comp.porco or 0) - (c.porcos or 0)
  if por > 0 then r[#r + 1] = { tipo = "porco", nome = "Porco", n = por, requer = not c.salas.fazenda and "Fazenda de animais" or nil } end
  local gal = (comp.galinha or 0) - (c.galinhas or 0)
  if gal > 0 then r[#r + 1] = { tipo = "galinha", nome = "Galinha", n = gal, requer = not c.salas.fazenda and "Fazenda de animais" or nil } end
  return r
end

function J.total_para_colocar()
  local n = 0
  for _, i in ipairs(J.para_colocar()) do n = n + i.n end
  return n
end

local function pendente(tipo, id)
  for _, i in ipairs(J.para_colocar()) do
    if i.tipo == tipo and (not id or i.id == id) then return i end
  end
end

local function objeto_do_item(tipo)
  if tipo == "mesa" then return "mesa" .. (J.num_mesas() + 1) end
  if tipo == "arvore" then return "arvore" .. (J.ef("frutas") + 3) end
  if tipo == "vaca" then return "vaca" .. (J.ef("vacas") + 1) end
  if tipo == "porco" then return "porco" .. (J.ef("porcos") + 1) end
  if tipo == "galinha" then return "galinha" .. (J.ef("galinhas") + 1) end
end

-- Onde o próximo item fica se ninguém escolher outro lugar: o dele, se estiver livre, ou o primeiro livre
function J.lugar_padrao(tipo)
  local id = objeto_do_item(tipo)
  local o = id and L.POR_ID[id]
  if not o then return nil end
  local x, z = L.t(id, o.x, o.z)
  if J.lugar_item(tipo, x, z) then return x, z end
  local x0, x1, z0, z1
  if tipo == "mesa" then
    x0, x1, z0, z1 = L.salao()
    if L.leste_aberta() and o.pai == "@leste" then x1 = x1 + 5.6 end
  elseif tipo == "arvore" then x0, x1, z0, z1 = L.sala_mundo("pomar")
  else x0, x1, z0, z1 = L.sala_mundo("fazenda") end
  -- mesas seguem a grade das primeiras: sempre sobra corredor entre elas
  if tipo == "mesa" then
    local ox, oz = L.origem.x, L.origem.z
    for lz = math.floor((z0 - oz - 0.2) / 3.2), math.ceil((z1 - oz - 0.2) / 3.2) do
      for lx = math.floor((x0 - ox + 3.6) / 3.9), math.ceil((x1 - ox + 3.6) / 3.9) do
        local gx, gz = ox - 3.6 + lx * 3.9, oz + 0.2 + lz * 3.2
        if J.lugar_item(tipo, gx, gz) then return gx, gz end
      end
    end
  end
  for gz = z0 + 1, z1 - 0.5, 0.5 do
    for gx = x0 + 1, x1 - 0.5, 0.5 do
      if J.lugar_item(tipo, gx, gz) then return gx, gz end
    end
  end
  return x, z, true    -- sem lugar: o fantasma nasce vermelho e o motivo aparece
end

local function perto_de_mesa(x, z, ignorar)
  for i = 1, J.num_mesas() do
    local m = POS_MESAS[i]
    local mx, mz = L.t(m.id, m.bx, m.bz)
    if m.id ~= ignorar and math.abs(mx - x) < 3.1 and math.abs(mz - z) < 1.9 then return "Mesa " .. i end
  end
end

-- Loja: unidades à venda --------------------------------------------------------------------------

J.LOJA = {}
for _, d in ipairs(C.loja) do J.LOJA[d.id] = d end

function J.compradas(tipo) return J.estado.compras[tipo] or 0 end

function J.preco_unidade(tipo)
  local d = J.LOJA[tipo]
  return math.floor(d.custo * d.mult ^ J.compradas(tipo))
end

-- quantos quartos cabem na ala de quartos: é o motivo para ampliá-la
function J.limite_quartos()
  local x0, x1, z0, z1 = L.sala_mundo("quartos_sala")
  return math.floor((x1 - x0) * (z1 - z0) / C.m2_por_quarto)
end

-- Dá para vender mais uma? Devolve o motivo se não der; `sem_boneco` = conta, mas nada novo entra em cena.
function J.estado_unidade(tipo)
  local d = J.LOJA[tipo]
  local r = { preco = J.preco_unidade(tipo) }
  if J.nivel(d.no) < 1 then r.motivo = "Libere na Árvore"; return r end
  local sala = ({ quartos = "quartos_sala", canteiro = "jardim", arvore = "pomar", vaca = "fazenda", porco = "fazenda", galinha = "fazenda" })[tipo]
  if sala and not L.aberta(sala) then r.motivo = "Antes: " .. select(2, L.nome_sala(sala)); return r end
  if tipo == "mesa" and J.num_mesas() >= L.MESAS_MAX then r.motivo = "Limite de " .. L.MESAS_MAX .. " mesas"; return r end
  if tipo == "quartos" and J.compradas(tipo) + 1 >= J.limite_quartos() then r.motivo = "Sem espaço: amplie"; return r end
  if tipo == "arvore" and J.ef("frutas") + 2 >= #L.ARVORES then r.sem_boneco = true end
  if tipo == "vaca" and J.ef("vacas") >= #L.VACAS then r.sem_boneco = true end
  if tipo == "porco" and J.ef("porcos") >= #L.PORCOS then r.sem_boneco = true end
  if tipo == "galinha" and J.ef("galinhas") >= #L.GALINHAS then r.sem_boneco = true end
  if tipo == "garcom" and J.ef("garcons") >= C.limite_garcons then r.sem_boneco = true end
  return r
end

-- Compra uma unidade. O que tem lugar precisa de lugar válido; sem x, z procura o primeiro livre.
function J.comprar_unidade(tipo, x, z)
  local d = J.LOJA[tipo]
  if not d then return false, "Item desconhecido" end
  local est = J.estado_unidade(tipo)
  if est.motivo then return false, est.motivo end
  local e = J.estado
  if e.ouro < est.preco then return false, "Faltam " .. util.formatar(math.ceil(est.preco - e.ouro)) .. " de ouro" end
  local c = e.colocados
  if d.lugar and not est.sem_boneco then
    local cheio
    if not x then x, z, cheio = J.lugar_padrao(tipo) end
    if cheio then return false, "Sem espaço: amplie com o Mestre de Obras" end
    local ok, motivo, nx, nz = J.lugar_item(tipo, x, z)
    if not ok then return false, motivo end
    local id = objeto_do_item(tipo)
    local d0 = L.dados[id]
    local sem_rota = tipo == "mesa" and J.lugares_sem_rota()
    L.colocar(id, nx, nz)
    L.limitar(id)
    L.limitar_carregados(id)
    -- a mesa nova não pode fechar a passagem de ninguém, nem a dela
    if sem_rota then
      e.compras.mesa = J.compradas("mesa") + 1
      recalcular()
      J.aplicar_visual(); J.reconstruir_lugares(); J.montar_mapa()
      local fechou = J.lugares_sem_rota() > sem_rota
      e.compras.mesa = e.compras.mesa - 1
      if fechou then
        L.dados[id] = d0
        recalcular()
        J.aplicar_visual(); J.reconstruir_lugares(); J.montar_mapa()
        return false, "Fecharia a passagem até um lugar"
      end
    end
  end
  e.ouro = e.ouro - est.preco
  e.compras[tipo] = J.compradas(tipo) + 1
  if J.manual() then
    if tipo == "mesa" then c.mesas = c.mesas + 1
    elseif CONTADOR[tipo] then c[CONTADOR[tipo]] = c[CONTADOR[tipo]] + 1 end
  end
  recalcular()
  J.ajustar_equipe()
  if d.lugar then J.aplicar_visual(); J.reconstruir_lugares(); J.montar_mapa(); L.salvar() end
  J.salvar()
  return true
end

-- Dá para pôr aqui? Devolve ok, motivo e o ponto já no passo de 0,25 m. Decoração: tipo = "decor", extra = tipo de TIPOS_EXTRAS.
function J.lugar_item(tipo, x, z, extra)
  if type(x) ~= "number" or type(z) ~= "number" or x ~= x or z ~= z then return false, "Posição inválida" end
  x, z = math.floor(x * 4 + 0.5) / 4, math.floor(z * 4 + 0.5) / 4
  local function nao(motivo) return false, motivo, x, z end
  local function dentro(id, f)
    local x0, x1, z0, z1 = L.sala_mundo(id)
    return x >= x0 + f and x <= x1 - f and z >= z0 + f and z <= z1 - f
  end
  if tipo == "mesa" then
    if L.andar_ativo ~= 0 then return nao("Mesas ficam no térreo") end
    local xa, xb, za, zb = L.salao()
    -- a ala leste é das mesas 7 e 8; as outras ficam no salão, ou cairiam fora se a ala fechasse
    local prox = L.POR_ID["mesa" .. math.min(J.num_mesas() + 1, L.MESAS_MAX)]
    if L.leste_aberta() and prox.pai == "@leste" then xb = xb + 5.6 end
    if x < xa + 1.6 or x > xb - 1.6 or z < za + 0.9 or z > zb - 0.9 then return nao("Fora da taverna ou colada na parede") end
    local q = perto_de_mesa(x, z)
    if q then return nao("Muito perto da " .. q) end
    if util.distancia(x, z, J.PORTA.x, J.PORTA.z) < 2 then return nao("Bloquearia a porta") end
    if Cam.bloqueado(x, z) then return nao("Tem um móvel neste lugar") end
    -- atrás do balcão há um corredor livre, mas é da equipe
    local bx, bz = L.t("balcao", 3.05, -2.15)
    if math.abs(x - bx) < 5 and z < bz then return nao("Atrás do balcão é da equipe") end
    if not Cam.rota(J.PORTA.x, J.PORTA.z, x - 1.25, z) or not Cam.rota(J.PORTA.x, J.PORTA.z, x + 1.25, z) then return nao("Ninguém consegue chegar aqui") end
  elseif tipo == "arvore" then
    if L.andar_ativo ~= 0 then return nao("Árvores ficam no térreo") end
    if not dentro("pomar", 0.6) then return nao("Precisa ficar dentro da Fazenda de árvores frutíferas") end
    for i = 1, J.ef("frutas") + 2 do
      local ax, az = L.t("arvore" .. i, L.POR_ID["arvore" .. i].x, L.POR_ID["arvore" .. i].z)
      if util.distancia(x, z, ax, az) < 1.2 then return nao("Muito perto de outra árvore") end
    end
  elseif tipo == "vaca" or tipo == "porco" or tipo == "galinha" then
    if L.andar_ativo ~= 0 then return nao("Animais ficam no térreo") end
    if not dentro("fazenda", tipo == "vaca" and 1 or 0.5) then return nao("Precisa ficar dentro da Fazenda de animais") end
  elseif tipo == "decor" then
    if L.andar_ativo ~= 0 then return nao("Decoração só fica no térreo") end
    local onde
    if dentro("taverna", 0.2) then onde = "taverna" end
    if not onde then
      local internas, externas = L.salas()
      for _, lista in ipairs({ internas, externas }) do
        for _, b in ipairs(lista) do
          if L.aberta(b.id) and L.andar_de(b.id) == 0 and dentro(b.id, 0.2) then onde = b.id end
        end
      end
    end
    if not onde then return nao("Precisa ficar dentro de uma sala") end
    local d = L.TIPOS_EXTRAS[extra]
    if d and d.raio and onde == "taverna" and Cam.bloqueado(x, z) then return nao("Tem um móvel neste lugar") end
  end
  return true, nil, x, z
end

-- Mover o que já está na cena ------------------------------------------------------------------

-- quem bloqueia o chão não pode parar na frente da porta
local CHAO = { balcao = true, lareira = true, lenha = true, prateleira = true, barril1 = true, barril2 = true, barril3 = true,
  barril4 = true, barril5 = true, carga = true, carga_leste = true, bardo = true, quartos = true }

-- Dá para levar este item até aqui? Devolve ok, motivo e o ponto no passo de 0,25 m.
function J.lugar_mover(id, x, z)
  if type(x) ~= "number" or type(z) ~= "number" or x ~= x or z ~= z then return false, "Posição inválida" end
  if not L.POR_ID[id] then return false, "Item desconhecido" end
  x, z = math.floor(x * 4 + 0.5) / 4, math.floor(z * 4 + 0.5) / 4
  local function nao(motivo) return false, motivo, x, z end
  local sala = L.sala_do_item(id)
  local x0, x1, z0, z1
  if sala then x0, x1, z0, z1 = L.sala_mundo(sala)
  elseif L.andar_de(id) == 0 then x0, x1, z0, z1 = L.sala_mundo("taverna")
  else x0, x1, z0, z1 = L.salao() end
  -- móvel de parede encosta nela: meio metro de folga, como em L.limitar
  if x < x0 - 0.5 or x > x1 + 0.5 or z < z0 - 0.5 or z > z1 + 0.55 then
    return nao("Precisa ficar dentro " .. (sala and ("de " .. select(2, L.nome_sala(sala))) or "da taverna"))
  end
  if id:match("^mesa%d") then
    if x < x0 + 1.6 or x > x1 - 1.6 or z < z0 + 0.9 or z > z1 - 0.9 then return nao("Colada na parede") end
    local q = perto_de_mesa(x, z, id)
    if q then return nao("Muito perto da " .. q) end
    if util.distancia(x, z, J.PORTA.x, J.PORTA.z) < 2 then return nao("Bloquearia a porta") end
  elseif id:match("^arvore%d") then
    for i = 1, J.ef("frutas") + 2 do
      local a = "arvore" .. i
      if a ~= id then
        local ax, az = L.t(a, L.POR_ID[a].x, L.POR_ID[a].z)
        if util.distancia(x, z, ax, az) < 1.2 then return nao("Muito perto de outra árvore") end
      end
    end
  elseif CHAO[id] or (L.decoracao(id) and L.TIPOS_EXTRAS[L.POR_ID[id].extra].raio) then
    if not sala and util.distancia(x, z, J.PORTA.x, J.PORTA.z) < 1.5 then return nao("Bloquearia a porta") end
  end
  return true, nil, x, z
end

-- Leva o item para o ponto, de graça e com o jogo rodando. Quem fechou a passagem até um lugar volta atrás.
function J.mover_item(id, x, z)
  local ok, motivo, nx, nz = J.lugar_mover(id, x, z)
  if not ok then return false, motivo end
  local antes = J.lugares_sem_rota()
  local o = L.POR_ID[id]
  local d0, extra0 = L.dados[id], o.extra and { x = o.x, z = o.z } or nil
  if d0 then d0 = { x = d0.x, z = d0.z, y = d0.y, g = d0.g, oculto = d0.oculto, orig = d0.orig } end
  L.colocar(id, nx, nz)
  L.limitar(id)
  L.limitar_carregados(id)
  J.aplicar_visual()
  J.montar_mapa()
  if J.lugares_sem_rota() > antes then
    L.dados[id] = d0
    L.limitar_carregados(id)
    J.aplicar_visual()
    J.montar_mapa()
    return false, "Fecharia a passagem até um lugar"
  end
  L.versao = L.versao + 1
  J.aplicar_obra()
  L.salvar()
  J.salvar()
  return true
end

-- Excluir só vale para decoração: o resto foi comprado na árvore e não se perde
function J.excluir_decoracao(id)
  if not L.decoracao(id) then return false, "Só a decoração pode ser excluída" end
  L.excluir(id)
  J.montar_mapa()
  L.salvar()
  J.salvar()
  return true
end

-- depois de pôr algo: quem conta muda, e a próxima abertura já encontra o jogo salvo
local function depois_de_colocar()
  recalcular()
  J.aplicar_visual()
  J.reconstruir_lugares()
  J.montar_mapa()
  L.salvar()
  J.salvar()
end

-- Põe o próximo item na posição dada (sem posição: no lugar padrão)
function J.por_item(tipo, x, z)
  local i = pendente(tipo)
  if not i then return false, "Nada deste tipo para colocar" end
  if i.requer then return false, "Coloque " .. i.requer .. " primeiro" end
  local c = J.estado.colocados
  if tipo == "canteiro" then
    c.canteiros = c.canteiros + 1
    depois_de_colocar()
    return true
  end
  local id = objeto_do_item(tipo)
  if not x then x, z = J.lugar_padrao(tipo) end
  local ok, motivo, nx, nz = J.lugar_item(tipo, x, z)
  if not ok then return false, motivo end
  L.colocar(id, nx, nz)
  L.limitar(id)
  L.limitar_carregados(id)
  if tipo == "mesa" then c.mesas = c.mesas + 1
  else c[CONTADOR[tipo]] = (c[CONTADOR[tipo]] or 0) + 1 end
  depois_de_colocar()
  return true
end

function J.por_sala(id, x, z, andar)
  if not pendente("sala", id) then return false, "Nada deste tipo para colocar" end
  local ok, motivo = L.encaixe_valido(id, x, z, andar)
  if not ok then return false, motivo end
  local c = J.estado.colocados
  c.salas[id] = true
  recalcular()
  ok, motivo = L.mover_sala(id, x, z, andar)
  if not ok then
    c.salas[id] = nil
    recalcular()
    return false, motivo
  end
  J.ajustar_equipe()
  depois_de_colocar()
  return true
end

-- Mercadinho ou mural. Sem o caminho, x e z dizem onde ele fica; com o caminho, o item só entra no lugar dele.
function J.por_fora(id, x, z)
  if not pendente("fora", id) then return false, "Nada deste tipo para colocar" end
  local c = J.estado.colocados
  if c.salas.caminho then
    c.salas[id] = true
    recalcular()
    J.ajustar_equipe()
    depois_de_colocar()
    return true
  end
  if not x then x, z = L.vaga_sala("caminho", 0) end
  local ok, motivo = L.encaixe_valido("caminho", x, z, 0)
  if not ok then return false, motivo end
  c.salas.caminho, c.salas[id] = true, true
  recalcular()
  ok, motivo = L.mover_sala("caminho", x, z, 0)
  if not ok then
    c.salas.caminho, c.salas[id] = nil, nil
    recalcular()
    return false, motivo
  end
  J.ajustar_equipe()
  J.aplicar_obra()
  depois_de_colocar()
  return true
end

local function quantos_extras()
  local n = 0
  for _, o in ipairs(L.OBJETOS) do if o.extra then n = n + 1 end end
  return n
end

-- Decoração é paga aqui; o preço só sai quando o lugar é aceito
function J.comprar_decoracao(tipo, x, z)
  local preco = C.preco_decoracao[tipo]
  if not preco or not L.TIPOS_EXTRAS[tipo] then return false, "Item desconhecido" end
  if quantos_extras() >= L.MAX_EXTRAS then return false, "Limite de " .. L.MAX_EXTRAS .. " itens de decoração" end
  local e = J.estado
  if e.ouro < preco then return false, "Faltam " .. util.formatar(math.ceil(preco - e.ouro)) .. " de ouro" end
  local ok, motivo, nx, nz = J.lugar_item("decor", x, z, tipo)
  if not ok then return false, motivo end
  e.ouro = e.ouro - preco
  local o = L.adicionar(tipo, nx, nz)
  depois_de_colocar()
  return true, nil, o.id
end

-- Obras: mover é de graça; cada metro novo é pago e guardado por lado --------------------------------

-- Antes do Mestre de Obras, o tamanho de tudo é fixo. Mover continua de graça.
function J.obras_liberadas() return J.ef("a_obras") > 0 end

-- Preço do próximo metro, cresce um pouco com tudo o que já foi aumentado. extra = metros ainda não aplicados.
function J.preco_metro(extra)
  local total = extra or 0
  for _, v in pairs(L.tamanho) do if v > 0 then total = total + v end end
  return math.floor(C.obra_metro_base * (1 + C.obra_metro_cresce * total))
end

-- O que aconteceria ao mudar `delta` metros nesta parede, sem mudar nada.
-- { metros = quanto dá de verdade, custo, devolve, falta = ouro para o metro seguinte, limite = bateu no máximo ou mínimo }
function J.orcar_obra(chave, delta)
  local r = { metros = 0, custo = 0, devolve = 0, falta = 0, limite = false }
  local atual = L.tamanho[chave]
  if not atual then return r end
  if not J.obras_liberadas() then r.sem_mestre = true; return r end
  local lim_max = L.TAMANHO_MAX
  local lim_min = math.min(L.tamanho_minimo(chave), lim_max)
  local ouro = J.estado.ouro
  if delta > 0 then
    for i = 1, delta do
      if atual + i > lim_max then r.limite = true; break end
      local p = J.preco_metro(i - 1)
      if r.custo + p > ouro then r.falta = r.custo + p - ouro; break end
      r.custo, r.metros = r.custo + p, i
    end
  elseif delta < 0 then
    local pilha = J.estado.obras[chave] or {}
    local topo = #pilha
    for i = 1, -delta do
      local v = atual - (i - 1)
      if v - 1 < lim_min then r.limite = true; break end
      if v > 0 and topo > 0 then
        r.devolve = r.devolve + math.floor(pilha[topo] * C.obra_devolucao)
        topo = topo - 1
      end
      r.metros = -i
    end
  end
  return r
end

-- Faz a obra metro a metro, conferindo o ouro de novo: o jogo não parou enquanto o dedo arrastava
function J.obra(chave, delta)
  local e = J.estado
  local r = { metros = 0, custo = 0, devolve = 0, falta = 0 }
  if not L.tamanho[chave] or delta == 0 or not J.obras_liberadas() then return false, r end
  local passo = delta > 0 and 1 or -1
  for _ = 1, math.abs(delta) do
    local orc = J.orcar_obra(chave, passo)
    if orc.metros == 0 then
      r.falta = orc.falta
      break
    end
    local antes = L.tamanho[chave]
    L.mudar_tamanho(chave, passo)
    if L.tamanho[chave] == antes then break end
    e.obras[chave] = e.obras[chave] or {}
    local pilha = e.obras[chave]
    if passo > 0 then
      e.ouro = e.ouro - orc.custo
      r.custo = r.custo + orc.custo
      -- metro abaixo do tamanho original não devolve nada: não entra na conta
      if antes >= 0 then pilha[#pilha + 1] = orc.custo end
    else
      e.ouro = e.ouro + orc.devolve
      r.devolve = r.devolve + orc.devolve
      if antes > 0 and #pilha > 0 then pilha[#pilha] = nil end
    end
    r.metros = r.metros + passo
  end
  if r.metros ~= 0 then
    J.aplicar_visual()
    L.salvar()
    J.salvar()
  end
  return r.metros ~= 0, r
end

-- Valor dos pedidos -----------------------------------------------------------------

function J.valor_pedido() return C.pedido_base * J.ef("x_pedido") end

function J.intervalo_chegada() return C.intervalo_chegada * J.ef("x_chegada") end

function J.paciencia() return C.paciencia + J.ef("paciencia") end

-- garçons acima do limite de bonecos não entram em cena: deixam os outros mais rápidos
function J.garcons_extras() return math.max(0, J.ef("garcons") - C.limite_garcons) end
function J.intervalo_garcom() return C.garcom_intervalo * J.ef("x_garcom") / (1 + C.garcom_extra_intervalo * J.garcons_extras()) end
function J.velocidade_garcom() return C.garcom_velocidade * (1 + math.min(1, C.garcom_extra_velocidade * J.garcons_extras())) end

-- Pessoas ---------------------------------------------------------------------------

local function nova_pessoa(tipo)
  local p = {
    x = J.PORTA.x, y = 0, z = J.PORTA.z, giro = math.pi / 2, fase = math.random() * 6, t = 0,
    tipo = tipo, pele = util.escolher(PELES),
    chapeu = tipo.nome == "comum" and util.escolher(CHAPEUS) or nil,
    pedido = math.random() < 0.5 and "bebida" or "comida",
    rota = {}, andando = true, estado = "entrando",
  }
  J.vir_de_fora(p, (math.random() - 0.5) * 0.6)
  return p
end

local function rota_ate(p, x, z) J.caminho(p, x, z) end

local function rota_saida(p)
  J.caminho(p, soleira_da_porta(0))
  p.estado = "saindo"
end

local function sentar_cliente(p, lugar)
  p.lugar = lugar
  lugar.dono = p
  rota_ate(p, lugar.x, lugar.z)
  p.estado = "entrando"
end

function J.porta_lotada()
  local n = 0
  for _, p in ipairs(J.pessoas) do
    -- quem está sentado perto da porta não atrapalha a entrada
    if p.andando and not p.sentado and not p.vao and util.distancia(p.x, p.z, J.PORTA.x, J.PORTA.z) < 2.2 then n = n + 1 end
  end
  return n >= 3
end

function J.novo_cliente()
  if J.porta_lotada() and (J.espera_porta or 0) < 6 then return nil end
  local lugar = lugar_livre()
  if not lugar then return nil end
  -- no começo só gente comum e alguns aventureiros; depois mais aventureiros
  local aventura = J.ef("prateleira") > 0 and 0.6 or 0.3
  local nome = math.random() < aventura and util.escolher({ "guerreiro", "mago", "arqueiro", "clerigo" }) or "comum"
  local p = nova_pessoa(tipo_de(nome))
  -- a missão acabou lá fora: a comemoração é de quem entra para comer e beber
  if (J.festas or 0) > 0 then
    J.festas = J.festas - 1
    p.festa = true
  end
  sentar_cliente(p, lugar)
  J.pessoas[#J.pessoas + 1] = p
  return p
end

local function liberar(p)
  if p.lugar then
    p.lugar.dono = nil
    p.lugar = nil
  end
  p.sentado, p.bebendo, p.y = false, false, 0
end

local function companheiro(p)
  if not (p.lugar and p.lugar.mesa) then return nil end
  for _, l in ipairs(J.lugares) do
    if l.mesa == p.lugar.mesa and l.dono and l.dono ~= p and l.dono.sentado then return l.dono end
  end
  return nil
end

-- guerreiro e arqueiro não se bicam; mago e clérigo se dão muito bem
local function combina(a, b)
  local x, y = a.tipo.temperamento, b.tipo.temperamento
  if (x == "bravo" and y == "orgulhoso") or (x == "orgulhoso" and y == "bravo") then return "briga" end
  if a.tipo.nome ~= b.tipo.nome and x == "sabio" and y == "sabio" then return "combo" end
  return nil
end

function J.servir(p, por_garcom)
  if p.estado ~= "esperando" then return false end
  local e = J.estado
  if not J.tem_mantimento(p) then
    J.flutuar(p.x, 2.7, p.z, p.pedido == "comida" and "Sem comida!" or "Sem bebida!", "#ff9a8a", 18)
    return false
  end
  local rende_casa = gastar_mantimento(p)
  if not por_garcom then J.chamar_gerente(p) end
  local v = J.valor_pedido()
  if p.tipo.nome ~= "comum" then v = v * C.bonus_aventureiro end
  if not por_garcom and p.t <= C.tempo_rapido then
    v = v * C.bonus_rapido
    J.flutuar(p.x, 2.7, p.z, "Rápido!", util.cores.verde, 18)
  end
  -- comida e bebida feitas em casa rendem mais
  v = v * rende_casa
  if (e.raros[p.pedido] or 0) >= 1 then
    e.raros[p.pedido] = e.raros[p.pedido] - 1
    v = v * C.raro_bonus
  end
  local par = companheiro(p)
  if par and combina(p, par) == "combo" then
    v = v * C.combo_mesa
    J.flutuar(p.x, 2.95, p.z, "Combo!", "#c9a7ff", 18)
  end
  if p.festa then
    v = v * (2 + J.ef("festa"))
    J.flutuar(p.x, 2.95, p.z, "Festa!", util.cores.verde, 18)
  end
  J.ganhar(v, p.x, 2.3, p.z)
  e.servidos = e.servidos + 1
  p.estado, p.t, p.reservado, p.festa = "comendo", 0, false, false
  J.som("moeda")
  return true
end

function J.som(nome) if J.tocar_som then J.tocar_som(nome) end end

function J.separar_briga(p)
  if p.estado ~= "brigando" then return false end
  local par = p.oponente
  local v = J.valor_pedido() * C.briga_recompensa
  J.ganhar(v, p.x, 2.3, p.z)
  J.flutuar(p.x, 2.95, p.z, "Briga separada!", util.cores.verde, 18)
  J.estado.brigas = J.estado.brigas + 1
  for _, q in ipairs({ p, par }) do
    if q and q.estado == "brigando" then
      q.estado, q.t, q.oponente, q.sem_briga = "esperando", 0, nil, true
      q.andando = false
    end
  end
  J.som("moeda")
  return true
end

local function andar(o, dx, dz, vel, dt)
  local ax, az = dx - o.x, dz - o.z
  local d = math.sqrt(ax * ax + az * az)
  if d < 0.04 then return true end
  local passo = math.min(vel * dt, d)
  o.x, o.z = o.x + ax / d * passo, o.z + az / d * passo
  local alvo = math.atan(ax, az)
  local dif = (alvo - o.giro + math.pi) % (2 * math.pi) - math.pi
  o.giro = o.giro + dif * math.min(1, dt * 12)
  o.fase = o.fase + dt
  return false
end

-- Empurrado por alguém, o caminho reto até o próximo ponto pode cruzar uma mesa: calcula de novo
local function refazer_se_for_bater(p, alvo, vel, dt)
  p.espera_rota = (p.espera_rota or 0) - dt
  if p.fantasma or not p.destino_x or p.espera_rota > 0 then return alvo end
  local ax, az = alvo.x - p.x, alvo.z - p.z
  local d = math.sqrt(ax * ax + az * az)
  if d < 0.01 then return alvo end
  local passo = math.min(d, math.max(vel * dt, 0.2))
  local nx, nz = p.x + ax / d * passo, p.z + az / d * passo
  if not Cam.bloqueado(nx, nz) then return alvo end
  -- em volta do banco e de onde saiu o caminho é liberado de propósito
  if util.distancia(nx, nz, p.destino_x, p.destino_z) < 0.45 or util.distancia(nx, nz, p.origem_x, p.origem_z) < 0.45 then return alvo end
  p.espera_rota = 0.3
  local preso = p.preso
  J.caminho(p, p.destino_x, p.destino_z)
  p.preso = preso
  return p.rota[1]
end

local function seguir_rota(p, dt, vel)
  -- a rota dele ficou para este quadro: sem folga de novo, espera parado
  if p.rota_pendente then
    if sem_folga_de_rotas() then return false end
    J.caminho(p, p.rota_pendente.x, p.rota_pendente.z)
  end
  local alvo = p.rota[1]
  if not alvo then return true end
  alvo = refazer_se_for_bater(p, alvo, vel, dt)
  if not alvo then return false end
  -- empurrado por outros, ninguém acerta um ponto exato: chegar perto já basta
  local dx, dz = alvo.x - p.x, alvo.z - p.z
  local tol = #p.rota > 1 and 0.3 or 0.15
  if p.estado == "saindo" and #p.rota == 1 then tol = 0.8 end
  if dx * dx + dz * dz < tol * tol or andar(p, alvo.x, alvo.z, vel, dt) then table.remove(p.rota, 1) end
  return #p.rota == 0
end

-- Reta pelo vão, sem colisões: as paredes do mapa bloqueiam tudo o que fica fora do salão
local function atravessar_vao(p, dt)
  local a = p.vao[1]
  if andar(p, a.x, a.z, C.velocidade_pessoa, dt) then table.remove(p.vao, 1) end
  if #p.vao > 0 then return end
  p.vao, p.fantasma = nil, p.sem_rota or nil
  -- só some depois de passar pela porta
  if p.estado == "saindo" then p.removido = true end
end

local function atualizar_pessoa(p, dt)
  p.t = p.t + dt
  if p.vao then return atravessar_vao(p, dt) end
  if p.estado == "entrando" then
    if seguir_rota(p, dt, C.velocidade_pessoa) then
      p.estado, p.t, p.andando, p.sentado = "esperando", 0, false, true
      p.fantasma = nil
      if p.lugar then p.x, p.z, p.y, p.giro = p.lugar.x, p.lugar.z, p.lugar.y, p.lugar.giro end
    end
  elseif p.estado == "esperando" then
    -- temperamentos incompatíveis na mesma mesa acabam em briga
    if not p.sem_briga and p.t >= C.briga_inicio then
      local par = companheiro(p)
      if par and par.estado == "esperando" and not par.sem_briga and combina(p, par) == "briga" then
        p.estado, p.oponente, p.t = "brigando", par, 0
        par.estado, par.oponente, par.t = "brigando", p, 0
        J.flutuar(p.x, 2.8, p.z, "Briga!", util.cores.vermelho, 20)
        J.som("briga")
        return
      end
    end
    if p.t >= J.paciencia() then
      J.flutuar(p.x, 2.5, p.z, "Desistiu...", util.cores.vermelho, 16)
      liberar(p)
      rota_saida(p)
    end
  elseif p.estado == "brigando" then
    p.fase = p.fase + dt
    if p.t >= C.briga_espera then
      J.flutuar(p.x, 2.5, p.z, "Foram embora!", util.cores.vermelho, 16)
      p.oponente = nil
      liberar(p)
      rota_saida(p)
    end
  elseif p.estado == "comendo" then
    p.bebendo = (p.t % 2) < 1.2
    if p.t > C.tempo_comendo then
      liberar(p)
      rota_saida(p)
    end
  elseif p.estado == "menestrel_indo" then
    if seguir_rota(p, dt, C.velocidade_pessoa) or p.t > (p.limite_palco or 15) then
      p.estado, p.t, p.andando = "menestrel_canta", 0, false
      p.fantasma = nil
      p.giro = 0
      J.comecar_historia(p.historia)
    end
  elseif p.estado == "menestrel_canta" then
    p.fase = p.fase + dt
    if p.t > C.menestrel_canta then rota_saida(p) end
  elseif p.estado == "saindo" then
    if seguir_rota(p, dt, C.velocidade_pessoa) then
      -- volta ao centro da soleira e cruza a porta em linha reta
      local sx, sz = soleira_da_porta(0)
      local fx, fz = L.t("porta", -7.7, 1.6)
      p.vao, p.fantasma = { { x = sx, z = sz }, { x = fx, z = fz } }, true
    end
  end
end

-- Lado de fora --------------------------------------------------------------------------
-- Quem vem pegar missão ou vender espólio anda só pela faixa de pedras e nem entra na taverna.
-- Não usa rotas nem colisão: o caminho é uma reta, então esse povo não pesa no jogo.

local MEIA_FAIXA = 0.32
J.MAX_VISITANTES = 40

-- começo e fim da faixa de pedras, no mundo, um pouco além das pontas
local function pontas_da_faixa()
  local x0, x1 = L.sala_mundo("caminho")
  return x0 - 0.8, x1 + 0.8
end

local function novo_visitante(tipo, estado, parada_x, parada_z)
  if not L.aberta("caminho") or #J.visitantes >= J.MAX_VISITANTES then return nil end
  local ini = pontas_da_faixa()
  local dz = (math.random() - 0.5) * 2 * MEIA_FAIXA
  local p = { x = ini, y = 0, z = parada_z + dz, giro = math.pi / 2, fase = math.random() * 6, t = 0,
    tipo = tipo, pele = util.escolher(PELES), chapeu = tipo.nome == "comum" and util.escolher(CHAPEUS) or nil,
    pedido = "bebida", andando = true, estado = estado, rota = { { x = parada_x, z = parada_z + dz } } }
  J.visitantes[#J.visitantes + 1] = p
  return p
end

local function ir_embora(p)
  local _, fim = pontas_da_faixa()
  p.estado, p.andando, p.rota = "saindo", true, { { x = fim, z = p.z } }
end

local function atualizar_visitante(p, dt)
  p.t = p.t + dt
  if p.andando then
    local a = p.rota[1]
    if a and not andar(p, a.x, a.z, C.velocidade_pessoa, dt) then return end
    p.rota = {}
    p.andando = false
    if p.estado == "indo_quadro" then
      p.estado, p.t, p.giro = "pegando", 0, math.pi
    elseif p.estado == "indo_barraca" then
      J.vender_espolio(p)
      p.estado, p.t, p.giro = "vendendo", 0, math.pi
    else
      p.removido = true
    end
  elseif p.estado == "pegando" then
    -- estica o braço, arranca o papel e sai com ele na mão
    if p.t > 0.55 and not p.com_papel then
      p.com_papel = true
      J.flutuar(p.x, 2.5, p.z, "Missão " .. (p.rank_missao or "") .. "!", util.cores.ouro, 18)
      J.som("clique")
    end
    if p.t > 1.3 then ir_embora(p) end
  elseif p.estado == "vendendo" then
    if p.t > 1.0 then ir_embora(p) end
  end
end

-- Garçons ---------------------------------------------------------------------------

-- Onde parar para atender: com a mesa ou o balcão girados, o lado de sempre pode estar dentro do móvel
local function ponto_de_servir(g, p)
  local dz = select(2, L.base("porta", p.x, p.z)) < J.RUA_Z and 0.72 or -0.72
  for _, o in ipairs({ { 0, dz }, { 0, -dz }, { 0.72, 0 }, { -0.72, 0 } }) do
    local x, z = p.x + o[1], p.z + o[2]
    if not Cam.bloqueado(x, z) and Cam.rota(g.x, g.z, x, z) then return x, z end
  end
  return p.x, p.z + dz
end

local function atualizar_garcom(g, dt)
  g.recarga = g.recarga - dt
  g.andando = false
  if g.estado == "parada" then
    if g.recarga <= 0 then
      local melhor
      for _, p in ipairs(J.pessoas) do
        if p.estado == "esperando" and not p.reservado and J.tem_mantimento(p) and (not melhor or p.t > melhor.t) then melhor = p end
      end
      if melhor then
        melhor.reservado = true
        -- primeiro pega o prato que o gerente deixou na ponta do balcão
        g.alvo, g.estado, g.levando, g.pega = melhor, "buscando", false, 0.5
      end
    end
  else
    g.andando = true
    if g.estado == "buscando" then
      -- a casa do garçom é ao lado do balcão: pega o prato ali mesmo
      g.andando = false
      g.pega = g.pega - dt
      -- achar onde parar custa várias buscas: sem folga neste quadro, o prato espera mais um pouco
      if g.pega <= 0 and not sem_folga_de_rotas() then
        local p = g.alvo
        if p and p.estado == "esperando" then
          g.estado, g.levando = "indo", true
          J.caminho(g, ponto_de_servir(g, p))
        else
          if p then p.reservado = false end
          g.alvo, g.estado = nil, "parada"
        end
      end
    elseif seguir_rota(g, dt, J.velocidade_garcom()) then
      if g.estado == "indo" then
        local p = g.alvo
        if p and p.estado == "esperando" then J.servir(p, true) end
        if p then p.reservado = false end
        g.alvo, g.levando, g.estado = nil, false, "voltando"
        g.recarga = J.intervalo_garcom()
        J.caminho(g, g.casa, g.casa_z)
      else
        g.estado = "parada"
        g.fantasma = nil
      end
    end
  end
end

local function casa_gerente() return L.t("balcao", 2.5, -3.25) end

function J.chamar_gerente(p)
  local g = J.gerente
  if not g or J.ef("garcons") > 0 or J.gerente_na_guilda() or g.estado == "servindo" then return end
  g.estado = "servindo"
  J.caminho(g, ponto_de_servir(g, p))
end

local function atualizar_gerente(g, dt)
  if J.gerente_na_guilda() then g.andando = false; return end
  if g.estado == "servindo" or g.estado == "voltando" or g.estado == "ajeitando" then
    g.andando = true
    if seguir_rota(g, dt, 3.8) then
      if g.estado == "servindo" then
        g.estado = "voltando"
        J.caminho(g, casa_gerente())
      else
        g.estado, g.t, g.andando = "balcao", 2 + math.random() * 4, false
      end
    end
  else
    g.andando = false
    g.t = (g.t or 0) - dt
    -- com garçom ele só anda de um lado para o outro atrás do balcão, preparando os pratos
    if g.t <= 0 then
      g.t = 3
      if J.ef("garcons") > 0 then
        local x, z = L.t("balcao", 2.5 + (math.random() * 3 - 1.5), -3.25)
        g.estado = "ajeitando"
        J.caminho(g, x, z)
      end
    end
  end
end

-- o moço vai até a porta da cozinha (ou a escada, se ela estiver em outro andar), some lá dentro e volta com o prato
local function porta_cozinha()
  if L.andar_de("cozinha") == 0 then
    for _, d in ipairs(L.portas(0)) do
      if (d.dono == "cozinha" and d.vizinho == "taverna") or (d.dono == "taverna" and d.vizinho == "cozinha") then
        local xa, xb, za, zb = L.salao()
        if d.eixo == "x" then return d.c, util.limitar(d.plano, za + 0.5, zb - 0.5) end
        return util.limitar(d.plano, xa + 0.5, xb - 0.5), d.c
      end
    end
  end
  return L.t("quartos", -4.6, -3)
end

local function atualizar_moco(m, dt)
  if J.ef("moco") < 1 or not L.aberta("cozinha") then m.visivel = false; return end
  if m.na_cozinha then
    m.visivel = false
    m.t = (m.t or 0) - dt
    if m.t <= 0 then
      m.na_cozinha, m.leva, m.indo = false, true, false
      m.visivel = true
      local x, z = L.t("balcao", 2.5, -3.25)
      if Cam.rota(m.x, m.z, x, z) then J.caminho(m, x, z) end
    end
    return
  end
  m.visivel, m.andando = true, true
  if seguir_rota(m, dt, 3) then
    m.andando = false
    m.t = (m.t or 0) - dt
    if m.t <= 0 then
      if m.indo then
        m.na_cozinha, m.t = true, 2
      else
        m.t, m.leva = 1, false
        local x, z = porta_cozinha()
        if Cam.rota(m.x, m.z, x, z) then
          m.indo = true
          J.caminho(m, x, z)
        end
      end
    end
  end
end

-- Missões ---------------------------------------------------------------------------

function J.prateleira_aberta() return J.ef("prateleira") > 0 end

function J.vagas_missao() return C.vagas_missao + J.ef("vagas") end

function J.missoes_comuns_ativas()
  local n = 0
  for _, m in ipairs(J.estado.missoes) do if not m.contratado then n = n + 1 end end
  return n
end

function J.duracao_rank(r) return C.ranks[r].duracao * J.ef("x_duracao") end

function J.nivel_reputacao()
  local f = J.estado.fama
  local n, limite = 0, C.reputacao_base
  while f >= limite and n < 60 do
    n = n + 1
    limite = limite * C.reputacao_mult
  end
  return n, limite
end

function J.multiplicador_missao()
  local m = J.ef("x_missao") * (1 + C.bonus_reputacao * J.nivel_reputacao())
  if J.buff and J.buff > 0 then m = m * C.fofoca_bonus end
  return m
end

function J.pagamento_rank(r) return C.ranks[r].pagamento * J.multiplicador_missao() end

-- reputação atrai aventureiros de rank mais alto: S e SS dependem dela
function J.rank_aventureiro()
  local r = J.ef("rank_max")
  local teto = 6
  local nv = J.nivel_reputacao()
  if nv >= 2 then teto = 7 end
  if nv >= 4 then teto = 8 end
  return math.min(r, teto)
end

local function pagamento_contratado(c, r)
  local v = J.pagamento_rank(r) * C.ganho_contratado
  if c.party then v = v * C.bonus_party end
  if c.heroi then v = v * C.ganho_heroi end
  if c.invocado then v = v * C.ganho_invocado end
  return v
end

local function concluir_missao(m)
  local e = J.estado
  local r = m.rank
  e.feitas = e.feitas + 1
  e.feitas_rank[r] = (e.feitas_rank[r] or 0) + 1
  J.fofoca_conta = (J.fofoca_conta or 0) + 1
  if J.fofoca_conta >= C.fofoca_a_cada then
    J.fofoca_conta = 0
    J.chamar_menestrel()
  end

  local c = m.contratado and J.contratado_por_id(m.contratado) or nil
  local v
  if c then
    c.em_missao = false
    c.missoes = (c.missoes or 0) + 1
    v = pagamento_contratado(c, r)
    if c.heroi or c.invocado then
      if J.ef("propaganda") > 0 then
        local f = C.fama_por_missao * r * J.ef("x_fama")
        c.fama = (c.fama or 0) + f
        e.fama = e.fama + f
      end
    end
  else
    v = J.pagamento_rank(r)
  end

  -- volta pelo caminho de pedras e paga; quem tem espólio vende e vai embora, sem entrar na taverna.
  -- A comemoração fica para o próximo cliente: é ele quem se senta. Com o caminho lotado, só o ouro entra.
  local vende = J.mercadinho_aberto() and r <= J.ef("mercadinho")
  local tipo = c and J.TIPOS_POR_NOME(c.tipo) or tipo_de(util.escolher({ "guerreiro", "mago", "arqueiro", "clerigo" }))
  local p
  if vende then p = novo_visitante(tipo, "indo_barraca", J.BARRACA.x + (math.random() - 0.5) * 3.2, J.BARRACA.z)
  else p = novo_visitante(tipo, "saindo", select(2, pontas_da_faixa()), J.QUADRO.z) end
  if p then
    p.contratado = c
    if c then p.pele = c.pele end
    p.leva_espolio = vende and r or nil
    J.ganhar(v, J.QUADRO.x, 2.3, J.QUADRO.z)
  else
    J.ganhar(v)
    if vende then J.vender_espolio({ leva_espolio = r }) end
  end
  if lugar_livre() then J.festas = math.min((J.festas or 0) + 1, 20) end
  J.som("missao")
end

local function partir_visual(tipo, c, rank)
  -- cada um vai a um ponto do mural e pega o papel com a mão
  local p = novo_visitante(tipo, "indo_quadro", J.QUADRO.x + util.escolher({ -0.9, -0.3, 0.3, 0.9 }), J.QUADRO.z)
  if not p then return end
  p.rank_missao = rank
  if c then p.pele = c.pele; p.contratado = c end
end

function J.iniciar_missao_comum(r)
  local e = J.estado
  e.missoes[#e.missoes + 1] = { rank = r, resta = J.duracao_rank(r) }
  partir_visual(tipo_de(util.escolher({ "guerreiro", "mago", "arqueiro", "clerigo" })), nil, C.ranks[r].nome)
end

local function atualizar_missoes(dt)
  local e = J.estado
  for i = #e.missoes, 1, -1 do
    local m = e.missoes[i]
    m.resta = m.resta - dt
    if m.resta <= 0 then
      table.remove(e.missoes, i)
      concluir_missao(m)
    end
  end

  if J.prateleira_aberta() then
    J.relogio_aventureiro = J.relogio_aventureiro + dt
    if J.relogio_aventureiro >= C.intervalo_aventureiro and J.missoes_comuns_ativas() < J.vagas_missao() then
      J.relogio_aventureiro = 0
      J.iniciar_missao_comum(J.rank_aventureiro())
    end
  end
  J.mandar_contratados()
end

-- Mercadinho ---------------------------------------------------------------------------

function J.mercadinho_aberto() return J.ef("mercadinho") > 0 end
function J.venda_aberta() return J.ef("venda") > 0 end

function J.lucro_espolio(r)
  local m = C.margem_espolio * J.ef("x_espolio")
  if J.venda_aberta() then m = m * C.margem_com_venda end
  return C.ranks[r].espolio * m
end

function J.vender_espolio(p)
  local r = p.leva_espolio
  if not r then return end
  p.leva_espolio = nil
  local v = J.lucro_espolio(r)
  J.estado.espolios = J.estado.espolios + 1
  J.estado.lucro_espolios = J.estado.lucro_espolios + v
  if p.x then J.ganhar(v, p.x, 2.4, p.z) else J.ganhar(v) end
end

function J.renda_venda()
  local t = 0
  for id, d in pairs(C.venda) do t = t + J.ef(id) * d.renda end
  return t
end

function J.renda_passiva() return J.ef("renda_quartos") + J.ef("renda_fazenda") + J.renda_venda() end

-- Jardim ---------------------------------------------------------------------------------

function J.jardim_aberto() return J.ef("a_jardim") > 0 end
function J.ciclo_jardim() return C.ciclo_jardim * J.ef("x_ciclo") end
function J.por_colheita() return J.ef("canteiros") * C.colheita * J.ef("x_colheita") end
function J.estoque_maximo() return C.estoque_maximo * (1 + J.ef("canteiros") * 0.25) end

-- O que a próxima colheita traz, por ingrediente. Canteiros: metade trigo, metade lúpulo.
-- Semente guardada dobra um canteiro de lúpulo ou uma árvore naquela colheita.
function J.proxima_colheita()
  local e, r = J.estado, {}
  local gasto = { lupulo = 0, fruta = 0 }
  local function sementes(tipo, base, plantas)
    if plantas <= 0 then return 0 end
    local usa = math.min(math.floor(e.sementes[tipo]), math.ceil(plantas))
    gasto[tipo] = usa
    return base * (1 + (C.semente_bonus - 1) * usa / plantas)
  end
  if J.jardim_aberto() then
    local q = J.por_colheita()
    r.trigo = q / 2
    r.lupulo = sementes("lupulo", q / 2, J.ef("canteiros") / 2)
  end
  if J.ef("a_pomar") > 0 then
    local arvores = J.ef("frutas") + 2
    r.frutas = sementes("fruta", arvores * C.frutas_por_arvore * J.ef("x_frutas"), arvores)
  end
  if J.ef("a_fazenda") > 0 then
    local k = J.ef("x_animais")
    r.carne_vaca = J.ef("vacas") * C.carne_por_vaca * k
    r.carne_porco = J.ef("porcos") * C.carne_por_porco * k
    r.ovos = J.ef("galinhas") * C.ovos_por_galinha * k
  end
  return r, gasto
end

local function atualizar_jardim(dt)
  if not J.jardim_aberto() and J.ef("a_pomar") < 1 and J.ef("a_fazenda") < 1 then return end
  local e = J.estado
  e.ciclo = e.ciclo + dt
  if e.ciclo >= J.ciclo_jardim() then
    e.ciclo = 0
    local r, gasto = J.proxima_colheita()
    local teto = J.estoque_maximo()
    for id, q in pairs(r) do
      e.estoques[id] = math.min(teto, e.estoques[id] + q)
      e.colhido = e.colhido + q
    end
    e.sementes.lupulo = e.sementes.lupulo - gasto.lupulo
    e.sementes.fruta = e.sementes.fruta - gasto.fruta
  end
end

-- Contratados e heróis ----------------------------------------------------------------------

-- sempre o mesmo visual para o mesmo contratado (é chamado a cada quadro no círculo)
function J.TIPOS_POR_NOME(nome)
  for _, t in ipairs(J.TIPOS) do if t.nome == nome then return t end end
end

function J.contratado_por_id(id)
  for _, c in ipairs(J.estado.contratados) do if c.id == id then return c end end
  return nil
end

function J.pode_contratar_aberto() return J.ef("contratar") > 0 end
function J.vagas_contrato() return J.ef("vagas_contrato") end

function J.num_contratos_normais()
  local n = 0
  for _, c in ipairs(J.estado.contratados) do if not c.invocado then n = n + 1 end end
  return n
end

function J.custo_contratar()
  return math.floor(C.contratar_custo * C.contratar_mult ^ J.num_contratos_normais())
end

function J.contratar()
  local e = J.estado
  if not J.pode_contratar_aberto() or J.num_contratos_normais() >= J.vagas_contrato() then return nil end
  local custo = J.custo_contratar()
  if e.ouro < custo then return nil end
  e.ouro = e.ouro - custo
  local i = e.prox_id
  e.prox_id = i + 1
  local tipos = { "guerreiro", "mago", "arqueiro", "clerigo" }
  local c = {
    id = i, nome = NOMES[(i - 1) % #NOMES + 1], tipo = tipos[(i - 1) % 4 + 1],
    pele = PELES[(i - 1) % #PELES + 1],
    armadura = 0, arma = 0, magia = 0, fama = 0, missoes = 0,
  }
  e.contratados[#e.contratados + 1] = c
  return c
end

function J.poder(c)
  local p = c.invocado and C.poder_invocado * J.ef("x_invocado") or C.poder_inicial
  for id, d in pairs(C.investir) do p = p + (c[id] or 0) * d.poder * (c.invocado and 4 or 1) end
  if c.party then p = p * C.bonus_party end
  if c.heroi then p = p * 1.5 end
  return p
end

function J.rank_contratado(c)
  local p, r = J.poder(c), 1
  for i, d in ipairs(C.ranks) do if p >= d.poder then r = i end end
  return r
end

function J.custo_investir(c, id)
  local d = C.investir[id]
  return math.floor(d.custo * d.mult ^ (c[id] or 0) * (c.invocado and 100 or 1))
end

function J.investir(c, id)
  local custo = J.custo_investir(c, id)
  if J.estado.ouro < custo then return false end
  J.estado.ouro = J.estado.ouro - custo
  c[id] = (c[id] or 0) + 1
  return true
end

function J.custo_promover(c) return math.floor(C.ranks[J.rank_contratado(c)].pagamento * C.promover_custo_mult) end

function J.pode_promover(c)
  return J.ef("heroi") > 0 and not c.heroi and not c.invocado and J.rank_contratado(c) >= C.rank_para_heroi
end

function J.promover(c)
  if not J.pode_promover(c) or J.estado.ouro < J.custo_promover(c) then return false end
  J.estado.ouro = J.estado.ouro - J.custo_promover(c)
  c.heroi = true
  J.avisar(c.nome .. " agora é um herói!")
  return true
end

-- Parties ---------------------------------------------------------------------------------------

function J.criar_party(ids)
  if J.ef("party") <= 0 or #ids ~= 4 then return false end
  local e = J.estado
  local num = e.prox_id
  e.prox_id = num + 1
  for _, id in ipairs(ids) do
    local c = J.contratado_por_id(id)
    if not c or c.party then return false end
  end
  for _, id in ipairs(ids) do J.contratado_por_id(id).party = num end
  e.parties[#e.parties + 1] = { id = num, membros = ids }
  return true
end

function J.desfazer_party(num)
  local e = J.estado
  for i, p in ipairs(e.parties) do
    if p.id == num then
      for _, id in ipairs(p.membros) do
        local c = J.contratado_por_id(id)
        -- no meio da batalha final a party não se desfaz: a luta continuaria sem ninguém nela
        if c and c.na_final then
          J.avisar("Esta party está enfrentando o Lorde Demônio!", 3)
          return false
        end
      end
      for _, id in ipairs(p.membros) do
        local c = J.contratado_por_id(id)
        if c then c.party = nil end
      end
      table.remove(e.parties, i)
      return true
    end
  end
  return false
end

-- junta os 4 invocados, tirando-os de qualquer outra party
function J.formar_party_final()
  if J.ef("party") <= 0 then return false end
  local ids = {}
  for _, c in ipairs(J.estado.contratados) do
    if c.invocado then ids[#ids + 1] = c.id end
  end
  if #ids ~= 4 then return false end
  for _, id in ipairs(ids) do
    local c = J.contratado_por_id(id)
    if c.party then J.desfazer_party(c.party) end
  end
  return J.criar_party(ids)
end

-- monta uma party com os 4 mais fortes disponíveis (invocados primeiro, se houver 4)
function J.melhores_sem_party()
  local l = {}
  for _, c in ipairs(J.estado.contratados) do if not c.party then l[#l + 1] = c end end
  table.sort(l, function(a, b)
    if (a.invocado or false) ~= (b.invocado or false) then return a.invocado or false end
    return J.poder(a) > J.poder(b)
  end)
  local ids = {}
  for i = 1, math.min(4, #l) do ids[i] = l[i].id end
  return ids
end

local function livre_para_missao(c) return not c.em_missao and not c.na_final end

function J.mandar_contratados()
  local e = J.estado
  if e.final_resta then return end
  -- parties vão juntas
  for _, pt in ipairs(e.parties) do
    local todos = true
    local rank = 99
    for _, id in ipairs(pt.membros) do
      local c = J.contratado_por_id(id)
      if not c or not livre_para_missao(c) then todos = false break end
      rank = math.min(rank, J.rank_contratado(c))
    end
    if todos then
      rank = math.min(rank, math.max(1, J.ef("rank_max")))
      for _, id in ipairs(pt.membros) do
        local c = J.contratado_por_id(id)
        c.em_missao = true
        e.missoes[#e.missoes + 1] = { rank = rank, resta = J.duracao_rank(rank), contratado = c.id }
        partir_visual(J.TIPOS_POR_NOME(c.tipo), c, C.ranks[rank].nome)
      end
    end
  end
  if J.ef("rank_max") < 1 then return end
  for _, c in ipairs(e.contratados) do
    if not c.party and livre_para_missao(c) then
      local rank = math.min(J.rank_contratado(c), J.ef("rank_max"))
      c.em_missao = true
      e.missoes[#e.missoes + 1] = { rank = rank, resta = J.duracao_rank(rank), contratado = c.id }
      partir_visual(J.TIPOS_POR_NOME(c.tipo), c, C.ranks[rank].nome)
    end
  end
end

-- Invocação e final --------------------------------------------------------------------------------

function J.invocacao_aberta() return J.ef("invocar") > 0 end

function J.custo_invocar() return C.invocar_custo * C.invocar_mult ^ J.estado.invocados_feitos end

function J.invocar()
  local e = J.estado
  if not J.invocacao_aberta() or e.invocados_feitos >= #C.invocados then return nil end
  local custo = J.custo_invocar()
  if e.ouro < custo then return nil end
  e.ouro = e.ouro - custo
  e.invocados_feitos = e.invocados_feitos + 1
  local d = C.invocados[e.invocados_feitos]
  local i = e.prox_id
  e.prox_id = i + 1
  local c = {
    id = i, nome = d.nome, titulo = d.titulo, tipo = d.tipo, pele = "#f1c9a5", invocado = true,
    armadura = 0, arma = 0, magia = 0, fama = 0, missoes = 0,
  }
  e.contratados[#e.contratados + 1] = c
  J.avisar(d.nome .. " atravessou o portal!", 4)
  J.som("invocar")
  return c
end

-- a missão SSS exige uma party de 4 invocados, todos com poder suficiente
function J.party_final()
  for _, pt in ipairs(J.estado.parties) do
    local ok = #pt.membros == 4
    for _, id in ipairs(pt.membros) do
      local c = J.contratado_por_id(id)
      if not (c and c.invocado) then ok = false end
    end
    if ok then return pt end
  end
  return nil
end

function J.pode_final()
  local pt = J.party_final()
  if not pt or J.estado.final_resta or J.estado.fim then return false end
  for _, id in ipairs(pt.membros) do
    local c = J.contratado_por_id(id)
    if J.poder(c) < C.sss.poder then return false end
  end
  return true
end

function J.iniciar_final()
  if not J.pode_final() then return false end
  local e = J.estado
  e.final_resta = C.sss.duracao
  for _, id in ipairs(J.party_final().membros) do
    local c = J.contratado_por_id(id)
    c.na_final = true
    -- quem estava em missão abandona o trabalho e parte para a batalha final
    for i = #e.missoes, 1, -1 do
      if e.missoes[i].contratado == c.id then table.remove(e.missoes, i) end
    end
    c.em_missao = nil
    partir_visual(J.TIPOS_POR_NOME(c.tipo), c, C.sss.nome)
  end
  J.avisar("A party partiu para enfrentar o Lorde Demônio!", 5)
  return true
end

-- Objetivo atual, para o jogador sempre saber o que buscar ---------------------------------------------

local OBJETIVOS = {
  { "servidos", "Toque nos balões para servir os clientes" },
  { "mesa", "Abra a Árvore e compre uma Nova mesa" },
  { "garcom", "Contrate um Garçom na Árvore" },
  { "cozinha", "Construa a Cozinha" },
  { "cervejaria", "Abra a Cervejaria" },
  { "jardim", "Abra a Fazenda de sementes" },
  { "prateleira", "Construa o Mural de missões" },
  { "mercadinho", "Abra o Mercadinho" },
  { "cozinheiro", "Contrate o Cozinheiro" },
  { "venda", "Libere a Aba de venda" },
  { "recrutador", "Traga o Recrutador" },
  { "party", "Libere as Parties" },
  { "heroi", "Libere o Caminho do herói" },
  { "propaganda", "Abra a Propaganda" },
  { "invocacao", "Construa o Círculo de invocação" },
}

function J.objetivo()
  local e = J.estado
  if e.fim then return "O mundo está em paz!" end
  if e.final_resta then return "A party enfrenta o Lorde Demônio..." end
  if e.mantimentos then
    if (e.emprestimos or 0) == 0 then return "Pegue o empréstimo com Bartolo" end
    if e.mantimentos.comida < 1 and e.mantimentos.bebida < 1 and J.ef("fornecedor") < 1 then
      return J.carroca_presente() and "Toque na carroça e compre comida e bebida" or "Espere a carroça ou peça socorro a Bartolo"
    end
  end
  for _, o in ipairs(OBJETIVOS) do
    if o[1] == "servidos" then
      if e.servidos < 5 then return o[2] end
    elseif J.nivel(o[1]) < 1 then
      return o[2]
    end
  end
  if e.invocados_feitos < #C.invocados then return "Invoque os 4 heróis de outro mundo" end
  if not J.party_final() then return "Forme uma party com os 4 invocados" end
  if not J.pode_final() then return "Fortaleça os invocados até " .. util.formatar(C.sss.poder) .. " de poder" end
  return "Envie a party para a missão SSS!"
end

-- Ciclo ----------------------------------------------------------------------------------------------

function J.iniciar()
  J.pronto = false
  J.estado = estado_inicial()
  J.pessoas = {}
  J.visitantes = {}
  J.festas = 0
  J.garcons = {}
  local gx, gz = L.t("balcao", 2.5, -3.25)
  J.gerente = { x = gx, z = gz, giro = 0, fase = 0, estado = "balcao", t = 2, rota = {} }
  J.moco = { x = gx + 3, z = gz, giro = 0, fase = 0, rota = {}, t = 0, na_cozinha = false }
  J.lugares = {}
  J.efeitos = {}
  J.aviso = nil
  J.offline = nil
  J.buff = 0
  J.MAX_PESSOAS = 60
  J.relogio_chegada = 2
  J.relogio_aventureiro = 5
  J.relogio_segundo = 0
  J.ganho_segundo = 0
  J.relogio_salvar = 0
  J.fofoca_conta = 0
  J.sem_caminho, J.socorros, J.relogio_preso = 0, 0, 0
  J.noticia, J.banner, J.travados, J.media_travados = nil, nil, 0, 0
  J.espera_porta = 0
  -- o que estava comprado no save anterior não pode abrir sala no layout deste
  recalcular()
  J.layout_do_save = {}    -- jogo novo e tela inicial: só o padrão
  if not J.em_menu then J.carregar() end
  recalcular()
  L.carregar(J.layout_do_save)
  J.layout_do_save = nil
  J.gerente.x, J.gerente.z = L.t("balcao", 2.5, -3.25)
  J.reconstruir_lugares()
  J.ajustar_equipe()
  J.calcular_offline()
  J.aplicar_layout()
  J.pronto = true
end

-- Colisão entre bonecos, e socorro para quem ficar preso muito tempo
local function atualizar_colisoes(dt)
  local lista = {}
  for _, p in ipairs(J.pessoas) do lista[#lista + 1] = p end
  for _, g in ipairs(J.garcons) do lista[#lista + 1] = g end
  Cam.separar(lista, dt)
  J.relogio_preso = (J.relogio_preso or 0) + dt
  if J.relogio_preso < 1 then return end
  J.relogio_preso = 0
  -- medidor: gente que queria andar e não conseguiu no último segundo
  local travados = 0
  for _, p in ipairs(lista) do
    if p.andando and p.rota and #p.rota > 0 and (p.preso or 0) >= 1 then travados = travados + 1 end
  end
  J.travados = travados
  J.media_travados = (J.media_travados or 0) * 0.95 + travados * 0.05
  for _, p in ipairs(lista) do
    if p.andando and p.rota and #p.rota > 0 and not p.sentado then
      -- mede a partir de um ponto fixo: quem só treme no lugar, empurrado pelos outros, também está preso
      local dx, dz = p.x - (p.ult_x or 1e9), p.z - (p.ult_z or 1e9)
      if dx * dx + dz * dz < 0.36 then
        p.preso = (p.preso or 0) + 1
        if p.preso == 3 and p.destino_x then
          J.caminho(p, p.destino_x, p.destino_z)
          p.preso = 3
        elseif p.preso >= 8 then
          p.fantasma = true
          J.socorros = (J.socorros or 0) + 1
        end
      else
        p.preso = 0
        p.ult_x, p.ult_z = p.x, p.z
        if not p.sem_rota and not p.vao then p.fantasma = nil end
      end
    end
  end
end

function J.atualizar(dt)
  local e = J.estado
  if J.offline then return end
  if J.versao_layout ~= L.versao then J.aplicar_obra() end
  -- notícia na tela: tudo espera o jogador ler
  if J.noticia then return end
  -- depois do final o mundo para: nada de ouro, sons ou tempo correndo atrás da tela final
  if e.fim then
    J.aviso, J.efeitos = nil, {}
    return
  end
  e.tempo = e.tempo + dt

  if not e.fim then
    -- missão concluída lá fora traz gente querendo comemorar: a próxima pessoa chega mais cedo
    local intervalo = J.intervalo_chegada() * ((J.festas or 0) > 0 and 0.5 or 1)
    J.relogio_chegada = math.min(J.relogio_chegada + dt, intervalo)
    if J.relogio_chegada >= intervalo then
      -- a porta pode segurar a chegada por alguns segundos, nunca para sempre
      if J.novo_cliente() then J.relogio_chegada, J.espera_porta = 0, 0
      elseif J.porta_lotada() then J.espera_porta = (J.espera_porta or 0) + dt end
    end
  end

  J.limite_buscas = Cam.buscas + math.ceil(BUSCAS_POR_SEGUNDO * dt)
  for _, p in ipairs(J.pessoas) do atualizar_pessoa(p, dt) end
  for i = #J.pessoas, 1, -1 do
    if J.pessoas[i].removido then table.remove(J.pessoas, i) end
  end
  for _, p in ipairs(J.visitantes) do atualizar_visitante(p, dt) end
  for i = #J.visitantes, 1, -1 do
    if J.visitantes[i].removido then table.remove(J.visitantes, i) end
  end
  for _, g in ipairs(J.garcons) do atualizar_garcom(g, dt) end
  if J.gerente then atualizar_gerente(J.gerente, dt) end
  if J.moco then atualizar_moco(J.moco, dt) end
  atualizar_colisoes(dt)
  J.limite_buscas = nil
  J.relogio_noticia = (J.relogio_noticia or 0) + dt
  if J.relogio_noticia >= 0.5 then
    J.relogio_noticia = 0
    J.procurar_noticia()
  end
  if J.banner then
    J.banner.vida = J.banner.vida + dt
    if J.banner.vida >= J.banner.duracao then J.banner = nil end
  end
  atualizar_missoes(dt)
  atualizar_jardim(dt)
  atualizar_carroca(dt)

  local passiva = J.renda_passiva()
  if passiva > 0 then J.ganhar(passiva * dt) end
  if J.buff > 0 then J.buff = J.buff - dt end

  if e.final_resta then
    e.final_resta = e.final_resta - dt
    if e.final_resta <= 0 then
      e.final_resta = nil
      e.fim = true
      J.noticia = nil
      for _, c in ipairs(e.contratados) do c.na_final = nil end
      J.som("invocar")
      J.salvar()
    end
  end

  for i = #J.efeitos, 1, -1 do
    local f = J.efeitos[i]
    f.vida = f.vida + dt
    if f.vida >= 1.1 then table.remove(J.efeitos, i) end
  end
  if J.aviso then
    J.aviso.vida = J.aviso.vida + dt
    if J.aviso.vida >= J.aviso.duracao then J.aviso = nil end
  end

  J.relogio_segundo = J.relogio_segundo + dt
  if J.relogio_segundo >= 1 then
    e.rps = e.rps * 0.85 + J.ganho_segundo * 0.15
    J.ganho_segundo = 0
    J.relogio_segundo = J.relogio_segundo - 1
  end

  J.relogio_salvar = J.relogio_salvar + dt
  if J.relogio_salvar >= C.salvar_a_cada then
    J.relogio_salvar = 0
    J.salvar()
  end
end

-- Salvar e carregar ------------------------------------------------------------------------------------

function J.salvar()
  if J.em_menu then return end   -- a taverna atrás da tela inicial não é progresso de ninguém
  -- se o início falhou, o estado está vazio: gravar agora apagaria o progresso de verdade
  if not J.pronto then return end
  -- quem sai sem coletar não perde o ganho do tempo fora
  if J.offline then J.coletar_offline() end
  local e = J.estado
  e.salvo_em = os.time()
  -- cada save guarda a própria construção: tamanhos, posições e decoração
  e.layout = L.exportar()
  motor.salvar(util.serializar(e))
end

local function copiar_sobre(destino, origem)
  for k, v in pairs(origem) do
    if type(v) == "table" and type(destino[k]) == "table" then copiar_sobre(destino[k], v)
    elseif destino[k] == nil or type(destino[k]) == type(v) then destino[k] = v end
  end
end

-- números inválidos em um save danificado não podem travar o jogo
local limpar_contratados

-- Save da árvore antiga: nada comprado se perde.
-- A sala da guilda vinha com o segundo andar; a cervejaria tinha níveis que agora são um nó à parte.
local function migrar_arvore(e, dados)
  if tonumber(dados.arvore_v) == J.VERSAO_ARVORE then return end
  local nos = e.nos
  if (tonumber(nos.segundo_andar) or 0) > 0 then nos.sala_guilda = 1 end
  local cerv = tonumber(nos.cervejaria) or 0
  if cerv > 1 then
    nos.cervejaria, nos.cerveja_melhor = 1, math.floor(cerv) - 1
  end
  -- quem já jogava podia fazer obras: continua podendo
  if next(nos) ~= nil then nos.mestre_obras = 1 end
  -- os níveis viram unidades da Loja; o primeiro nível de quartos, frutíferas e animais já vinha com o nó
  for no, tipo, gratis in string.gmatch("mesa:mesa:0 garcom:garcom:0 canteiro:canteiro:0 quartos:quartos:1 pomar:arvore:1 fazenda:vaca:1", "(%w+):(%w+):(%d)") do
    local nv = math.floor(tonumber(nos[no]) or 0)
    if nv > 0 then
      nos[no] = 1
      e.compras[tipo] = (e.compras[tipo] or 0) + nv - tonumber(gratis)
    end
  end
  e.arvore_v = J.VERSAO_ARVORE
end

local function saneado(v, padrao)
  if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return padrao end
  return v
end

-- contratado estragado sai do save; party incompleta é desfeita (sem isso, os membros nunca mais saem em missão)
local TIPOS_CONTRATADO = { guerreiro = true, mago = true, arqueiro = true, clerigo = true }

function limpar_contratados(e)
  local maior = 0
  for i = #e.contratados, 1, -1 do
    local c = e.contratados[i]
    if type(c) ~= "table" or not saneado(c.id, nil) or not TIPOS_CONTRATADO[c.tipo] then
      table.remove(e.contratados, i)
    else
      maior = math.max(maior, c.id)
      if type(c.nome) ~= "string" then c.nome = "Aventureiro" end
      if type(c.titulo) ~= "string" then c.titulo = c.invocado and "Herói" or nil end
      if type(c.pele) ~= "string" then c.pele = PELES[1] end
      for _, k in ipairs({ "armadura", "arma", "magia", "fama", "missoes" }) do c[k] = math.max(0, saneado(c[k], 0)) end
    end
  end
  local por_id, em_party = {}, {}
  for _, c in ipairs(e.contratados) do por_id[c.id] = c; c.party = nil end
  for i = #e.parties, 1, -1 do
    local p = e.parties[i]
    local boa = type(p) == "table" and saneado(p.id, nil) and type(p.membros) == "table" and #p.membros == 4
    if boa then
      for _, id in ipairs(p.membros) do
        if not por_id[id] or em_party[id] then boa = false end
      end
    end
    if boa then
      maior = math.max(maior, p.id)
      for _, id in ipairs(p.membros) do em_party[id] = true; por_id[id].party = p.id end
    else
      table.remove(e.parties, i)
    end
  end
  e.prox_id = math.max(math.floor(e.prox_id), maior + 1)
end

function J.carregar()
  local dados = util.desserializar(motor.carregar())
  if type(dados) ~= "table" or dados.versao ~= 2 then return end
  local e = estado_inicial()
  copiar_sobre(e, dados)
  -- save de antes da construção própria: fica com a do arquivo antigo, que todos dividiam (nil lê o arquivo)
  if dados.layout == nil then J.layout_do_save = nil
  else J.layout_do_save = type(dados.layout) == "table" and dados.layout or {} end
  e.layout = nil
  e.ouro = math.max(0, saneado(e.ouro, 0))
  e.total = math.max(0, saneado(e.total, 0))
  e.rps = math.max(0, saneado(e.rps, 0))
  e.fama = math.max(0, saneado(e.fama, 0))
  -- estoque único de antes das fazendas: era o que os canteiros colhiam, então vira trigo e lúpulo
  local unico = math.max(0, saneado(e.estoque, 0))
  e.estoque = nil
  if type(dados.estoques) ~= "table" and unico > 0 then
    e.estoques.trigo, e.estoques.lupulo = math.ceil(unico / 2), math.floor(unico / 2)
  end
  for _, d in ipairs(C.estoques) do e.estoques[d.id] = math.max(0, saneado(e.estoques[d.id], 0)) end
  for _, k in ipairs({ "lupulo", "fruta" }) do e.sementes[k] = math.max(0, saneado(e.sementes[k], 0)) end
  if type(e.mantimentos) == "table" then
    e.mantimentos.comida = math.max(0, saneado(e.mantimentos.comida, 0))
    e.mantimentos.bebida = math.max(0, saneado(e.mantimentos.bebida, 0))
    e.divida = math.max(0, saneado(e.divida, 0))
    e.emprestimos = math.max(0, saneado(e.emprestimos, 0))
  else
    e.mantimentos, e.divida, e.emprestimos = nil, nil, nil
  end
  for k, v in pairs(estado_inicial()) do
    if type(v) == "number" then e[k] = saneado(e[k], v) end
  end
  -- carroça: save de antes dela (ou estragado) começa com ela parada na estrada
  do
    local c = e.carroca
    if type(c.presente) ~= "boolean" then c.presente = true end
    local maximo = c.presente and C.carroca_fica or C.carroca_intervalo - C.carroca_fica
    c.resta = util.limitar(saneado(c.resta, maximo), 0, maximo)
    c.visitas = math.max(1, math.floor(saneado(c.visitas, 1)))
    if type(c.vendidos) ~= "table" then c.vendidos = {} end
    for _, k in ipairs({ "comida", "bebida" }) do e.raros[k] = math.max(0, saneado(e.raros[k], 0)) end
  end
  -- contadores da Loja: arquivo estragado volta a colocar sozinho, nunca trava
  if type(e.colocados) == "table" then
    local c = e.colocados
    for _, k in ipairs({ "mesas", "canteiros", "frutas", "vacas", "porcos", "galinhas" }) do c[k] = math.max(0, math.floor(saneado(c[k], 0))) end
    if type(c.salas) ~= "table" then c.salas = {} end
    for id, v in pairs(c.salas) do
      if not NO_DA_SALA[id] or v ~= true then c.salas[id] = nil end
    end
    -- save de antes do caminho de pedras: o que já funcionava continua funcionando, no lugar padrão
    if c.com_caminho ~= true then
      c.com_caminho = true
      local nos = type(e.nos) == "table" and e.nos or {}
      if (tonumber(nos.prateleira) or 0) > 0 then c.salas.mural, c.salas.caminho = true, true end
      if (tonumber(nos.mercadinho) or 0) > 0 then c.salas.mercadinho, c.salas.caminho = true, true end
    end
  else
    e.colocados = nil
  end
  for chave, pilha in pairs(e.obras) do
    if not L.tamanho[chave] or type(pilha) ~= "table" then e.obras[chave] = nil
    else
      for i = #pilha, 1, -1 do
        local v = saneado(pilha[i], nil)
        if not v or v < 0 then table.remove(pilha, i) end
      end
    end
  end
  e.salvo_em = saneado(e.salvo_em, nil)
  e.final_resta = saneado(e.final_resta, nil)
  if e.fim then e.final_resta = nil end
  if e.final_resta then e.final_resta = util.limitar(e.final_resta, 0, C.sss.duracao) end
  e.invocados_feitos = util.limitar(math.floor(e.invocados_feitos), 0, #C.invocados)
  for r, n in pairs(e.feitas_rank) do
    if type(n) ~= "number" then e.feitas_rank[r] = nil end
  end
  if type(e.nos) == "table" then migrar_arvore(e, dados) end
  -- quem já tinha cozinheiro antes de existir a cozinha ganha a sala
  if type(e.nos) == "table" and (tonumber(e.nos.cozinheiro) or 0) > 0 then e.nos.cozinha = 1 end
  -- ignora nós que não existem mais e níveis acima do máximo
  for id, nv in pairs(e.nos) do
    local no = A.POR_ID[id]
    nv = saneado(nv, 0)
    if not no or nv < 1 then e.nos[id] = nil
    else e.nos[id] = math.min(math.floor(nv), no.max) end
  end
  for _, d in ipairs(C.loja) do e.compras[d.id] = math.max(0, math.floor(saneado(e.compras[d.id], 0))) end
  limpar_contratados(e)
  -- ninguém fica preso em uma missão que sumiu do save
  local em, ids = {}, {}
  for _, c in ipairs(e.contratados) do ids[c.id] = true end
  for i = #e.missoes, 1, -1 do
    local m = e.missoes[i]
    if type(m) ~= "table" or not (C.ranks[m.rank]) or (m.contratado and not ids[m.contratado]) then table.remove(e.missoes, i)
    else
      m.resta = util.limitar(saneado(m.resta, 1), 0, C.ranks[m.rank].duracao)
      if m.contratado then em[m.contratado] = true end
    end
  end
  for _, c in ipairs(e.contratados) do
    c.em_missao = em[c.id] or nil
    if not e.final_resta then c.na_final = nil end
  end
  J.estado = e
  -- save de antes das notícias: o que já dava para comprar não vira uma fila de janelas
  if type(dados.noticias) ~= "table" then
    for _, n in ipairs(J.NOTICIAS) do
      local no = A.POR_ID[n.id]
      if J.nivel(n.id) == 0 and J.no_liberado(no) and e.ouro >= J.custo_no(no) then e.noticias[n.id] = true end
    end
  end
end

function J.calcular_offline()
  local e = J.estado
  if not e.salvo_em or J.ef("garcons") < 1 or e.fim then return end
  local fora = os.time() - e.salvo_em
  if fora < C.offline_minimo then return end
  local s = math.min(fora, C.offline_maximo)
  local ganho = math.floor(e.rps * s * C.offline_eficiencia)
  -- as missões em andamento também avançam
  for _, m in ipairs(e.missoes) do m.resta = math.max(0, m.resta - s) end
  if e.final_resta then e.final_resta = math.max(1, e.final_resta - s) end
  if ganho >= 1 then J.offline = { ganho = ganho, segundos = fora } end
end

-- O celular congela o jogo em segundo plano: ao voltar, o tempo parado conta como tempo fora.
function J.ao_voltar()
  if J.em_menu or J.offline or not J.pronto then return end
  J.calcular_offline()
end

function J.coletar_offline()
  if not J.offline then return end
  -- entra de uma vez, mas não conta como renda por segundo: senão o próximo tempo fora rende muito mais
  local g = J.offline.ganho
  J.ganhar(g)
  J.ganho_segundo = J.ganho_segundo - g
  J.offline = nil
end

function J.apagar_progresso()
  motor.salvar("")
  J.estado = nil
  J.pessoas, J.lugares = {}, nil
  J.iniciar()
end

return J
