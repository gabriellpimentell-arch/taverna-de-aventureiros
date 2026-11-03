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
  if L.oculto(id) then G = { oculto = true } return end
  local o = L.POR_ID[id]
  local x, z = L.desloc(id)
  local y, g = L.altura(id), L.giro(id)
  if x == 0 and z == 0 and y == 0 and g == 0 then G = nil return end
  G = { px = o.x, pz = o.z, x = x, z = z, y = y, g = g, co = math.cos(g), si = math.sin(g) }
end
M.grupo = grupo

local function peca(f, x, y, z, ex, ey, ez, giro, c, rx, rz, b)
  if G and G.oculto then return end
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
local function esfera(x, y, z, d, c, ey) peca("esfera", x, y, z, d, ey or d, d, 0, c) end

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
  M.cozinheiro = nil
  M.vacas = {}
  M.anim = { leste = 0, jardim = 0, cerveja = 0, circulo = 0, cozinha = 0, pomar = 0, fazenda = 0 }
  local a = M.alvos()
  for k, v in pairs(a) do M.anim[k] = v end
  M.quadro = M.calcular_enquadramento(M.anim)
end

function M.alvos()
  local function aberta(id) return L.aberta(id) and 1 or 0 end
  return {
    leste = L.leste_aberta() and 1 or 0,
    jardim = aberta("jardim"),
    cerveja = aberta("cervejaria"),
    circulo = aberta("circulo"),
    cozinha = aberta("cozinha"),
    pomar = aberta("pomar"),
    fazenda = aberta("fazenda"),
  }
end

-- a câmera recua conforme as áreas abrem, para sempre caber tudo
function M.calcular_enquadramento(a)
  local xa, xb, za, zb = L.salao()
  local xmin, zmin = xa - 0.4, za - 0.4
  local xmax = xb + util.lerp(0.2, 5.7, a.leste)
  local zmax = zb + 0.2
  -- cada sala aberta entra no quadro com o tamanho e a posição que tem agora
  for id, k in pairs({ jardim = a.jardim, pomar = a.pomar, fazenda = a.fazenda, cozinha = a.cozinha, cervejaria = a.cerveja, circulo = a.circulo }) do
    local _, sx, _, sz = L.sala_mundo(id)
    xmax = math.max(xmax, util.lerp(xb + 0.2, sx + 0.2, k))
    zmax = math.max(zmax, util.lerp(zb + 0.2, sz + 0.6, k))
  end
  local cx, cz = (xmin + xmax) / 2, (zmin + zmax) / 2
  -- a fileira de salas é larga e rasa: aproveita melhor a tela do que o salão sozinho
  local w = xmax - xmin
  local escala = math.max(w / (13.6 + 0.13 * math.max(0, w - 14)), (zmax - zmin) / 9.8)
  return { x = cx, z = cz, escala = escala, largura = xmax - xmin, fundo = zmax - zmin }
end

function M.atualizar(dt)
  M.tempo = M.tempo + dt
  M.dt_cena = dt
  -- a porta só acompanha quem passa: abre e fecha em 0,25 s
  local alvo_porta = J.alguem_na_porta() and 1 or 0
  M.porta_aberta = util.limitar((M.porta_aberta or 0) + (alvo_porta > 0 and dt or -dt) / 0.25, 0, 1)
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
  M.mover_cozinheiro(dt)
  M.mover_vacas(dt)
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

local CIRC_X, CIRC_Z = 25.95, 0.1   -- centro de origem do círculo de invocação
local PORTA_GIRO = 1.75   -- pouco mais de 90 graus: as folhas abertas não escondem quem passa

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
  -- cada folha gira na própria dobradiça, para dentro do salão
  local abre = M.porta_aberta or 0
  local ang = abre * abre * (3 - 2 * abre) * PORTA_GIRO
  local si, co = math.sin(ang), math.cos(ang)
  caixa(-6.4 + 0.33 * si, 0, pz - 0.7 + 0.33 * co, 0.06, 2.42, 0.66, MAD_ESC, ang)
  caixa(-6.4 + 0.33 * si, 0, pz + 0.7 - 0.33 * co, 0.06, 2.42, 0.66, MAD_MED, -ang)
  caixa(-6.4 + 0.5 * si + 0.05 * co, 1.0, pz + 0.7 - 0.5 * co + 0.05 * si, 0.06, 0.14, 0.14, OURO, -ang)
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

-- Cômodos ------------------------------------------------------------------------------

local ALT_PAREDE = 4.2     -- igual à do salão: todas as paredes da taverna têm esta altura
local ESP_PAREDE = 0.4
local ALT_PORTA, LARG_PORTA = 2.5, 1.4

-- piso em lajes sobre a base; as lajes crescem com a sala para não pesar no desenho
local function lajes(x0, x1, z0, z1, c1, c2, o)
  local w, d = x1 - x0, z1 - z0
  caixa((x0 + x1) / 2, -0.95, (z0 + z1) / 2, w + 0.2, 0.65, d + 0.2, "#2a1b12")
  local t = math.max(0.95, math.max(w, d) / 14)
  local nx, nz = math.max(1, math.floor(w / t + 0.5)), math.max(1, math.floor(d / t + 0.5))
  local sx, sz = w / nx, d / nz
  for i = 0, nx - 1 do
    for k = 0, nz - 1 do
      caixa(x0 + (i + 0.5) * sx, -0.3, z0 + (k + 0.5) * sz, sx - 0.03, 0.3 * o, sz - 0.03, (i + k) % 2 == 0 and c1 or c2)
    end
  end
end

-- a porta fica sobre o salão (ou a ala leste) mesmo quando as salas vizinhas crescem e empurram esta
local function porta_x(id, desejado, x0, x1, l)
  local dx = L.desloc(id)
  local xa, xb = L.salao()
  if M.anim.leste > 0.5 then xb = xb + 5.5 end
  local a = math.max(x0 + 0.4, xa - dx + 0.3) + l / 2
  local b = math.min(x1 - 0.4, xb - dx - 0.3) - l / 2
  if a > b then return desejado end
  return util.limitar(desejado, a, b)
end

