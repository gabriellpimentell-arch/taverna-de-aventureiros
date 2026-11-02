-- =============================================================================
--  PROTÓTIPO 3D LOW POLY
--
--  Só para avaliar o visual: não usa as regras do jogo nem grava o progresso.
--  Unidades: 1 = cerca de 1 metro. x vai para a direita, z vem para a câmera.
-- =============================================================================

local desenho = require("desenho")
local util = require("util")
local cor = util.cores
local TEXTO_OURO = "#3a2410"

local P = {}

local peca = motor.peca

-- Formas com base no chão, para facilitar empilhar ---------------------------------

local function caixa(x, y, z, ex, ey, ez, c, giro) peca("caixa", x, y + ey / 2, z, ex, ey, ez, giro or 0, c) end
local function cilindro(x, y, z, d, a, c) peca("cilindro", x, y, z, d, a, d, 0, c) end
local function cone(x, y, z, d, a, c) peca("cone", x, y, z, d, a, d, 0, c) end
local function esfera(x, y, z, d, c, ey) peca("esfera", x, y, z, d, ey or d, d, 0, c) end

-- Cenário ----------------------------------------------------------------------------

local MESAS = {
  { x = -3.3, z = -0.7 }, { x = 0.9, z = -0.7 },
  { x = -3.3, z = 2.9 }, { x = 0.9, z = 2.9 },
}
local MESAS_NOVAS = { { x = 8.0, z = 2.9 } }
local RUA_Z = 1.1          -- corredor por onde todo mundo anda
local PORTA = { x = -6.4, z = 1.1 }
local BANCOS_BALCAO = { 1.4, 2.5, 3.6, 4.7 }

local function piso(x0, x1, z0, z1, a, b, escala)
  local e = escala or 1
  local i = 0
  local z = z0
  while z < z1 - 0.01 do
    local largura = math.min(0.8, z1 - z)
    caixa((x0 + x1) / 2, -0.3, z + largura / 2, x1 - x0, 0.3 * e, largura - 0.03, i % 2 == 0 and a or b)
    z = z + 0.8
    i = i + 1
  end
end

local function mesa(x, z)
  cilindro(x, 0, z, 0.26, 0.72, "#4a2c17")
  cilindro(x, 0, z, 0.8, 0.07, "#3f2614")
  peca("cilindro", x, 0.70, z, 1.75, 0.12, 1.75, 0, "#9a6235")
end

local function banquinho(x, z)
  cilindro(x, 0, z, 0.16, 0.38, "#3f2614")
  cilindro(x, 0.36, z, 0.54, 0.09, "#7c4d29")
end

local function barril(x, z, a)
  a = a or 1
  cilindro(x, 0, z, 0.82, 1.05 * a, "#7b4a26")
  cilindro(x, 0.2 * a, z, 0.86, 0.08, "#2f2319")
  cilindro(x, 0.78 * a, z, 0.86, 0.08, "#2f2319")
end

