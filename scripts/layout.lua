-- =============================================================================
--  POSIÇÕES DOS OBJETOS
--  Guarda quanto cada objeto foi movido no modo de edição. Regras (mesas, rotas,
--  colisões) e desenho usam estes dados, então tudo acompanha o que você mover.
-- =============================================================================

local util = require("util")

local L = {}

L.OBJETOS = {
  { id = "mesa1", nome = "Mesa 1", x = -3.6, z = 0.2 },
  { id = "mesa2", nome = "Mesa 2", x = 0.3, z = 0.2 },
  { id = "mesa3", nome = "Mesa 3", x = 4.2, z = 0.2 },
  { id = "mesa4", nome = "Mesa 4", x = -3.6, z = 3.4 },
  { id = "mesa5", nome = "Mesa 5", x = 0.3, z = 3.4 },
  { id = "mesa6", nome = "Mesa 6", x = 4.2, z = 3.4 },
  { id = "mesa7", nome = "Mesa 7", x = 8.0, z = 3.4 },
  { id = "mesa8", nome = "Mesa 8", x = 10.7, z = 3.4 },
  { id = "balcao", nome = "Balcão e bancos", x = 3.05, z = -2.2 },
  { id = "garrafas", nome = "Prateleira de garrafas", x = 3.05, z = -4.3 },
  { id = "fogao", nome = "Fogão", x = 0.95, z = -3.55 },
  { id = "cozinheiro", nome = "Cozinheiro", x = 0.95, z = -2.75 },
  { id = "lareira", nome = "Lareira", x = -6.1, z = -3.2 },
  { id = "lenha", nome = "Lenha", x = -6.05, z = -1.95 },
  { id = "quadro", nome = "Quadro de missões", x = -2.6, z = -4.4 },
  { id = "porta", nome = "Porta", x = -6.4, z = 1.6 },
  { id = "bardo", nome = "Bardo", x = -5.1, z = -1.25 },
  { id = "barris_fundo", nome = "Barris do fundo", x = 5.2, z = -3.5 },
  { id = "barris_frente", nome = "Barris da frente", x = -5.2, z = 4.0 },
  { id = "carga", nome = "Caixote", x = 5.85, z = 4.1 },
  { id = "tapete1", nome = "Tapete do fundo", x = -3.6, z = 0.3 },
  { id = "tapete2", nome = "Tapete da frente", x = 0.3, z = 3.4 },
  { id = "quartos", nome = "Escada dos quartos", x = -4.6, z = -3.9 },
  { id = "barraca", nome = "Mercadinho", x = 9.3, z = -2.2 },
  { id = "carga_leste", nome = "Caixote da ala leste", x = 11.5, z = -0.4 },
  { id = "jardim", nome = "Jardim", x = -3, z = 6.75 },
  { id = "cervejaria", nome = "Cervejaria", x = 3.5, z = 6.75 },
  { id = "circulo", nome = "Círculo de invocação", x = 9.25, z = 6.75 },
}
L.POR_ID = {}
for _, o in ipairs(L.OBJETOS) do L.POR_ID[o.id] = o end

L.dados = {}

local function numero(v)
  return type(v) == "number" and v == v and v > -1000 and v < 1000 and v or 0
end

local function aplicar_tabela(t)
  if type(t) ~= "table" then return end
  for id, d in pairs(t) do
    if L.POR_ID[id] and type(d) == "table" then
      L.dados[id] = { x = numero(d.x), z = numero(d.z), y = numero(d.y), g = numero(d.g) }
    end
  end
end

-- as posições oficiais vêm primeiro; as editadas neste computador têm prioridade
function L.carregar()
  L.dados = {}
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
    aplicar_tabela(padrao)
  end
end

function L.texto() return util.serializar(L.dados) end
function L.salvar() motor.layout_salvar(L.texto()) end

function L.de(id)
  local d = L.dados[id]
  if not d then
    d = { x = 0, z = 0, y = 0, g = 0 }
    L.dados[id] = d
  end
  return d
end

-- posição base -> posição no mundo, girando em volta do centro do objeto
function L.t(id, x, z)
  local o, d = L.POR_ID[id], L.dados[id]
  if not d then return x, z end
  local co, si = math.cos(d.g), math.sin(d.g)
  local rx, rz = x - o.x, z - o.z
  return o.x + d.x + rx * co + rz * si, o.z + d.z - rx * si + rz * co
end

function L.giro(id)
  local d = L.dados[id]
  return d and d.g or 0
end

-- ponto do mundo -> posição base (usado nas colisões com caixas giradas)
function L.base(id, x, z)
  local o, d = L.POR_ID[id], L.dados[id]
  if not d then return x, z end
  local co, si = math.cos(d.g), math.sin(d.g)
  local rx, rz = x - o.x - d.x, z - o.z - d.z
  return o.x + rx * co - rz * si, o.z + rx * si + rz * co
end

return L
