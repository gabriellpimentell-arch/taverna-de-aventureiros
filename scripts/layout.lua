-- =============================================================================
--  POSIÇÕES DOS OBJETOS
--  Guarda quanto cada objeto foi movido no modo de edição. Regras (mesas, rotas,
--  colisões) e desenho usam estes dados, então tudo acompanha o que você mover.
-- =============================================================================

local util = require("util")

local L = {}

-- cat: categoria na lista do editor. pai: o objeto acompanha outro objeto ou uma
-- parede ("@fundo", "@oeste", "@leste", "@frente", "@canto") quando a taverna muda de tamanho.
L.CATEGORIAS = { "Tamanho", "Salas", "Móveis", "Balcão", "Paredes", "Decoração", "Áreas", "Jardim", "Cervejaria", "Círculo" }
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
ob("fogao", "Fogão", 0.95, -3.55, "Balcão", "@fundo")
ob("cozinheiro", "Cozinheiro", 0.95, -2.75, "Balcão", "@fundo")
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
ob("cervejaria", "Cervejaria", 3.5, 6.75, "Áreas", "@cerv")
ob("circulo", "Círculo de invocação", 9.25, 6.75, "Áreas", "@canto")

ob("canteiros", "Canteiros", -3.2, 6.3, "Jardim", "jardim")
ob("cerca", "Cerca", -3, 8.55, "Jardim", "jardim")
ob("moita1", "Moita 1", -5.9, 8.05, "Jardim", "jardim")
ob("moita2", "Moita 2", -5.3, 8.1, "Jardim", "jardim")
ob("moita3", "Moita 3", -0.3, 8.05, "Jardim", "jardim")
ob("abobora1", "Abóbora 1", -3.6, 8.1, "Jardim", "jardim")
ob("abobora2", "Abóbora 2", -3.1, 8.0, "Jardim", "jardim")

ob("tina", "Tina de cobre", 1.9, 6.2, "Cervejaria", "cervejaria")
ob("barril_grande", "Barril grande", 3.5, 6.2, "Cervejaria", "cervejaria")
ob("barril_c1", "Barril A", 4.45, 7.6, "Cervejaria", "cervejaria")
ob("barril_c2", "Barril B", 5.17, 7.6, "Cervejaria", "cervejaria")
ob("barril_c3", "Barril C", 5.89, 7.6, "Cervejaria", "cervejaria")
ob("bancada", "Bancada", 2.7, 7.8, "Cervejaria", "cervejaria")
ob("malte1", "Saco de malte 1", 5.5, 5.6, "Cervejaria", "cervejaria")
ob("malte2", "Saco de malte 2", 6.05, 5.75, "Cervejaria", "cervejaria")

ob("pilar1", "Pilar 1", 10.91, 7.99, "Círculo", "circulo")
ob("pilar2", "Pilar 2", 7.59, 7.99, "Círculo", "circulo")
ob("pilar3", "Pilar 3", 7.59, 5.51, "Círculo", "circulo")
ob("pilar4", "Pilar 4", 10.91, 5.51, "Círculo", "circulo")

-- metros acrescentados em cada lado do salão
local function tamanho_zero()
  return { dir = 0, frente = 0, fundo = 0, oeste = 0, jardim_l = 0, jardim_p = 0, cerv_l = 0, cerv_p = 0, circ_l = 0, circ_p = 0 }
end
L.tamanho = tamanho_zero()
L.TAMANHO_MAX = 40

L.dados = {}

local function numero(v)
  return type(v) == "number" and v == v and v > -1000 and v < 1000 and v or 0
end

-- onde o salão termina, já contando o tamanho escolhido
function L.salao()
  local s = L.tamanho
  return -6.5 - s.oeste, 6.5 + s.dir, -4.5 - s.fundo, 4.7 + s.frente
end