local function salao(tempo)
  -- chão e paredes (só o fundo e a esquerda, para ver lá dentro)
  piso(-6.5, 6.5, -4.5, 4.7, "#7a5433", "#6f4b2c")
  caixa(0, -0.95, 0.1, 13.6, 0.65, 9.9, "#2a1b12")

  caixa(0, 0, -4.7, 13.4, 4.2, 0.4, "#4f3522")
  caixa(-6.7, 0, 0.05, 0.4, 4.2, 9.9, "#47301f")
  caixa(0, 0, -4.48, 13, 0.75, 0.08, "#2f1e13")   -- rodapé escuro

  -- vigas
  for x = -6, 6, 3 do caixa(x, 0, -4.45, 0.26, 4.2, 0.2, "#2d1c11") end
  for z = -3, 4.5, 2.5 do caixa(-6.45, 0, z, 0.2, 4.2, 0.26, "#2d1c11") end
  caixa(0, 3.75, -4.42, 13, 0.26, 0.2, "#2d1c11")

  -- porta na parede da esquerda
  caixa(-6.47, 0, PORTA.z, 0.12, 2.5, 1.5, "#20140c")
  caixa(-6.42, 2.5, PORTA.z, 0.24, 0.2, 1.8, "#2d1c11")

  -- lareira
  local lx, lz = -6.1, -3.2
  caixa(lx, 0, lz, 0.9, 2.5, 2.2, "#62605c")
  caixa(lx + 0.34, 0, lz, 0.3, 1.2, 1.3, "#201a18")
  caixa(lx + 0.5, 2.45, lz, 0.9, 0.18, 2.5, "#3d2616")
  local f = 1 + math.sin(tempo * 9) * 0.1 + math.sin(tempo * 23) * 0.06
  peca("cone", lx + 0.52, 0.05, lz - 0.28, 0.5, 0.62 * f, 0.5, 0, "#ff7a24", 0, 0, 1.2)
  peca("cone", lx + 0.52, 0.05, lz + 0.28, 0.46, 0.5 / f, 0.46, 0, "#ff9a30", 0, 0, 1.2)
  peca("cone", lx + 0.56, 0.05, lz, 0.42, 0.8 * f, 0.42, 0, "#ffc04a", 0, 0, 1.3)

  -- quadro de missões
  local qx = -2.6
  caixa(qx, 1.45, -4.42, 2.6, 1.7, 0.1, "#5a3a20")
  caixa(qx, 1.55, -4.36, 2.3, 1.5, 0.05, "#a87e4f")
  for i, p in ipairs({ { -0.8, 1.95 }, { -0.1, 1.72 }, { 0.72, 2.08 }, { 0.28, 2.28 } }) do
    caixa(qx + p[1], p[2], -4.32, 0.52, 0.66, 0.02, "#f0e4c8", (i - 2) * 0.0)
  end

  -- balcão e prateleira
  local bx, bz = 3.05, -2.2
  caixa(bx, 0, bz, 5.2, 1.05, 0.72, "#6f4326")
  caixa(bx, 1.05, bz, 5.5, 0.12, 0.95, "#a5703f")
  caixa(bx, 2.1, -4.32, 5.4, 0.1, 0.5, "#4a2c17")
  caixa(bx, 1.25, -4.32, 5.4, 0.1, 0.5, "#4a2c17")
  local garrafas = { "#3f8d4f", "#a13b3b", "#3c68a8", "#d0a23e", "#7a4a9c", "#3f8d4f", "#a13b3b", "#d0a23e" }
  for i, c in ipairs(garrafas) do
    local gx = bx - 2.4 + (i - 1) * 0.68
    local y = i % 2 == 0 and 2.2 or 1.35
    cilindro(gx, y, -4.3, 0.24, 0.42, c)
    cilindro(gx, y + 0.42, -4.3, 0.1, 0.2, c)
  end

  -- barris
  barril(5.6, -3.7); barril(4.75, -3.8); barril(5.75, -2.9, 0.9)
  barril(-5.6, 3.9, 0.9); barril(-4.8, 4.1, 0.8)

  -- mesas e banquinhos
  for _, m in ipairs(MESAS) do
    mesa(m.x, m.z)
    banquinho(m.x - 1.25, m.z)
    banquinho(m.x + 1.25, m.z)
  end
  for _, x in ipairs(BANCOS_BALCAO) do banquinho(x, -1.42) end

  -- lampiões na parede
  for _, lx2 in ipairs({ -4.5, -0.6 }) do
    caixa(lx2, 2.6, -4.4, 0.08, 0.08, 0.3, "#1d130c")
    peca("esfera", lx2, 2.48, -4.2, 0.24, 0.32, 0.24, 0, "#ffd26a", 0, 0, 1.6)
  end
end

