-- =============================================================================
--  A TAVERNA EM 3D: cenário, áreas que crescem e personagens low poly.
--  Unidades: 1 = cerca de 1 metro. x para a direita, z vem para a câmera.
-- =============================================================================

local J = require("jogo")
local C = require("config")
local util = require("util")
local U = require("ui")
local cor = util.cores

local M = {}

local peca = motor.peca

local function caixa(x, y, z, ex, ey, ez, c, giro) peca("caixa", x, y + ey / 2, z, ex, ey, ez, giro or 0, c) end
local function cilindro(x, y, z, d, a, c) peca("cilindro", x, y, z, d, a, d, 0, c) end
local function cone(x, y, z, d, a, c) peca("cone", x, y, z, d, a, d, 0, c) end
local function brilho(f, x, y, z, ex, ey, ez, c, b) peca(f, x, y, z, ex, ey, ez, 0, c, 0, 0, b or 1.5) end

function M.iniciar()
  M.tempo = 0
  M.zoom, M.zoom_alvo = 1, 1
  M.pan_x, M.pan_z = 0, 0
  M.anim = { leste = 0, jardim = 0, cerveja = 0, circulo = 0 }
  local a = M.alvos()
  for k, v in pairs(a) do M.anim[k] = v end
  M.quadro = M.calcular_enquadramento(M.anim)
end

function M.alvos()
  return {
    leste = J.ef("a_leste") > 0 and 1 or 0,
    jardim = J.ef("a_jardim") > 0 and 1 or 0,
    cerveja = J.ef("a_cerveja") > 0 and 1 or 0,
    circulo = J.ef("a_circulo") > 0 and 1 or 0,
  }
end

-- a câmera recua conforme as áreas abrem, para sempre caber tudo
function M.calcular_enquadramento(a)
  local xmax = util.lerp(6.7, 12.2, math.max(a.leste, a.circulo))
  local zmax = util.lerp(4.9, 8.8, math.max(a.jardim, a.cerveja, a.circulo))
  local cx, cz = (-6.9 + xmax) / 2, (-4.9 + zmax) / 2
  local escala = math.max((xmax + 6.9) / 13.6, (zmax + 4.9) / 9.8)
  return { x = cx, z = cz, escala = escala }
end

function M.atualizar(dt)
  M.tempo = M.tempo + dt
  local a = M.alvos()
  for k, v in pairs(a) do
    if M.anim[k] < v then M.anim[k] = math.min(v, M.anim[k] + dt / 1.6)
    else M.anim[k] = v end
  end
  local q = M.calcular_enquadramento(M.anim)
  local k = math.min(1, dt * 2.5)
  M.quadro.x = util.lerp(M.quadro.x, q.x, k)
  M.quadro.z = util.lerp(M.quadro.z, q.z, k)
  M.quadro.escala = util.lerp(M.quadro.escala, q.escala, k)
  M.zoom = util.lerp(M.zoom, M.zoom_alvo, math.min(1, dt * 8))
  M.aplicar_camera()
end

function M.aplicar_camera()
  local q = M.quadro
  local d = q.escala / M.zoom
  local ax, az = q.x + M.pan_x, q.z + M.pan_z
  motor.cena_camera(ax + 6.5 * d, 15 * d, az + 18 * d, ax, 0.3, az - 0.3, 28)
end

function M.arrastar(dx, dy)
  if M.zoom_alvo <= 1.02 then return end
  local f = 0.022 * M.quadro.escala / M.zoom
  M.pan_x = util.limitar(M.pan_x - dx * f, -9, 9)
  M.pan_z = util.limitar(M.pan_z - dy * f * 1.2, -7, 7)
end

function M.rolar(v)
  M.zoom_alvo = util.limitar(M.zoom_alvo + v * 0.15, 1, 2.4)
  if M.zoom_alvo <= 1.02 then M.pan_x, M.pan_z = 0, 0 end
end

-- Cenário ------------------------------------------------------------------------------

local function piso(x0, x1, z0, z1, a, b, e)
  e = e or 1
  local i, z = 0, z0
  while z < z1 - 0.01 do
    local l = math.min(0.8, z1 - z)
    caixa((x0 + x1) / 2, -0.3, z + l / 2, x1 - x0, 0.3 * e, l - 0.03, i % 2 == 0 and a or b)
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