-- Sala interna, em corte de casa de bonecas como o salão: parede de fundo e parede esquerda
-- com porta para a sala vizinha; sem parede de frente nem direita.
local function casca_sala(x0, x1, z0, z1, o, c)
  local cx, w = (x0 + x1) / 2, x1 - x0
  local h, e = ALT_PAREDE * o, ESP_PAREDE
  lajes(x0, x1, z0, z1, c.piso1, c.piso2, o)
  -- fundo
  caixa(cx, 0, z0 - e / 2, w, h, e, c.parede)
  caixa(cx, 0, z0 + 0.02, w, 0.75 * o, 0.08, c.rodape)
  for x = x0 + 1.5, x1 - 0.2, 3 do caixa(x, 0, z0 + 0.05, 0.26, h, 0.2, c.viga) end
  caixa(cx, 3.75 * o, z0 + 0.08, w, 0.26, 0.2, c.viga)
  -- esquerda: porta sempre na mesma altura da sala, longe do fundo onde ficam as coisas altas
  local d = z1 - z0
  local zm = z0 + util.limitar(d * 0.55, LARG_PORTA / 2 + 0.3, d - LARG_PORTA / 2 - 0.3)
  local xp = x0 + e / 2
  local za, zb = zm - LARG_PORTA / 2, zm + LARG_PORTA / 2
  caixa(xp, 0, (z0 - e + za) / 2, e, h, za - z0 + e, c.parede_lado)
  caixa(xp, 0, (zb + z1) / 2, e, h, z1 - zb, c.parede_lado)
  caixa(xp, ALT_PORTA * o, zm, e, (ALT_PAREDE - ALT_PORTA) * o, LARG_PORTA, c.parede_lado)
  for z = z0 + 1.5, z1 - 0.2, 2.5 do
    if math.abs(z - zm) > LARG_PORTA / 2 + 0.2 then caixa(x0 + e + 0.05, 0, z, 0.2, h, 0.26, c.viga) end
  end
  caixa(x0 + e + 0.08, 3.75 * o, (z0 + z1) / 2, 0.2, 0.26, d, c.viga)
  caixa(x0 + e + 0.02, 0, (z0 + z1) / 2, 0.08, 0.75 * o, d, c.rodape)
  -- batentes, verga, soleira e folha aberta para dentro da sala
  caixa(xp, 0, zm, e + 0.1, 0.04, LARG_PORTA, c.rodape)
  for s = -1, 1, 2 do caixa(x0 + e + 0.04, 0, zm + s * (LARG_PORTA / 2 + 0.06), 0.12, ALT_PORTA * o, 0.12, c.viga) end
  caixa(x0 + e + 0.04, ALT_PORTA * o, zm, 0.12, 0.16, LARG_PORTA + 0.24, c.viga)
  local ang, lf = 1.2, LARG_PORTA - 0.05
  local si, co = math.sin(ang), math.cos(ang)
  local hx = x0 + e + 0.03
  caixa(hx + lf / 2 * si, 0.02, za + 0.02 + lf / 2 * co, 0.06, (ALT_PORTA - 0.08) * o, lf, c.folha, ang)
  caixa(hx + lf * 0.85 * si + 0.05 * co, 1.0 * o, za + lf * 0.85 * co, 0.08, 0.14, 0.14, c.acento, ang)
end

local function cerca_trecho(x0, z0, x1, z1, o)
  local em_x = x1 - x0 >= z1 - z0
  local comp = em_x and x1 - x0 or z1 - z0
  local n = math.max(1, math.floor(comp / 1.1 + 0.5))
  for i = 0, n do
    local p = i / n * comp
    caixa(em_x and x0 + p or x0, 0, em_x and z0 or z0 + p, 0.12, 0.7 * o, 0.12, MAD_MED)
  end
  for _, y in ipairs({ 0.2, 0.5 }) do
    caixa((x0 + x1) / 2, y * o, (z0 + z1) / 2, em_x and comp or 0.05, 0.08, em_x and 0.05 or comp, TAMPO)
  end
end

-- Porteira aberta na cerca do fundo, que dá para a frente da taverna, e caminho de pedras
local function porteira(xd, z, l, o)
  for s = -1, 1, 2 do caixa(xd + s * (l / 2 + 0.08), 0, z, 0.16, 0.95 * o, 0.16, MAD_ESC) end
  local hx = xd - l / 2
  for _, y in ipairs({ 0.22, 0.56 }) do caixa(hx + 0.08, y * o, z + l / 2, 0.06, 0.1, l, TAMPO) end
  caixa(hx + 0.08, 0, z + l, 0.1, 0.72 * o, 0.1, MAD_ESC)
  -- soleira de pedra emendando no piso do salão, depois as pedras pela grama
  caixa(xd, 0, z - 0.1, l + 0.2, 0.05, 0.4, PEDRA)
  local pz, i = z + 0.45, 0
  while i < 5 do
    cilindro(xd + (i % 2 == 0 and 0.08 or -0.1), 0, pz, 0.48 + (i % 3) * 0.04, 0.03, i % 2 == 0 and PEDRA_CLARA or "#8f8a7e")
    pz, i = pz + 0.55, i + 1
  end
end

-- Área ao ar livre: grama, cerca baixa nos quatro lados e porteira no lado da taverna
local function area_externa(id, x0, x1, z0, z1, o, g1, g2, gc)
  lajes(x0, x1, z0, z1, g1, g2, o)
  if o > 0.9 then
    -- tufos soltos, sempre nos mesmos lugares
    local w, d = x1 - x0, z1 - z0
    for k = 1, math.floor(w * d * 0.35) do
      cone(x0 + 0.3 + (k * 37 % 97) / 97 * (w - 0.6), 0, z0 + 0.5 + (k * 61 % 89) / 89 * (d - 0.9), 0.12, 0.17, gc)
    end
  end
  local l = 1.3
  local xd = porta_x(id, x0 + math.min(2, (x1 - x0) / 2), x0, x1, l)
  local zf = z0 + 0.15
  cerca_trecho(x0 + 0.12, zf, xd - l / 2 - 0.08, zf, o)
  cerca_trecho(xd + l / 2 + 0.08, zf, x1 - 0.12, zf, o)
  cerca_trecho(x0 + 0.12, z1 - 0.15, x1 - 0.12, z1 - 0.15, o)
  cerca_trecho(x0 + 0.12, zf, x0 + 0.12, z1 - 0.15, o)
  cerca_trecho(x1 - 0.12, zf, x1 - 0.12, z1 - 0.15, o)
  porteira(xd, zf, l, o)
  return xd
