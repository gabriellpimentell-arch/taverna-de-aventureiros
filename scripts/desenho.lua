-- =============================================================================
--  Desenho do salão: parede, piso, mesas, heróis e garçonete
--  (tudo feito com formas simples por enquanto; depois trocamos por imagens)
-- =============================================================================

local taverna = require("taverna")
local config = require("config")
local util = require("util")
local cor = util.cores

local D = {}

local TOPO_SALAO, FIM_SALAO = 0, 540
local FIM_PAREDE = 98
local L = taverna.LARGURA_SALAO

-- Ícones pequenos (usados nos balões e nas cartas de melhoria) -----------------

function D.caneca(x, y, e)
  e = e or 1
  motor.retangulo(x - 10 * e, y - 9 * e, 18 * e, 22 * e, "#e8a33d", 3 * e)
  motor.contorno(x + 5 * e, y - 5 * e, 10 * e, 12 * e, "#c98a2c", 3 * e, 4 * e)
  motor.retangulo(x - 11 * e, y - 14 * e, 20 * e, 8 * e, "#fff8ec", 4 * e)
  motor.circulo(x - 6 * e, y - 13 * e, 4 * e, "#fff8ec")
end

function D.coxa(x, y, e)
  e = e or 1
  motor.linha(x + 2 * e, y + 2 * e, x + 12 * e, y + 12 * e, 5 * e, "#f3e9d2")
  motor.circulo(x + 13 * e, y + 10 * e, 3.5 * e, "#f3e9d2")
  motor.circulo(x + 10 * e, y + 13 * e, 3.5 * e, "#f3e9d2")
  motor.circulo(x - 3 * e, y - 3 * e, 11 * e, "#b8642e")
  motor.circulo(x - 6 * e, y - 7 * e, 4 * e, "#d68a4f")
end

function D.moeda(x, y, r)
  motor.circulo(x, y, r, cor.ouro_escuro)
  motor.circulo(x, y, r * 0.78, cor.ouro)
  motor.retangulo(x - r * 0.12, y - r * 0.45, r * 0.24, r * 0.9, cor.ouro_escuro, r * 0.1)
end

-- Cenário --------------------------------------------------------------------------

local function parede()
  motor.retangulo(0, TOPO_SALAO, L, FIM_PAREDE - TOPO_SALAO, cor.parede)
  for x = 30, L, 60 do
    motor.linha(x, TOPO_SALAO, x, FIM_PAREDE, 2, "#00000022")
  end

  -- barris à esquerda
  for _, bx in ipairs({ 22, 70 }) do
    motor.retangulo(bx, 40, 40, 54, "#7b4a26", 10)
    motor.retangulo(bx, 52, 40, 4, "#3b2414")
    motor.retangulo(bx, 78, 40, 4, "#3b2414")
  end

  -- quadro de missões (ainda fechado: próxima etapa do jogo)
  local qx = 238
  motor.retangulo(qx, 14, 124, 70, "#5b3a22", 6)
  motor.retangulo(qx + 6, 20, 112, 58, "#9c7448", 4)
  motor.opacidade(0.55)
  motor.retangulo(qx + 16, 28, 26, 30, "#efe2c4", 2)
  motor.retangulo(qx + 50, 34, 26, 30, "#efe2c4", 2)
  motor.retangulo(qx + 84, 26, 26, 30, "#efe2c4", 2)
  motor.opacidade(1)
  motor.retangulo(qx + 12, 60, 100, 16, "#2c1d13cc", 4)
  motor.texto("em breve", qx + 62, 60, 12, cor.texto_fraco, "centro")

  -- prateleira com garrafas
  motor.retangulo(400, 24, 180, 6, "#5b3a22", 2)
  local garrafas = { "#4f8a3c", "#8a3c3c", "#3c5f8a", "#c9a24a", "#7a4a8a", "#4f8a3c" }
  for i, c in ipairs(garrafas) do
    local gx = 410 + (i - 1) * 28
    motor.retangulo(gx, 8, 12, 16, c, 3)
    motor.retangulo(gx + 3, 2, 6, 8, c, 2)
  end

  -- balcão
  motor.retangulo(390, 58, L - 390, 40, cor.balcao)
  motor.retangulo(390, 54, L - 390, 8, "#a8713f", 3)