-- a ala nova nasce do chão, peça por peça
local function nova_ala(e, tempo)
  if e <= 0 then return end
  local s = util.limitar(e, 0, 1)
  local o = s + math.sin(s * math.pi) * 0.12
  local function c2(x, y, z, ex, ey, ez, c) caixa(x, y * o, z, ex, ey * o, ez, c) end

  piso(6.5, 12, -4.5, 4.7, "#8a6b43", "#7f613a", o)
  c2(9.25, 0, -4.7, 5.5, 4.2, 0.4, "#4f3522")
  caixa(9.25, -0.95, 0.1, 5.7, 0.65, 9.9, "#2a1b12")
  for x = 7.5, 12, 3 do c2(x, 0, -4.45, 0.26, 4.2, 0.2, "#2d1c11") end

  -- barraca do mercadinho
  local mx, mz = 9.3, -2.2
  for _, d in ipairs({ { -2.1, -0.65 }, { 2.1, -0.65 }, { -2.1, 0.7 }, { 2.1, 0.7 } }) do
    c2(mx + d[1], 0, mz + d[2], 0.18, 2.5, 0.18, "#4a2c17")
  end
  c2(mx, 0, mz + 0.4, 4.2, 0.95, 0.8, "#8a5a33")
  c2(mx, 0.95, mz + 0.4, 4.4, 0.1, 0.95, "#b98a55")
  for i = 0, 5 do
    local listra = i % 2 == 0 and "#b5403a" or "#efe2c4"
    c2(mx - 1.95 + i * 0.78, 2.5, mz, 0.8, 0.14, 1.9, listra)
  end
  -- mercadorias: espada, escudo, poções e arca
  if s > 0.45 then
    local v = (s - 0.45) / 0.55
    peca("caixa", mx - 1.3, 1.45 * v, mz + 0.4, 0.09, 0.8 * v, 0.2, 0, "#c7d0d8", 0, 0.5)
    peca("cilindro", mx - 0.3, 1.25, mz + 0.42, 0.72 * v, 0.1, 0.72 * v, 0, "#a13b3b", 1.3)
    cilindro(mx + 0.6, 1.05, mz + 0.4, 0.24 * v, 0.34 * v, "#5abf7c")
    cilindro(mx + 1.0, 1.05, mz + 0.35, 0.24 * v, 0.34 * v, "#6d8fe0")
    caixa(mx + 1.55, 1.05, mz + 0.35, 0.56 * v, 0.34 * v, 0.42 * v, "#c9a24a")
  end

  for _, m in ipairs(MESAS_NOVAS) do
    if s > 0.6 then
      mesa(m.x, m.z)
      banquinho(m.x - 1.25, m.z)
      banquinho(m.x + 1.25, m.z)
    end
  end
end

-- Personagens --------------------------------------------------------------------------

local TIPOS = {
  { nome = "comum",     corpo = "#b58a5a", perna = "#4b3b2c", braco = "#a57a4e" },
  { nome = "comum",     corpo = "#6f8f6a", perna = "#3e3a2e", braco = "#607f5b" },
  { nome = "comum",     corpo = "#b76f62", perna = "#3f3734", braco = "#a7625a" },
  { nome = "guerreiro", corpo = "#a8b4bf", perna = "#4d5560", braco = "#8e99a4" },
  { nome = "guerreiro", corpo = "#a8b4bf", perna = "#6d3f2a", braco = "#b5483a" },
  { nome = "mago",      corpo = "#6d4bb3", perna = "#4a2f86", braco = "#5e3fa0" },
  { nome = "mago",      corpo = "#3e6db3", perna = "#27487f", braco = "#355f9e" },
  { nome = "arqueiro",  corpo = "#4f8a3c", perna = "#4b3b2c", braco = "#437531" },
  { nome = "clerigo",   corpo = "#eadfca", perna = "#c9b98f", braco = "#ddd0b6" },
}
local PELES = { "#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a36" }