local function salao()
  local tempo = M.tempo
  piso(-6.5, 6.5, -4.5, 4.7, "#7a5433", "#6f4b2c")
  caixa(0, -0.95, 0.1, 13.6, 0.65, 9.9, "#2a1b12")
  caixa(0, 0, -4.7, 13.4, 4.2, 0.4, "#4f3522")
  caixa(-6.7, 0, 0.05, 0.4, 4.2, 9.9, "#47301f")
  caixa(0, 0, -4.48, 13, 0.75, 0.08, "#2f1e13")

  for x = -6, 6, 3 do caixa(x, 0, -4.45, 0.26, 4.2, 0.2, "#2d1c11") end
  for z = -3, 4.5, 2.5 do caixa(-6.45, 0, z, 0.2, 4.2, 0.26, "#2d1c11") end
  caixa(0, 3.75, -4.42, 13, 0.26, 0.2, "#2d1c11")

  caixa(-6.47, 0, J.PORTA.z, 0.12, 2.5, 1.5, "#20140c")
  caixa(-6.42, 2.5, J.PORTA.z, 0.24, 0.2, 1.8, "#2d1c11")

  -- lareira
  local lx, lz = -6.1, -3.2
  caixa(lx, 0, lz, 0.9, 2.5, 2.2, "#62605c")
  caixa(lx + 0.34, 0, lz, 0.3, 1.2, 1.3, "#201a18")
  caixa(lx + 0.5, 2.45, lz, 0.9, 0.18, 2.5, "#3d2616")
  local f = 1 + math.sin(tempo * 9) * 0.1 + math.sin(tempo * 23) * 0.06
  brilho("cone", lx + 0.52, 0.05, lz - 0.28, 0.5, 0.62 * f, 0.5, "#ff7a24", 1.2)
  brilho("cone", lx + 0.52, 0.05, lz + 0.28, 0.46, 0.5 / f, 0.46, "#ff9a30", 1.2)
  brilho("cone", lx + 0.56, 0.05, lz, 0.42, 0.8 * f, 0.42, "#ffc04a", 1.3)

  -- quadro de missões: os papéis aparecem quando a prateleira abre
  local qx = J.QUADRO.x
  caixa(qx, 1.45, -4.42, 2.6, 1.7, 0.1, "#5a3a20")
  caixa(qx, 1.55, -4.36, 2.3, 1.5, 0.05, "#a87e4f")
  if J.prateleira_aberta() then
    local n = math.min(8, J.vagas_missao())
    for i = 1, n do
      local coluna, linha = (i - 1) % 4, math.floor((i - 1) / 4)
      caixa(qx - 0.84 + coluna * 0.56, 2.25 - linha * 0.68, -4.32, 0.44, 0.56, 0.02, "#f0e4c8")
    end
  end

  -- balcão, prateleira e fogão do cozinheiro
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
  if J.ef("cozinheiro") > 0 then
    caixa(0.95, 0, -3.55, 1.1, 0.95, 0.9, "#55504c")
    brilho("caixa", 0.95, 0.96, -3.55, 0.8, 0.03, 0.6, "#ff7a24", 1.0)
    cilindro(0.95, 0.98, -3.55, 0.52, 0.36, "#3a3a40")
  end

  barril(5.6, -3.7); barril(4.75, -3.8); barril(5.75, -2.9, 0.9)
  barril(-5.6, 3.9, 0.9); barril(-4.8, 4.1, 0.8)

  -- quartos: escada e porta no fundo
  if J.nivel("quartos") > 0 then
    for i = 0, 5 do caixa(-5.2 + i * 0.22, 0, -3.9, 0.3, 0.24 + i * 0.24, 0.8, "#6a4426") end
    caixa(-4.0, 1.5, -4.46, 1.0, 1.9, 0.08, "#3a2415")
  end

  -- decoração: flâmulas na parede
  local d = math.min(J.nivel("decoracao") + (J.nivel("conforto") > 0 and 1 or 0), 5)
  for i = 1, d do
    local x = -5.5 + (i - 1) * 3
    caixa(x + 1.5, 2.4, -4.4, 0.7, 1.1, 0.04, i % 2 == 0 and "#3d5a8a" or "#a13b3b")
  end

  -- lampiões
  for _, x in ipairs({ -4.5, -0.6 }) do
    caixa(x, 2.6, -4.4, 0.08, 0.08, 0.3, "#1d130c")
    brilho("esfera", x, 2.48, -4.2, 0.24, 0.32, 0.24, "#ffd26a", 1.6)
  end

  for i = 1, math.min(J.num_mesas(), 6) do
    local m = J.POS_MESAS[i]
    mesa(m.x, m.z)
    banquinho(m.x - 1.25, m.z)
    banquinho(m.x + 1.25, m.z)
  end
  if J.ef("balcao") > 0 then
    for _, x in ipairs(J.BANCOS_BALCAO) do banquinho(x, -1.42) end
  end