local function ancora(pai)
  local s = L.tamanho
  if pai == "@fundo" then return 0, -s.fundo
  elseif pai == "@oeste" then return -s.oeste, 0
  elseif pai == "@leste" then return s.dir, 0
  elseif pai == "@frente" then return -s.oeste, s.frente                         -- jardim
  elseif pai == "@cerv" then return s.jardim_l - s.oeste, s.frente               -- depois do jardim
  elseif pai == "@canto" then return s.jardim_l + s.cerv_l - s.oeste, s.frente   -- depois da cervejaria
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
end

-- nada sai da área do jogo; fora dela ninguém consegue chegar e o objeto some da tela
function L.limitar(id)
  local o, d = L.POR_ID[id], L.dados[id]
  if not d then return end
  local xa, xb, za, zb = L.salao()
  local dx, dz = L.desloc(id)
  local externo = o.cat == "Áreas" or o.cat == "Jardim" or o.cat == "Cervejaria" or o.cat == "Círculo"
  local wx, wz = o.x + dx, o.z + dz
  local x = util.limitar(wx, xa - 0.5, xb + 6.5)
  local z = util.limitar(wz, za - 0.5, zb + (externo and 5.3 or 0.55))
  if x ~= wx or z ~= wz then L.colocar(id, x, z) end
  d.y = util.limitar(d.y, -1, 6)
end

-- limites de cada sala (já com o tamanho escolhido), em coordenadas de origem do objeto
function L.sala(id)
  local s = L.tamanho
  if id == "jardim" then return -6.5, 0.5 + s.jardim_l, 4.8, 8.7 + s.jardim_p end
  if id == "cervejaria" then return 0.5, 6.5 + s.cerv_l, 4.8, 8.7 + s.cerv_p end
  return 6.5, 12 + s.circ_l, 4.8, 8.7 + s.circ_p
end

function L.mudar_tamanho(lado, delta)
  local s = L.tamanho
  s[lado] = util.limitar((s[lado] or 0) + delta, 0, L.TAMANHO_MAX)
  -- encolheu: o que estava no espaço que sumiu volta para dentro
  for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
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
      L.tamanho[lado] = util.limitar(math.floor(numero(t._tamanho[lado])), 0, L.TAMANHO_MAX)
    end
  end
  migrar(t)
  for id, d in pairs(t) do
    if L.POR_ID[id] and type(d) == "table" then
      L.dados[id] = { x = numero(d.x), z = numero(d.z), y = numero(d.y), g = numero(d.g) }
    end
  end
  -- só depois de ler tudo: o limite de um objeto depende de onde está quem o carrega
  for _, o in ipairs(L.OBJETOS) do L.limitar(o.id) end
end

-- as posições oficiais vêm primeiro; as editadas neste computador têm prioridade
function L.carregar()
  L.dados = {}
  L.tamanho = tamanho_zero()
  aplicar_tabela(require("layout_padrao"))
  aplicar_tabela(util.desserializar(motor.layout_carregar()))
end

function L.restaurar(id)
  local padrao = require("layout_padrao")
  if id then
    L.dados[id] = nil
    if padrao[id] then aplicar_tabela({ [id] = padrao[id] }) end
  else
    L.dados = {}
    L.tamanho = tamanho_zero()
    aplicar_tabela(padrao)
  end
end

function L.texto()
  local t = {}
  for id, d in pairs(L.dados) do t[id] = d end
  t._tamanho = L.tamanho
  return util.serializar(t)
end

-- só guarda o que difere das posições oficiais: senão abrir o editor congelaria as de hoje para sempre
function L.salvar()
  local padrao, editado = require("layout_padrao"), {}
  for id, d in pairs(L.dados) do
    local p = padrao[id] or {}
    if d.x ~= (p.x or 0) or d.z ~= (p.z or 0) or d.y ~= (p.y or 0) or d.g ~= (p.g or 0) then editado[id] = d end
  end
  editado._tamanho = L.tamanho
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
