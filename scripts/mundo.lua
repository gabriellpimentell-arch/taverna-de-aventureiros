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

local L = require("layout")

-- Grupo atual: tudo desenhado depois de grupo("id") acompanha o objeto no modo de edição
local G = nil
local function grupo(id)
  if not id then G = nil return end
  local o = L.POR_ID[id]
  local x, z = L.desloc(id)
  local y, g = L.altura(id), L.giro(id)
  if x == 0 and z == 0 and y == 0 and g == 0 then G = nil return end
  G = { px = o.x, pz = o.z, x = x, z = z, y = y, g = g, co = math.cos(g), si = math.sin(g) }
end
M.grupo = grupo

local function peca(f, x, y, z, ex, ey, ez, giro, c, rx, rz, b)
  if G then
    local ax, az = x - G.px, z - G.pz
    x = G.px + G.x + ax * G.co + az * G.si
    z = G.pz + G.z - ax * G.si + az * G.co
    y = y + G.y
    giro = (giro or 0) + G.g
  end
  motor.peca(f, x, y, z, ex, ey, ez, giro, c, rx, rz, b)
end

local function caixa(x, y, z, ex, ey, ez, c, giro) peca("caixa", x, y + ey / 2, z, ex, ey, ez, giro or 0, c) end
local function cilindro(x, y, z, d, a, c) peca("cilindro", x, y, z, d, a, d, 0, c) end
local function cone(x, y, z, d, a, c) peca("cone", x, y, z, d, a, d, 0, c) end
local function brilho(f, x, y, z, ex, ey, ez, c, b) peca(f, x, y, z, ex, ey, ez, 0, c, 0, 0, b or 1.5) end

-- Paleta (docs/estilo-visual.md): poucos tons por família, cor forte só no destaque da área
local PISO_A, PISO_B, CORREDOR = "#6b4a30", "#62442b", "#7d5a3a"
local PAREDE, VIGA = "#4f3522", "#2d1c11"
local MAD_ESC, MAD_MED, TAMPO = "#4a2c17", "#7b4a26", "#b07a47"
local PEDRA_ESC, PEDRA, PEDRA_CLARA = "#4e4a48", "#6e6a64", "#a8a294"
local PERGAMINHO, FERRO = "#f0e4c8", "#2f2c2c"
local VELA, ALARANJADO, FOGO = "#ffd26a", "#ffc04a", "#ff7a24"
local TAPETE, TAPETE_ESC, AMBAR, ESPUMA = "#8f3a32", "#5e2622", "#e8a33d", "#fff4dd"
local COBRE, COBRE_CLARO = "#b8693a", "#d98f55"
local VIOLETA, CIANO, FUNDO_MAGIA = "#a06aff", "#6fe6ff", "#2a2244"
local AZUL_GUILDA, OURO = "#2b4a8c", "#d4a83e"
local RANKS = { "#9aa0a6", "#5abf7c", "#6d8fe0", "#a06ad8", "#f2c14e" }

function M.iniciar()
  M.tempo = 0
  M.zoom, M.zoom_alvo = 1, 1
  M.pan_x, M.pan_z = 0, 0
  M.dt_cena = 0
  M.fazendeiro = { x = -5.7, z = 6.35, giro = 0, fase = 0, t = 0, i = 1 }
  M.anim = { leste = 0, jardim = 0, cerveja = 0, circulo = 0 }
  local a = M.alvos()
  for k, v in pairs(a) do M.anim[k] = v end
  M.quadro = M.calcular_enquadramento(M.anim)
end

function M.alvos()
  return {
    leste = (J.ef("a_leste") > 0 or J.mercadinho_aberto()) and 1 or 0,
    jardim = J.ef("a_jardim") > 0 and 1 or 0,
    cerveja = J.ef("a_cerveja") > 0 and 1 or 0,
    circulo = J.ef("a_circulo") > 0 and 1 or 0,
  }
end

-- a câmera recua conforme as áreas abrem, para sempre caber tudo
function M.calcular_enquadramento(a)
  local xa, xb, za, zb = L.salao()
  local xmin, zmin = xa - 0.4, za - 0.4
  local xmax = xb + util.lerp(0.2, 5.7, math.max(a.leste, a.circulo))
  local zmax = zb + util.lerp(0.2, 4.1, math.max(a.jardim, a.cerveja, a.circulo))
  local cx, cz = (xmin + xmax) / 2, (zmin + zmax) / 2
  local escala = math.max((xmax - xmin) / 13.6, (zmax - zmin) / 9.8)
  return { x = cx, z = cz, escala = escala, largura = xmax - xmin, fundo = zmax - zmin }
end

function M.atualizar(dt)
  M.tempo = M.tempo + dt
  M.dt_cena = dt
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
  M.quadro.largura, M.quadro.fundo = q.largura, q.fundo
  M.zoom = util.lerp(M.zoom, M.zoom_alvo, math.min(1, dt * 8))
  M.aplicar_camera()
