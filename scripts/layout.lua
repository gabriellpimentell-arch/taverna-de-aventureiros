-- =============================================================================
--  POSIÇÕES DOS OBJETOS
--  Guarda quanto cada objeto foi movido pela Loja. Regras (mesas, rotas, colisões)
--  e desenho usam estes dados, então tudo acompanha o que o jogador mover.
-- =============================================================================

local util = require("util")

local L = {}

-- cat: de que parte da taverna o objeto é. pai: o objeto acompanha outro objeto ou uma
-- parede ("@fundo", "@oeste", "@leste", "@frente", "@canto") quando a taverna muda de tamanho.
L.OBJETOS = {}
L.POR_ID = {}
local function ob(id, nome, x, z, cat, pai)
  local o = { id = id, nome = nome, x = x, z = z, cat = cat, pai = pai }
  L.OBJETOS[#L.OBJETOS + 1] = o
  L.POR_ID[id] = o
end

local MESAS = { { -3.6, 0.2 }, { 0.3, 0.2 }, { 4.2, 0.2 }, { -3.6, 3.4 }, { 0.3, 3.4 }, { 4.2, 3.4 }, { 9.25, -1.4 }, { 9.25, 2.4 } } -- mesas 7 e 8: a ala leste é delas, uma atrás da outra
-- as demais não têm lugar próprio: ao comprar, o jogo procura um lugar livre e as leva para lá
L.MESAS_MAX = require("config").limite_mesas
for i = #MESAS + 1, L.MESAS_MAX do MESAS[i] = { 0.3, 0.2 } end
for i, m in ipairs(MESAS) do
  ob("mesa" .. i, "Mesa " .. i, m[1], m[2], "Móveis", (i == 7 or i == 8) and "@leste" or nil)
end
for i, m in ipairs(MESAS) do
  ob("vela" .. i, "Vela da mesa " .. i, m[1], m[2] + 0.001, "Decoração", "mesa" .. i)
end
ob("palco", "Lugar do menestrel", -1.65, 0.2, "Móveis")
ob("barril1", "Barril 1", 5.6, -3.7, "Móveis")
ob("barril2", "Barril 2", 4.75, -3.8, "Móveis")
ob("barril3", "Barril 3", 5.75, -2.9, "Móveis")
ob("barril4", "Barril 4", -5.6, 3.9, "Móveis")
ob("barril5", "Barril 5", -4.8, 4.1, "Móveis")
ob("carga", "Caixote e saco", 5.5, 4.1, "Móveis")
ob("carga_leste", "Caixote da ala leste", 11.2, -3.6, "Móveis", "@leste")

ob("balcao", "Balcão e bancos", 3.05, -2.2, "Balcão")
ob("barrilete", "Barrilete com torneira", 4.95, -2.3, "Balcão", "balcao")
ob("caneca1", "Caneca 1", 1.05, -1.98, "Balcão", "balcao")
ob("caneca2", "Caneca 2", 4.15, -1.98, "Balcão", "balcao")
ob("prateleira", "Prateleiras", 3.05, -4.32, "Balcão", "@fundo")
for i = 1, 8 do
  ob("garrafa" .. i, "Garrafa " .. i, 0.65 + (i - 1) * 0.68, -4.3, "Balcão", "prateleira")
end

ob("porta", "Porta", -6.4, 1.6, "Paredes", "@oeste")
ob("lampiao_porta", "Lampião da porta", -6.25, 2.6, "Paredes", "porta") -- anda e gira junto com a porta
ob("janela1", "Janela 1", -6.46, -1.27, "Paredes", "@oeste")
ob("janela2", "Janela 2", -6.46, 3.7, "Paredes", "@oeste")
ob("lareira", "Lareira", -6.1, -3.2, "Paredes", "@oeste")
ob("lenha", "Lenha", -6.05, -1.95, "Paredes", "@oeste")
ob("lampiao1", "Lampião 1", -4.5, -4.3, "Paredes", "@fundo")
ob("lampiao2", "Lampião 2", -0.6, -4.3, "Paredes", "@fundo")
ob("quartos", "Escada dos quartos", -4.6, -3.9, "Paredes", "@fundo")
for i = 1, 5 do
  ob("flamula" .. i, "Flâmula " .. i, -4 + (i - 1) * 3, -4.4, "Paredes", "@fundo")
end

ob("tapete1", "Tapete do fundo", -3.6, 0.3, "Decoração")
ob("tapete2", "Tapete da frente", 0.3, 3.4, "Decoração")
ob("vassoura", "Vassoura", -6.25, 2.75, "Decoração", "@oeste")
ob("bardo", "Bardo", -5.1, -1.25, "Decoração")
ob("alcapao", "Escada do subsolo", -0.2, -3.85, "Paredes", "@fundo")

-- Caminho de pedras, do lado de fora: o mercadinho e o mural de missões vivem nele e andam com ele
ob("caminho", "Caminho de pedras", 76, -1.5, "Áreas", "@caminho")
ob("barraca", "Mercadinho", 73, -2, "Áreas", "caminho")
ob("estantes", "Estantes de venda", 73, -4.1, "Áreas", "caminho")
ob("quadro", "Mural de missões", 79, -1.6, "Áreas", "caminho")
ob("jardim", "Fazenda de sementes", -3, 6.75, "Áreas", "@frente")
ob("pomar", "Fazenda de árvores frutíferas", 4.25, 7.8, "Áreas", "@pomar")
ob("fazenda", "Fazenda de animais", 13, 7.8, "Áreas", "@fazenda")
-- salas internas: as paredes ficam na fileira; "mover a sala" leva o que está dentro dela
ob("cozinha", "Cozinha", 14.75, 0.1, "Áreas", "@cozinha")
ob("cervejaria", "Cervejaria", 20.25, 0.1, "Áreas", "@cerv")
ob("circulo", "Círculo de invocação", 25.95, 0.1, "Áreas", "@canto")

ob("canteiros", "Canteiros", -3.2, 6.3, "Jardim", "jardim")
ob("cerca", "Cerca", -3, 8.55, "Jardim", "jardim")
ob("moita1", "Moita 1", -5.9, 8.05, "Jardim", "jardim")
ob("moita2", "Moita 2", -5.3, 8.1, "Jardim", "jardim")
ob("moita3", "Moita 3", -0.3, 8.05, "Jardim", "jardim")
ob("abobora1", "Abóbora 1", -3.6, 8.1, "Jardim", "jardim")
ob("abobora2", "Abóbora 2", -3.1, 8.0, "Jardim", "jardim")

L.ARVORES = { { 1.7, 7.2 }, { 3.4, 7.2 }, { 5.1, 7.2 }, { 6.8, 7.2 }, { 2.5, 9.3 }, { 4.2, 9.3 }, { 5.9, 9.3 }, { 7.3, 9.3 } }
for i = #L.ARVORES + 1, require("config").limite_arvores do L.ARVORES[i] = { 4.2, 8.2 } end
for i, a in ipairs(L.ARVORES) do ob("arvore" .. i, "Árvore " .. i, a[1], a[2], "Pomar", "pomar") end
ob("cesto", "Cesto de frutas", 1.3, 5.9, "Pomar", "pomar")

ob("celeiro", "Celeiro", 15.6, 8, "Fazenda", "fazenda")
ob("cocho", "Cocho", 11.2, 6.2, "Fazenda", "fazenda")
ob("feno", "Feno", 13.3, 10, "Fazenda", "fazenda")
L.VACAS = { { 9.3, 7.2, 0.4 }, { 11.4, 7.5, 2.7 }, { 12.8, 6.6, -0.5 }, { 9.5, 8.8, -0.7 }, { 11.6, 9.1, 0.3 }, { 9.7, 10.1, 3.4 }, { 12.8, 8.4, 1.5 }, { 11.5, 10.2, 5.5 } }
for i = #L.VACAS + 1, require("config").limite_vacas do L.VACAS[i] = { 9.5 + i % 4 * 1.1, 6.6 + i % 3 * 1.5, i * 0.7 } end
for i, v in ipairs(L.VACAS) do ob("vaca" .. i, "Vaca " .. i, v[1], v[2], "Fazenda", "fazenda") end
-- porcos do lado esquerdo do curral; galinhas soltas pela frente, perto do feno
L.PORCOS = {}
for i = 1, require("config").limite_porcos do L.PORCOS[i] = { 8.9 + (i - 1) % 4 * 1.05, 5.5 + math.floor((i - 1) / 4) * 1.5, i * 1.3 } end
for i, v in ipairs(L.PORCOS) do ob("porco" .. i, "Porco " .. i, v[1], v[2], "Fazenda", "fazenda") end
L.GALINHAS = {}
for i = 1, require("config").limite_galinhas do L.GALINHAS[i] = { 9 + (i - 1) % 8 * 0.75, 10 - math.floor((i - 1) / 8) * 0.8, i * 0.9 } end
for i, v in ipairs(L.GALINHAS) do ob("galinha" .. i, "Galinha " .. i, v[1], v[2], "Fazenda", "fazenda") end

ob("fogao", "Fogão", 14, -3.95, "Cozinha", "cozinha")
ob("cozinheiro", "Cozinheiro", 14, -2.5, "Cozinha", "cozinha")
ob("panelas", "Panelas penduradas", 16, -4.32, "Cozinha", "cozinha")
ob("mesa_preparo", "Mesa de preparo", 15, -0.9, "Cozinha", "cozinha")
ob("despensa", "Despensa", 16.2, 3.4, "Cozinha", "cozinha")

ob("tina", "Tina de cobre", 19, -3.2, "Cervejaria", "cervejaria")
ob("barril_grande", "Barril grande", 20.6, -3.2, "Cervejaria", "cervejaria")
ob("barril_c1", "Barril A", 19.2, 2.6, "Cervejaria", "cervejaria")
ob("barril_c2", "Barril B", 20.1, 2.6, "Cervejaria", "cervejaria")
ob("barril_c3", "Barril C", 21, 2.6, "Cervejaria", "cervejaria")
ob("bancada", "Bancada", 20.1, -1.2, "Cervejaria", "cervejaria")
ob("malte1", "Saco de malte 1", 22.1, -3.8, "Cervejaria", "cervejaria")
ob("malte2", "Saco de malte 2", 22.3, -3.1, "Cervejaria", "cervejaria")

ob("pilar1", "Pilar 1", 27.61, 1.34, "Círculo", "circulo")
ob("pilar2", "Pilar 2", 24.29, 1.34, "Círculo", "circulo")
ob("pilar3", "Pilar 3", 24.29, -1.14, "Círculo", "circulo")
ob("pilar4", "Pilar 4", 27.61, -1.14, "Círculo", "circulo")

-- Salas de cima: cada uma tem coordenadas de origem próprias, longe de tudo
ob("quartos_sala", "Quartos", 43.5, -1.5, "Áreas", "@quartos")
for i = 1, 4 do ob("cama" .. i, "Cama " .. i, 41.5 + (i - 1) % 2 * 3.6, -3 + (i > 2 and 2.9 or 0), "Quartos", "quartos_sala") end
ob("bau_quartos", "Baú", 43.3, 0.8, "Quartos", "quartos_sala")
ob("sala_guilda", "Sala da guilda", 53, -1.5, "Áreas", "@guilda")
ob("mesa_guilda", "Mesa do chefe", 53, -1.9, "Guilda", "sala_guilda")
ob("cadeira_guilda", "Cadeira do chefe", 53, -3, "Guilda", "sala_guilda")
ob("estante_guilda", "Estante da guilda", 51.6, -4.15, "Guilda", "sala_guilda")
ob("tapete_guilda", "Tapete da guilda", 53, 0, "Guilda", "sala_guilda")
-- Halls: do tamanho da taverna e nas coordenadas dela
ob("escada_cima", "Escada do segundo andar", -4.3, -3.6, "Segundo andar", "@hall_cima")
ob("tapete_cima", "Passadeira", 0, 0.1, "Segundo andar", "@hall_cima")
ob("escada_baixo", "Escada do subsolo", -4.3, -3.6, "Subsolo", "@hall_baixo")
ob("barris_baixo", "Barris do subsolo", 4.8, -3.6, "Subsolo", "@hall_baixo")

-- a taverna inteira não está na lista: nunca rouba o toque do chão
L.POR_ID.taverna = { id = "taverna", nome = "Taverna inteira", x = 0, z = 0, cat = "Salas" }

-- metros acrescentados em cada lado do salão
local function tamanho_zero()
  return { dir = 0, frente = 0, fundo = 0, oeste = 0, jardim_l = 0, jardim_p = 0, pomar_l = 0, pomar_p = 0, faz_l = 0, faz_p = 0,
    coz_l = 0, coz_p = 0, cerv_l = 0, cerv_p = 0, circ_l = 0, circ_p = 0, quartos_l = 0, quartos_p = 0, guilda_l = 0, guilda_p = 0 }
end
L.tamanho = tamanho_zero()
L.TAMANHO_MAX = 40
L.MAX_EXTRAS = 60
local SALAO_L, SALAO_P = 13, 9.2      -- tamanho original do salão
local SALAO_L_MIN, SALAO_P_MIN = 8, 7
local SALA_MIN = 3
local ALA_L = 5.5

-- Blocos: cada sala tem posição salva (L.blocos). x0, z0, l e p são as medidas de origem:
-- os filhos foram posicionados contando com elas. A posição é o canto de menor x e z.
local INTERNAS = {
  { id = "cozinha", ancora = "@cozinha", x0 = 12, z0 = -4.5, l = 5.5, p = SALAO_P, k = "coz", nome = "Cozinha" },
  { id = "cervejaria", ancora = "@cerv", x0 = 17.5, z0 = -4.5, l = 5.5, p = SALAO_P, k = "cerv", nome = "Cervejaria" },
  { id = "circulo", ancora = "@canto", x0 = 23, z0 = -4.5, l = 5.5, p = SALAO_P, k = "circ", nome = "Invocação" },
  { id = "quartos_sala", ancora = "@quartos", x0 = 40, z0 = -4.5, l = 7, p = 6, k = "quartos", nome = "Quartos", andar = 1, so_andar = 1 },
  { id = "sala_guilda", ancora = "@guilda", x0 = 50, z0 = -4.5, l = 6, p = 6, k = "guilda", nome = "Sala da guilda", andar = 1, so_andar = 1 },
}
local EXTERNAS = {
  { id = "jardim", ancora = "@frente", x0 = -6.5, l = 7, z0 = 4.8, p = 4, k = "jardim", nome = "Fazenda de sementes" },
  { id = "pomar", ancora = "@pomar", x0 = 0.5, l = 7.5, z0 = 4.8, p = 6, k = "pomar", nome = "Fazenda de árvores frutíferas" },
  { id = "fazenda", ancora = "@fazenda", x0 = 8, l = 10, z0 = 4.8, p = 6, k = "faz", nome = "Fazenda de animais" },
  -- sem k: o caminho tem tamanho fixo, não entra em L.tamanho nem tem alça
  { id = "caminho", ancora = "@caminho", x0 = 70, l = 12, z0 = -4.5, p = 6, nome = "Caminho de pedras" },
}
local SALA_DE, POR_ANCORA = {}, {}
for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
  for _, b in ipairs(lista) do
    b.interna = lista == INTERNAS
    SALA_DE[b.id], POR_ANCORA[b.ancora] = b, b
  end
end
-- quem mora em cada andar extra: o hall anda com a taverna
local HALL_ANCORA = { ["@hall_cima"] = 1, ["@hall_baixo"] = -1 }
L.ANDARES = { 1, 0, -1 }
L.NOME_ANDAR = { [1] = "Segundo andar", [0] = "Térreo", [-1] = "Subsolo" }
local PAREDE_MIN = 2         -- menor parede comum que dá acesso entre duas salas
local AFASTAMENTO_MAX = 12   -- área externa não fica perdida no meio do nada
local EPS = 0.01

-- layout.lua é carregado antes de jogo.lua: enquanto o jogo não existe, nada foi comprado
local function ef(k)
  local J = package.loaded.jogo
  return J and J.ef(k) or 0
end

local ABRE = { cervejaria = "a_cerveja", circulo = "a_circulo", jardim = "a_jardim", pomar = "a_pomar", fazenda = "a_fazenda",
  quartos_sala = "a_quartos", sala_guilda = "a_guilda" }
function L.aberta(id)
  -- comprada e ainda sem lugar escolhido na Loja: por enquanto não existe na cena
  local J = package.loaded.jogo
  if J and J.sala_posta and not J.sala_posta(id) then return false end
  -- save antigo pode ter o cozinheiro de antes de a cozinha existir: ele precisa de onde ficar
  if id == "cozinha" then return ef("a_cozinha") > 0 or ef("cozinheiro") > 0 end
  -- surge com o que vier primeiro: o mural ou o mercadinho
  if id == "caminho" then return ef("prateleira") > 0 or ef("mercadinho") > 0 end
  -- as duas salas de cima só existem com o andar
  if (id == "quartos_sala" or id == "sala_guilda") and ef("a_segundo_andar") <= 0 then return false end
  return ef(ABRE[id]) > 0
end

function L.leste_aberta() return ef("a_leste") > 0 end

-- andar ainda não comprado não existe; o térreo sempre existe
function L.andar_existe(n)
  if n == 0 then return true end
  if n == 1 then return ef("a_segundo_andar") > 0 end
  if n == -1 then return ef("a_subsolo") > 0 end
  return false
end

function L.andares()
  local r = {}
  for _, n in ipairs(L.ANDARES) do
    if L.andar_existe(n) then r[#r + 1] = n end
  end
  return r
end

-- medida que encaixe_valido está testando no lugar da atual
local SOBRE = nil
local function largura(b)
  if SOBRE and SOBRE.id == b.id and SOBRE.l then return math.max(SALA_MIN, SOBRE.l) end
  if not b.k then return b.l end
  return math.max(SALA_MIN, b.l + L.tamanho[b.k .. "_l"])
end
local function fundura(b)
  if SOBRE and SOBRE.id == b.id and SOBRE.p then return math.max(SALA_MIN, SOBRE.p) end
  if not b.k then return b.p end
  return math.max(SALA_MIN, b.p + L.tamanho[b.k .. "_p"])
end

local function r3(v) return math.floor(v * 1000 + 0.5) / 1000 end

L.dados = {}
L.blocos = {}            -- id -> { x, z, andar, prov = ainda não é definitiva, ajuste = deslocamento de layout antigo }
L.origem = { x = 0, z = 0 }  -- quanto a taverna foi deslocada
L.porta_parede = nil     -- { lado, t }: nil enquanto a porta está onde sempre esteve
L.andar_ativo = 0
L.versao = 0             -- muda quando salas ou porta mudam: o jogo refaz rotas e lugares

local function numero(v)
  return type(v) == "number" and v == v and v > -1000 and v < 1000 and v or 0
end

-- onde o salão termina, já contando o tamanho escolhido
function L.salao()
  local s, o = L.tamanho, L.origem
  return -6.5 - s.oeste + o.x, 6.5 + s.dir + o.x, -4.5 - s.fundo + o.z, 4.7 + s.frente + o.z
end

local garantir -- definida depois: dá lugar a quem abriu e tira de cima quem ficou sobreposto

-- Muda quando o conjunto de salas abertas muda. Barato: é chamada a cada objeto desenhado.
local function assinatura()
  local v, bit = 0, 1
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      if L.aberta(b.id) then v = v + bit end
      bit = bit * 2
    end
  end
  if L.leste_aberta() then v = v + bit end
  bit = bit * 2
  if L.andar_existe(1) then v = v + bit end
  bit = bit * 2
  if L.andar_existe(-1) then v = v + bit end
  return v
end

local function bloco(id)
  if L._sig ~= assinatura() then garantir() end
  return L.blocos[id]
end

local function ancora(pai)
  local s, og = L.tamanho, L.origem
  if pai == "@fundo" then return og.x, -s.fundo + og.z
  elseif pai == "@oeste" then return -s.oeste + og.x, og.z
  elseif pai == "@leste" then return s.dir + og.x, og.z
  end
  if HALL_ANCORA[pai] then return og.x, og.z end
  local b = POR_ANCORA[pai]
  if b then
    local p = bloco(b.id)
    return r3(p.x - b.x0), r3(p.z - b.z0)
  end
  return og.x, og.z
end

-- quanto o objeto está deslocado de onde nasceu: ele mesmo + quem o carrega
function L.desloc(id)
  local o, d = L.POR_ID[id], L.dados[id]
  local x, z = 0, 0
  if d then x, z = d.x, d.z end
  if o and o.pai then
    if o.pai:sub(1, 1) == "@" then
      local px, pz = ancora(o.pai)
      return x + px, z + pz
    end
    -- preso a outro objeto: gira e sobe junto com ele
    local wx, wz = L.t(o.pai, o.x + x, o.z + z)
    return wx - o.x, wz - o.z
  end
  return x + L.origem.x, z + L.origem.z
end

-- põe o centro do objeto em um ponto do mundo, seja quem for que o carrega
function L.colocar(id, x, z)
  local o, d = L.POR_ID[id], L.de(id)
  if id == "porta" then L.porta_parede = nil end
  -- a área externa não tem deslocamento próprio: colocar é mudar a posição do bloco
  if SALA_DE[id] and not SALA_DE[id].interna then
    local b = SALA_DE[id]
    local p = bloco(id)
    p.x, p.z, p.prov = r3(x - (o.x - b.x0)), r3(z - (o.z - b.z0)), nil
    return
  end
  if o.pai and o.pai:sub(1, 1) ~= "@" then
    x, z = L.base(o.pai, x, z)
  elseif o.pai then
    local px, pz = ancora(o.pai)
    x, z = x - px, z - pz
  else
    x, z = x - L.origem.x, z - L.origem.z
  end
  d.x, d.z = x - o.x, z - o.z
  d.orig = nil     -- agora este é o lugar escolhido
end

-- meia largura (x) e meia profundidade (z) de quem precisa caber inteiro num salão menor
-- Quem recebe gente precisa ficar dentro das paredes, em qualquer tamanho de salão:
-- { folga em x, folga do fundo, folga da frente, fim = quanto pode entrar na ala leste }
local DENTRO = {
  balcao = { 2.8, 1.6, 1.6, fim = 0.5 }, palco = { 0.6, 0.6, 0.6 }, bardo = { 0.4, 0.4, 0.4 },
}
local function folga_dentro(id, d)
  local m = DENTRO[id]
  if m or not id:match("^mesa%d") then return m end
  -- os bancos ficam nas pontas e giram com a mesa
  local g = d and d.g or 0
  local mx, mz = 0.9 + 0.7 * math.abs(math.cos(g)), 0.9 + 0.7 * math.abs(math.sin(g))
  return { mx, mz, mz, fim = L.POR_ID[id].pai == "@leste" and 5.6 + 0.3 or nil }
end

local MEIA = { balcao = { 2.8, 1.6 }, prateleira = { 2.7, 0.3 }, tapete1 = { 2.3, 1 }, tapete2 = { 2.2, 1 }, carga = { 0.8, 0.5 } }

local function raiz(o)
  while o.pai and o.pai:sub(1, 1) ~= "@" and L.POR_ID[o.pai] do o = L.POR_ID[o.pai] end
  return o
end

local function algum_negativo()
  for _, v in pairs(L.tamanho) do
    if v < 0 then return true end
  end
  return false
end

-- nada sai da área do jogo; fora dela ninguém consegue chegar e o objeto some da tela
function L.limitar(id)
  local o, d = L.POR_ID[id], L.dados[id]
  -- sem edição e sem salão encolhido o objeto está onde nasceu: não cria dado à toa
  if not d and not algum_negativo() and not L.dados[raiz(o).id] then return end
  -- a área externa em si é a posição do bloco: o que ela carrega é que precisa caber
  if SALA_DE[id] and not SALA_DE[id].interna then return end
  local s = L.tamanho
  local xa, xb, za, zb = L.salao()
  local dx, dz = L.desloc(id)
  local wx, wz = o.x + dx, o.z + dz
  local r = raiz(o)
  local sala = SALA_DE[r.id]
  local x0, x1, z0, z1
  if sala and sala.interna then
    -- sala interna: fica entre as paredes dela
    x0, x1, z0, z1 = L.sala_mundo(r.id)
    -- o que está dentro não entra na parede da frente nem na sala vizinha
    local borda = r == o and 0.1 or 0.5
    x0, x1, z0, z1 = x0 + 0.5, x1 - borda, z0 - 0.1, z1 - borda
  elseif sala then
    x0, x1, z0, z1 = L.sala_mundo(r.id)
    x0, x1, z0, z1 = x0 - 0.5, x1 + 0.5, z0 - 0.5, z1 + 0.5
  else
    x0, x1, z0, z1 = xa - 0.5, xb + 6.5, za - 0.5, zb + 0.55
    -- salão menor que o original: quem não segue aquela parede precisa caber inteiro dentro
    local dentro = r == o and folga_dentro(id, d)
    if dentro then
      x0, x1 = xa + dentro[1], xb + (dentro.fim or 0) - dentro[1]
      z0, z1 = za + dentro[2], zb - dentro[3]
    elseif r == o then
      local p = o.pai
      local m = MEIA[id] or (id:match("^mesa%d") and { 1.6, 0.9 }) or { 0.5, 0.6 }
      local mx, mz = math.min(m[1], (xb - xa) / 2), math.min(m[2], (zb - za) / 2)
      if s.oeste < 0 and p ~= "@oeste" then x0 = xa + mx end
      if s.dir < 0 and p ~= "@leste" then x1 = xb - mx end
      if s.fundo < 0 and p ~= "@fundo" then z0 = za + mz end
      if s.frente < 0 then z1 = zb - mz end
    end
  end
  local x = util.limitar(wx, x0, math.max(x0, x1))
  local z = util.limitar(wz, z0, math.max(z0, z1))
  if x ~= wx or z ~= wz then
    -- empurrado pelo tamanho, não por escolha: guarda o lugar para voltar se o salão crescer de novo
    local velho = d and (d.orig or { x = d.x, z = d.z }) or { x = 0, z = 0 }
    L.colocar(id, x, z)
    L.dados[id].orig = velho
  end
  d = L.dados[id]
  if d then d.y = util.limitar(d.y, -1, 6) end
end

-- quem é carregado pelo objeto também precisa continuar dentro depois que ele se move
function L.limitar_carregados(id)
  local function carregado(o)
    while o and o.pai and o.pai:sub(1, 1) ~= "@" do
      if o.pai == id then return true end
      o = L.POR_ID[o.pai]
    end
    return false
  end
  for _, o in ipairs(L.OBJETOS) do
    if carregado(o) then
      local d = L.dados[o.id]
      if d and d.orig then d.x, d.z, d.orig = d.orig.x, d.orig.z, nil end
      L.limitar(o.id)
    end
  end
end

-- Limites da sala no mundo: vêm só da posição salva e do tamanho
function L.sala_mundo(id)
  if id == "taverna" then
    local xa, xb, za, zb = L.salao()
    return xa, xb + (L.leste_aberta() and ALA_L or 0), za, zb
  end
  if id == "hall_cima" or id == "hall_baixo" then return L.salao() end
  local b = SALA_DE[id]
  local p = bloco(id)
  return p.x, r3(p.x + largura(b)), p.z, r3(p.z + fundura(b))
end

-- Os mesmos limites em coordenadas de origem do objeto: passando por L.t caem no mundo
function L.sala(id)
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local dx, dz = L.desloc(id)
  return x0 - dx, x1 - dx, z0 - dz, z1 - dz
end

function L.salas() return INTERNAS, EXTERNAS end

function L.nome_sala(id)
  return id, SALA_DE[id] and SALA_DE[id].nome or id
end

-- Em que andar o objeto (ou a sala) está
-- A sala que carrega o objeto (ela mesma, se for sala), ou nil se ele fica no salão ou num hall
function L.sala_do_item(id)
  local o = L.POR_ID[id]
  if not o then return nil end
  local r = raiz(o)
  return SALA_DE[r.id] and r.id or nil
end

function L.andar_de(id)
  local o = L.POR_ID[id]
  if not o then return 0 end
  local r = raiz(o)
  if r.pai and HALL_ANCORA[r.pai] then return HALL_ANCORA[r.pai] end
  if SALA_DE[r.id] then return bloco(r.id).andar end
  return 0
end

function L.no_andar_ativo(id) return L.andar_de(id) == L.andar_ativo end

function L.mudar_andar(n)
  if not L.andar_existe(n) then return false, "Este andar ainda não foi construído" end
  L.andar_ativo = n
  return true
end

-- Encaixe das salas --------------------------------------------------------------------

local ASSENTADAS = nil   -- enquanto garantir() roda: só quem já tem lugar conta

-- retângulos de quem ocupa o andar: a base (taverna ou hall) e as salas abertas
local function ocupantes(andar, ignorar)
  local r = {}
  if ignorar ~= "taverna" or andar ~= 0 then
    local x0, x1, z0, z1
    if andar == 0 then x0, x1, z0, z1 = L.sala_mundo("taverna") else x0, x1, z0, z1 = L.salao() end
    r[1] = { id = "taverna", base = true, nome = andar == 0 and "a taverna" or "o hall", de = andar == 0 and "da taverna" or "do hall", x0 = x0, x1 = x1, z0 = z0, z1 = z1, interna = true }
  end
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      local p = L.blocos[b.id]
      if b.id ~= ignorar and p and p.andar == andar and L.aberta(b.id) and (not ASSENTADAS or ASSENTADAS[b.id]) then
        r[#r + 1] = { id = b.id, nome = b.nome, interna = b.interna, x0 = p.x, x1 = r3(p.x + largura(b)), z0 = p.z, z1 = r3(p.z + fundura(b)) }
      end
    end
  end
  return r
end

local function bloqueio(ignorar, x0, x1, z0, z1, andar)
  for _, q in ipairs(ocupantes(andar, ignorar)) do
    if x0 < q.x1 - EPS and x1 > q.x0 + EPS and z0 < q.z1 - EPS and z1 > q.z0 + EPS then return q end
  end
end

-- comprimento da parede em comum entre dois retângulos, ou 0 se não encostam
local function comum(a, b)
  if math.abs(a.x1 - b.x0) < EPS or math.abs(a.x0 - b.x1) < EPS then
    return math.max(0, math.min(a.z1, b.z1) - math.max(a.z0, b.z0))
  end
  if math.abs(a.z1 - b.z0) < EPS or math.abs(a.z0 - b.z1) < EPS then
    return math.max(0, math.min(a.x1, b.x1) - math.max(a.x0, b.x0))
  end
  return 0
end

-- maior parede que o retângulo divide com a base do andar ou com uma sala interna
local function melhor_contato(ignorar, ret, andar)
  local m = 0
  for _, q in ipairs(ocupantes(andar, ignorar)) do
    if q.interna then m = math.max(m, comum(ret, q)) end
  end
  return m
end

-- primeira interna que perdeu o caminho até a base do andar
local function sem_acesso(andar)
  local grupo, chegou = ocupantes(andar), {}
  local fila = { grupo[1] }
  chegou[grupo[1].id] = true
  local i = 1
  while fila[i] do
    for _, q in ipairs(grupo) do
      if q.interna and not chegou[q.id] and comum(fila[i], q) >= PAREDE_MIN - EPS then
        chegou[q.id] = true
        fila[#fila + 1] = q
      end
    end
    i = i + 1
  end
  for _, q in ipairs(grupo) do
    if q.interna and not chegou[q.id] then return q end
  end
end

-- Porta da rua: fica em uma das paredes da taverna. t = metros desde o começo da parede.
local LADOS_PORTA = { "oeste", "fundo", "leste", "frente" }
local GIRO_PORTA = { oeste = 0, fundo = -math.pi / 2, leste = math.pi, frente = math.pi / 2 }
local MEIA_PORTA = 0.95
-- móveis grandes de parede que a porta não pode atravessar: meia medida em x e z
local MOVEIS_PAREDE = { lareira = { 0.65, 1.3 }, lenha = { 0.35, 0.5 }, prateleira = { 2.7, 0.25 } }

local function comprimento_parede(lado)
  local x0, x1, z0, z1 = L.sala_mundo("taverna")
  if lado == "oeste" or lado == "leste" then return z1 - z0 end
  return x1 - x0
end

-- há sala encostada neste trecho da parede da taverna?
local function coberta(lado, t)
  local x0, x1, z0, z1 = L.sala_mundo("taverna")
  for _, q in ipairs(ocupantes(0, "taverna")) do
    local perto
    if lado == "oeste" then perto = x0 - q.x1 < 0.5 and q.x1 <= x0 + EPS and q.z0 < z0 + t + MEIA_PORTA and q.z1 > z0 + t - MEIA_PORTA
    elseif lado == "leste" then perto = q.x0 - x1 < 0.5 and q.x0 >= x1 - EPS and q.z0 < z0 + t + MEIA_PORTA and q.z1 > z0 + t - MEIA_PORTA
    elseif lado == "fundo" then perto = z0 - q.z1 < 0.5 and q.z1 <= z0 + EPS and q.x0 < x0 + t + MEIA_PORTA and q.x1 > x0 + t - MEIA_PORTA
    else perto = q.z0 - z1 < 0.5 and q.z0 >= z1 - EPS and q.x0 < x0 + t + MEIA_PORTA and q.x1 > x0 + t - MEIA_PORTA end
    if perto then return q end
  end
end

local function ponto_porta(lado, t)
  local x0, x1, z0, z1 = L.sala_mundo("taverna")
  if lado == "oeste" then return x0 + 0.1, z0 + t end
  if lado == "leste" then return x1 - 0.1, z0 + t end
  if lado == "fundo" then return x0 + t, z0 + 0.1 end
  return x0 + t, z1 - 0.1
end

local function atrapalha_movel(lado, t)
  local px, pz = ponto_porta(lado, t)
  local ax, az = MEIA_PORTA, 0.9
  if lado == "oeste" or lado == "leste" then ax, az = 0.9, MEIA_PORTA end
  for id, m in pairs(MOVEIS_PAREDE) do
    if not L.oculto(id) then
      local o = L.POR_ID[id]
      local dx, dz = L.desloc(id)
      if math.abs(o.x + dx - px) < ax + m[1] and math.abs(o.z + dz - pz) < az + m[2] then return id end
    end
  end
end

-- Dá para pôr a porta neste ponto? Devolve ok e o motivo em português.
function L.porta_livre(lado, t)
  if not GIRO_PORTA[lado] then return false, "Parede desconhecida" end
  if t < MEIA_PORTA or t > comprimento_parede(lado) - MEIA_PORTA then return false, "A porta não cabe tão perto do canto" end
  local q = coberta(lado, t)
  if q then return false, "Esta parede está coberta por " .. q.nome end
  local m = atrapalha_movel(lado, t)
  if m then return false, "Tem " .. L.POR_ID[m].nome .. " neste lugar" end
  return true
end

-- lugar livre mais perto de onde a porta está, começando pela mesma parede
local function achar_porta(lado0, t0, com_moveis)
  local ordem = { lado0 }
  for _, l in ipairs(LADOS_PORTA) do if l ~= lado0 then ordem[#ordem + 1] = l end end
  for _, lado in ipairs(ordem) do
    local n = comprimento_parede(lado)
    local alvo = lado == lado0 and t0 or n / 2
    local melhor, md
    local t = MEIA_PORTA
    while t <= n - MEIA_PORTA + EPS do
      local bom = not coberta(lado, t) and (not com_moveis or not atrapalha_movel(lado, t))
      if bom and (not md or math.abs(t - alvo) < md) then melhor, md = t, math.abs(t - alvo) end
      t = t + 0.5
    end
    if melhor then return lado, melhor end
  end
end

-- em qual parede e onde a porta está agora
function L.pos_porta()
  if L.porta_parede then return L.porta_parede.lado, L.porta_parede.t end
  local o = L.POR_ID.porta
  local dx, dz = L.desloc("porta")
  local _, _, z0 = L.sala_mundo("taverna")
  return "oeste", o.z + dz - z0, o.x + dx
end

local function aplicar_porta()
  local pp = L.porta_parede
  if not pp then return end
  pp.t = util.limitar(pp.t, MEIA_PORTA, math.max(MEIA_PORTA, comprimento_parede(pp.lado) - MEIA_PORTA))
  local x, z = ponto_porta(pp.lado, pp.t)
  local guarda = L.porta_parede
  L.colocar("porta", x, z)
  L.porta_parede = guarda
  L.de("porta").g = GIRO_PORTA[pp.lado]
end

-- a sala cobriu a porta: ela foge para o lugar livre mais próximo
local function porta_foge()
  local lado, t = L.pos_porta()
  if not L.porta_parede then
    -- porta de layout antigo, solta no salão: só foge se ainda estiver na parede de origem e for coberta
    local _, _, wx = L.pos_porta()
    local x0 = L.sala_mundo("taverna")
    if math.abs(wx - x0) > 1 or (L.dados.porta and L.dados.porta.g ~= 0) then return end
  end
  if coberta(lado, t) then
    local nl, nt = achar_porta(lado, t, true)
    if not nl then nl, nt = achar_porta(lado, t, false) end
    if nl then
      L.porta_parede = { lado = nl, t = nt }
      L.versao = L.versao + 1
    end
  end
  aplicar_porta()
end

-- Põe a porta numa parede. Passo de meio metro: a porta tem 1,5 m e as paredes têm medidas quebradas.
function L.mover_porta(lado, t)
  t = math.floor(t * 2 + 0.5) / 2
  local ok, motivo = L.porta_livre(lado, t)
  if not ok then return false, motivo end
  L.porta_parede = { lado = lado, t = t }
  aplicar_porta()
  L.versao = L.versao + 1
  return true
end

-- A parede mais perto de um ponto do mundo (o dedo arrastando a porta)
function L.porta_mais_perto(x, z)
  local x0, x1, z0, z1 = L.sala_mundo("taverna")
  local d = { oeste = math.abs(x - x0), leste = math.abs(x - x1), fundo = math.abs(z - z0), frente = math.abs(z - z1) }
  local lado, md
  for _, l in ipairs(LADOS_PORTA) do
    if not md or d[l] < md then lado, md = l, d[l] end
  end
  local t = (lado == "oeste" or lado == "leste") and z - z0 or x - x0
  return lado, util.limitar(t, MEIA_PORTA, comprimento_parede(lado) - MEIA_PORTA)
end

-- Vagas ------------------------------------------------------------------------------

-- Encaixa no passo de 1 m a partir da taverna e, a menos de meio metro de outra parede, encosta nela
local function encaixar(id, x, z, andar, l, p)
  local xa, _, za = L.salao()
  if id == "taverna" then return r3(xa + math.floor(x - xa + 0.5)), r3(za + math.floor(z - za + 0.5)) end
  local nx, nz = xa + math.floor(x - xa + 0.5), za + math.floor(z - za + 0.5)
  local bx, bz, mx, mz = 0.5 + EPS, 0.5 + EPS, nil, nil
  for _, q in ipairs(ocupantes(andar, id)) do
    for _, a in ipairs({ q.x1, q.x0 - l, q.x0, q.x1 - l }) do
      if math.abs(a - x) < bx then bx, mx = math.abs(a - x), a end
    end
    for _, a in ipairs({ q.z1, q.z0 - p, q.z0, q.z1 - p }) do
      if math.abs(a - z) < bz then bz, mz = math.abs(a - z), a end
    end
  end
  return r3(mx or nx), r3(mz or nz)
end

-- Serve para sala e para taverna. Devolve ok, motivo e o ponto já encaixado no passo.
function L.encaixe_valido(id, x, z, andar, l, p)
  local b = SALA_DE[id]
  if id ~= "taverna" and not b then return false, "Sala desconhecida" end
  if type(x) ~= "number" or type(z) ~= "number" or x ~= x or z ~= z then return false, "Posição inválida" end
  local atual = b and bloco(id) or { andar = 0 }
  andar = andar or atual.andar or 0
  if not L.andar_existe(andar) then return false, "Este andar ainda não foi construído" end
  if id == "taverna" then
    if andar ~= 0 then return false, "A taverna fica no térreo" end
    local x0, x1, z0, z1 = L.sala_mundo("taverna")
    local nx, nz = encaixar(id, x, z, 0)
    local q = bloqueio("taverna", nx, nx + x1 - x0, nz, nz + z1 - z0, 0)
    if q then return false, "Ficaria em cima " .. (q.de or "de " .. q.nome), nx, nz end
    local ox, oz = L.origem.x, L.origem.z
    L.origem.x, L.origem.z = ox + nx - x0, oz + nz - z0
    local perdeu = sem_acesso(0)   -- os andares extras vão junto com o hall
    L.origem.x, L.origem.z = ox, oz
    if perdeu then return false, perdeu.nome .. " ficaria sem acesso", nx, nz end
    return true, nil, nx, nz
  end
  if b.so_andar and andar ~= b.so_andar then return false, b.nome .. " só fica no " .. L.NOME_ANDAR[b.so_andar]:lower(), x, z end
  if not b.interna and andar ~= 0 then return false, b.nome .. " é ao ar livre: só fica no térreo", x, z end
  SOBRE = { id = id, l = l, p = p }
  local lg, fd = largura(b), fundura(b)
  local nx, nz = encaixar(id, x, z, andar, lg, fd)
  local function fim(ok, motivo)
    SOBRE = nil
    return ok, motivo, nx, nz
  end
  local ret = { x0 = nx, x1 = r3(nx + lg), z0 = nz, z1 = r3(nz + fd) }
  local q = bloqueio(id, ret.x0, ret.x1, ret.z0, ret.z1, andar)
  if q then return fim(false, "Ficaria em cima " .. (q.de or "de " .. q.nome)) end
  if b.interna then
    local c = melhor_contato(id, ret, andar)
    if c <= 0 then return fim(false, "Precisa encostar na taverna, no hall ou em outra sala interna") end
    if c < PAREDE_MIN - EPS then return fim(false, "Precisa de ao menos 2 m de parede em comum") end
  else
    local base = ocupantes(0)[1]
    local dx = math.max(base.x0 - ret.x1, ret.x0 - base.x1, 0)
    local dz = math.max(base.z0 - ret.z1, ret.z0 - base.z1, 0)
    if dx > AFASTAMENTO_MAX or dz > AFASTAMENTO_MAX then return fim(false, "Longe demais da taverna") end
  end
  -- testa de verdade: ninguém pode perder o acesso nem a taverna a última porta
  local pos = L.blocos[id]
  L.blocos[id] = { x = nx, z = nz, andar = andar }
  local perdeu = sem_acesso(andar)
  if not perdeu and pos and pos.andar ~= andar then perdeu = sem_acesso(pos.andar) end
  local sem_porta = false
  if andar == 0 or (pos and pos.andar == 0) then
    local lado, t = L.pos_porta()
    sem_porta = not achar_porta(lado, t, false)
  end
  L.blocos[id] = pos
  if perdeu then return fim(false, perdeu.nome .. " ficaria sem acesso") end
  if sem_porta then return fim(false, "A taverna ficaria sem porta para a rua") end
  return fim(true)
end

-- Canto, andar. Taverna: canto do salão.
function L.pos_sala(id)
  if id == "taverna" then
    local x0, _, z0 = L.salao()
    return x0, z0, 0
  end
  local p = bloco(id)
  return p.x, p.z, p.andar
end

-- Move se couber; se não, nada muda. Devolve ok e o motivo. O jogo chama J.aplicar_obra e L.salvar depois.
function L.mover_sala(id, x, z, andar)
  local ok, motivo, nx, nz = L.encaixe_valido(id, x, z, andar)
  if not ok then return false, motivo end
  if id == "taverna" then
    local x0, _, z0 = L.salao()
    L.origem.x, L.origem.z = r3(L.origem.x + nx - x0), r3(L.origem.z + nz - z0)
    -- os halls são a taverna em outro andar: o que encosta neles acompanha
    for _, p in pairs(L.blocos) do
      if p.andar ~= 0 then p.x, p.z = r3(p.x + nx - x0), r3(p.z + nz - z0) end
    end
    for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
  else
    local p = L.blocos[id]
    p.x, p.z, p.andar, p.prov, p.ajuste = nx, nz, andar or p.andar, nil, nil
    L.limitar_carregados(id)
  end
  garantir()
  L.versao = L.versao + 1
  return true
end

-- primeira vaga da sala neste andar: a fileira de sempre e, sem espaço nela, encostada em quem houver
local function primeira_vaga(b, andar)
  local l, p = largura(b), fundura(b)
  local base = ocupantes(andar)[1]
  if b.interna then
    local x, z = base.x1, base.z0
    for _ = 1, 40 do
      local q = bloqueio(b.id, x, x + l, z, z + p, andar)
      if not q then
        if melhor_contato(b.id, { x0 = x, x1 = x + l, z0 = z, z1 = z + p }, andar) >= PAREDE_MIN - EPS then return r3(x), r3(z) end
        break
      end
      x = q.x1
    end
    for _, r in ipairs(ocupantes(andar, b.id)) do
      if r.interna then
        for _, c in ipairs({ { r.x0, r.z1 }, { r.x1, r.z0 }, { r.x0 - l, r.z0 }, { r.x0, r.z0 - p } }) do
          local ret = { x0 = c[1], x1 = c[1] + l, z0 = c[2], z1 = c[2] + p }
          if not bloqueio(b.id, ret.x0, ret.x1, ret.z0, ret.z1, andar)
            and melhor_contato(b.id, ret, andar) >= PAREDE_MIN - EPS then return r3(c[1]), r3(c[2]) end
        end
      end
    end
    return r3(x), r3(z)
  end
  local x, z = base.x0, base.z1 + 0.1
  for _ = 1, 40 do
    local q = bloqueio(b.id, x, x + l, z, z + p, 0)
    if not q then return r3(x), r3(z) end
    if q.interna then z = q.z1 + 0.1 else x = q.x1 end
  end
  return r3(x), r3(z)
end

-- Vaga para a Loja: onde a sala entraria neste andar, sem mexer em nada
function L.vaga_sala(id, andar)
  local b = SALA_DE[id]
  if not b then return nil end
  return primeira_vaga(b, andar or (b.so_andar or bloco(id).andar))
end

-- Dá lugar a quem abriu e resolve o que ficou errado. O save de cada sala continua valendo.
garantir = function()
  if L._em_garantir then return end
  L._em_garantir = true
  L._sig = assinatura()
  if not L.andar_existe(L.andar_ativo) then L.andar_ativo = 0 end
  -- provisórias são refeitas: sala fechada não guarda lugar
  for id, p in pairs(L.blocos) do
    if p.prov then L.blocos[id] = nil end
  end
  ASSENTADAS = {}
  -- primeiro quem já tem lugar, da esquerda para a direita: é assim que a ala leste empurra a fileira
  local fixos = {}
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      local p = L.blocos[b.id]
      if p and L.aberta(b.id) then
        local bom_andar = L.andar_existe(p.andar) and (b.interna or p.andar == 0) and (not b.so_andar or p.andar == b.so_andar)
        if bom_andar then fixos[#fixos + 1] = b else L.blocos[b.id] = nil end
      end
    end
  end
  table.sort(fixos, function(a, c)
    local pa, pc = L.blocos[a.id], L.blocos[c.id]
    if pa.x ~= pc.x then return pa.x < pc.x end
    if pa.z ~= pc.z then return pa.z < pc.z end
    return a.id < c.id
  end)
  for _, b in ipairs(fixos) do
    local p = L.blocos[b.id]
    local l, f = largura(b), fundura(b)
    for _ = 1, 12 do
      local q = bloqueio(b.id, p.x, p.x + l, p.z, p.z + f, p.andar)
      if not q then break end
      p.x = r3(q.x1)
    end
    if bloqueio(b.id, p.x, p.x + l, p.z, p.z + f, p.andar) then L.blocos[b.id] = nil
    else ASSENTADAS[b.id] = true end
  end
  -- quem perdeu o acesso (ala fechada em outro save, por exemplo) procura vaga de novo
  for _, n in ipairs(L.ANDARES) do
    local q = sem_acesso(n)
    while q do
      L.blocos[q.id], ASSENTADAS[q.id] = nil, nil
      q = sem_acesso(n)
    end
  end
  -- quem abriu agora entra na vaga livre
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      if L.aberta(b.id) and not L.blocos[b.id] then
        local andar = b.andar or 0
        local x, z = primeira_vaga(b, andar)
        local aj = L._ajuste and L._ajuste[b.id]
        if aj then
          -- layout antigo: a área que o jogador tinha movido continua deslocada, se couber
          local nx, nz = r3(x + aj.x), r3(z + aj.z)
          if not bloqueio(b.id, nx, nx + largura(b), nz, nz + fundura(b), andar) then x, z = nx, nz end
          L._ajuste[b.id] = nil
        end
        L.blocos[b.id] = { x = x, z = z, andar = andar }
        ASSENTADAS[b.id] = true
      end
    end
  end
  -- sala fechada ainda precisa de um lugar para os cálculos: onde abriria hoje, sem ocupar nada
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      if not L.blocos[b.id] then
        local andar = b.andar or 0
        local x, z
        if L.andar_existe(andar) or andar == 0 then x, z = primeira_vaga(b, andar)
        else
          x, z = select(2, L.salao()), select(3, L.salao())
        end
        L.blocos[b.id] = { x = x, z = z, andar = andar, prov = true }
      end
    end
  end
  ASSENTADAS = nil
  porta_foge()
  L.versao = L.versao + 1
  L._em_garantir = false
end

-- Portas entre salas: uma por par de vizinhos, no centro do maior trecho de parede comum.
-- Se um móvel alto de parede estiver ali, anda até o ponto livre mais perto dentro do trecho.
local function centro_livre(eixo, plano, a, b)
  local meio = (a + b) / 2
  local function livre(c)
    local px, pz = c, plano
    if eixo == "z" then px, pz = plano, c end
    for id, m in pairs(MOVEIS_PAREDE) do
      if not L.oculto(id) then
        local o = L.POR_ID[id]
        local dx, dz = L.desloc(id)
        if math.abs(o.x + dx - px) < m[1] + 0.9 and math.abs(o.z + dz - pz) < m[2] + 0.9 then return false end
      end
    end
    return true
  end
  local passo = 0
  while meio + passo <= b - 1 or meio - passo >= a + 1 do
    if meio + passo <= b - 1 and livre(meio + passo) then return meio + passo end
    if meio - passo >= a + 1 and livre(meio - passo) then return meio - passo end
    passo = passo + 0.5
  end
  return meio
end

-- { dono = quem desenha a parede, vizinho, eixo = "x" (parede corre em x) ou "z", plano, c, a, b }
function L.portas(andar)
  bloco("cozinha")
  andar = andar or L.andar_ativo
  local r = {}
  local g = ocupantes(andar)
  local dono_base = andar == 0 and "taverna" or (andar == 1 and "hall_cima" or "hall_baixo")
  local function nome(q) return q.base and dono_base or q.id end
  for i = 1, #g do
    for k = i + 1, #g do
      local q, w = g[i], g[k]
      if q.interna and w.interna and comum(q, w) >= PAREDE_MIN - EPS then
        local eixo, plano, dono, viz, a, b
        if math.abs(q.z0 - w.z1) < EPS then eixo, plano, dono, viz = "x", q.z0, q, w
        elseif math.abs(w.z0 - q.z1) < EPS then eixo, plano, dono, viz = "x", w.z0, w, q
        elseif math.abs(q.x0 - w.x1) < EPS then eixo, plano, dono, viz = "z", q.x0, q, w
        else eixo, plano, dono, viz = "z", w.x0, w, q end
        if eixo == "x" then a, b = math.max(q.x0, w.x0), math.min(q.x1, w.x1)
        else a, b = math.max(q.z0, w.z0), math.min(q.z1, w.z1) end
        r[#r + 1] = { dono = nome(dono), vizinho = nome(viz), eixo = eixo, plano = plano, c = centro_livre(eixo, plano, a, b), a = a, b = b }
      end
    end
  end
  return r
end

-- Lado da área externa que olha para a taverna: a porteira fica nele, o mais perto possível dela
function L.lado_porteira(id)
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local xa, xb, za, zb = L.sala_mundo("taverna")
  local function dentro(de, ate, a, b, l)
    local i, f = math.max(de + 0.4, a + 0.3) + l / 2, math.min(ate - 0.4, b - 0.3) - l / 2
    if i <= f then return i, f end
    return de + 0.4 + l / 2, ate - 0.4 - l / 2
  end
  if z0 >= zb - EPS then return "fundo", dentro(x0, x1, xa, xb, 1.3) end
  if z1 <= za + EPS then return "frente", dentro(x0, x1, xa, xb, 1.3) end
  if x1 <= xa + EPS then return "direita", dentro(z0, z1, za, zb, 1.3) end
  return "esquerda", dentro(z0, z1, za, zb, 1.3)
end

-- Trechos da parede que precisam ficar baixos porque há sala atrás. A câmera olha de cima, da
-- direita e da frente: o fundo de 4,2 m esconde uns 5 m atrás dele; a esquerda, menos.
local OCULTA = { fundo = 5.5, oeste = 2.2 }
local SOBRA = { fundo = 1.8, oeste = 5 }
function L.trechos_baixos(id, lado)
  bloco("cozinha")
  local andar = (id == "taverna" and 0) or (id == "hall_cima" and 1) or (id == "hall_baixo" and -1) or L.blocos[id].andar
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local r = {}
  for _, q in ipairs(ocupantes(andar, id == "hall_cima" and "" or id)) do
    if not (q.base and id ~= "taverna" and (id == "hall_cima" or id == "hall_baixo")) then
      if lado == "fundo" and q.z1 <= z0 + EPS and z0 - q.z1 < OCULTA.fundo and q.x0 < x1 and q.x1 + SOBRA.fundo > x0 then
        r[#r + 1] = { a = math.max(q.x0, x0), b = math.min(q.x1 + SOBRA.fundo, x1) }
      elseif lado == "oeste" and q.x0 < x0 - EPS and q.x1 > x0 - OCULTA.oeste and q.z0 < z1 and q.z1 + SOBRA.oeste > z0 then
        r[#r + 1] = { a = math.max(q.z0, z0), b = math.min(q.z1 + SOBRA.oeste, z1) }
      end
    end
  end
  table.sort(r, function(a, b) return a.a < b.a end)
  return r
end

function L.parede_baixa(id, lado, c)
  for _, t in ipairs(L.trechos_baixos(id, lado)) do
    if c >= t.a - 0.01 and c <= t.b + 0.01 then return true end
  end
  return false
end

-- Cópia de tudo o que descreve os blocos: para o Desfazer
function L.estado_blocos()
  local b = {}
  for id, p in pairs(L.blocos) do b[id] = { x = p.x, z = p.z, andar = p.andar, prov = p.prov } end
  local pp = L.porta_parede
  return { blocos = b, origem = { x = L.origem.x, z = L.origem.z }, porta = pp and { lado = pp.lado, t = pp.t } or nil }
end

function L.definir_blocos(t)
  L.blocos, L.origem, L.porta_parede = t.blocos, t.origem, t.porta
  garantir()
end

-- Em qualquer lugar da tela: o retângulo de todo bloco aberto no andar ativo
function L.blocos_visiveis()
  bloco("cozinha")
  return ocupantes(L.andar_ativo)
end

-- menor valor que cada chave aceita, contando o que já foi acrescentado do outro lado
local function minimo(lado)
  local s = L.tamanho
  if lado == "dir" then return math.ceil(SALAO_L_MIN - SALAO_L) - s.oeste end
  if lado == "oeste" then return math.ceil(SALAO_L_MIN - SALAO_L) - s.dir end
  if lado == "frente" then return math.ceil(SALAO_P_MIN - SALAO_P) - s.fundo end
  if lado == "fundo" then return math.ceil(SALAO_P_MIN - SALAO_P) - s.frente end
  local k, eixo = lado:match("^(.-)_([lp])$")
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      if b.k == k then
        if eixo == "l" then return math.ceil(SALA_MIN - b.l) end
        return math.ceil(SALA_MIN - b.p)
      end
    end
  end
  return 0
end
L.tamanho_minimo = minimo

-- Parede de um bloco andou: quem estava colado nela anda junto, quem estava no caminho é empurrado.
-- eixo "x" ou "z"; sinal: para que lado a parede olha; ret: o bloco antes da mudança.
local function levar_vizinhos(andar, eixo, sinal, ret, delta, visitados)
  if delta == 0 then return end
  local parede = eixo == "x" and (sinal > 0 and ret.x1 or ret.x0) or (sinal > 0 and ret.z1 or ret.z0)
  for _, q in ipairs(ocupantes(andar)) do
    local p = L.blocos[q.id]
    if not q.base and p and not p.prov and not visitados[q.id] then
      local cruza
      if eixo == "x" then cruza = q.z0 < ret.z1 - EPS and q.z1 > ret.z0 + EPS
      else cruza = q.x0 < ret.x1 - EPS and q.x1 > ret.x0 + EPS end
      if cruza then
        local perto = eixo == "x" and (sinal > 0 and q.x0 or q.x1) or (sinal > 0 and q.z0 or q.z1)
        local vao = (perto - parede) * sinal
        local anda = 0
        if vao >= -EPS and vao <= 0.2 then anda = delta         -- colado: vai junto, para os dois lados
        elseif vao > 0.2 and delta > vao then anda = delta - vao end  -- longe: só se a parede chegar nele
        if anda ~= 0 then
          visitados[q.id] = true
          if eixo == "x" then p.x = r3(p.x + anda * sinal) else p.z = r3(p.z + anda * sinal) end
          levar_vizinhos(andar, eixo, sinal, q, anda, visitados)
        end
      end
    end
  end
end

local CHAVE_SALAO = { dir = { "x", 1 }, oeste = { "x", -1 }, frente = { "z", 1 }, fundo = { "z", -1 } }

function L.mudar_tamanho(lado, delta)
  bloco("cozinha")
  local s = L.tamanho
  local antes = s[lado] or 0
  local novo = util.limitar(antes + delta, math.min(minimo(lado), L.TAMANHO_MAX), L.TAMANHO_MAX)
  local cs = CHAVE_SALAO[lado]
  if cs then
    -- a taverna e os halls mudam juntos: quem encosta neles, em cada andar, acompanha
    local rets = {}
    for _, n in ipairs(L.ANDARES) do
      local q = ocupantes(n)[1]
      rets[n] = q
    end
    s[lado] = novo
    for _, n in ipairs(L.ANDARES) do levar_vizinhos(n, cs[1], cs[2], rets[n], novo - antes, {}) end
  else
    local k, eixo_k = lado:match("^(.-)_([lp])$")
    local alvo
    for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
      for _, b in ipairs(lista) do if b.k == k then alvo = b end end
    end
    local p = alvo and L.blocos[alvo.id]
    if p and not p.prov then
      local eixo = eixo_k == "l" and "x" or "z"
      local ret = { x0 = p.x, x1 = r3(p.x + largura(alvo)), z0 = p.z, z1 = r3(p.z + fundura(alvo)) }
      local med0 = eixo == "x" and largura(alvo) or fundura(alvo)
      s[lado] = novo
      local dm = (eixo == "x" and largura(alvo) or fundura(alvo)) - med0
      -- encostada só do lado de lá: cresce para o lado livre, sem empurrar quem a segura
      local lado_mais, lado_menos = false, false
      for _, q in ipairs(ocupantes(p.andar, alvo.id)) do
        if not q.interna then -- cerca não segura ninguém
        elseif eixo == "x" and q.z0 < ret.z1 - EPS and q.z1 > ret.z0 + EPS then
          if math.abs(q.x0 - ret.x1) <= 0.2 then lado_mais = true end
          if math.abs(q.x1 - ret.x0) <= 0.2 then lado_menos = true end
        elseif eixo == "z" and q.x0 < ret.x1 - EPS and q.x1 > ret.x0 + EPS then
          if math.abs(q.z0 - ret.z1) <= 0.2 then lado_mais = true end
          if math.abs(q.z1 - ret.z0) <= 0.2 then lado_menos = true end
        end
      end
      if lado_mais and not lado_menos then
        if eixo == "x" then p.x = r3(p.x - dm) else p.z = r3(p.z - dm) end
        levar_vizinhos(p.andar, eixo, -1, ret, dm, { [alvo.id] = true })
      else
        levar_vizinhos(p.andar, eixo, 1, ret, dm, { [alvo.id] = true })
      end
    else
      s[lado] = novo
    end
  end
  L._em_garantir = false
  garantir()
  -- quem foi empurrado tenta voltar ao lugar; o que estava no espaço que sumiu vem para dentro
  for _, o in ipairs(L.OBJETOS) do
    local d = L.dados[o.id]
    if d and d.orig then d.x, d.z, d.orig = d.orig.x, d.orig.z, nil end
  end
  for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
end

-- Alças da Loja: uma por lado redimensionável, com x e z no centro da borda, no mundo.
-- Puxar 1 m no sentido de `sinal` equivale a L.mudar_tamanho(chave, 1).
function L.paredes()
  local xa, xb, za, zb = L.salao()
  local cx, cz = (xa + xb) / 2, (za + zb) / 2
  local l = {}
  if L.andar_ativo == 0 then
    l = {
      { id = "salao_dir", nome = "Salão: direita", chave = "dir", eixo = "x", sinal = 1, x = xb, z = cz },
      { id = "salao_frente", nome = "Salão: frente", chave = "frente", eixo = "z", sinal = 1, x = cx, z = zb },
      { id = "salao_fundo", nome = "Salão: fundo", chave = "fundo", eixo = "z", sinal = -1, x = cx, z = za },
      { id = "salao_oeste", nome = "Salão: esquerda", chave = "oeste", eixo = "x", sinal = -1, x = xa, z = cz },
    }
  end
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      if b.k and L.aberta(b.id) and L.blocos[b.id].andar == L.andar_ativo then
        local x0, x1, z0, z1 = L.sala_mundo(b.id)
        -- a alça fica no lado livre: sala à esquerda da taverna cresce para a esquerda
        local ret = { x0 = x0, x1 = x1, z0 = z0, z1 = z1 }
        local mx, mn, zx, zn = false, false, false, false
        for _, q in ipairs(ocupantes(L.andar_ativo, b.id)) do
          if q.interna and q.z0 < z1 - EPS and q.z1 > z0 + EPS then
            if math.abs(q.x0 - ret.x1) <= 0.2 then mx = true end
            if math.abs(q.x1 - ret.x0) <= 0.2 then mn = true end
          end
          if q.interna and q.x0 < x1 - EPS and q.x1 > x0 + EPS then
            if math.abs(q.z0 - ret.z1) <= 0.2 then zx = true end
            if math.abs(q.z1 - ret.z0) <= 0.2 then zn = true end
          end
        end
        local vl, vz = mx and not mn, zx and not zn
        l[#l + 1] = { id = b.id .. "_largura", nome = b.nome .. ": largura", chave = b.k .. "_l", eixo = "x", sinal = vl and -1 or 1, x = vl and x0 or x1, z = (z0 + z1) / 2 }
        l[#l + 1] = { id = b.id .. "_fundo", nome = b.nome .. ": fundo", chave = b.k .. "_p", eixo = "z", sinal = vz and -1 or 1, x = (x0 + x1) / 2, z = vz and z0 or z1 }
      end
    end
  end
  return l
end

-- nomes de versões antigas: um grupo virou vários objetos, e o que o jogador moveu continua movido
local ANTIGOS = {
  garrafas = { x = 3.05, z = -4.3, "prateleira" },
  barris_fundo = { x = 5.2, z = -3.5, "barril1", "barril2", "barril3" },
  barris_frente = { x = -5.2, z = 4.0, "barril4", "barril5" },
}

local function migrar(t)
  for velho, g in pairs(ANTIGOS) do
    local d = t[velho]
    if type(d) == "table" then
      local dg = numero(d.g)
      local co, si = math.cos(dg), math.sin(dg)
      for _, id in ipairs(g) do
        if t[id] == nil then
          local o = L.POR_ID[id]
          local rx, rz = o.x - g.x, o.z - g.z
          L.dados[id] = { x = numero(d.x) + g.x + rx * co + rz * si - o.x, z = numero(d.z) + g.z - rx * si + rz * co - o.z, y = numero(d.y), g = dg }
        end
      end
    end
  end
end

local function aplicar_tabela(t)
  if type(t) ~= "table" then return end
  local antigo = type(t._salas) ~= "table"
  if type(t._tamanho) == "table" then
    for lado in pairs(L.tamanho) do
      L.tamanho[lado] = util.limitar(math.floor(numero(t._tamanho[lado])), -L.TAMANHO_MAX, L.TAMANHO_MAX)
    end
    -- depois de ler tudo: o mínimo de cada lado depende do lado oposto
    for lado in pairs(L.tamanho) do
      L.tamanho[lado] = math.max(L.tamanho[lado], math.min(minimo(lado), 0))
    end
    -- layout de antes dos blocos: a sala interna era tão funda quanto o salão, e continua sendo
    if antigo then
      local extra = numero(t._tamanho.frente) + numero(t._tamanho.fundo)
      for _, b in ipairs(INTERNAS) do
        local c = b.k .. "_p"
        L.tamanho[c] = util.limitar(L.tamanho[c] + math.floor(extra), minimo(c), L.TAMANHO_MAX)
      end
    end
  end
  if type(t._salas) == "table" then
    for id, p in pairs(t._salas) do
      local b = SALA_DE[id]
      if b and type(p) == "table" and type(p.x) == "number" and type(p.z) == "number" then
        local andar = (p.andar == 1 or p.andar == -1) and p.andar or 0
        L.blocos[id] = { x = r3(numero(p.x)), z = r3(numero(p.z)), andar = andar }
      end
    end
  end
  if type(t._taverna) == "table" then
    L.origem = { x = numero(t._taverna.x), z = numero(t._taverna.z) }
  end
  if type(t._porta) == "table" and GIRO_PORTA[t._porta.lado] then
    L.porta_parede = { lado = t._porta.lado, t = numero(t._porta.t) }
  end
  migrar(t)
  -- layout de antes do caminho de pedras: mural e mercadinho estavam dentro, e aquele lugar não vale mais
  local antes_do_caminho = t._caminho == nil
  if type(t._extras) == "table" then
    local n = 0
    for _, x in ipairs(t._extras) do
      if n < L.MAX_EXTRAS and type(x) == "table" and L.TIPOS_EXTRAS[x.tipo] then
        L.adicionar(x.tipo, numero(x.x), numero(x.z), type(x.id) == "string" and x.id or nil)
        n = n + 1
      end
    end
  end
  for id, d in pairs(t) do
    if L.POR_ID[id] and type(d) == "table" and not (antes_do_caminho and (id == "quadro" or id == "barraca" or id == "estantes")) then
      L.dados[id] = { x = numero(d.x), z = numero(d.z), y = numero(d.y), g = numero(d.g), oculto = d.oculto == true and L.removivel(id) or nil }
      -- empurrado por um salão menor: continua sabendo para onde voltar quando ele crescer
      if type(d.orig) == "table" then L.dados[id].orig = { x = numero(d.orig.x), z = numero(d.orig.z) } end
      -- área externa movida em layout antigo: o deslocamento vale quando ela ganhar lugar
      local b = SALA_DE[id]
      if b and not b.interna then
        local dd = L.dados[id]
        if antigo and (dd.x ~= 0 or dd.z ~= 0) then
          L._ajuste = L._ajuste or {}
          L._ajuste[id] = { x = dd.x, z = dd.z }
        end
        dd.x, dd.z, dd.orig = 0, 0, nil
      end
    end
  end
  garantir()
  -- só depois de ler tudo: o limite de um objeto depende de onde está quem o carrega
  for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
end

-- as posições oficiais vêm primeiro; as deste save têm prioridade
local function zerar_blocos()
  L.blocos, L.origem, L.porta_parede, L._ajuste, L._sig = {}, { x = 0, z = 0 }, nil, nil, nil
  L.andar_ativo = 0
end

-- t: o que o save guarda ({} = jogo novo, só o padrão). Sem t, lê o arquivo de layout antigo, de quando
-- todos os saves dividiam a mesma construção: ele só é lido, para migrar quem ainda não tem a própria.
function L.carregar(t)
  L.limpar_extras()
  L.dados = {}
  L.tamanho = tamanho_zero()
  zerar_blocos()
  aplicar_tabela(require("layout_padrao"))
  if t == nil then t = util.desserializar(motor.layout_carregar()) end
  aplicar_tabela(t)
end

-- Decoração que o jogador compra na Loja: entra como objeto comum da lista
L.TIPOS_EXTRAS = {
  barril = { nome = "Barril", raio = 0.43 },
  caixote = { nome = "Caixote", raio = 0.45 },
  planta = { nome = "Planta", raio = 0.3 },
  vela = { nome = "Candelabro", raio = 0.2 },
  tapete = { nome = "Tapete" },
  estante = { nome = "Estante", raio = 0.6 },
  banco = { nome = "Banco", raio = 0.28 },
  quadro = { nome = "Quadro na parede" },
}

function L.adicionar(tipo, x, z, id)
  local t = L.TIPOS_EXTRAS[tipo]
  if not t then return nil end
  if not id or L.POR_ID[id] then
    L.prox_extra = (L.prox_extra or 0) + 1
    id = "extra_" .. L.prox_extra
    while L.POR_ID[id] do
      L.prox_extra = L.prox_extra + 1
      id = "extra_" .. L.prox_extra
    end
  end
  local o = { id = id, nome = t.nome, x = x, z = z, cat = "Extras", extra = tipo }
  L.OBJETOS[#L.OBJETOS + 1] = o
  L.POR_ID[id] = o
  return o
end

local function tirar_extra(id)
  for i, o in ipairs(L.OBJETOS) do
    if o.id == id then
      table.remove(L.OBJETOS, i)
      break
    end
  end
  L.POR_ID[id] = nil
  L.dados[id] = nil
end

function L.limpar_extras()
  for i = #L.OBJETOS, 1, -1 do
    if L.OBJETOS[i].extra then tirar_extra(L.OBJETOS[i].id) end
  end
end

-- Decoração comprada na Loja: é a única coisa que o jogador pode excluir
function L.decoracao(id)
  local o = L.POR_ID[id]
  return o ~= nil and o.extra ~= nil
end

-- O que a árvore de habilidades constrói não pode ser excluído: só movido
local FIXOS = { mesa = true, balcao = true, fogao = true, cozinheiro = true, bardo = true, barraca = true, estantes = true,
  quadro = true, porta = true, palco = true, jardim = true, caminho = true, cervejaria = true, circulo = true, quartos = true,
  cozinha = true, pomar = true, fazenda = true, celeiro = true, canteiros = true,
  taverna = true, quartos_sala = true, sala_guilda = true, alcapao = true }
-- móveis dos andares extras vêm junto com o andar comprado
local CAT_FIXA = { ["Segundo andar"] = true, ["Subsolo"] = true, Quartos = true, Guilda = true }

function L.removivel(id)
  local o = L.POR_ID[id]
  if not o then return false end
  if o.extra then return true end
  if CAT_FIXA[o.cat] then return false end
  -- mesas, árvores e vacas mostram quantas foram compradas
  if id:match("^mesa%d") or id:match("^arvore%d") or id:match("^vaca%d") or id:match("^porco%d") or id:match("^galinha%d") then return false end
  return not FIXOS[id]
end

function L.oculto(id)
  local d = L.dados[id]
  return d ~= nil and d.oculto == true
end

-- Exclui: decoração comprada some de vez; layout antigo ainda pode trazer item original escondido
function L.excluir(id)
  if not L.removivel(id) then return false end
  if L.POR_ID[id].extra then tirar_extra(id)
  else L.de(id).oculto = true end
  return true
end

function L.restaurar(id)
  local padrao = require("layout_padrao")
  if id then
    L.dados[id] = nil
    if id == "porta" then
      L.porta_parede = nil
      garantir()
    elseif id == "taverna" then
      L.origem = { x = 0, z = 0 }
      garantir()
    elseif SALA_DE[id] then
      L.blocos[id] = nil      -- volta para a primeira vaga
      garantir()
    end
    if padrao[id] then aplicar_tabela({ [id] = padrao[id], _salas = {} }) end
    -- a posição original pode ter ficado fora de um salão que encolheu
    L.limitar(id)
    L.limitar_carregados(id)
  else
    L.limpar_extras()
    L.dados = {}
    L.tamanho = tamanho_zero()
    zerar_blocos()
    aplicar_tabela(padrao)
  end
end

-- O que vai para o arquivo: só o que é definitivo. A presença de _salas marca o layout como novo.
function L.gravar_blocos(t)
  local s = {}
  for id, p in pairs(L.blocos) do
    if not p.prov then s[id] = { x = p.x, z = p.z, andar = p.andar } end
  end
  t._salas = s
  t._caminho = 1
  if L.origem.x ~= 0 or L.origem.z ~= 0 then t._taverna = { x = L.origem.x, z = L.origem.z } end
  if L.porta_parede then t._porta = { lado = L.porta_parede.lado, t = L.porta_parede.t } end
end

function L.lista_extras()
  local l = {}
  for _, o in ipairs(L.OBJETOS) do
    if o.extra then l[#l + 1] = { id = o.id, tipo = o.extra, x = o.x, z = o.z } end
  end
  return l
end

-- O que vai para o save: só o que difere das posições oficiais, senão elas ficariam congeladas para sempre
function L.exportar()
  local padrao, editado = require("layout_padrao"), {}
  for id, d in pairs(L.dados) do
    local p = padrao[id] or {}
    if d.x ~= (p.x or 0) or d.z ~= (p.z or 0) or d.y ~= (p.y or 0) or d.g ~= (p.g or 0) or d.oculto then editado[id] = d end
  end
  editado._tamanho = L.tamanho
  editado._extras = L.lista_extras()
  L.gravar_blocos(editado)
  return editado
end

-- A construção mora no save: gravar o jogo grava ela junto
function L.salvar()
  local J = package.loaded.jogo
  if J then J.salvar() end
end

function L.de(id)
  local d = L.dados[id]
  if not d then
    d = { x = 0, z = 0, y = 0, g = 0 }
    L.dados[id] = d
  end
  return d
end

-- giro e altura somam os de quem carrega o objeto
function L.giro(id)
  local o, d = L.POR_ID[id], L.dados[id]
  local g = d and d.g or 0
  if o and o.pai and o.pai:sub(1, 1) ~= "@" then g = g + L.giro(o.pai) end
  return g
end

function L.altura(id)
  local o, d = L.POR_ID[id], L.dados[id]
  local y = d and d.y or 0
  if o and o.pai and o.pai:sub(1, 1) ~= "@" then y = y + L.altura(o.pai) end
  return y
end

-- posição base -> posição no mundo, girando em volta do centro do objeto
function L.t(id, x, z)
  local o = L.POR_ID[id]
  local dx, dz = L.desloc(id)
  local g = L.giro(id)
  local co, si = math.cos(g), math.sin(g)
  local rx, rz = x - o.x, z - o.z
  return o.x + dx + rx * co + rz * si, o.z + dz - rx * si + rz * co
end

-- ponto do mundo -> posição base (usado nas colisões com caixas giradas)
function L.base(id, x, z)
  local o = L.POR_ID[id]
  local dx, dz = L.desloc(id)
  local g = L.giro(id)
  local co, si = math.cos(g), math.sin(g)
  local rx, rz = x - o.x - dx, z - o.z - dz
  return o.x + rx * co - rz * si, o.z + rx * si + rz * co
end

return L