end

local function piso()
  local i = 0
  for y = FIM_PAREDE, FIM_SALAO, 34 do
    motor.retangulo(0, y, L, 34, (i % 2 == 0) and cor.piso_a or cor.piso_b)
    local desloc = (i % 2 == 0) and 0 or 45
    for x = desloc, L, 90 do
      motor.linha(x, y, x, y + 34, 1.5, "#00000020")
    end
    i = i + 1
  end
  motor.retangulo(0, FIM_PAREDE, L, 6, "#00000030")

  -- porta
  local p = taverna.PORTA
  motor.retangulo(p.x - 38, FIM_SALAO - 46, 76, 46, "#3b2414", 10)
  motor.retangulo(p.x - 32, FIM_SALAO - 40, 64, 40, "#1a0f08", 8)
end

local function mesa(x, y, fantasma)
  if fantasma then
    motor.opacidade(0.22)
    motor.elipse(x, y, 44, 24, cor.madeira_esc)
    motor.opacidade(0.45)
    motor.texto("+", x, y - 14, 28, cor.texto_fraco, "centro", true)
    motor.opacidade(1)
    return
  end
  motor.elipse(x, y + 7, 46, 25, "#00000040")
  motor.elipse(x, y + 4, 44, 25, cor.madeira_esc)
  motor.elipse(x, y, 44, 23, cor.madeira)
  motor.elipse(x - 8, y - 5, 24, 9, "#ffffff10")
end

local function banquinho(x, y)
  motor.elipse(x, y + 18, 15, 7, "#00000040")
  motor.elipse(x, y + 14, 15, 8, cor.madeira_esc)
end

-- Personagens --------------------------------------------------------------------------

local function balao(h)
  local bx = h.x
  local by = h.y - 96 + math.sin(h.t * 4 + h.fase) * 2
  motor.retangulo(bx - 27, by - 27, 54, 54, "#00000033", 13)
  motor.retangulo(bx - 26, by - 28, 52, 52, "#fff6e6", 12)
  motor.triangulo(bx - 8, by + 22, bx + 8, by + 22, bx, by + 34, "#fff6e6")
  if h.pedido == "bebida" then D.caneca(bx, by - 4, 1) else D.coxa(bx, by - 4, 1) end

  -- barra de paciência
  local resta = util.limitar(1 - h.t / config.paciencia, 0, 1)
  local c = resta > 0.5 and cor.verde or (resta > 0.25 and "#e8b13d" or cor.vermelho)
  motor.retangulo(bx - 18, by + 14, 36, 5, "#00000026", 2)
  motor.retangulo(bx - 18, by + 14, 36 * resta, 5, c, 2)
end