end

local function jardim(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local x0, x1, z0, z1 = L.sala("jardim")
  -- lado de fora: grama, cerca baixa e porteira, sem parede
  lajes(x0, x1, z0, z1, "#5b8f44", "#558a40", o)
  local l = 1.3
  local xd = porta_x("jardim", x1 - 1.1, x0, x1, l)
  local zf = z0 + 0.15
  if e > 0.9 then
    -- tufos e florzinhas soltas, sempre nos mesmos lugares
    local w, d = x1 - x0, z1 - z0
    for k = 1, math.floor(w * d * 0.6) do
      local tx, tz = x0 + 0.3 + (k * 37 % 97) / 97 * (w - 0.6), z0 + 0.5 + (k * 61 % 89) / 89 * (d - 0.9)
      cone(tx, 0, tz, 0.12, 0.17, "#86b552")
      if k % 3 == 0 then peca("esfera", tx, 0.19, tz, 0.08, 0.08, 0.08, 0, k % 2 == 0 and "#f0e4c8" or "#e8c04a") end
    end
  end
  -- cerca em volta do que é lado de fora
  grupo("cerca")
  cerca_trecho(x0 + 0.12, zf, xd - l / 2 - 0.08, zf, o)
  cerca_trecho(xd + l / 2 + 0.08, zf, x1 - 0.12, zf, o)
  cerca_trecho(x0 + 0.12, z1 - 0.15, x1 - 0.12, z1 - 0.15, o)
  cerca_trecho(x0 + 0.12, zf, x0 + 0.12, z1 - 0.15, o)
  cerca_trecho(x1 - 0.12, zf, x1 - 0.12, z1 - 0.15, o)
  porteira(xd, zf, l, o)
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
    local x, z = -5.7 + col * 1.1, 5.6 + lin * 1.45
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
    local ax, az = -5.7 + col * 1.1, 5.6 + lin * 1.45 + 0.75
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

-- Vaca low poly (olha para +x). `passo` afasta as patas alternadamente: 0 = parada.
-- `pasta` (0 a 1) abaixa a cabeça até o chão.
local function vaca(x, z, giro, passo, pasta)
  giro, passo, pasta = giro or 0, passo or 0, pasta or 0
  local co, si = math.cos(giro), math.sin(giro)
  local function p(f, lx, y, lz, ex, ey, ez, c)
    peca(f, x + lx * co + lz * si, y, z - lx * si + lz * co, ex, ey, ez, giro, c)
  end
  local function cx(lx, y, lz, ex, ey, ez, c) p("caixa", lx, y + ey / 2, lz, ex, ey, ez, c) end
  cx(0, 0.55, 0, 1.2, 0.6, 0.6, "#ece4d4")
  for i, q in ipairs({ { -0.42, -0.2 }, { 0.42, -0.2 }, { -0.42, 0.2 }, { 0.42, 0.2 } }) do
    local anda = (i == 1 or i == 4) and passo or -passo
    cx(q[1] + anda * 0.08, 0, q[2], 0.16, 0.57, 0.16, "#ece4d4")
  end
  cx(-0.2, 0.9, 0, 0.5, 0.27, 0.62, "#3a302b")
  cx(0.3, 0.7, 0, 0.3, 0.47, 0.62, "#3a302b")
  local cab = 0.8 - 0.66 * pasta
  local fr = 0.75 + 0.08 * pasta
  -- pescoço: só aparece quando a cabeça desce e deixaria um vão
  if pasta > 0.05 then cx(0.64, cab + 0.2, 0, 0.3, 0.8 - cab, 0.32, "#ece4d4") end
  cx(fr, cab, 0, 0.4, 0.4, 0.4, "#ece4d4")
  cx(fr + 0.22, cab, 0, 0.12, 0.2, 0.34, "#e8a6a0")
  p("cone", fr, cab + 0.4, -0.14, 0.08, 0.14, 0.08, "#e8dcc0")
  p("cone", fr, cab + 0.4, 0.14, 0.08, 0.14, 0.08, "#e8dcc0")
  cx(-0.63, 0.55, 0, 0.08, 0.55, 0.08, "#3a302b")
end
M.vaca = vaca

-- Só aparência: nada aqui toca em regras, ouro ou tempo de jogo. Sorteio próprio, para
-- não gastar o math.random que o jogo usa.
local function sorte(v)
  v.s = (v.s * 16807) % 2147483647
  return v.s / 2147483647
end

local function editando()
  local E = package.loaded["editor"]
  return E and E.ativo
end

-- gira `a` em direção a `alvo` pelo caminho mais curto, no máximo `passo` radianos
local function virar(a, alvo, passo)
  local d = (alvo - a + math.pi) % (2 * math.pi) - math.pi
  if math.abs(d) <= passo then return alvo, true end
  return a + (d > 0 and passo or -passo), false
end

-- As vacas vivem nas coordenadas de origem da fazenda: assim a cerca, que é um retângulo
-- ali, continua valendo com a fazenda movida ou girada no editor.
local RAIO_VACA = 0.33
local VACA_PONTOS = { 0.72, 0.3, -0.1, -0.42 } -- centros dos círculos do focinho ao rabo
local OBSTACULOS_FAZENDA = { { "celeiro", 2.05, 1.6 }, { "cocho", 0.8, 0.33 }, { "feno", 1.08, 0.33 } }

local function vaca_circulos(x, z, g)
  local co, si = math.cos(g), math.sin(g)
  local r = {}
  for k, d in ipairs(VACA_PONTOS) do r[k] = { x + d * co, z - d * si } end
  return r
end

-- folga da vaca nessa pose até a cerca, os obstáculos e as outras; negativo = encostou
local function vaca_folga(v, x, z, g, limites)
  local cs = vaca_circulos(x, z, g)
  local folga = math.huge
  for _, q in ipairs(cs) do
    folga = math.min(folga, q[1] - limites[1], limites[2] - q[1], q[2] - limites[3], limites[4] - q[2])
  end
  folga = folga - 0.2 - RAIO_VACA
  for _, ob in ipairs(OBSTACULOS_FAZENDA) do
    if not L.oculto(ob[1]) then
      local c = L.POR_ID[ob[1]]
      for _, q in ipairs(cs) do
        local ox, oz = L.base(ob[1], L.t("fazenda", q[1], q[2]))
        local dx = math.max(math.abs(ox - c.x) - ob[2], 0)
        local dz = math.max(math.abs(oz - c.z) - ob[3], 0)
        folga = math.min(folga, math.sqrt(dx * dx + dz * dz) - RAIO_VACA)
      end
    end
  end
  for _, u in pairs(M.vacas) do
    if u ~= v then
      for _, q in ipairs(cs) do
        for _, e in ipairs(vaca_circulos(u.x, u.z, u.g)) do
          local dx, dz = q[1] - e[1], q[2] - e[2]
          folga = math.min(folga, math.sqrt(dx * dx + dz * dz) - 2 * RAIO_VACA - 0.06)
        end
      end
    end
  end
  return folga
end

-- aceita a pose se ela não encosta em nada; quem já começou encostado pode ir se soltando
local function vaca_pode(v, x, z, g, limites)
  local f = vaca_folga(v, x, z, g, limites)
  return f >= 0 or f > vaca_folga(v, v.x, v.z, v.g, limites)
end

local function vaca_casa(i)
  local id = "vaca" .. i
  local o = L.POR_ID[id]
  local wx, wz = L.t(id, o.x, o.z)
  local x, z = L.base("fazenda", wx, wz)
  return x, z, L.VACAS[i][3] + L.giro(id) - L.giro("fazenda")
end

local function vaca_descansa(v, pastando)
  v.est = pastando and "pasta" or "para"
  v.t = pastando and 4 + sorte(v) * 6 or 1 + sorte(v) * 2.5
end

-- só escolhe um passeio que ela consiga fazer inteiro: primeiro a virada, depois o trajeto
local function vaca_trajeto_livre(v, x, z, ag, limites)
  local atual = vaca_folga(v, v.x, v.z, v.g, limites)
  local function livre(px, pz, pg)
    local f = vaca_folga(v, px, pz, pg, limites)
    return f >= 0 or f > atual
  end
  local d = (ag - v.g + math.pi) % (2 * math.pi) - math.pi
  for k = 1, 6 do
    if not livre(v.x, v.z, v.g + d * k / 6) then return false end
  end
  for k = 1, 6 do
    if not livre(v.x + (x - v.x) * k / 6, v.z + (z - v.z) * k / 6, ag) then return false end
  end
  -- termina com alguma sobra: quem para colada na outra não consegue mais virar
  return vaca_folga(v, x, z, ag, limites) >= 0.1
end

-- a casa guardada no layout pode ficar colada na cerca ou em outra vaca: sai para um lugar livre
local function vaca_acha_lugar(v, limites)
  local melhor = vaca_folga(v, v.x, v.z, v.g, limites)
  if melhor >= 0 then return end
  local mx, mz, mg = v.x, v.z, v.g
  for _ = 1, 300 do
    local x = limites[1] + sorte(v) * (limites[2] - limites[1])
    local z = limites[3] + sorte(v) * (limites[4] - limites[3])
    local g = sorte(v) * 2 * math.pi
    local f = vaca_folga(v, x, z, g, limites)
    if f > melhor then melhor, mx, mz, mg = f, x, z, g end
    if f >= 0.15 then break end
  end
  v.x, v.z, v.g = mx, mz, mg
end

local function vaca_escolhe_destino(v, limites)
  -- com a fazenda cheia virar é difícil: tenta seguir quase reto, dar uns passos de ré,
  -- virar só um pouco no lugar e, por último, ir para qualquer lado
  for tentativa = 1, 20 do
    local g, x, z = v.g, v.x, v.z
    if tentativa <= 6 then
      g = v.g + (sorte(v) - 0.5) * 1.2
      local d = 0.6 + sorte(v) * 1.8
      x, z = v.x + math.cos(g) * d, v.z - math.sin(g) * d
    elseif tentativa <= 10 then
      local d = 0.4 + sorte(v) * 0.7
      x, z = v.x - math.cos(g) * d, v.z + math.sin(g) * d
    elseif tentativa <= 15 then
      g = v.g + (sorte(v) - 0.5) * 1.8
    else
      g = v.g + (sorte(v) - 0.5) * 2 * math.pi
      local d = 0.6 + sorte(v) * 1.8
      x, z = v.x + math.cos(g) * d, v.z - math.sin(g) * d
    end
    if vaca_trajeto_livre(v, x, z, g, limites) then
      v.est, v.ax, v.az, v.ag = "anda", x, z, g
      return
    end
  end
  vaca_descansa(v, true)
end

function M.mover_vacas(dt)
  if not M.vacas or (M.anim.fazenda or 0) <= 0 then return end
  local x0, x1, z0, z1 = L.sala("fazenda")
  local limites = { x0, x1, z0, z1 }
  local fixas = editando()
  for i = 1, #L.VACAS do
    if i > math.min(J.ef("vacas"), #L.VACAS) or L.oculto("vaca" .. i) then
      M.vacas[i] = nil
    else
      local v = M.vacas[i]
      local cx, cz, cg = vaca_casa(i)
      -- nasce em casa; volta para casa se ela ou a cerca mudarem, e fica lá durante a edição
      if not v or fixas or v.cx ~= cx or v.cz ~= cz or v.x0 ~= x0 or v.x1 ~= x1 or v.z0 ~= z0 or v.z1 ~= z1 then
        local nova = not v
        v = v or { s = 7919 * i + 13, velo = 0, pasta = 0, fase = 0 }
        M.vacas[i] = v
        v.x, v.z, v.g, v.cx, v.cz, v.x0, v.x1, v.z0, v.z1 = cx, cz, cg, cx, cz, x0, x1, z0, z1
        v.velo = 0.35 + sorte(v) * 0.3
        v.pasta, v.passo, v.acomodar = 0, 0, true
        vaca_descansa(v, i % 2 == 0)
        if nova then v.t = v.t * 0.4 + i * 0.5 end
      end
      if not fixas then
        if v.acomodar then
          v.acomodar = false
          vaca_acha_lugar(v, limites)
        end
        v.pasta = util.limitar(v.pasta + (v.est == "pasta" and dt or -dt) / 0.8, 0, 1)
        v.passo = 0
        if v.est == "anda" then
          if v.pasta <= 0 then
            local ng, pronto = virar(v.g, v.ag, dt * 1.1)
            if not vaca_pode(v, v.x, v.z, ng, limites) then
              vaca_descansa(v, false)
            elseif not pronto then
              v.g = ng
              v.fase = v.fase + dt
              v.passo = math.sin(v.fase * 5) * 0.5
            else
              v.g = ng
              local dx, dz = v.ax - v.x, v.az - v.z
              local d = math.sqrt(dx * dx + dz * dz)
              local p = math.min(d, v.velo * dt)
              if d < 0.05 then
                vaca_descansa(v, sorte(v) < 0.65)
              else
                local nx, nz = v.x + dx / d * p, v.z + dz / d * p
                if vaca_pode(v, nx, nz, v.g, limites) then
                  v.x, v.z = nx, nz
                  v.fase = v.fase + dt
                  v.passo = math.sin(v.fase * (5 + v.velo * 6))
                else
                  vaca_descansa(v, false)
                end
              end
            end
          end
        else
          v.t = v.t - dt
          if v.t <= 0 then
            if v.est == "pasta" or sorte(v) < 0.6 then vaca_escolhe_destino(v, limites)
            else vaca_descansa(v, true) end
          end
        end
      end
    end
  end
end

local function pomar(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local x0, x1, z0, z1 = L.sala("pomar")
  area_externa("pomar", x0, x1, z0, z1, o, "#6f9a48", "#6a9444", "#86b552")
  -- as frutas só aparecem perto da colheita: a árvore mostra o estado do jogo
  local maduras = J.estado.ciclo / J.ciclo_jardim() > 0.5
  for i = 1, math.min(J.ef("frutas") + 2, #L.ARVORES) do
    local x, z = L.ARVORES[i][1], L.ARVORES[i][2]
    grupo("arvore" .. i)
    if i % 2 == 1 then
      -- macieira
      cilindro(x, 0, z, 0.34, 1.2 * o, "#5b3a22")
      esfera(x, 1.75 * o, z, 1.7, "#5a8f42", 1.4 * o)
      esfera(x - 0.35, 2.15 * o, z - 0.15, 0.9, "#3f6b34", 0.7 * o)
      if maduras then
        for _, f in ipairs({ { 0.55, 1.95, 0.55 }, { -0.4, 2.2, 0.5 }, { 0.1, 2.35, 0.35 }, { -0.65, 1.75, 0.5 }, { 0.75, 1.6, 0.3 } }) do
          esfera(x + f[1], f[2] * o, z + f[3], 0.18, "#c8382e")
        end
      end
    else
      -- pereira, copa alta
      cilindro(x, 0, z, 0.3, 1.05 * o, "#5b3a22")
      esfera(x, 1.9 * o, z, 1.3, "#3f6b34", 1.7 * o)
      if maduras then
        for _, f in ipairs({ { 0.45, 1.75, 0.45 }, { -0.5, 2, 0.4 }, { 0.1, 2.5, 0.45 } }) do
          esfera(x + f[1], f[2] * o, z + f[3], 0.18, "#d9c24a")
          cone(x + f[1], (f[2] + 0.06) * o, z + f[3], 0.1, 0.14, "#d9c24a")
        end
      end
    end
  end
  -- cesto de vime
  grupo("cesto")
  local x, z = 1.3, 5.9
  cilindro(x, 0, z, 0.6, 0.3, "#a87a42")
  cilindro(x, 0.12, z, 0.63, 0.08, "#7b4a26")
  if maduras then esfera(x, 0.3, z, 0.5, "#c8382e", 0.2) end
  caixa(x - 0.27, 0.3, z, 0.08, 0.28, 0.08, "#7b4a26")
  caixa(x + 0.27, 0.3, z, 0.08, 0.28, 0.08, "#7b4a26")
  caixa(x, 0.58, z, 0.62, 0.08, 0.08, "#7b4a26")
end

local function fazenda(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local x0, x1, z0, z1 = L.sala("fazenda")
  area_externa("fazenda", x0, x1, z0, z1, o, "#739c4c", "#6d9647", "#86b552")
  -- celeiro: bem para dentro da área, senão os 3,1 m esconderiam a frente da taverna
  grupo("celeiro")
  local x, z = 15.6, 8
  caixa(x, 0, z, 4, 2 * o, 3, "#8f3a2c")
  caixa(x, 2 * o, z, 4, 0.2, 2.4, "#8f3a2c")
  caixa(x, 2.2 * o, z, 4, 0.3, 1.4, "#8f3a2c")
  caixa(x, 2.5 * o, z, 4, 0.35, 0.5, "#8f3a2c")
  peca("caixa", x, 2.55 * o, z + 0.82, 4.4, 0.14, 2, 0, PEDRA_ESC, 0.6)
  peca("caixa", x, 2.55 * o, z - 0.82, 4.4, 0.14, 2, 0, PEDRA_ESC, -0.6)
  caixa(x, 0, z + 1.5, 1.4, 1.5 * o, 0.06, "#6b2a20")
  peca("caixa", x, 0.75 * o, z + 1.55, 0.1, 1.6 * o, 0.04, 0, "#efe2c4", 0, 0.75)
  peca("caixa", x, 0.75 * o, z + 1.55, 0.1, 1.6 * o, 0.04, 0, "#efe2c4", 0, -0.75)
  -- cocho
  grupo("cocho")
  x, z = 11.2, 6.2
  caixa(x - 0.55, 0, z, 0.1, 0.18, 0.5, MAD_ESC)
  caixa(x + 0.55, 0, z, 0.1, 0.18, 0.5, MAD_ESC)
  caixa(x, 0.18, z, 1.4, 0.08, 0.5, MAD_MED)
  caixa(x, 0.18, z - 0.25, 1.5, 0.3, 0.08, MAD_MED)
  caixa(x, 0.18, z + 0.25, 1.5, 0.3, 0.08, MAD_MED)
  caixa(x - 0.72, 0.18, z, 0.08, 0.3, 0.58, MAD_MED)
  caixa(x + 0.72, 0.18, z, 0.08, 0.3, 0.58, MAD_MED)
  caixa(x, 0.26, z, 1.3, 0.14, 0.42, "#d3ad4f")
  -- feno: dois fardos embaixo, um em cima
  grupo("feno")
  x, z = 13.3, 10
  for _, f in ipairs({ { -0.52, 0, "#d3ad4f" }, { 0.52, 0, "#b8923c" }, { 0, 0.55, "#d3ad4f" } }) do
    caixa(x + f[1], f[2], z, 1, 0.55, 0.6, f[3])
    caixa(x + f[1] - 0.25, f[2], z, 0.08, 0.57, 0.64, MAD_MED)
    caixa(x + f[1] + 0.25, f[2], z, 0.08, 0.57, 0.64, MAD_MED)
  end
  for i = 1, math.min(J.ef("vacas"), #L.VACAS) do
    local v = L.VACAS[i]
    local id = "vaca" .. i
    grupo(id)
    local a = M.vacas and M.vacas[i]
    if a then
      -- de fazenda para o grupo da própria vaca, que o editor pode ter movido ou girado
      local wx, wz = L.t("fazenda", a.x, a.z)
      local px, pz = L.base(id, wx, wz)
      -- mastigando: a cabeça sobe e desce um pouco, cada vaca em seu tempo
      local masca = a.pasta * (0.94 + 0.06 * math.sin(M.tempo * 3 + i * 1.7))
      vaca(px, pz, a.g + L.giro("fazenda") - L.giro(id), a.passo, masca)
    else
      vaca(v[1], v[2], v[3], 0)
    end
  end
end

local function cozinha(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local x0, x1, z0, z1 = L.sala_mundo("cozinha")
  casca_sala(x0, x1, z0, z1, o, { piso1 = "#6e675c", piso2 = "#645d53", parede = PAREDE, parede_lado = "#47301f", rodape = "#2b2523",
    viga = VIGA, folha = MAD_MED, acento = OURO })
  -- faixa de azulejo atrás do fogão: é a cor que diz "cozinha"
  caixa((x0 + x1) / 2, 0.75 * o, z0 + 0.03, x1 - x0, 1.0 * o, 0.06, "#c9bda6")
  -- fogão a lenha
  grupo("fogao")
  local x, z = 14, -3.95
  caixa(x, 0, z, 1.4, 0.85 * o, 0.8, PEDRA_ESC)
  caixa(x, 0.85 * o, z, 1.5, 0.08, 0.9, "#2b2523")
  caixa(x - 0.3, 0.15, z + 0.39, 0.5, 0.4, 0.06, "#201a18")
  brilho("caixa", x - 0.3, 0.28, z + 0.41, 0.36, 0.2, 0.06, FOGO, 1.3)
  cilindro(x - 0.3, 0.93 * o, z, 0.5, 0.3, COBRE)
  -- mexendo: a tampa fica de lado no fogão
  local mexendo = M.cozinheiro and M.cozinheiro.fazendo == "fogao"
  if mexendo then cilindro(x + 0.25, 0.93 * o, z + 0.17, 0.54, 0.05, FERRO)
  else cilindro(x - 0.3, 1.23 * o, z, 0.54, 0.05, FERRO) end
  cilindro(x + 0.45, 0.93 * o, z - 0.2, 0.26, 3.27 * o, FERRO)
  -- panelas penduradas na parede
  grupo("panelas")
  x, z = 16, -4.32
  caixa(x, 2.5 * o, z, 2, 0.08, 0.08, FERRO)
  for i, dx in ipairs({ -0.6, 0, 0.6 }) do
    local d = 0.28 + i * 0.06
    caixa(x + dx, 2.25 * o, z, 0.08, 0.25, 0.08, FERRO)
    cilindro(x + dx, (2.25 - d * 0.7) * o, z, d, d * 0.7, COBRE)
  end
  -- mesa de preparo no meio
  grupo("mesa_preparo")
  x, z = 15, -0.9
  for _, q in ipairs({ { -0.9, -0.35 }, { 0.9, -0.35 }, { -0.9, 0.35 }, { 0.9, 0.35 } }) do
    caixa(x + q[1], 0, z + q[2], 0.12, 0.72 * o, 0.12, MAD_ESC)
  end
  caixa(x, 0.72 * o, z, 2, 0.1, 0.9, TAMPO)
  caixa(x, 0.25 * o, z, 1.8, 0.08, 0.7, MAD_MED)
  caixa(x - 0.4, 0.82 * o, z + 0.05, 0.6, 0.06, 0.4, MAD_MED)
  cone(x - 0.4, 0.88 * o, z + 0.05, 0.14, 0.24, "#e08a3c")
  esfera(x + 0.5, 0.94 * o, z, 0.24, "#86b552")
  -- despensa: baixa, porque fica na parte da frente da sala
  grupo("despensa")
  x, z = 16.2, 3.4
  carga(x, z)
  barril(x - 2.2, z + 0.1, 0.8)
end

local function cervejaria(e)
  if e <= 0 then return end
  local o = e + math.sin(e * math.pi) * 0.12
  local x0, x1, z0, z1 = L.sala_mundo("cervejaria")
  -- cômodo de pedra com detalhes de cobre
  casca_sala(x0, x1, z0, z1, o, { piso1 = PEDRA, piso2 = "#635f5a", parede = PEDRA_ESC, parede_lado = "#46423f", rodape = PEDRA_CLARA,
    viga = "#3a3634", folha = "#5b3a22", acento = COBRE_CLARO })
  -- cano de cobre correndo pela parede do fundo
  caixa((x0 + x1) / 2, 2.6 * o, z0 + 0.06, x1 - x0 - 0.1, 0.08, 0.08, COBRE)
  -- tina de cobre com domo, cano e fogo embaixo
  local tx, tz = 19, -3.2
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
  cilindro(20.6, 0, tz, 1.1 * o, 1.2 * o, MAD_MED)
  cilindro(20.6, 0.2, tz, 1.14, 0.08, FERRO)
  cilindro(20.6, 0.9, tz, 1.14, 0.08, FERRO)
  for i = 0, 2 do
    grupo("barril_c" .. (i + 1))
    barril(19.2 + i * 0.9, 2.6, 0.9 * o)
  end
  grupo("bancada")
  caixa(20.1, 0, -1.2, 2.0, 0.85 * o, 0.7, MAD_MED)
  caixa(20.1, 0.85 * o, -1.2, 2.1, 0.08, 0.78, TAMPO)
  -- sacos de malte
  grupo("malte1")
  peca("esfera", 22.1, 0.26, -3.8, 0.6, 0.52, 0.6, 0, "#c9b58b")
  grupo("malte2")
  peca("esfera", 22.3, 0.22, -3.1, 0.5, 0.44, 0.5, 0, "#a8946c")
  -- cervejeiro: aparece junto com a cervejaria e vai da tina à bancada
  grupo("cervejaria")
  local c = (math.sin(M.tempo * 0.5) + 1) / 2
  local bx, bz = 19.3 + c * 1.6, -2.05
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
  local o = e
  local x0, x1, z0, z1 = L.sala_mundo("circulo")
  -- cômodo de pedra escura com a magia escapando pela parede
  casca_sala(x0, x1, z0, z1, o, { piso1 = "#39344e", piso2 = "#322d46", parede = "#2c2838", parede_lado = "#322e40", rodape = "#54497a",
    viga = "#1f1c29", folha = "#2a2030", acento = VIOLETA })
  brilho("caixa", (x0 + x1) / 2, 1.05 * o, z0 + 0.03, x1 - x0, 0.05, 0.05, VIOLETA, 1.2)
  -- o círculo em si é um objeto: anda no editor, os pilares acompanham
  grupo("circulo")
  local cx, cz = CIRC_X, CIRC_Z
  cilindro(cx, 0, cz, 3.3, 0.08, PEDRA_ESC)
  peca("cilindro", cx, 0.07, cz, 2.95, 0.03, 2.95, 0, VIOLETA, 0, 0, 1.2)
  cilindro(cx, 0.09, cz, 2.7, 0.03, FUNDO_MAGIA)
  -- hexagrama girando devagar
  for k = 0, 5 do
    local a = k * math.pi / 3 + t * 0.3
    peca("caixa", cx + 0.58 * math.cos(a), 0.13, cz + 0.58 * math.sin(a), 0.08, 0.02, 2.0, -a, CIANO, 0, 0, 1.3)
  end
  for i = 0, 3 do
    local a = t * 0.6 + i * math.pi / 2
    brilho("esfera", cx + math.cos(a) * 1.4, 0.5 + math.sin(t * 2 + i) * 0.1, cz + math.sin(a) * 1.4, 0.2, 0.2, 0.2, "#c9a7ff", 1.6)
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
  elseif b.mao then
    -- braço esticado à frente, trabalhando
    p("caixa", 0.3, y0 + by + b.mao, 0.2, 0.14, 0.15, 0.44, t.braco)
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
    -- touca de cozinheiro: sobe junto com a cabeça, mesmo se ele andar ou mudar de tipo
    if b.chapeu_alto then p("cilindro", 0, y0 + cy + 0.3, 0, 0.42, 0.24, 0.42, b.chapeu) end
  end
end

local T_GARCOM = { nome = "comum", corpo = "#2f7a8a", perna = "#23303a", braco = "#2a6d7c" }
local T_COZINHEIRO = { nome = "comum", corpo = "#eeeae2", perna = "#3a3a40", braco = "#e2ddd2" }
local T_GERENTE = { nome = "comum", corpo = "#6b3f2a", perna = "#2c2a30", braco = "#5f3826" }
local T_MOCO = { nome = "comum", corpo = "#c9b48a", perna = "#4a3a2a", braco = "#b9a47a" }
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

-- Ponto do cozinheiro (nas coordenadas de origem dele) e para onde olha, em cada posto.
-- Vêm do próprio móvel, para acompanhar o que for movido no editor.
local function posto_cozinheiro(qual)
  -- no fogão fica de lado, à esquerda da panela: de frente ele a esconderia da câmera
  local id, px, pz, ox, oz = "fogao", 13.0, -3.25, 13.7, -3.95
  if qual == "mesa" then id, px, pz, ox, oz = "mesa_preparo", 14.3, -1.64, 14.3, -0.9 end
  -- móvel colado na parede: o posto fica do lado de dentro, nunca dentro da parede
  local wx, wz = L.t(id, px, pz)
  local x0, x1, z0, z1 = L.sala_mundo("cozinha")
  wx = util.limitar(wx, x0 + 0.4, math.max(x0 + 0.4, x1 - 0.4))
  wz = util.limitar(wz, z0 + 0.4, math.max(z0 + 0.4, z1 - 0.4))
  local x, z = L.base("cozinheiro", wx, wz)
  local ax, az = L.base("cozinheiro", L.t(id, ox, oz))
  return x, z, math.atan(ax - x, az - z)
end

function M.mover_cozinheiro(dt)
  if J.ef("cozinheiro") <= 0 then M.cozinheiro = nil return end
  local c = M.cozinheiro
  if not c then
    c = { posto = "fogao", t = 5, fase = 0, giro = math.pi }
    c.x, c.z = posto_cozinheiro("fogao")
    M.cozinheiro = c
  end
  c.andando, c.fazendo = false, nil
  if editando() then
    -- na edição ele fica no lugar que o editor mostra e deixa selecionar
    c.parado = true
    return
  end
  if c.parado then
    c.parado = false
    c.x, c.z = posto_cozinheiro(c.posto)
  end
  if c.posto == "mesa" and L.oculto("mesa_preparo") then c.posto, c.t = "fogao", 5 end
  local ax, az, ag = posto_cozinheiro(c.posto)
  local dx, dz = ax - c.x, az - c.z
  local d = math.sqrt(dx * dx + dz * dz)
  if d > 0.05 then
    c.andando = true
    c.fase = c.fase + dt
    c.giro = virar(c.giro, math.atan(dx, dz), dt * 8)
    local p = math.min(d, dt * 1.4)
    c.x, c.z = c.x + dx / d * p, c.z + dz / d * p
  else
    local pronto
    c.giro, pronto = virar(c.giro, ag, dt * 8)
    if pronto then
      c.fazendo = c.posto
      c.t = c.t - dt
      if c.t <= 0 then
        c.posto = c.posto == "fogao" and "mesa" or "fogao"
        c.t = c.posto == "fogao" and 5 or 3.5
        if c.posto == "mesa" and L.oculto("mesa_preparo") then c.posto, c.t = "fogao", 5 end
      end
    end
  end
end

local function equipe_fixa()
  local g = J.gerente
  if g and not J.gerente_na_guilda() then
    M.boneco({ x = g.x, z = g.z, giro = g.giro, fase = g.fase, andando = g.andando, pele = "#d8a06e", tipo = T_GERENTE, chapeu = "#3a2a20" })
  end
  local m = J.moco
  if m and m.visivel then
    M.boneco({ x = m.x, z = m.z, giro = m.giro, fase = m.fase, andando = m.andando, pele = "#e0ac7e", tipo = T_MOCO, levando = m.leva })
  end
  -- prato pronto na ponta do balcão esperando o garçom
  for _, w in ipairs(J.garcons or {}) do
    if w.estado == "buscando" then
      grupo("balcao")
      cilindro(0.45, 1.13, -2.2, 0.34, 0.04, "#efe6d2")
      esfera(0.45, 1.2, -2.2, 0.2, "#c98a4e", 0.12)
      break
    end
  end
  grupo("cozinheiro")
  if J.ef("cozinheiro") > 0 then
    local c = M.cozinheiro
    local x, z, giro = 14, -2.5, math.pi
    if c and not c.parado then x, z, giro = c.x, c.z, c.giro end
    local fazendo = c and c.fazendo
    local mao
    if fazendo == "fogao" then mao = 0.26 + math.sin(M.tempo * 4) * 0.02
    elseif fazendo == "mesa" then mao = 0.14 + math.abs(math.sin(M.tempo * 7)) * 0.08 end
    M.boneco({ x = x, z = z, giro = giro, fase = c and c.fase or 0, andando = c and c.andando, mao = mao,
      pele = "#e0ac7e", tipo = T_COZINHEIRO, chapeu = "#f4f4f0", chapeu_alto = true })
    if fazendo == "fogao" then
      -- colher dando voltas dentro da panela
      grupo("fogao")
      local a = M.tempo * 4
      peca("caixa", 13.56 + math.cos(a) * 0.08, 1.3, -3.9 + math.sin(a) * 0.08, 0.07, 0.8, 0.07, 0, TAMPO, 0, 0.7)
    elseif fazendo == "mesa" then
      -- faca subindo e descendo na tábua
      grupo("mesa_preparo")
      local y = 0.95 + math.abs(math.sin(M.tempo * 7)) * 0.1
      caixa(14.6, y, -1.0, 0.05, 0.04, 0.42, "#c0c4c8")
    end
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

-- Itens acrescentados no editor
local function extras()
  for _, o in ipairs(L.OBJETOS) do
    if o.extra then
      grupo(o.id)
      local x, z, t = o.x, o.z, o.extra
      if t == "barril" then barril(x, z)
      elseif t == "caixote" then
        caixa(x, 0, z, 0.8, 0.7, 0.8, MAD_MED)
        caixa(x, 0.7, z, 0.84, 0.06, 0.84, TAMPO)
      elseif t == "planta" then
        cilindro(x, 0, z, 0.42, 0.42, "#8a5a33")
        peca("esfera", x, 0.72, z, 0.72, 0.72, 0.72, 0, "#4f8a3c")
      elseif t == "vela" then
        cilindro(x, 0, z, 0.1, 1.1, FERRO)
        cilindro(x, 0, z, 0.36, 0.05, FERRO)
        vela(x, 1.1, z)
      elseif t == "tapete" then tapete(x, z, 2.6, 1.7)
      elseif t == "estante" then
        caixa(x, 0, z, 1.5, 2.0, 0.42, MAD_ESC)
        for k = 0, 2 do caixa(x, 0.45 + k * 0.6, z + 0.2, 1.3, 0.06, 0.1, TAMPO) end
      elseif t == "banco" then banquinho(x, z)
      elseif t == "quadro" then
        caixa(x, 1.6, z, 1.0, 0.8, 0.06, MAD_ESC)
        caixa(x, 1.68, z + 0.02, 0.84, 0.64, 0.05, "#c9a24a")
      end
    end
  end
  grupo(nil)
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
    local cirx, cirz = L.t("circulo", CIRC_X, CIRC_Z)
    motor.cena_luz(4, cirx, 1.2, cirz, 0.9 * c, 0.6 * c, 1.5 * c, 6)
  else
    local l = a.leste
    local brx, brz = L.t("barraca", 9.3, -1.4)
    motor.cena_luz(4, brx, 2.2, brz, 0.95 * l, 0.66 * l, 0.36 * l, 6.5)
  end

  salao()
  extras()
  ala_leste(a.leste)
  grupo("jardim")
  jardim(a.jardim)
  grupo("pomar")
  pomar(a.pomar)
  grupo("fazenda")
  fazenda(a.fazenda)
  grupo(nil)
  cozinha(a.cozinha)
  grupo(nil)
  cervejaria(a.cerveja)
  grupo(nil)
  circulo(a.circulo)
  grupo(nil)

  for _, p in ipairs(J.pessoas) do
    -- do lado de fora da parede ninguém é desenhado: a pessoa surge já dentro do vão
    if not J.fora_da_porta(p) then M.boneco(p) end
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
        M.boneco({ x = CIRC_X + math.cos(ang) * 0.9, z = CIRC_Z + math.sin(ang) * 0.7, giro = -ang + math.pi / 2, fase = 0,
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