end

function M.aplicar_camera()
  local q = M.quadro
  local d = q.escala / M.zoom
  local ax, az = q.x + M.pan_x, q.z + M.pan_z
  motor.cena_camera(ax + 6.5 * d, 15 * d, az + 18 * d, ax, 0.3, az - 0.3, 28)
  motor.cena_sombra(q.x, q.z, math.max(24, math.max(q.largura or 14, q.fundo or 10) * 1.1))
end

function M.arrastar(dx, dy)
  if M.zoom_alvo <= 1.02 then return end
  local f = 0.022 * M.quadro.escala / M.zoom
  local lx, lz = (M.quadro.largura or 14) * 0.65, (M.quadro.fundo or 10) * 0.65
  M.pan_x = util.limitar(M.pan_x - dx * f, -lx, lx)
  M.pan_z = util.limitar(M.pan_z - dy * f * 1.2, -lz, lz)
end

function M.rolar(v)
  M.zoom_alvo = util.limitar(M.zoom_alvo + v * 0.15, 1, 2.4)
  if M.zoom_alvo <= 1.02 then M.pan_x, M.pan_z = 0, 0 end
end

-- Cenário ------------------------------------------------------------------------------

local function piso(x0, x1, z0, z1, a, b, e, gasto)
  e = e or 1
  local i, z = 0, z0
  while z < z1 - 0.01 do
    local l = math.min(0.8, z1 - z)
    local c = i % 2 == 0 and a or b
    -- as tábuas por onde todos andam ficam mais gastas
    if gasto and math.abs(z + l / 2 - J.PORTA.z) < 0.8 then c = gasto end
    caixa((x0 + x1) / 2, -0.3, z + l / 2, x1 - x0, 0.3 * e, l - 0.03, c)
    z = z + 0.8
    i = i + 1
  end
end

local function vela(x, y, z, a)
  a = a or 0.18
  cilindro(x, y, z, 0.1, a, "#efe2c4")
  brilho("esfera", x, y + a + 0.06, z, 0.11, 0.15, 0.11, VELA, 1.6)
end

local function mesa(x, z)
  cilindro(x, 0, z, 0.26, 0.72, MAD_ESC)
  cilindro(x, 0, z, 0.8, 0.07, VIGA)
  peca("cilindro", x, 0.70, z, 1.75, 0.12, 1.75, 0, TAMPO)
end

local function banquinho(x, z)
  cilindro(x, 0, z, 0.16, 0.38, MAD_ESC)
  cilindro(x, 0.36, z, 0.54, 0.09, "#96643a")
end

local function barril(x, z, a)
  a = a or 1
  cilindro(x, 0, z, 0.82, 1.05 * a, MAD_MED)
  cilindro(x, 0.2 * a, z, 0.86, 0.08, FERRO)
  cilindro(x, 0.78 * a, z, 0.86, 0.08, FERRO)
end

local function tapete(x, z, ex, ez)
  caixa(x, 0, z, ex, 0.03, ez, TAPETE_ESC)
  caixa(x, 0.02, z, ex - 0.24, 0.03, ez - 0.24, OURO)
  caixa(x, 0.04, z, ex - 0.4, 0.03, ez - 0.4, TAPETE)
end

-- janela acesa na parede esquerda
local function janela(id, z)
  grupo(id)
  local x = -6.46
  caixa(x, 1.5, z, 0.08, 1.5, 1.2, VIGA)
  brilho("caixa", x + 0.05, 2.25, z, 0.04, 1.26, 0.96, "#ffc96b", 1.3)
  caixa(x + 0.08, 1.62, z, 0.03, 1.26, 0.08, VIGA)
  caixa(x + 0.08, 2.2, z, 0.03, 0.08, 0.96, VIGA)
  caixa(x + 0.12, 1.42, z, 0.24, 0.1, 1.4, MAD_MED)
end

-- caixote com saco ao lado, para encher os cantos
local function carga(x, z)
  caixa(x, 0, z, 0.7, 0.6, 0.7, MAD_MED)
  caixa(x, 0.6, z, 0.74, 0.06, 0.74, TAMPO)
  peca("esfera", x - 0.72, 0.26, z + 0.1, 0.6, 0.52, 0.6, 0, "#c9b58b")
  peca("esfera", x - 0.72, 0.54, z + 0.1, 0.18, 0.18, 0.18, 0, "#a8946c")
end