-- monta o boneco girando as peças em volta dele
local function boneco(b)
  local co, si = math.cos(b.giro), math.sin(b.giro)
  local function W(lx, lz) return b.x + lx * co + lz * si, b.z - lx * si + lz * co end
  local function p(f, lx, ly, lz, ex, ey, ez, c, rx, rz)
    local x, z = W(lx, lz)
    peca(f, x, b.y + ly, z, ex, ey, ez, b.giro, c, rx or 0, rz or 0)
  end

  local t = b.tipo
  local passo = b.andando and math.sin(b.fase * 10) or 0
  local pulo = b.andando and math.abs(passo) * 0.07 or 0
  local y0 = pulo
  local pernas = b.sentado and 0 or 0.3

  -- pernas
  if not b.sentado then
    p("caixa", -0.13, y0 + 0.15, passo * 0.14, 0.17, 0.32, 0.2, t.perna)
    p("caixa", 0.13, y0 + 0.15, -passo * 0.14, 0.17, 0.32, 0.2, t.perna)
  else
    p("caixa", -0.13, y0 + 0.08, 0.14, 0.17, 0.16, 0.42, t.perna)
    p("caixa", 0.13, y0 + 0.08, 0.14, 0.17, 0.16, 0.42, t.perna)
  end

  -- corpo
  local inclina = b.bebendo and -0.12 or 0
  local topo = pernas + 0.62
  if t.nome == "mago" then
    p("cone", 0, y0 + pernas - 0.26, 0, 0.74, 1.1, 0.74, t.corpo)
    topo = pernas + 0.56
  elseif t.nome == "clerigo" then
    p("cilindro", 0, y0 + pernas - 0.28, 0, 0.56, 0.9, 0.56, t.corpo)
    p("caixa", 0, y0 + pernas + 0.32, 0.27, 0.07, 0.34, 0.03, "#d4a83e")
    p("caixa", 0, y0 + pernas + 0.36, 0.27, 0.22, 0.07, 0.03, "#d4a83e")
  else
    p("cilindro", 0, y0 + pernas, 0, 0.56, 0.62, 0.48, t.corpo, inclina)
  end
  if t.nome == "guerreiro" then
    p("caixa", 0, y0 + pernas + 0.33, 0.13, 0.48, 0.46, 0.24, "#c5cfd8", inclina)  -- peitoral
    p("cilindro", 0, y0 + pernas + 0.02, 0, 0.6, 0.09, 0.52, "#4a2c17")             -- cinto
  elseif t.nome == "arqueiro" then
    p("cilindro", 0, y0 + pernas + 0.02, 0, 0.6, 0.08, 0.52, "#5b3a22")
    p("caixa", 0.26, y0 + pernas + 0.3, -0.27, 0.15, 0.6, 0.15, "#7b4a26", 0, -0.3) -- aljava
  end

  -- braços
  local bs = b.andando and passo * 0.55 or 0
  local bracoY = topo - 0.06
  if t.nome == "mago" then bracoY = pernas + 0.45 end
  p("caixa", -0.36, y0 + bracoY - 0.2, -bs * 0.28, 0.14, 0.44, 0.15, t.braco, bs)
  if b.bebendo then
    p("caixa", 0.3, y0 + bracoY + 0.02, 0.2, 0.14, 0.15, 0.44, t.braco)
    p("cilindro", 0.3, y0 + bracoY + 0.0, 0.48, 0.22, 0.26, 0.22, "#e8a33d")
    p("cilindro", 0.3, y0 + bracoY + 0.25, 0.48, 0.24, 0.07, 0.24, "#fff4dd")
  else
    p("caixa", 0.36, y0 + bracoY - 0.2, bs * 0.28, 0.14, 0.44, 0.15, t.braco, -bs)
  end

  -- cabeça lisa, sem rosto
  local cy = topo + 0.25
  p("esfera", 0, y0 + cy, 0, 0.52, 0.52, 0.52, b.pele)

  if t.nome == "guerreiro" then
    p("cilindro", 0, y0 + cy + 0.02, 0, 0.58, 0.28, 0.58, "#8e99a4")
    p("caixa", 0, y0 + cy + 0.32, 0, 0.07, 0.2, 0.26, "#b5403a")
  elseif t.nome == "mago" then
    p("cilindro", 0, y0 + cy + 0.13, 0, 0.86, 0.05, 0.86, t.perna)
    p("cone", 0, y0 + cy + 0.16, 0, 0.5, 0.72, 0.5, t.perna, -0.1)
  elseif t.nome == "arqueiro" then
    p("esfera", 0, y0 + cy + 0.05, -0.05, 0.6, 0.56, 0.6, "#3b6b2c")
    p("esfera", 0, y0 + cy, 0.12, 0.47, 0.42, 0.42, b.pele)
  elseif t.nome == "clerigo" then
    p("cilindro", 0, y0 + cy + 0.38, 0, 0.42, 0.04, 0.42, "#f2c14e")
  elseif b.chapeu then
    p("cilindro", 0, y0 + cy + 0.16, 0, 0.56, 0.16, 0.56, b.chapeu)
  end
