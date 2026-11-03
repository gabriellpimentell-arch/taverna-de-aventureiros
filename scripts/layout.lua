-- =============================================================================
--  POSIÇÕES DOS OBJETOS
--  Guarda quanto cada objeto foi movido no modo de edição. Regras (mesas, rotas,
--  colisões) e desenho usam estes dados, então tudo acompanha o que você mover.
-- =============================================================================

local util = require("util")

local L = {}

-- cat: categoria na lista do editor. pai: o objeto acompanha outro objeto ou uma
-- parede ("@fundo", "@oeste", "@leste", "@frente", "@canto") quando a taverna muda de tamanho.
L.CATEGORIAS = { "Tamanho", "Salas", "Extras", "Móveis", "Balcão", "Paredes", "Decoração", "Áreas", "Jardim", "Pomar", "Fazenda", "Cozinha", "Cervejaria", "Círculo" }
L.OBJETOS = {}
L.POR_ID = {}
local function ob(id, nome, x, z, cat, pai)
  local o = { id = id, nome = nome, x = x, z = z, cat = cat, pai = pai }
  L.OBJETOS[#L.OBJETOS + 1] = o
  L.POR_ID[id] = o
end

local MESAS = { { -3.6, 0.2 }, { 0.3, 0.2 }, { 4.2, 0.2 }, { -3.6, 3.4 }, { 0.3, 3.4 }, { 4.2, 3.4 }, { 7.5, 3.4 }, { 10.7, 3.4 } } -- mesas 7 e 8 afastadas: bancos a menos de um corpo de distância travavam quem chegava
for i, m in ipairs(MESAS) do
  ob("mesa" .. i, "Mesa " .. i, m[1], m[2], "Móveis", i >= 7 and "@leste" or nil)
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
ob("carga_leste", "Caixote da ala leste", 11.2, -0.4, "Móveis", "@leste")

ob("balcao", "Balcão e bancos", 3.05, -2.2, "Balcão")
ob("barrilete", "Barrilete com torneira", 4.95, -2.3, "Balcão", "balcao")
ob("caneca1", "Caneca 1", 1.05, -1.98, "Balcão", "balcao")
ob("caneca2", "Caneca 2", 4.15, -1.98, "Balcão", "balcao")
ob("prateleira", "Prateleiras", 3.05, -4.32, "Balcão", "@fundo")
for i = 1, 8 do
  ob("garrafa" .. i, "Garrafa " .. i, 0.65 + (i - 1) * 0.68, -4.3, "Balcão", "prateleira")
end

ob("porta", "Porta", -6.4, 1.6, "Paredes", "@oeste")
ob("lampiao_porta", "Lampião da porta", -6.25, 2.6, "Paredes", "@oeste")
ob("janela1", "Janela 1", -6.46, -1.27, "Paredes", "@oeste")
ob("janela2", "Janela 2", -6.46, 3.7, "Paredes", "@oeste")
ob("lareira", "Lareira", -6.1, -3.2, "Paredes", "@oeste")
ob("lenha", "Lenha", -6.05, -1.95, "Paredes", "@oeste")
ob("quadro", "Quadro de missões", -2.6, -4.4, "Paredes", "@fundo")
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

ob("barraca", "Mercadinho", 9.3, -2.2, "Áreas", "@leste")
ob("estantes", "Estantes de venda", 9.3, -4.3, "Áreas", "@leste")
ob("jardim", "Jardim", -3, 6.75, "Áreas", "@frente")
ob("pomar", "Jardim de frutas", 4.25, 7.8, "Áreas", "@pomar")
ob("fazenda", "Fazenda", 13, 7.8, "Áreas", "@fazenda")
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
for i, a in ipairs(L.ARVORES) do ob("arvore" .. i, "Árvore " .. i, a[1], a[2], "Pomar", "pomar") end
ob("cesto", "Cesto de frutas", 1.3, 5.9, "Pomar", "pomar")

ob("celeiro", "Celeiro", 15.6, 8, "Fazenda", "fazenda")
ob("cocho", "Cocho", 11.2, 6.2, "Fazenda", "fazenda")
ob("feno", "Feno", 13.3, 10, "Fazenda", "fazenda")
L.VACAS = { { 9.3, 7.2, 0.4 }, { 11.4, 7.5, 2.7 }, { 12.8, 6.6, -0.5 }, { 9.5, 8.8, -0.7 }, { 11.6, 9.1, 0.3 }, { 9.7, 10.1, 3.4 }, { 12.8, 8.4, 1.5 }, { 11.5, 10.2, 5.5 } }
for i, v in ipairs(L.VACAS) do ob("vaca" .. i, "Vaca " .. i, v[1], v[2], "Fazenda", "fazenda") end

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

-- metros acrescentados em cada lado do salão
local function tamanho_zero()
  return { dir = 0, frente = 0, fundo = 0, oeste = 0, jardim_l = 0, jardim_p = 0, pomar_l = 0, pomar_p = 0, faz_l = 0, faz_p = 0,
    coz_l = 0, coz_p = 0, cerv_l = 0, cerv_p = 0, circ_l = 0, circ_p = 0 }
end
L.tamanho = tamanho_zero()
L.TAMANHO_MAX = 40
local SALAO_L, SALAO_P = 13, 9.2      -- tamanho original do salão
local SALAO_L_MIN, SALAO_P_MIN = 8, 7
local SALA_MIN = 3
local ALA_L = 5.5

-- Salas internas: fileira à direita do salão e da ala leste. Áreas externas: fileira na frente do salão.
-- x0, l e p são as medidas de origem; os filhos foram posicionados contando com elas.
local INTERNAS = {
  { id = "cozinha", ancora = "@cozinha", x0 = 12, l = 5.5, k = "coz", nome = "Cozinha" },
  { id = "cervejaria", ancora = "@cerv", x0 = 17.5, l = 5.5, k = "cerv", nome = "Cervejaria" },
  { id = "circulo", ancora = "@canto", x0 = 23, l = 5.5, k = "circ", nome = "Invocação" },
}
local EXTERNAS = {
  { id = "jardim", ancora = "@frente", x0 = -6.5, l = 7, z0 = 4.8, p = 4, k = "jardim", nome = "Jardim" },
  { id = "pomar", ancora = "@pomar", x0 = 0.5, l = 7.5, z0 = 4.8, p = 6, k = "pomar", nome = "Jardim de frutas" },
  { id = "fazenda", ancora = "@fazenda", x0 = 8, l = 10, z0 = 4.8, p = 6, k = "faz", nome = "Fazenda" },
}
local SALA_DE, POR_ANCORA = {}, {}
for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
  for _, b in ipairs(lista) do
    b.interna = lista == INTERNAS
    SALA_DE[b.id], POR_ANCORA[b.ancora] = b, b
  end
end

-- layout.lua é carregado antes de jogo.lua: enquanto o jogo não existe, nada foi comprado
local function ef(k)
  local J = package.loaded.jogo
  return J and J.ef(k) or 0
end

local ABRE = { cervejaria = "a_cerveja", circulo = "a_circulo", jardim = "a_jardim", pomar = "a_pomar", fazenda = "a_fazenda" }
function L.aberta(id)
  -- save antigo pode ter o cozinheiro de antes de a cozinha existir: ele precisa de onde ficar
  if id == "cozinha" then return ef("a_cozinha") > 0 or ef("cozinheiro") > 0 end
  return ef(ABRE[id]) > 0
end

function L.leste_aberta()
  local J = package.loaded.jogo
  return ef("a_leste") > 0 or (J ~= nil and J.mercadinho_aberto ~= nil and J.mercadinho_aberto())
end

local function largura(b) return math.max(SALA_MIN, b.l + L.tamanho[b.k .. "_l"]) end

L.dados = {}

local function numero(v)
  return type(v) == "number" and v == v and v > -1000 and v < 1000 and v or 0
end

-- onde o salão termina, já contando o tamanho escolhido
function L.salao()
  local s = L.tamanho
  return -6.5 - s.oeste, 6.5 + s.dir, -4.5 - s.fundo, 4.7 + s.frente
end

-- onde a sala começa em x: encosta na anterior que estiver aberta, sem deixar buraco
local function cursor(alvo)
  local xa, xb = L.salao()
  local x = xa
  if alvo.interna then x = xb + (L.leste_aberta() and ALA_L or 0) end
  for _, b in ipairs(alvo.interna and INTERNAS or EXTERNAS) do
    if b == alvo then break end
    if L.aberta(b.id) then x = x + largura(b) end
  end
  return x
end

local function ancora(pai)
  local s = L.tamanho
  if pai == "@fundo" then return 0, -s.fundo
  elseif pai == "@oeste" then return -s.oeste, 0
  elseif pai == "@leste" then return s.dir, 0
  end
  local b = POR_ANCORA[pai]
  if b then
    local x = cursor(b)
    return x - b.x0, b.interna and -s.fundo or s.frente
  end
  return 0, 0
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
  return x, z
end

-- põe o centro do objeto em um ponto do mundo, seja quem for que o carrega
function L.colocar(id, x, z)
  local o, d = L.POR_ID[id], L.de(id)
  if o.pai and o.pai:sub(1, 1) ~= "@" then
    x, z = L.base(o.pai, x, z)
  elseif o.pai then
    local px, pz = ancora(o.pai)
    x, z = x - px, z - pz
  end
  d.x, d.z = x - o.x, z - o.z
  d.orig = nil     -- agora este é o lugar escolhido
end

-- meia largura (x) e meia profundidade (z) de quem precisa caber inteiro num salão menor
local MEIA = { balcao = { 2.8, 1.6 }, prateleira = { 2.7, 0.3 }, tapete1 = { 2.3, 1 }, tapete2 = { 2.2, 1 }, carga = { 0.8, 0.5 } }

local function raiz(o)
  while o.pai and o.pai:sub(1, 1) ~= "@" and L.POR_ID[o.pai] do o = L.POR_ID[o.pai] end
  return o
end

-- até onde a área externa pode ir: a fileira inteira em x, e o fundo dela em z
local function limites_externos(sala)
  local xa, xb, _, zb = L.salao()
  local xmax = xb + 6.5
  for _, b in ipairs(EXTERNAS) do xmax = math.max(xmax, cursor(b) + largura(b) + 0.5) end
  return xa - 0.5, xmax, math.max(zb + 5.3, zb + 0.6 + math.max(SALA_MIN, sala.p + L.tamanho[sala.k .. "_p"]))
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
  if not d and not algum_negativo() then return end
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
    x0, x1, z0, z1 = x0 + 0.5, x1 - 0.1, z0 - 0.1, z1 - 0.1
  elseif sala then
    x0, x1, z1 = limites_externos(sala)
    z0 = za - 0.5
  else
    x0, x1, z0, z1 = xa - 0.5, xb + 6.5, za - 0.5, zb + 0.55
    -- salão menor que o original: quem não segue aquela parede precisa caber inteiro dentro
    if r == o then
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

-- Limites da sala no mundo. As paredes das internas não andam no editor; as externas andam inteiras.
function L.sala_mundo(id)
  local b = SALA_DE[id]
  local s = L.tamanho
  if b.interna then
    local _, _, za, zb = L.salao()
    local x = cursor(b)
    return x, x + largura(b), za, math.max(za + SALA_MIN, zb + s[b.k .. "_p"])
  end
  local dx, dz = L.desloc(id)
  local x0, z0 = b.x0 + dx, b.z0 + dz
  return x0, x0 + largura(b), z0, z0 + math.max(SALA_MIN, b.p + s[b.k .. "_p"])
end

-- Os mesmos limites em coordenadas de origem do objeto: passando por L.t caem no mundo
function L.sala(id)
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local dx, dz = L.desloc(id)
  return x0 - dx, x1 - dx, z0 - dz, z1 - dz
end

function L.salas() return INTERNAS, EXTERNAS end

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
        if b.interna then return math.ceil(SALA_MIN - (SALAO_P + s.fundo + s.frente)) end
        return math.ceil(SALA_MIN - b.p)
      end
    end
  end
  return 0
end
L.tamanho_minimo = minimo

function L.mudar_tamanho(lado, delta)
  local s = L.tamanho
  s[lado] = util.limitar((s[lado] or 0) + delta, math.min(minimo(lado), L.TAMANHO_MAX), L.TAMANHO_MAX)
  -- quem foi empurrado tenta voltar ao lugar; o que estava no espaço que sumiu vem para dentro
  for _, o in ipairs(L.OBJETOS) do
    local d = L.dados[o.id]
    if d and d.orig then d.x, d.z, d.orig = d.orig.x, d.orig.z, nil end
  end
  for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
end

-- Alças do editor: uma por lado redimensionável, com x e z no centro da borda, no mundo.
-- Puxar 1 m no sentido de `sinal` equivale a L.mudar_tamanho(chave, 1).
function L.paredes()
  local xa, xb, za, zb = L.salao()
  local cx, cz = (xa + xb) / 2, (za + zb) / 2
  local l = {
    { id = "salao_dir", nome = "Salão: direita", chave = "dir", eixo = "x", sinal = 1, x = xb, z = cz },
    { id = "salao_frente", nome = "Salão: frente", chave = "frente", eixo = "z", sinal = 1, x = cx, z = zb },
    { id = "salao_fundo", nome = "Salão: fundo", chave = "fundo", eixo = "z", sinal = -1, x = cx, z = za },
    { id = "salao_oeste", nome = "Salão: esquerda", chave = "oeste", eixo = "x", sinal = -1, x = xa, z = cz },
  }
  for _, lista in ipairs({ INTERNAS, EXTERNAS }) do
    for _, b in ipairs(lista) do
      if L.aberta(b.id) then
        local x0, x1, z0, z1 = L.sala_mundo(b.id)
        l[#l + 1] = { id = b.id .. "_largura", nome = b.nome .. ": largura", chave = b.k .. "_l", eixo = "x", sinal = 1, x = x1, z = (z0 + z1) / 2 }
        l[#l + 1] = { id = b.id .. "_fundo", nome = b.nome .. ": fundo", chave = b.k .. "_p", eixo = "z", sinal = 1, x = (x0 + x1) / 2, z = z1 }
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
  if type(t._tamanho) == "table" then
    for lado in pairs(L.tamanho) do
      L.tamanho[lado] = util.limitar(math.floor(numero(t._tamanho[lado])), -L.TAMANHO_MAX, L.TAMANHO_MAX)
    end
    -- depois de ler tudo: o mínimo de cada lado depende do lado oposto
    for lado in pairs(L.tamanho) do
      L.tamanho[lado] = math.max(L.tamanho[lado], math.min(minimo(lado), 0))
    end
  end
  migrar(t)
  if type(t._extras) == "table" then
    for _, x in ipairs(t._extras) do
      if type(x) == "table" and L.TIPOS_EXTRAS[x.tipo] then L.adicionar(x.tipo, numero(x.x), numero(x.z), x.id) end
    end
  end
  for id, d in pairs(t) do
    if L.POR_ID[id] and type(d) == "table" then
      L.dados[id] = { x = numero(d.x), z = numero(d.z), y = numero(d.y), g = numero(d.g), oculto = d.oculto == true or nil }
    end
  end
  -- só depois de ler tudo: o limite de um objeto depende de onde está quem o carrega
  for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
end

-- as posições oficiais vêm primeiro; as editadas neste computador têm prioridade
function L.carregar()
  L.limpar_extras()
  L.dados = {}
  L.tamanho = tamanho_zero()
  aplicar_tabela(require("layout_padrao"))
  aplicar_tabela(util.desserializar(motor.layout_carregar()))
end

-- Itens que o jogador acrescenta pelo editor: entram como objetos comuns da lista
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

-- O que a árvore de habilidades constrói não pode ser excluído: só movido
local FIXOS = { mesa = true, balcao = true, fogao = true, cozinheiro = true, bardo = true, barraca = true, estantes = true,
  quadro = true, porta = true, palco = true, jardim = true, cervejaria = true, circulo = true, quartos = true,
  cozinha = true, pomar = true, fazenda = true, celeiro = true }

function L.removivel(id)
  local o = L.POR_ID[id]
  if not o then return false end
  if o.extra then return true end
  -- mesas, árvores e vacas mostram quantas foram compradas
  if id:match("^mesa%d") or id:match("^arvore%d") or id:match("^vaca%d") then return false end
  return not FIXOS[id]
end

function L.oculto(id)
  local d = L.dados[id]
  return d ~= nil and d.oculto == true
end

-- Exclui: item novo some de vez; item original fica escondido e pode voltar
function L.excluir(id)
  if not L.removivel(id) then return false end
  if L.POR_ID[id].extra then tirar_extra(id)
  else L.de(id).oculto = true end
  return true
end

function L.devolver(id)
  if L.dados[id] then L.dados[id].oculto = nil end
end

function L.restaurar(id)
  local padrao = require("layout_padrao")
  if id then
    L.dados[id] = nil
    if padrao[id] then aplicar_tabela({ [id] = padrao[id] }) end
  else
    L.limpar_extras()
    L.dados = {}
    L.tamanho = tamanho_zero()
    aplicar_tabela(padrao)
  end
end

function L.lista_extras()
  local l = {}
  for _, o in ipairs(L.OBJETOS) do
    if o.extra then l[#l + 1] = { id = o.id, tipo = o.extra, x = o.x, z = o.z } end
  end
  return l
end

function L.texto()
  local t = {}
  for id, d in pairs(L.dados) do t[id] = d end
  t._tamanho = L.tamanho
  t._extras = L.lista_extras()
  return util.serializar(t)
end

-- só guarda o que difere das posições oficiais: senão abrir o editor congelaria as de hoje para sempre
function L.salvar()
  local padrao, editado = require("layout_padrao"), {}
  for id, d in pairs(L.dados) do
    local p = padrao[id] or {}
    if d.x ~= (p.x or 0) or d.z ~= (p.z or 0) or d.y ~= (p.y or 0) or d.g ~= (p.g or 0) or d.oculto then editado[id] = d end
  end
  editado._tamanho = L.tamanho
  editado._extras = L.lista_extras()
  motor.layout_salvar(util.serializar(editado))
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