local function salao()
  local tempo = M.tempo
  local xa, xb, za, zb = L.salao()
  local cx, cz, lx, lz = (xa + xb) / 2, (za + zb) / 2, xb - xa, zb - za
  piso(xa, xb, za, zb, PISO_A, PISO_B, 1, CORREDOR)
  caixa(cx, -0.95, cz, lx + 0.6, 0.65, lz + 0.7, "#2a1b12")
  caixa(cx, 0, za - 0.2, lx + 0.4, 4.2, 0.4, PAREDE)
  caixa(xa - 0.2, 0, cz, 0.4, 4.2, lz + 0.7, "#47301f")
  -- o rodapé vira pedra clara quando a taverna chega à fase de guilda
  local guilda = M.anim.circulo > 0
  local rodape = guilda and PEDRA_CLARA or "#2f1e13"
  caixa(cx, 0, za + 0.02, lx, 0.75, 0.08, rodape)
  caixa(xa + 0.02, 0, cz, 0.08, 0.75, lz + 0.5, rodape)

  for x = xa + 0.5, xb, 3 do caixa(x, 0, za + 0.05, 0.26, 4.2, 0.2, VIGA) end
  for z = za + 1.5, zb, 2.5 do caixa(xa + 0.05, 0, z, 0.2, 4.2, 0.26, VIGA) end
  caixa(cx, 3.75, za + 0.08, lx, 0.26, 0.2, VIGA)

  grupo("porta")
  -- porta (o corredor termina nela) com lampião, porque a parede esquerda fica na sombra
  local pz = 1.6
  caixa(-6.47, 0, pz, 0.12, 2.5, 1.5, "#20140c")
  caixa(-6.42, 2.5, pz, 0.24, 0.2, 1.8, VIGA)
  caixa(-6.4, 0, pz - 0.37, 0.06, 2.42, 0.66, MAD_ESC)
  caixa(-6.4, 0, pz + 0.37, 0.06, 2.42, 0.66, MAD_MED)
  caixa(-6.35, 1.0, pz + 0.55, 0.06, 0.14, 0.14, OURO)
  grupo("lampiao_porta")
  caixa(-6.34, 2.6, 2.6, 0.3, 0.08, 0.08, FERRO)
  brilho("esfera", -6.18, 2.48, 2.6, 0.24, 0.32, 0.24, VELA, 1.6)
  janela("janela1", -1.27)
  janela("janela2", 3.7)
  grupo("vassoura")
  -- vassoura encostada ao lado da porta
  peca("cilindro", -6.25, 0.1, 2.75, 0.07, 1.5, 0.07, 0, MAD_MED, -0.12)
  cone(-6.25, 0, 2.72, 0.3, 0.42, "#c9a24a")

  -- lareira
  grupo("lareira")
  local lx, lz = -6.1, -3.2
  caixa(lx + 0.68, 0, lz, 0.5, 0.04, 2.5, PEDRA_ESC)
  caixa(lx, 0, lz, 0.9, 2.5, 2.2, PEDRA)
  caixa(lx - 0.1, 2.5, lz, 0.7, 1.7, 1.4, PEDRA_ESC)
  for _, d in ipairs({ { 0.5, -0.82 }, { 1.75, 0.8 }, { 2.05, -0.72 }, { 0.9, 0.86 }, { 2.25, 0.2 } }) do
    caixa(lx + 0.44, d[1], lz + d[2], 0.06, 0.25, 0.4, PEDRA_CLARA)
  end
  caixa(lx + 0.34, 0, lz, 0.3, 1.2, 1.3, "#201a18")
  caixa(lx + 0.2, 1.45, lz, 1.0, 0.16, 2.5, MAD_ESC)
  vela(lx + 0.5, 1.61, lz - 0.9, 0.22)
  vela(lx + 0.5, 1.61, lz + 0.9, 0.16)
  peca("cilindro", lx + 0.56, 0.12, lz - 0.4, 0.16, 0.8, 0.16, 0, "#5b3a22", math.pi / 2)
  peca("cilindro", lx + 0.7, 0.12, lz - 0.4, 0.16, 0.8, 0.16, 0, MAD_ESC, math.pi / 2)
  local f = 1 + math.sin(tempo * 9) * 0.1 + math.sin(tempo * 23) * 0.06
  brilho("cone", lx + 0.52, 0.05, lz - 0.28, 0.5, 0.62 * f, 0.5, FOGO, 1.2)
  brilho("cone", lx + 0.52, 0.05, lz + 0.28, 0.46, 0.5 / f, 0.46, "#ff9a30", 1.2)
  brilho("cone", lx + 0.56, 0.05, lz, 0.42, 0.8 * f, 0.42, ALARANJADO, 1.3)
  grupo("lenha")
  -- lenha empilhada contra a parede, entre a lareira e a janela
  for i, d in ipairs({ { -0.22, 0.09 }, { 0.22, 0.09 }, { 0, 0.3 } }) do
    peca("cilindro", -6.05 + d[1], d[2], -1.95, 0.22, 0.9, 0.22, 0, i == 3 and "#6b4427" or "#5b3a22", math.pi / 2)
  end

  -- tapetes do salão (ficam fora das tábuas gastas do corredor)
  grupo("tapete1")
  tapete(-3.6, 0.3, 4.6, 1.9)
  grupo("tapete2")
  if J.num_mesas() >= 5 then tapete(0.3, 3.4, 4.4, 1.9) end

  -- quadro de missões: cada papel some quando alguém o pega
  grupo("quadro")
  local qx = -2.6
  caixa(qx, 1.45, -4.42, 2.6, 1.7, 0.1, MAD_ESC)
  caixa(qx, 1.55, -4.36, 2.3, 1.5, 0.05, "#a87e4f")
  caixa(qx, 3.15, -4.3, 2.9, 0.12, 0.34, MAD_ESC)
  if J.prateleira_aberta() then
    local indo = 0
    for _, p in ipairs(J.pessoas) do
      if p.estado == "indo_quadro" or (p.estado == "pegando" and not p.com_papel) then indo = indo + 1 end
    end
    local n = util.limitar(J.vagas_missao() - J.missoes_comuns_ativas() + indo, 2, 8)
    local tortos = { 0.07, -0.05, 0.09, -0.07, -0.06, 0.05, -0.09, 0.06 }
    for i = 1, n do
      local coluna, linha = (i - 1) % 4, math.floor((i - 1) / 4)
      local x, y = qx - 0.84 + coluna * 0.56, 2.53 - linha * 0.68 + (i % 2) * 0.04
      peca("caixa", x, y, -4.32, 0.44, 0.56, 0.02, 0, PERGAMINHO, 0, tortos[i])
      peca("caixa", x, y + 0.2, -4.305, 0.44, 0.1, 0.02, 0, RANKS[(i - 1) % #RANKS + 1], 0, tortos[i])
    end
  end

  -- balcão, prateleira e fogão do cozinheiro
  grupo("balcao")
  local bx, bz = 3.05, -2.2
  caixa(bx, 0, bz, 5.2, 1.05, 0.72, MAD_MED)
  caixa(bx, 0, bz + 0.02, 5.3, 0.14, 0.76, MAD_ESC)
  for k = -2, 2 do caixa(bx + k, 0.24, bz + 0.37, 0.72, 0.62, 0.04, MAD_ESC) end
  caixa(bx, 1.05, bz + 0.05, 5.5, 0.12, 0.95, TAMPO)
  -- barrilete com torneira e canecas: a cor do balcão é o âmbar
  grupo("barrilete")
  cilindro(bx + 1.9, 1.17, bz - 0.1, 0.5, 0.6, MAD_MED)
  caixa(bx + 1.9, 1.4, bz + 0.17, 0.08, 0.08, 0.16, FERRO)
  for i, x in ipairs({ bx - 2.0, bx + 1.1 }) do
    grupo("caneca" .. i)
    cilindro(x, 1.17, bz + 0.22, 0.16, 0.2, AMBAR)
    cilindro(x, 1.37, bz + 0.22, 0.18, 0.05, ESPUMA)
  end
  grupo("prateleira")
  caixa(bx, 2.1, -4.32, 5.4, 0.1, 0.5, MAD_ESC)
  caixa(bx, 1.25, -4.32, 5.4, 0.1, 0.5, MAD_ESC)
  local garrafas = { "#3f8d4f", "#a13b3b", "#3c68a8", "#d0a23e", "#7a4a9c", "#3f8d4f", "#a13b3b", "#d0a23e" }
  for i, c in ipairs(garrafas) do
    grupo("garrafa" .. i)
    local gx = bx - 2.4 + (i - 1) * 0.68
    local y = i % 2 == 0 and 2.2 or 1.35
    cilindro(gx, y, -4.3, 0.24, 0.42, c)
    cilindro(gx, y + 0.42, -4.3, 0.1, 0.2, c)
  end
  grupo("fogao")
  if J.ef("cozinheiro") > 0 then
    caixa(0.95, 0, -3.55, 1.1, 0.95, 0.9, "#55504c")
    brilho("caixa", 0.95, 0.96, -3.55, 0.8, 0.03, 0.6, "#ff7a24", 1.0)
    cilindro(0.95, 0.98, -3.55, 0.52, 0.36, "#3a3a40")
  end

  for i, b in ipairs({ { 5.6, -3.7, 1 }, { 4.75, -3.8, 1 }, { 5.75, -2.9, 0.9 }, { -5.6, 3.9, 0.9 }, { -4.8, 4.1, 0.8 } }) do
    grupo("barril" .. i)
    barril(b[1], b[2], b[3])
  end
  grupo("carga")
  carga(5.85, 4.1)

  -- quartos: escada e porta no fundo
  grupo("quartos")
  if J.nivel("quartos") > 0 then
    for i = 0, 5 do caixa(-5.2 + i * 0.22, 0, -3.9, 0.3, 0.24 + i * 0.24, 0.8, "#6a4426") end
    caixa(-4.0, 1.5, -4.46, 1.0, 1.9, 0.08, "#3a2415")
  end

  grupo(nil)
  -- decoração: flâmulas na parede
  local d = math.min(J.nivel("decoracao") + (J.nivel("conforto") > 0 and 1 or 0), 5)
  for i = 1, d do
    local x = -5.5 + (i - 1) * 3 + 1.5
    -- a última flâmula fica na ala leste: só aparece quando a parede dela existe
    if x < 6.5 or M.anim.leste > 0.9 or L.tamanho.dir >= 3 then
      grupo("flamula" .. i)
      local pano = guilda and AZUL_GUILDA or (i % 2 == 0 and "#3d5a8a" or TAPETE)
      x = -4 + (i - 1) * 3
      caixa(x, 2.4, -4.4, 0.7, 1.1, 0.04, pano)
      caixa(x, 3.4, -4.37, 0.7, 0.08, 0.04, OURO)
      peca("caixa", x, 2.4, -4.4, 0.5, 0.5, 0.04, 0, pano, 0, math.pi / 4)
    end
  end

  -- lampiões
  for i, x in ipairs({ -4.5, -0.6 }) do
    grupo("lampiao" .. i)
    caixa(x, 2.6, -4.4, 0.08, 0.08, 0.3, FERRO)
    brilho("esfera", x, 2.48, -4.2, 0.24, 0.32, 0.24, VELA, 1.6)
  end

  for i = 1, math.min(J.num_mesas(), 6) do
    local m = J.POS_MESAS[i]
    grupo(m.id)
    mesa(m.bx, m.bz)
    banquinho(m.bx - 1.25, m.bz)
    banquinho(m.bx + 1.25, m.bz)
    grupo("vela" .. i)
    vela(m.bx, 0.82, m.bz + 0.001)
  end
  grupo("balcao")
  if J.ef("balcao") > 0 then
    for _, x in ipairs(J.BANCOS_BALCAO) do banquinho(x, -1.42) end
  end
  grupo(nil)
end

local function ala_leste(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local function c2(x, y, z, ex, ey, ez, c) caixa(x, y * o, z, ex, ey * o, ez, c) end
  local _, xb, za, zb = L.salao()
  piso(xb, xb + 5.5, za, zb, "#7a5a3a", "#715335", o, "#8c6a46")
  caixa(xb + 2.75, -0.95, (za + zb) / 2, 5.7, 0.65, zb - za + 0.7, "#2a1b12")
  c2(xb + 2.75, 0, za - 0.2, 5.5, 4.2, 0.4, PAREDE)
  for x = xb + 1, xb + 5.5, 3 do c2(x, 0, za + 0.05, 0.26, 4.2, 0.2, VIGA) end

  if J.mercadinho_aberto() then
    grupo("barraca")
    local mx, mz = 9.3, -2.2
    for _, d in ipairs({ { -2.1, -0.65, 2.7 }, { 2.1, -0.65, 2.7 }, { -2.1, 0.7, 2.3 }, { 2.1, 0.7, 2.3 } }) do
      c2(mx + d[1], 0, mz + d[2], 0.18, d[3], 0.18, MAD_ESC)
    end
    c2(mx, 0, mz + 0.4, 4.2, 0.95, 0.8, MAD_MED)
    c2(mx, 0.95, mz + 0.4, 4.4, 0.1, 0.95, TAMPO)
    for i = 0, 5 do
      local tx, tc = mx - 1.95 + i * 0.78, i % 2 == 0 and "#b5403a" or "#efe2c4"
      peca("caixa", tx, 2.6 * o, mz, 0.8, 0.1, 2, 0, tc, 0.3)
      c2(tx, 2.1, mz + 0.95, 0.8, 0.18, 0.05, tc)
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
    grupo("estantes")
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

  grupo("carga_leste")
  if e > 0.9 then carga(11.5, -0.4) end

  for i = 7, math.min(J.num_mesas(), 8) do
    local m = J.POS_MESAS[i]
    grupo(m.id)
    mesa(m.bx, m.bz)
    banquinho(m.bx - 1.25, m.bz)
    banquinho(m.bx + 1.25, m.bz)
    grupo("vela" .. i)
    vela(m.bx, 0.82, m.bz + 0.001)
  end
  grupo(nil)
end

local function jardim(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  caixa(-3, -0.95, 6.75, 7.2, 0.65, 4.1, "#2a1b12")
  caixa(-3, -0.3, 6.75, 7, 0.3 * o, 3.9, "#4f7a3a")
  -- cerca
  grupo("cerca")
  for x = -6.3, 0.5, 1.1 do caixa(x, 0, 8.55, 0.12, 0.7 * o, 0.12, MAD_MED) end
  caixa(-3, 0.5 * o, 8.55, 7, 0.08, 0.05, TAMPO)
  caixa(-3, 0.2 * o, 8.55, 7, 0.08, 0.05, TAMPO)
  -- moitas e abóboras na faixa livre diante da cerca
  if e > 0.9 then
    grupo("moita1")
    peca("esfera", -5.9, 0.22, 8.05, 0.62, 0.48, 0.62, 0, "#3f6b34")
    grupo("moita2")
    peca("esfera", -5.3, 0.18, 8.1, 0.46, 0.36, 0.46, 0, "#86b552")
    grupo("moita3")
    peca("esfera", -0.3, 0.22, 8.05, 0.62, 0.48, 0.62, 0, "#3f6b34")
    grupo("abobora1")
    peca("esfera", -3.6, 0.15, 8.1, 0.36, 0.3, 0.36, 0, "#e08a3c")
    grupo("abobora2")
    peca("esfera", -3.1, 0.15, 8.0, 0.42, 0.32, 0.42, 0, "#e08a3c")
  end
  -- canteiros
  grupo("canteiros")
  local n = J.ef("canteiros")
  local cresce = J.estado.ciclo / J.ciclo_jardim()
  for i = 1, n do
    local col, lin = (i - 1) % 5, math.floor((i - 1) / 5)
    local x, z = -5.7 + col * 1.25, 5.6 + lin * 1.45
    caixa(x, 0, z, 1.0, 0.14, 1.1, "#5a3d26")
    for k = -1, 1, 1 do
      local a = 0.2 + cresce * 0.6
      peca("cone", x + k * 0.3, 0.12, z, 0.26, a, 0.26, 0, i % 3 == 0 and "#c9a24a" or "#5a8f42")
      if cresce > 0.7 then peca("esfera", x + k * 0.3, 0.12 + a * 0.6, z + 0.1, 0.12, 0.12, 0.12, 0, i % 3 == 0 and "#e8c04a" or "#d9534a") end
    end
  end
  -- fazendeiro: anda entre os canteiros e cuida de um de cada vez
  if J.ef("fazendeiro") > 0 and n > 0 then
    local f = M.fazendeiro
    local col, lin = (f.i - 1) % 5, math.floor((f.i - 1) / 5)
    local ax, az = -5.7 + col * 1.25, 5.6 + lin * 1.45 + 0.75
    local dx, dz = ax - f.x, az - f.z
    local d = math.sqrt(dx * dx + dz * dz)
    local andando = d > 0.1
    if andando then
      f.x, f.z = f.x + dx / d * M.dt_cena * 1.6, f.z + dz / d * M.dt_cena * 1.6
      f.giro, f.fase = math.atan(dx, dz), f.fase + M.dt_cena
    else
      f.giro = math.pi
      f.t = f.t + M.dt_cena
      if f.t > 2.5 then
        f.t = 0
        f.i = f.i % n + 1
      end
    end
    M.boneco({ x = f.x, z = f.z, giro = f.giro, fase = f.fase, andando = andando, pele = "#c68a5a", chapeu = "#c9a24a",
      tipo = { nome = "comum", corpo = "#5f7a3a", perna = "#4b3b2c", braco = "#54702f" } })
    -- enxada
    local mexe = andando and 0 or math.sin(M.tempo * 6) * 0.25
    peca("caixa", f.x + 0.42 * math.cos(f.giro), 0.75, f.z - 0.42 * math.sin(f.giro), 0.06, 1.3, 0.06, f.giro, "#7b4a26", mexe)
  end
end

local function cervejaria(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  caixa(3.5, -0.95, 6.75, 6.2, 0.65, 4.1, "#2a1b12")
  caixa(3.5, -0.3, 6.75, 6, 0.3 * o, 3.9, PEDRA)
  -- tina de cobre com domo, cano e fogo embaixo
  local tx, tz = 1.9, 6.2
  grupo("tina")
  cilindro(tx, 0, tz, 1.5, 0.16 * o, FERRO)
  cilindro(tx, 0.16 * o, tz, 1.3, 1.1 * o, COBRE)
  cilindro(tx, 0.35 * o, tz, 1.34, 0.07, FERRO)
  cilindro(tx, 0.95 * o, tz, 1.34, 0.07, FERRO)
  peca("esfera", tx, 1.26 * o, tz, 1.3, 0.7 * o, 1.3, 0, COBRE_CLARO)
  cilindro(tx, 1.5 * o, tz, 0.22, 0.6 * o, COBRE)
  caixa(tx + 0.6, 2.05 * o, tz, 1.3, 0.14, 0.14, COBRE)
  cilindro(tx + 1.25, 0.9 * o, tz, 0.14, 1.25 * o, COBRE)
  brilho("caixa", tx, 0.12, tz + 0.72, 0.5, 0.2, 0.12, "#ffb347", 1.3)
  -- barril que recebe o cano
  grupo("barril_grande")
  cilindro(3.5, 0, tz, 1.1 * o, 1.2 * o, MAD_MED)
  cilindro(3.5, 0.2, tz, 1.14, 0.08, FERRO)
  cilindro(3.5, 0.9, tz, 1.14, 0.08, FERRO)
  for i = 0, 2 do
    grupo("barril_c" .. (i + 1))
    barril(4.8 + i * 0.75, 7.6, 0.9 * o)
  end
  grupo("bancada")
  caixa(2.7, 0, 7.8, 2.0, 0.85 * o, 0.7, MAD_MED)
  caixa(2.7, 0.85 * o, 7.8, 2.1, 0.08, 0.78, TAMPO)
  -- sacos de malte
  grupo("malte1")
  peca("esfera", 5.5, 0.26, 5.6, 0.6, 0.52, 0.6, 0, "#c9b58b")
  grupo("malte2")
  peca("esfera", 6.05, 0.22, 5.75, 0.5, 0.44, 0.5, 0, "#a8946c")
  -- cervejeiro: aparece junto com a cervejaria e vai da tina à bancada
  grupo("cervejaria")
  local c = (math.sin(M.tempo * 0.5) + 1) / 2
  local bx, bz = 2.7 + c * 1.6, 7.05
  local d = math.cos(M.tempo * 0.5)
  M.boneco({ x = bx, z = bz, giro = math.abs(d) > 0.2 and (d > 0 and math.pi / 2 or -math.pi / 2) or math.pi, fase = M.tempo,
    andando = math.abs(d) > 0.2, pele = "#e0ac7e", chapeu = "#7a3a3a",
    tipo = { nome = "comum", corpo = "#8a5a33", perna = "#3f2f22", braco = "#7b4f2c" } })
  -- o avental vira junto com ele
  local gc = math.abs(d) > 0.2 and (d > 0 and math.pi / 2 or -math.pi / 2) or math.pi
  caixa(bx + math.sin(gc) * 0.26, 0.45, bz + math.cos(gc) * 0.26, 0.42, 0.5, 0.03, "#efe2c4", gc)
end

local function circulo(e)
  if e <= 0 then return end
  local t = M.tempo
  caixa(9.25, -0.95, 6.75, 5.7, 0.65, 4.1, "#2a1b12")
  caixa(9.25, -0.3, 6.75, 5.5, 0.3 * e, 3.9, "#39344e")
  local cx, cz = 9.25, 6.75
  cilindro(cx, 0, cz, 3.7, 0.08, PEDRA_ESC)
  peca("cilindro", cx, 0.07, cz, 3.3, 0.03, 3.3, 0, VIOLETA, 0, 0, 1.2)
  cilindro(cx, 0.09, cz, 3.0, 0.03, FUNDO_MAGIA)
  -- hexagrama girando devagar
  for k = 0, 5 do
    local a = k * math.pi / 3 + t * 0.3
    peca("caixa", cx + 0.65 * math.cos(a), 0.13, cz + 0.65 * math.sin(a), 0.08, 0.02, 2.25, -a, CIANO, 0, 0, 1.3)
  end
  for i = 0, 3 do
    local a = t * 0.6 + i * math.pi / 2
    brilho("esfera", cx + math.cos(a) * 1.55, 0.5 + math.sin(t * 2 + i) * 0.1, cz + math.sin(a) * 1.55, 0.2, 0.2, 0.2, "#c9a7ff", 1.6)
  end
  for i = 0, 3 do
    local a = i * math.pi / 2 + math.pi / 4
    -- pilares de pedra com cristal aceso
    grupo("pilar" .. (i + 1))
    local px, pz = cx + math.cos(a) * 2.35, cz + math.sin(a) * 1.75
    caixa(px, 0, pz, 0.36, 0.3 * e, 0.36, PEDRA)
    peca("cone", px, 0.3 * e, pz, 0.3, 0.5 * e, 0.3, 0, CIANO, 0, 0, 1.3)
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
  if b.estado == "menestrel_canta" then y0 = y0 + math.abs(math.sin(M.tempo * 5)) * 0.1 end
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
  if b.menestrel then
    -- alaúde nas mãos; quando canta, balança o corpo
    p("caixa", 0.3, y0 + by + 0.02, 0.2, 0.14, 0.15, 0.44, t.braco)
    p("esfera", 0.12, y0 + by - 0.1, 0.36, 0.38, 0.5, 0.14, "#b5763a")
    p("caixa", 0.42, y0 + by + 0.16, 0.36, 0.5, 0.06, 0.06, "#6f4326", 0, 0.5)
    p("cilindro", 0, y0 + topo + 0.5, 0, 0.1, 0.5, 0.1, "#c9413a", 0, -0.7)
  elseif b.estado == "pegando" then
    -- estica o braço até o quadro e puxa o papel
    local alto = util.limitar(b.t / 0.5, 0, 1) * (1 - util.limitar((b.t - 0.75) / 0.4, 0, 0.6))
    local ay = y0 + by + 0.06 + alto * 0.62
    p("caixa", 0.3, ay, 0.16, 0.14, 0.15 + alto * 0.42, 0.15, t.braco, 0.5)
    if b.com_papel then
      p("caixa", 0.3, ay + 0.16, 0.26, 0.3, 0.38, 0.02, "#f0e4c8", 0, 0.08)
      p("caixa", 0.3, ay + 0.3, 0.27, 0.3, 0.08, 0.02, "#d9534a", 0, 0.08)
    end
  elseif b.com_papel then
    -- leva o papel erguido à frente, para ler a missão
    p("caixa", 0.3, y0 + by + 0.02, 0.2, 0.14, 0.15, 0.44, t.braco)
    p("caixa", 0.3, y0 + by + 0.02, 0.48, 0.3, 0.38, 0.02, "#f0e4c8", -0.2)
    p("caixa", 0.3, y0 + by + 0.16, 0.5, 0.3, 0.08, 0.02, "#d9534a", -0.2)
  elseif b.leva_espolio then
    -- volta com um saco de espólios nas costas
    p("caixa", 0.36, y0 + by - 0.2, bs * 0.28, 0.14, 0.44, 0.15, t.braco, -bs)
    p("esfera", 0, y0 + pernas + 0.42, -0.34, 0.5, 0.56, 0.42, "#b59463")
  elseif b.bebendo then
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
  grupo("cozinheiro")
  if J.ef("cozinheiro") > 0 then
    local x = 0.95 + math.sin(M.tempo * 0.8) * 0.15
    M.boneco({ x = x, z = -2.75, giro = math.pi, fase = 0, pele = "#e0ac7e", tipo = T_COZINHEIRO, chapeu = "#f4f4f0" })
    cilindro(x, 2.08, -2.75, 0.42, 0.24, "#f4f4f0")
  end
  grupo("bardo")
  if J.ef("bardo") > 0 then
    local b = math.sin(M.tempo * 5) * 0.03
    M.boneco({ x = -5.1, z = -1.25, y = b + 0.03, giro = 0.9, fase = 0, pele = "#c68a5a", tipo = T_BARDO, chapeu = "#3e5a4b" })
    peca("esfera", -4.85, 0.8, -1.0, 0.3, 0.42, 0.14, 0.9, "#a5703f")
    peca("caixa", -4.62, 1.02, -0.86, 0.06, 0.5, 0.06, 0.9, "#6f4326", 0, -1.0)
  end
  grupo(nil)
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
  grupo(nil)
  M.aplicar_camera()
  local t = M.tempo
  local f = 1 + math.sin(t * 9) * 0.1 + math.sin(t * 23) * 0.07
  local fx, fz = L.t("lareira", -5.3, -3.2)
  motor.cena_luz(1, fx, 1.1, fz, 2.1 * f, 1.0 * f, 0.36 * f, 7.5)
  local lmx, lmz = L.t("lampiao2", -0.6, -3.0)
  motor.cena_luz(2, lmx, 2.6, lmz, 1.15, 0.8, 0.42, 8)
  motor.cena_luz(3, 3.0, 2.4, -3.0, 0.75, 0.5, 0.26, 5.5)
  local c = a.circulo
  if c > 0 then
    local cirx, cirz = L.t("circulo", 9.25, 6.75)
    motor.cena_luz(4, cirx, 1.2, cirz, 0.9 * c, 0.6 * c, 1.5 * c, 6)
  else
    local l = a.leste
    local brx, brz = L.t("barraca", 9.3, -1.4)
    motor.cena_luz(4, brx, 2.2, brz, 0.95 * l, 0.66 * l, 0.36 * l, 6.5)
  end

  salao()
  ala_leste(a.leste)
  grupo("jardim")
  jardim(a.jardim)
  grupo("cervejaria")
  cervejaria(a.cerveja)
  grupo("circulo")
  circulo(a.circulo)
  grupo(nil)

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
        grupo("circulo")
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
    if p.estado == "menestrel_canta" then
      local x, y = M.posicao_balao(p)
      if x then
        y = y - math.abs(math.sin(M.tempo * 4)) * 5
        motor.circulo(x - 5, y + 6, 4.5, "#fff6e6")
        motor.linha(x - 1, y + 6, x - 1, y - 9, 2.5, "#fff6e6")
        motor.linha(x - 1, y - 9, x + 7, y - 5, 2.5, "#fff6e6")
      end
    end
    if p.estado == "indo_quadro" then
      -- mostra que está indo atrás de uma missão
      local x, y = M.posicao_balao(p)
      if x then
        y = y + math.sin(M.tempo * 4 + p.fase) * 2
        local q = 15 * e
        motor.retangulo(x - q, y - q, q * 2, q * 2, "#fff6e6", 7 * e)
        motor.triangulo(x - 5 * e, y + q - 1, x + 5 * e, y + q - 1, x, y + q + 5 * e, "#fff6e6")
        motor.retangulo(x - 7 * e, y - 9 * e, 14 * e, 18 * e, "#e6d3a8", 2)
        motor.retangulo(x - 7 * e, y - 9 * e, 14 * e, 4 * e, cor.vermelho, 2)
      end
    end
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
