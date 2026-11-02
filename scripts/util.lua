-- =============================================================================
--  Funções de apoio usadas pelo resto do jogo
-- =============================================================================

local util = {}

-- Paleta de cores do jogo, num lugar só
util.cores = {
  fundo        = "#21150e",
  parede       = "#3a2719",
  parede_clara = "#4a3220",
  piso_a       = "#6b4a2f",
  piso_b       = "#634429",
  madeira      = "#7a4b2a",
  madeira_esc  = "#55331c",
  balcao       = "#8a5a33",
  painel       = "#2c1d13",
  carta        = "#3d291b",
  carta_borda  = "#5c3f29",
  texto        = "#f6ead8",
  texto_fraco  = "#bfa58a",
  ouro         = "#f2c14e",
  ouro_escuro  = "#b8862b",
  verde        = "#7cc56a",
  vermelho     = "#e2604a",
  sombra       = "#00000055",
}

-- 1234 -> "1.234" | 12345 -> "12,3 mil" | 1234567 -> "1,23 mi"
local function separar_milhar(n)
  local s = tostring(math.floor(n))
  local r = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
  return (r:gsub("^%.", ""))
end

local function decimal(n, casas)
  local s = string.format("%." .. casas .. "f", n)
  s = s:gsub("0+$", ""):gsub("%.$", "")
  return (s:gsub("%.", ","))
end

local sufixos = { { 1e15, "qua" }, { 1e12, "tri" }, { 1e9, "bi" }, { 1e6, "mi" }, { 1e4, "mil" } }

function util.formatar(n)
  n = math.floor(n + 0.5)
  for _, s in ipairs(sufixos) do
    local base = s[1] == 1e4 and 1e3 or s[1]
    if n >= s[1] then
      local v = n / base
      local casas = v < 10 and 2 or (v < 100 and 1 or 0)
      return decimal(v, casas) .. " " .. s[2]
    end
  end
  return separar_milhar(n)
end

-- Transforma uma tabela em texto (para salvar) e de volta
function util.serializar(t)
  local partes = {}
  local chaves = {}
  for k in pairs(t) do chaves[#chaves + 1] = k end
  table.sort(chaves, function(a, b) return tostring(a) < tostring(b) end)
  for _, k in ipairs(chaves) do
    local v = t[k]
    local tipo = type(v)
    local valor
    if tipo == "number" then valor = string.format("%.17g", v)
    elseif tipo == "boolean" then valor = tostring(v)
    elseif tipo == "string" then valor = string.format("%q", v)
    elseif tipo == "table" then valor = util.serializar(v)
    end
    if valor then
      partes[#partes + 1] = string.format("[%q] = %s", k, valor)
    end
  end
  return "{\n" .. table.concat(partes, ",\n") .. "\n}"
end

function util.desserializar(texto)
  if not texto then return nil end
  local f = load("return " .. texto, "save", "t", {})   -- ambiente vazio: só dados
  if not f then return nil end
  local ok, dados = pcall(f)
  if ok and type(dados) == "table" then return dados end
  return nil
end

function util.limitar(v, min, max)
  if v < min then return min elseif v > max then return max end
  return v
end

function util.lerp(a, b, t) return a + (b - a) * t end

-- suaviza a saída de uma animação (0..1)
function util.suave(t) return 1 - (1 - t) * (1 - t) end

function util.dentro(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function util.distancia(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

function util.escolher(lista) return lista[math.random(#lista)] end

return util