end

local function ala_leste(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local function c2(x, y, z, ex, ey, ez, c) caixa(x, y * o, z, ex, ey * o, ez, c) end
  piso(6.5, 12, -4.5, 4.7, "#8a6b43", "#7f613a", o)
  caixa(9.25, -0.95, 0.1, 5.7, 0.65, 9.9, "#2a1b12")
  c2(9.25, 0, -4.7, 5.5, 4.2, 0.4, "#4f3522")
  for x = 7.5, 12, 3 do c2(x, 0, -4.45, 0.26, 4.2, 0.2, "#2d1c11") end

  if J.mercadinho_aberto() then
    local mx, mz = 9.3, -2.2
    for _, d in ipairs({ { -2.1, -0.65 }, { 2.1, -0.65 }, { -2.1, 0.7 }, { 2.1, 0.7 } }) do
      c2(mx + d[1], 0, mz + d[2], 0.18, 2.5, 0.18, "#4a2c17")
    end
    c2(mx, 0, mz + 0.4, 4.2, 0.95, 0.8, "#8a5a33")
    c2(mx, 0.95, mz + 0.4, 4.4, 0.1, 0.95, "#b98a55")
    for i = 0, 5 do
      c2(mx - 1.95 + i * 0.78, 2.5, mz, 0.8, 0.14, 1.9, i % 2 == 0 and "#b5403a" or "#efe2c4")
    end
    -- quanto mais alto o rank do mercadinho, mais mercadoria à mostra
    local r = J.ef("mercadinho")
    if r >= 1 then caixa(mx + 1.55, 1.05, mz + 0.35, 0.56, 0.34, 0.42, "#c9a24a") end
    if r >= 2 then cilindro(mx + 0.6, 1.05, mz + 0.4, 0.24, 0.34, "#5abf7c") end
    if r >= 3 then cilindro(mx + 1.0, 1.05, mz + 0.35, 0.24, 0.34, "#6d8fe0") end
    if r >= 4 then peca("cilindro", mx - 0.3, 1.25, mz + 0.42, 0.72, 0.1, 0.72, 0, "#a13b3b", 1.3) end
    if r >= 5 then peca("caixa", mx - 1.3, 1.45, mz + 0.4, 0.09, 0.8, 0.2, 0, "#c7d0d8", 0, 0.5) end
    if r >= 6 then peca("caixa", mx - 1.7, 1.45, mz + 0.4, 0.09, 0.8, 0.2, 0, "#e0c04a", 0, -0.5) end
    if r >= 7 then brilho("esfera", mx + 0.1, 1.2, mz + 0.35, 0.3, 0.3, 0.3, "#c9a7ff", 0.7) end
    if r >= 8 then caixa(mx - 0.9, 1.05, mz + 0.35, 0.5, 0.5, 0.4, "#f2c14e") end
    -- estantes da aba de venda
    if J.venda_aberta() then
      c2(mx, 0, -4.3, 4.6, 2.2, 0.5, "#5b3a22")
      local lista = { J.ef("pocoes") > 0 and "#5abf7c", J.ef("armaduras") > 0 and "#a8b4bf", J.ef("armas") > 0 and "#c7d0d8" }
      for i = 1, 3 do
        if lista[i] then
          for k = 0, 4 do caixa(mx - 1.9 + k * 0.9, 0.5 + (i - 1) * 0.55, -4.0, 0.28, 0.34, 0.1, lista[i]) end
        end
      end
    end
  end

  for i = 7, math.min(J.num_mesas(), 8) do
    local m = J.POS_MESAS[i]
    mesa(m.x, m.z)
    banquinho(m.x - 1.25, m.z)
    banquinho(m.x + 1.25, m.z)
  end
end

local function jardim(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  caixa(-3, -0.95, 6.75, 7.2, 0.65, 4.1, "#2a1b12")
  caixa(-3, -0.3, 6.75, 7, 0.3 * o, 3.9, "#5d7a3e")
  -- cerca
  for x = -6.3, 0.5, 1.1 do caixa(x, 0, 8.55, 0.1, 0.65 * o, 0.1, "#7a5433") end
  caixa(-3, 0.4 * o, 8.55, 7, 0.07, 0.05, "#7a5433")
  -- canteiros
  local n = J.ef("canteiros")
  local cresce = J.estado.ciclo / J.ciclo_jardim()
  for i = 1, n do
    local col, lin = (i - 1) % 5, math.floor((i - 1) / 5)
    local x, z = -5.7 + col * 1.25, 5.6 + lin * 1.45
    caixa(x, 0, z, 1.0, 0.14, 1.1, "#4a3020")
    for k = -1, 1, 1 do
      local a = 0.2 + cresce * 0.6
      peca("cone", x + k * 0.3, 0.12, z, 0.26, a, 0.26, 0, i % 3 == 0 and "#c9a24a" or "#5fae4a")
      if cresce > 0.7 then peca("esfera", x + k * 0.3, 0.12 + a * 0.6, z + 0.1, 0.12, 0.12, 0.12, 0, i % 3 == 0 and "#e8c04a" or "#d9534a") end
    end
  end
end

local function cervejaria(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  caixa(3.5, -0.95, 6.75, 6.2, 0.65, 4.1, "#2a1b12")
  caixa(3.5, -0.3, 6.75, 6, 0.3 * o, 3.9, "#6b5842")
  cilindro(1.9, 0, 6.2, 1.3 * o, 1.5 * o, "#b5763a")
  peca("cone", 1.9, 1.5 * o, 6.2, 1.34, 0.6 * o, 1.34, 0, "#c98a4e")
  cilindro(3.5, 0, 6.2, 1.1 * o, 1.2 * o, "#7b4a26")
  cilindro(3.5, 0.2, 6.2, 1.14, 0.08, "#2f2319")
  cilindro(3.5, 0.9, 6.2, 1.14, 0.08, "#2f2319")
  brilho("caixa", 1.9, 0.08, 6.95, 0.6, 0.14, 0.2, "#ff7a24", 1.0)
  for i = 0, 2 do barril(4.8 + i * 0.75, 7.6, 0.9 * o) end
  caixa(2.7, 0, 7.8, 2.0, 0.85 * o, 0.7, "#6f4326")
end

local function circulo(e)
  if e <= 0 then return end
  local t = M.tempo
  caixa(9.25, -0.95, 6.75, 5.7, 0.65, 4.1, "#2a1b12")
  caixa(9.25, -0.3, 6.75, 5.5, 0.3 * e, 3.9, "#3b3650")
  local cx, cz = 9.25, 6.75
  peca("cilindro", cx, 0, cz, 3.0, 0.05, 3.0, 0, "#6d4bb3", 0, 0, 0.6)
  peca("cilindro", cx, 0.03, cz, 2.3, 0.05, 2.3, 0, "#2c2340")
  peca("cilindro", cx, 0.06, cz, 1.6, 0.05, 1.6, 0, "#9c78ff", 0, 0, 0.9)
  peca("cilindro", cx, 0.09, cz, 1.2, 0.05, 1.2, 0, "#2c2340")
  for i = 0, 3 do
    local a = t * 0.6 + i * math.pi / 2
    brilho("esfera", cx + math.cos(a) * 1.3, 0.5 + math.sin(t * 2 + i) * 0.1, cz + math.sin(a) * 1.3, 0.2, 0.2, 0.2, "#c9a7ff", 1.6)
  end
  for i = 0, 3 do
    local a = i * math.pi / 2 + math.pi / 4
    cone(cx + math.cos(a) * 2.2, 0, cz + math.sin(a) * 1.7, 0.45, 1.3 * e, "#5a5668")
  end
end

-- Personagens ---------------------------------------------------------------------------

function M.boneco(b)
  local co, si = math.cos(b.giro), math.sin(b.giro)
  local function p(f, lx, ly, lz, ex, ey, ez, c, rx, rz)
    peca(f, b.x + lx * co + lz * si, (b.y or 0) + ly, b.z - lx * si + lz * co, ex, ey, ez, b.giro, c, rx or 0, rz or 0)
  end
  local t = b.tipo
  local passo = b.andando and math.sin(b.fase * 10) or 0
  local y0 = b.andando and math.abs(passo) * 0.07 or 0
  if b.estado == "brigando" then
    y0 = math.abs(math.sin(M.tempo * 14)) * 0.12
    passo = math.sin(M.tempo * 14)
  end
  local pernas = b.sentado and 0 or 0.3

  if not b.sentado then
    p("caixa", -0.13, y0 + 0.15, passo * 0.14, 0.17, 0.32, 0.2, t.perna)
    p("caixa", 0.13, y0 + 0.15, -passo * 0.14, 0.17, 0.32, 0.2, t.perna)
  else
    p("caixa", -0.13, y0 + 0.08, 0.14, 0.17, 0.16, 0.42, t.perna)
    p("caixa", 0.13, y0 + 0.08, 0.14, 0.17, 0.16, 0.42, t.perna)
  end

  local inc = b.bebendo and -0.12 or 0
  local topo = pernas + 0.62
  if t.nome == "mago" then
    p("cone", 0, y0 + pernas - 0.26, 0, 0.74, 1.1, 0.74, t.corpo)
    topo = pernas + 0.56
  elseif t.nome == "clerigo" then
    p("cilindro", 0, y0 + pernas - 0.28, 0, 0.56, 0.9, 0.56, t.corpo)
    p("caixa", 0, y0 + pernas + 0.32, 0.27, 0.07, 0.34, 0.03, "#d4a83e")
    p("caixa", 0, y0 + pernas + 0.36, 0.27, 0.22, 0.07, 0.03, "#d4a83e")
  else
    p("cilindro", 0, y0 + pernas, 0, 0.56, 0.62, 0.48, t.corpo, inc)
  end
  if t.nome == "guerreiro" then
    p("caixa", 0, y0 + pernas + 0.33, 0.13, 0.48, 0.46, 0.24, "#c5cfd8", inc)
    p("cilindro", 0, y0 + pernas + 0.02, 0, 0.6, 0.09, 0.52, "#4a2c17")
  elseif t.nome == "arqueiro" then
    p("cilindro", 0, y0 + pernas + 0.02, 0, 0.6, 0.08, 0.52, "#5b3a22")
    p("caixa", 0.26, y0 + pernas + 0.3, -0.27, 0.15, 0.6, 0.15, "#7b4a26", 0, -0.3)
  end

  local bs = b.andando and passo * 0.55 or 0
  local by = topo - 0.06
  if t.nome == "mago" then by = pernas + 0.45 end
  p("caixa", -0.36, y0 + by - 0.2, -bs * 0.28, 0.14, 0.44, 0.15, t.braco, bs)
  if b.bebendo then
    p("caixa", 0.3, y0 + by + 0.02, 0.2, 0.14, 0.15, 0.44, t.braco)
    p("cilindro", 0.3, y0 + by, 0.48, 0.22, 0.26, 0.22, "#e8a33d")
    p("cilindro", 0.3, y0 + by + 0.25, 0.48, 0.24, 0.07, 0.24, "#fff4dd")
  else
    p("caixa", 0.36, y0 + by - 0.2, bs * 0.28, 0.14, 0.44, 0.15, t.braco, -bs)
  end

  -- capa de herói e aura de invocado
  local c = b.contratado
  if c and (c.heroi or c.invocado) then
    p("caixa", 0, y0 + pernas + 0.02, -0.28, 0.52, 0.66, 0.05, c.invocado and "#7f8fe6" or "#b5403a")
  end
  if c and c.invocado then
    peca("cilindro", b.x, 0.02, b.z, 1.0, 0.03, 1.0, 0, "#c9a7ff", 0, 0, 0.9)
  end

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

local T_GARCOM = { nome = "comum", corpo = "#2f7a8a", perna = "#23303a", braco = "#2a6d7c" }
local T_COZINHEIRO = { nome = "comum", corpo = "#eeeae2", perna = "#3a3a40", braco = "#e2ddd2" }
local T_BARDO = { nome = "comum", corpo = "#a13b6c", perna = "#3f2a3a", braco = "#8f3360" }

local function garcom(g)
  M.boneco({ x = g.x, z = g.z, giro = g.giro, fase = g.fase, andando = g.andando, pele = "#f1c9a5", tipo = T_GARCOM })
  local co, si = math.cos(g.giro), math.sin(g.giro)
  local ax, az = g.x + 0.42 * co + 0.2 * si, g.z - 0.42 * si + 0.2 * co
  caixa(g.x - 0.1 * si, 0.47, g.z - 0.1 * co, 0.5, 0.44, 0.04, "#f4ece0", g.giro)
  peca("cilindro", ax, 1.0, az, 0.56, 0.04, 0.56, 0, "#c0c4c8")
  if g.levando then
    cilindro(ax, 1.03, az, 0.2, 0.24, "#e8a33d")
    cilindro(ax, 1.25, az, 0.22, 0.06, "#fff4dd")
  end
end

local function equipe_fixa()
  if J.ef("cozinheiro") > 0 then
    local x = 0.95 + math.sin(M.tempo * 0.8) * 0.15
    M.boneco({ x = x, z = -2.75, giro = math.pi, fase = 0, pele = "#e0ac7e", tipo = T_COZINHEIRO, chapeu = "#f4f4f0" })
    cilindro(x, 2.08, -2.75, 0.42, 0.24, "#f4f4f0")
  end
  if J.ef("bardo") > 0 then
    local b = math.sin(M.tempo * 5) * 0.03
    M.boneco({ x = -5.1, z = -1.25, y = b + 0.03, giro = 0.9, fase = 0, pele = "#c68a5a", tipo = T_BARDO, chapeu = "#3e5a4b" })
    peca("esfera", -4.85, 0.8, -1.0, 0.3, 0.42, 0.14, 0.9, "#a5703f")
    peca("caixa", -4.62, 1.02, -0.86, 0.06, 0.5, 0.06, 0.9, "#6f4326", 0, -1.0)
  end
end

local function poeira_briga(p)
  if not p.oponente then return end
  local mx, mz = (p.x + p.oponente.x) / 2, (p.z + p.oponente.z) / 2
  local t = M.tempo
  for i = 0, 4 do
    local a = t * 3 + i * 1.26
    peca("esfera", mx + math.cos(a) * 0.5, 1.0 + math.sin(a * 1.7) * 0.3, mz + math.sin(a) * 0.4, 0.42, 0.34, 0.42, 0, "#d9cfc0")
  end
end

-- Desenho ------------------------------------------------------------------------------

function M.desenhar_cena()
  local a = M.anim
  M.aplicar_camera()
  local t = M.tempo
  local f = 1 + math.sin(t * 9) * 0.1 + math.sin(t * 23) * 0.07
  motor.cena_luz(1, -5.3, 1.1, -3.2, 2.1 * f, 1.0 * f, 0.36 * f, 7.5)
  motor.cena_luz(2, -0.6, 2.6, -3.0, 1.15, 0.8, 0.42, 8)
  motor.cena_luz(3, 3.0, 2.4, -3.0, 0.75, 0.5, 0.26, 5.5)
  local c = a.circulo
  if c > 0 then
    motor.cena_luz(4, 9.25, 1.2, 6.75, 0.9 * c, 0.6 * c, 1.5 * c, 6)
  else
    local l = a.leste
    motor.cena_luz(4, 9.3, 2.2, -1.4, 0.95 * l, 0.66 * l, 0.36 * l, 6.5)
  end

  salao()
  ala_leste(a.leste)
  jardim(a.jardim)
  cervejaria(a.cerveja)
  circulo(a.circulo)

  for _, p in ipairs(J.pessoas) do
    M.boneco(p)
    if p.estado == "brigando" then poeira_briga(p) end
  end
  for _, g in ipairs(J.garcons) do garcom(g) end
  equipe_fixa()

  -- os invocados ficam em volta do círculo quando não estão em missão
  if a.circulo > 0.9 then
    local i = 0
    for _, ch in ipairs(J.estado.contratados) do
      if ch.invocado and not ch.em_missao and not ch.na_final then
        i = i + 1
        local ang = i * math.pi / 2
        M.boneco({ x = 9.25 + math.cos(ang) * 0.9, z = 6.75 + math.sin(ang) * 0.7, giro = -ang + math.pi / 2, fase = 0,
          pele = ch.pele, tipo = J.TIPOS_POR_NOME(ch.tipo), contratado = ch })
      end
    end
  end
  motor.cena_desenhar()
end

-- balões em 2D sobre a cena; devolve para o toque onde cada um está
function M.posicao_balao(p)
  local x, y = motor.projetar(p.x, (p.y or 0) + 1.75, p.z)
  if not x then return nil end
  return x, y - 16
end

function M.desenhar_baloes()
  local e = util.limitar(1 / M.quadro.escala * M.zoom, 0.72, 1.1)
  for _, p in ipairs(J.pessoas) do
    if p.estado == "esperando" or p.estado == "brigando" then
      local x, y = M.posicao_balao(p)
      if x then
        y = y + math.sin(M.tempo * 4 + p.fase) * 2
        local q = 20 * e
        motor.retangulo(x - q - 1, y - q - 1, q * 2 + 2, q * 2, "#00000033", 10 * e)
        if p.estado == "brigando" then
          motor.retangulo(x - q, y - q - 2, q * 2, q * 2, cor.vermelho, 10 * e)
          motor.triangulo(x - 6 * e, y + q - 3, x + 6 * e, y + q - 3, x, y + q + 5 * e, cor.vermelho)
          motor.texto("!", x, y - 16 * e, 28 * e, "#ffffff", "centro", true)
        else
          motor.retangulo(x - q, y - q - 2, q * 2, q * 2, "#fff6e6", 10 * e)
          motor.triangulo(x - 6 * e, y + q - 3, x + 6 * e, y + q - 3, x, y + q + 5 * e, "#fff6e6")
          if p.t <= C.tempo_rapido then motor.contorno(x - q, y - q - 2, q * 2, q * 2, cor.verde, 2.5, 10 * e) end
          if p.pedido == "bebida" then U.caneca(x, y - 5 * e, 0.72 * e) else U.coxa(x, y - 5 * e, 0.72 * e) end
          local resta = util.limitar(1 - p.t / J.paciencia(), 0, 1)
          local b = resta > 0.5 and cor.verde or (resta > 0.25 and "#e8b13d" or cor.vermelho)
          U.barra(x - 14 * e, y + 8 * e, 28 * e, 4, resta, b)
        end
      end
    end
  end
  for _, f in ipairs(J.efeitos) do
    local x, y = motor.projetar(f.x, f.y, f.z)
    if x then
      local q = f.vida / 1.1
      motor.opacidade(1 - q * q)
      motor.texto(f.texto, x + 1, y - q * 44 + 2, f.tam, "#00000088", "centro", true)
      motor.texto(f.texto, x, y - q * 44, f.tam, f.cor, "centro", true)
    end
  end
  motor.opacidade(1)
end

-- toque na taverna: serve ou separa quem estiver mais perto
function M.tocar(x, y)
  local melhor, md = nil, 42
  for _, p in ipairs(J.pessoas) do
    if p.estado == "esperando" or p.estado == "brigando" then
      local sx, sy = M.posicao_balao(p)
      if sx then
        local d = util.distancia(x, y, sx, sy)
        if d < md then melhor, md = p, d end
      end
    end
  end
  if not melhor then return false end
  if melhor.estado == "brigando" then return J.separar_briga(melhor) end
  return J.servir(melhor, false)
end

return M