local function heroi(h)
  local x, y = h.x, h.y
  if h.estado == "chegando" or h.estado == "saindo" then
    y = y - math.abs(math.sin(h.t * 12)) * 5
  elseif h.estado == "comendo" then
    y = y + math.sin(h.t * 7) * 1.5
  end
  local classe = h.classe

  motor.elipse(h.x, h.y + 22, 17, 6, "#00000040")
  if classe.nome == "arqueiro" then motor.circulo(x, y - 31, 17, classe.detalhe) end
  motor.retangulo(x - 15, y - 14, 30, 34, classe.corpo, 10)
  if classe.nome == "clerigo" then
    motor.retangulo(x - 2, y - 8, 4, 16, classe.detalhe)
    motor.retangulo(x - 7, y - 4, 14, 4, classe.detalhe)
  elseif classe.nome == "guerreiro" then
    motor.retangulo(x - 15, y + 4, 30, 5, "#5b3a22")
  end
  motor.circulo(x, y - 30, 13, h.pele)

  if classe.nome == "guerreiro" then
    motor.retangulo(x - 14, y - 46, 28, 13, classe.detalhe, 6)
    motor.retangulo(x - 2, y - 52, 4, 8, cor.vermelho, 2)
  elseif classe.nome == "maga" then
    motor.triangulo(x - 13, y - 40, x + 13, y - 40, x + 5, y - 70, classe.detalhe)
    motor.retangulo(x - 18, y - 43, 36, 6, classe.detalhe, 3)
  elseif classe.nome == "arqueiro" then
    motor.retangulo(x - 14, y - 46, 28, 10, classe.detalhe, 5)
  elseif classe.nome == "clerigo" then
    motor.anel(x, y - 50, 8, 10.5, classe.detalhe)
  end

  -- rosto
  local olho = "#2a1a10"
  if h.estado == "comendo" then
    motor.linha(x - 8, y - 31, x - 3, y - 31, 2, olho)
    motor.linha(x + 3, y - 31, x + 8, y - 31, 2, olho)
  else
    motor.circulo(x - 5, y - 31, 2.2, olho)
    motor.circulo(x + 5, y - 31, 2.2, olho)
  end
  if h.irritado then
    motor.linha(x - 9, y - 38, x - 3, y - 35, 2, olho)
    motor.linha(x + 9, y - 38, x + 3, y - 35, 2, olho)
  end

  -- o que está consumindo
  if h.estado == "comendo" then
    local lado = -h.lado   -- segura o pedido do lado da mesa
    if h.pedido == "bebida" then D.caneca(x + lado * 22, y + 2, 0.55)
    else D.coxa(x + lado * 22, y + 2, 0.55) end
  end
end

local function garconete(g)
  local x, y = g.x, g.y
  if g.estado ~= "parada" then y = y - math.abs(math.sin(motor.tempo() * 13)) * 4 end
  motor.elipse(g.x, g.y + 22, 17, 6, "#00000040")
  motor.circulo(x, y - 33, 15, "#6b3a1e")                    -- cabelo
  motor.circulo(x, y - 48, 7, "#6b3a1e")                     -- coque
  motor.retangulo(x - 15, y - 14, 30, 34, "#2f7a8a", 10)     -- vestido
  motor.retangulo(x - 10, y - 6, 20, 24, "#f4ece0", 6)       -- avental
  motor.circulo(x, y - 30, 13, "#f1c9a5")
  motor.circulo(x - 5, y - 31, 2.2, "#2a1a10")
  motor.circulo(x + 5, y - 31, 2.2, "#2a1a10")
  if g.estado == "indo" then
    motor.elipse(x + 18, y - 16, 16, 5, "#c0c4c8")
    D.caneca(x + 18, y - 28, 0.5)
  end
end

-- Tudo junto -----------------------------------------------------------------------------

function D.salao()
  motor.retangulo(0, 0, L, FIM_SALAO, cor.fundo)
  parede()
  piso()

  local n = taverna.num_mesas()
  for i = 1, n * 2 do
    local sx, sy = taverna.assento(i)
    banquinho(sx, sy)
  end
  for i = 1, taverna.MAX_MESAS do
    local m = taverna.posicao_mesa(i)
    if i <= n then mesa(m.x, m.y) elseif i == n + 1 then mesa(m.x, m.y, true) end
  end

  -- desenha de cima para baixo, para quem está mais à frente cobrir quem está atrás
  local pessoas = {}
  for _, h in ipairs(taverna.herois) do pessoas[#pessoas + 1] = h end
  if taverna.garconete then pessoas[#pessoas + 1] = taverna.garconete end
  table.sort(pessoas, function(a, b) return a.y < b.y end)
  for _, p in ipairs(pessoas) do
    if p == taverna.garconete then garconete(p) else heroi(p) end
  end
  -- balões por cima de todo mundo
  for _, h in ipairs(taverna.herois) do
    if h.estado == "esperando" then balao(h) end
  end
end

return D