end

local function garconete(g)
  local b = { x = g.x, y = 0, z = g.z, giro = g.giro, fase = g.fase, andando = g.andando, pele = "#f1c9a5",
    tipo = { nome = "comum", corpo = "#2f7a8a", perna = "#23303a", braco = "#2a6d7c" } }
  boneco(b)
  local co, si = math.cos(g.giro), math.sin(g.giro)
  local ax, az = g.x + 0.42 * co + 0.2 * si, g.z - 0.42 * si + 0.2 * co
  caixa(g.x - 0.1 * si, 0.47, g.z - 0.1 * co, 0.5, 0.44, 0.04, "#f4ece0", g.giro)
  peca("cilindro", ax, 1.0, az, 0.56, 0.04, 0.56, 0, "#c0c4c8")
  if g.levando then
    cilindro(ax, 1.03, az, 0.2, 0.24, "#e8a33d")
    cilindro(ax, 1.25, az, 0.22, 0.06, "#fff4dd")
  end
end

-- Simulação simples -------------------------------------------------------------------

local function novos_lugares()
  local l = {}
  for _, m in ipairs(MESAS) do
    l[#l + 1] = { x = m.x - 1.25, z = m.z, giro = math.pi / 2, y = 0.42 }
    l[#l + 1] = { x = m.x + 1.25, z = m.z, giro = -math.pi / 2, y = 0.42 }
  end
  for _, x in ipairs(BANCOS_BALCAO) do
    l[#l + 1] = { x = x, z = -1.42, giro = math.pi, y = 0.42 }
  end
  return l
end

local function novo_cliente(lugar)
  local t = util.escolher(TIPOS)
  local chapeus = { "#6b4a2f", "#3e5a4b", false, "#7a3a3a" }
  local c = {
    x = PORTA.x, y = 0, z = PORTA.z, giro = math.pi / 2,
    tipo = t, pele = util.escolher(PELES), chapeu = t.nome == "comum" and util.escolher(chapeus) or nil,
    fase = math.random() * 6, lugar = lugar, estado = "entrando", t = 0,
    pedido = math.random() < 0.5 and "bebida" or "comida",
  }
  c.rota = { { x = PORTA.x + 1.2, z = RUA_Z }, { x = lugar.x, z = RUA_Z }, { x = lugar.x, z = lugar.z } }
  c.andando = true
  return c
end

function P.iniciar()
  P.lugares = novos_lugares()
  P.clientes = {}
  P.vagantes = {}
  P.ouro = 0
  P.ouro_visivel = 0
  P.tempo = 0
  P.chegada = 0
  P.expansao = 0
  P.expandindo = false
  P.efeitos = {}
  P.cam = 0
  P.g = { x = 3, z = -1.0, giro = 0, fase = 0, estado = "parada", recarga = 3 }
  -- a taverna já abre com gente
  for i = 1, 7 do
    local l = P.lugares[i * 2 - (i % 2)] or P.lugares[i]
    if l and not l.ocupado then
      l.ocupado = true
      local c = novo_cliente(l)
      c.x, c.z, c.rota, c.andando = l.x, l.z, {}, false
      c.y, c.giro, c.sentado = l.y, l.giro, true
      c.estado = "esperando"
      c.t = math.random() * 5
      P.clientes[#P.clientes + 1] = c
    end
  end
end

local function andar(o, dx, dz, vel, dt)
  local ax, az = dx - o.x, dz - o.z
  local d = math.sqrt(ax * ax + az * az)
  if d < 0.03 then return true end
  local passo = math.min(vel * dt, d)
  o.x, o.z = o.x + ax / d * passo, o.z + az / d * passo
  local alvo = math.atan(ax, az)
  local dif = (alvo - o.giro + math.pi) % (2 * math.pi) - math.pi
  o.giro = o.giro + dif * math.min(1, dt * 12)
  o.fase = o.fase + dt
  return false
end

local function atualizar_cliente(c, dt)
  c.t = c.t + dt
  if c.estado == "entrando" or c.estado == "saindo" then
    local alvo = c.rota[1]
    if not alvo then
      if c.estado == "saindo" then c.removido = true return end
      c.estado, c.t, c.andando, c.sentado = "esperando", 0, false, true
      c.y, c.giro = c.lugar.y, c.lugar.giro
      return
    end
    if andar(c, alvo.x, alvo.z, 2.6, dt) then table.remove(c.rota, 1) end
  elseif c.estado == "esperando" then
    if c.t > 16 then
      c.estado = "indo_embora"
    end
  elseif c.estado == "comendo" then
    c.bebendo = (c.t % 2) < 1.2
    if c.t > 5 then c.estado = "indo_embora" end
  end
  if c.estado == "indo_embora" then
    c.bebendo, c.sentado, c.y = false, false, 0
    c.lugar.ocupado = false
    c.estado, c.andando = "saindo", true
    c.rota = { { x = c.x, z = RUA_Z }, { x = PORTA.x + 1.2, z = RUA_Z }, { x = PORTA.x, z = PORTA.z } }
  end
end

local function servir(c, x, y)
  c.estado, c.t, c.reservado = "comendo", 0, false
  local v = 12
  P.ouro = P.ouro + v
  P.efeitos[#P.efeitos + 1] = { texto = "+" .. v, x = x, y = y, vida = 0 }
end

local function atualizar_garconete(dt)
  local g = P.g
  g.recarga = g.recarga - dt
  g.andando = false
  if g.estado == "parada" then
    if g.recarga <= 0 then
      for _, c in ipairs(P.clientes) do
        if c.estado == "esperando" and c.t > 5 and not c.reservado then
          c.reservado = true
          g.alvo, g.estado, g.levando = c, "indo", true
          g.rota = { { x = g.x, z = RUA_Z }, { x = c.x, z = RUA_Z }, { x = c.x + (c.lugar.z < -1 and 0 or 0), z = c.z + (c.z < RUA_Z and 0.7 or -0.7) } }
          break
        end
      end
    end
  else
    local alvo = g.rota[1]
    if alvo then
      g.andando = true
      if andar(g, alvo.x, alvo.z, 3.2, dt) then table.remove(g.rota, 1) end
    elseif g.estado == "indo" then
      local c = g.alvo
      if c and c.estado == "esperando" then
        local sx, sy = motor.projetar(c.x, 2.2, c.z)
        servir(c, sx or 480, sy or 270)
      end
      g.levando, g.estado = false, "voltando"
      g.rota = { { x = g.x, z = RUA_Z }, { x = 3, z = RUA_Z }, { x = 3, z = -1.0 } }
    else
      g.estado, g.recarga = "parada", 2
    end
  end
end

local function atualizar_vagantes(dt)
  for _, v in ipairs(P.vagantes) do
    if not v.alvo or andar(v, v.alvo.x, v.alvo.z, 2.2, dt) then
      local xmax = P.expansao > 0.5 and 11 or 5.8
      v.alvo = { x = -5.5 + math.random() * (xmax + 5.5), z = RUA_Z + (math.random() - 0.5) * 1.5 }
    end
  end
end

function P.atualizar(dt)
  P.tempo = P.tempo + dt

  P.chegada = P.chegada + dt
  if P.chegada > 2.0 then
    P.chegada = 0
    local livres = {}
    for _, l in ipairs(P.lugares) do if not l.ocupado then livres[#livres + 1] = l end end
    if #livres > 0 then
      local l = util.escolher(livres)
      l.ocupado = true
      P.clientes[#P.clientes + 1] = novo_cliente(l)
    end
  end

  for _, c in ipairs(P.clientes) do atualizar_cliente(c, dt) end
  for i = #P.clientes, 1, -1 do
    if P.clientes[i].removido then table.remove(P.clientes, i) end
  end
  atualizar_garconete(dt)
  atualizar_vagantes(dt)

  if P.expandindo and P.expansao < 1 then
    P.expansao = math.min(1, P.expansao + dt / 1.6)
    if P.expansao == 1 then
      for _, m in ipairs(MESAS_NOVAS) do
        P.lugares[#P.lugares + 1] = { x = m.x - 1.25, z = m.z, giro = math.pi / 2, y = 0.42 }
        P.lugares[#P.lugares + 1] = { x = m.x + 1.25, z = m.z, giro = -math.pi / 2, y = 0.42 }
      end
    end
  end
  P.cam = util.lerp(P.cam, P.expansao, math.min(1, dt * 2.5))

  local d = P.ouro - P.ouro_visivel
  P.ouro_visivel = math.abs(d) < 1 and P.ouro or P.ouro_visivel + d * math.min(1, dt * 10)

  for i = #P.efeitos, 1, -1 do
    local e = P.efeitos[i]
    e.vida = e.vida + dt
    if e.vida > 1.1 then table.remove(P.efeitos, i) end
  end
end

-- Desenho ------------------------------------------------------------------------------

local function balao(c)
  local x, y = motor.projetar(c.x, c.y + 1.75, c.z)
  if not x then return end
  y = y - 16 + math.sin(P.tempo * 4 + c.fase) * 2
  local resta = util.limitar(1 - c.t / 16, 0, 1)
  motor.retangulo(x - 21, y - 21, 42, 42, "#00000033", 11)
  motor.retangulo(x - 20, y - 22, 40, 40, "#fff6e6", 10)
  motor.triangulo(x - 6, y + 17, x + 6, y + 17, x, y + 25, "#fff6e6")
  if c.pedido == "bebida" then desenho.caneca(x, y - 5, 0.72) else desenho.coxa(x, y - 5, 0.72) end
  local b = resta > 0.5 and cor.verde or (resta > 0.25 and "#e8b13d" or cor.vermelho)
  motor.retangulo(x - 14, y + 8, 28, 4, "#00000026", 2)
  motor.retangulo(x - 14, y + 8, 28 * resta, 4, b, 2)
  return x, y
end

local function botao(x, y, w, h, texto, ativo)
  motor.retangulo(x, y + 2, w, h, "#00000055", 10)
  motor.retangulo(x, y, w, h, ativo and cor.ouro or "#3d291b", 10)
  motor.texto(texto, x + w / 2, y + h / 2 - 9, 14, ativo and TEXTO_OURO or cor.texto_fraco, "centro", true)
end

P.BOTAO_ALA = { x = 590, y = 488, w = 176, h = 40 }
P.BOTAO_CARGA = { x = 776, y = 488, w = 172, h = 40 }

local function hud()
  motor.retangulo(12, 12, 190, 52, "#21150ee0", 14)
  desenho.moeda(40, 38, 16)
  motor.texto(util.formatar(P.ouro_visivel), 64, 19, 28, cor.ouro, "esquerda", true)

  local total = #P.clientes + #P.vagantes
  local info = "Protótipo 3D  •  " .. motor.fps() .. " FPS  •  " .. total .. " pessoas"
  local w = motor.largura_texto(info, 13) + 24
  motor.retangulo(960 - 12 - w, 12, w, 30, "#21150ee0", 10)
  motor.texto(info, 960 - 24, 18, 13, cor.texto, "direita")

  local r = P.BOTAO_ALA
  botao(r.x, r.y, r.w, r.h, P.expandindo and "Mercadinho aberto" or "Abrir mercadinho", not P.expandindo)
  r = P.BOTAO_CARGA
  botao(r.x, r.y, r.w, r.h, "+10 pessoas (teste)", true)
end

function P.desenhar()
  local t = P.tempo
  -- ao expandir, a câmera recua e anda para mostrar a ala nova
  local k = util.suave(util.limitar(P.cam, 0, 1))
  local ax = util.lerp(0.2, 2.9, k)
  local recuo = util.lerp(1, 1.27, k)
  motor.cena_camera(ax + 6.5 * recuo, 15 * recuo, 0.6 + 17.5 * recuo, ax, 0.3, 0.2, 28)

  local f = 1 + math.sin(t * 9) * 0.1 + math.sin(t * 23) * 0.07
  motor.cena_luz(1, -5.3, 1.1, -3.2, 2.1 * f, 1.0 * f, 0.36 * f, 7.5)
  motor.cena_luz(2, -0.6, 2.6, -3.0, 1.15, 0.8, 0.42, 8)
  motor.cena_luz(3, 3.0, 2.4, -3.0, 0.75, 0.5, 0.26, 5.5)
  motor.cena_luz(4, 9.3, 2.2, -1.4, 0.95 * P.expansao, 0.66 * P.expansao, 0.36 * P.expansao, 6.5)

  salao(t)
  nova_ala(P.expansao, t)
  for _, c in ipairs(P.clientes) do boneco(c) end
  for _, v in ipairs(P.vagantes) do boneco(v) end
  garconete(P.g)
  motor.cena_desenhar()

  for _, c in ipairs(P.clientes) do
    if c.estado == "esperando" then balao(c) end
  end
  for _, e in ipairs(P.efeitos) do
    local q = e.vida / 1.1
    motor.opacidade(1 - q * q)
    motor.texto(e.texto, e.x + 1, e.y - q * 44 + 2, 24, "#00000088", "centro", true)
    motor.texto(e.texto, e.x, e.y - q * 44, 24, cor.ouro, "centro", true)
  end
  motor.opacidade(1)
  hud()
end

function P.tocar(x, y)
  if util.dentro(x, y, P.BOTAO_ALA) then
    P.expandindo = true
    return
  end
  if util.dentro(x, y, P.BOTAO_CARGA) then
    for _ = 1, 10 do
      local t = util.escolher(TIPOS)
      P.vagantes[#P.vagantes + 1] = {
        x = -5 + math.random() * 10, y = 0, z = RUA_Z + (math.random() - 0.5) * 1.5,
        giro = 0, tipo = t, pele = util.escolher(PELES), fase = math.random() * 6, andando = true,
      }
    end
    return
  end
  -- serve o cliente cujo balão está mais perto do toque
  local melhor, md, mx, my = nil, 40, nil, nil
  for _, c in ipairs(P.clientes) do
    if c.estado == "esperando" then
      local sx, sy = motor.projetar(c.x, c.y + 1.75, c.z)
      if sx then
        local d = util.distancia(x, y, sx, sy - 18)
        if d < md then melhor, md, mx, my = c, d, sx, sy end
      end
    end
  end
  if melhor then servir(melhor, mx, my - 30) end
end

return P
