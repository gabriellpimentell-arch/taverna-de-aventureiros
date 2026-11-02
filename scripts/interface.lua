-- =============================================================================
--  Interface: placar de ouro, cartas de melhoria, avisos e textos flutuantes
-- =============================================================================

local taverna = require("taverna")
local desenho = require("desenho")
local config = require("config")
local util = require("util")
local cor = util.cores

local UI = {}

-- painel à direita do salão
local PX = 600          -- onde o painel começa
local PW = 960 - PX     -- largura do painel

function UI.iniciar()
  UI.brilho = {}     -- id -> tempo restante do brilho de compra
  UI.tremor = {}     -- id -> tempo restante do tremor de "sem ouro"
end

local function carta(i)
  return { x = PX + 12, y = 150 + (i - 1) * 96, w = PW - 24, h = 88 }
end

-- Ícones das melhorias ------------------------------------------------------------

local icones = {
  mesa = function(x, y)
    motor.linha(x - 8, y + 2, x - 10, y + 14, 3, cor.madeira_esc)
    motor.linha(x + 8, y + 2, x + 10, y + 14, 3, cor.madeira_esc)
    motor.elipse(x, y, 16, 8, "#a8713f")
  end,
  cardapio = function(x, y) desenho.caneca(x - 1, y + 1, 0.8) end,
  placa = function(x, y)
    motor.retangulo(x - 2, y - 4, 4, 20, cor.madeira_esc)
    motor.retangulo(x - 14, y - 14, 28, 14, "#c08a52", 3)
    motor.triangulo(x + 14, y - 14, x + 14, y, x + 20, y - 7, "#c08a52")
  end,
  garconete = function(x, y)
    motor.circulo(x, y - 6, 10, "#6b3a1e")
    motor.retangulo(x - 10, y + 2, 20, 14, "#2f7a8a", 6)
    motor.circulo(x, y - 5, 8, "#f1c9a5")
  end,
}

local cores_icone = {
  mesa = "#5c3f29", cardapio = "#6a4a1f", placa = "#4b4a2a", garconete = "#2a4f57",
}

-- Topo: ouro e estatísticas --------------------------------------------------------

local function topo()
  local e = taverna.estado
  desenho.moeda(taverna.MOEDA_TOPO.x, taverna.MOEDA_TOPO.y, 24)
  motor.texto(util.formatar(e.ouro), PX + 76, 14, 40, cor.texto, "esquerda", true)
  local rps = e.rps < 10 and string.format("%.1f", e.rps):gsub("%.", ",") or util.formatar(e.rps)
  motor.texto("+" .. rps .. " por segundo", PX + 78, 64, 15, cor.texto_fraco)
  local servidos = e.servidos == 1 and "1 herói servido" or (util.formatar(e.servidos) .. " heróis servidos")
  motor.texto(servidos, 960 - 16, 66, 13, cor.texto_fraco, "direita")
  motor.retangulo(PX + 16, 102, PW - 32, 2, "#00000040")
end

-- Painel de melhorias ---------------------------------------------------------------

local function desenhar_carta(i, id)
  local m = config.melhorias[id]
  local r = carta(i)
  local nivel = taverna.estado.niveis[id]
  local liberada = taverna.disponivel(id)
  local maximo = taverna.no_maximo(id)
  local custo = taverna.custo(id)
  local pode = taverna.pode_comprar(id)

  local dx = 0
  if UI.tremor[id] then dx = math.sin(UI.tremor[id] * 60) * 6 * (UI.tremor[id] / 0.3) end
  local x = r.x + dx

  if not liberada then motor.opacidade(0.45) end
  motor.retangulo(x, r.y, r.w, r.h, pode and "#47301f" or cor.carta, 12)
  motor.contorno(x, r.y, r.w, r.h, pode and cor.ouro_escuro or cor.carta_borda, 2, 12)

  motor.circulo(x + 36, r.y + 44, 24, cores_icone[id])
  icones[id](x + 36, r.y + 44)

  -- nome, situação e descrição
  motor.texto(m.nome, x + 72, r.y + 9, 18, cor.texto, "esquerda", true)
  local situacao
  if not liberada then situacao = "Bloqueado"
  elseif id == "mesa" then
    local n = taverna.num_mesas()
    situacao = n == 1 and "1 mesa" or (n .. " mesas")
  elseif nivel == 0 then situacao = "Ainda não comprado"
  else situacao = "Nível " .. nivel end
  motor.texto(situacao, x + 72, r.y + 33, 13, cor.ouro_escuro)

  local descricao = m.descricao
  if not liberada then
    descricao = "Desbloqueia com " .. m.desbloqueio_mesas .. " mesas"
  elseif nivel > 0 and m.descricao_nivel then
    descricao = m.descricao_nivel
  end
  motor.texto(descricao, x + 72, r.y + 55, 14, cor.texto_fraco)

  -- preço
  if liberada then
    if maximo then
      motor.texto("Máximo", x + r.w - 14, r.y + 14, 15, cor.texto_fraco, "direita", true)
    else
      local txt = util.formatar(custo)
      local w = motor.largura_texto(txt, 16, true) + 40
      local px, py = x + r.w - 12 - w, r.y + 10
      motor.retangulo(px, py, w, 30, pode and cor.ouro or "#4d3a2c", 15)
      desenho.moeda(px + 16, py + 15, 9)
      motor.texto(txt, px + 29, py + 7, 16, pode and "#3a2410" or cor.texto_fraco, "esquerda", true)

      -- barrinha mostrando quanto falta para comprar
      if not pode then
        local p = util.limitar(taverna.estado.ouro / custo, 0, 1)
        motor.retangulo(x + 14, r.y + r.h - 6, (r.w - 28) * p, 3, cor.ouro_escuro, 1)
      end
    end
  end

  if UI.brilho[id] then
    motor.opacidade(UI.brilho[id] / 0.35 * 0.35)
    motor.retangulo(x, r.y, r.w, r.h, "#fff3c4", 12)
  end
  motor.opacidade(1)
end

local function painel()
  motor.retangulo(PX, 0, PW, 540, cor.painel)
  motor.retangulo(PX, 0, 4, 540, "#00000050")
  motor.texto("Melhorias", PX + 16, 114, 18, cor.texto, "esquerda", true)
  motor.texto("Toque para comprar", 960 - 16, 118, 12, cor.texto_fraco, "direita")
  for i, id in ipairs(taverna.ORDEM_MELHORIAS) do desenhar_carta(i, id) end
end

-- Efeitos, avisos e janela de boas-vindas ---------------------------------------------

local function efeitos()
  for _, e in ipairs(taverna.efeitos) do
    local t = e.vida / e.duracao
    if e.tipo == "texto" then
      motor.opacidade(1 - t * t)
      local y = e.y - util.suave(t) * 50
      motor.texto(e.texto, e.x + 1, y + 2, e.tamanho, "#00000088", "centro", true)
      motor.texto(e.texto, e.x, y, e.tamanho, e.cor, "centro", true)
    elseif e.tipo == "moeda" and t > 0 then
      local s = util.suave(t)
      local alvo = taverna.MOEDA_TOPO
      local x = util.lerp(e.x0, alvo.x, s)
      local y = util.lerp(e.y0, alvo.y, s) - math.sin(t * math.pi) * 60
      desenho.moeda(x, y, 8)
    end
  end
  motor.opacidade(1)
end

local function aviso()
  local a = taverna.aviso
  if not a then return end
  local entrada = util.limitar(a.vida / 0.3, 0, 1)
  local saida = util.limitar((a.duracao - a.vida) / 0.4, 0, 1)
  motor.opacidade(math.min(entrada, saida))
  local cx = taverna.LARGURA_SALAO / 2
  local y = 112 - (1 - util.suave(entrada)) * 20
  local w = motor.largura_texto(a.texto, 18, true) + 40
  motor.retangulo(cx - w / 2, y + 3, w, 44, "#00000055", 22)
  motor.retangulo(cx - w / 2, y, w, 44, cor.ouro, 22)
  motor.texto(a.texto, cx, y + 13, 18, "#3a2410", "centro", true)
  motor.opacidade(1)
end

local function duracao(segundos)
  local min = math.floor(segundos / 60)
  if min < 60 then return min .. " min" end
  local h = math.floor(min / 60)
  return h .. " h " .. (min % 60) .. " min"
end

local function boas_vindas()
  local o = taverna.offline
  if not o then return end
  motor.retangulo(0, 0, 960, 540, "#000000b0")
  local x, y, w, h = 260, 110, 440, 320
  motor.retangulo(x, y, w, h, cor.carta, 20)
  motor.contorno(x, y, w, h, cor.ouro_escuro, 3, 20)
  motor.texto("Bem-vindo de volta!", 480, y + 32, 28, cor.texto, "centro", true)
  motor.texto("Você ficou fora por " .. duracao(o.segundos) .. ".", 480, y + 82, 16, cor.texto_fraco, "centro")
  motor.texto("A garçonete cuidou da taverna:", 480, y + 106, 16, cor.texto_fraco, "centro")
  local txt = "+" .. util.formatar(o.ganho)
  local tw = motor.largura_texto(txt, 44, true)
  desenho.moeda(480 - tw / 2 - 12, y + 175, 20)
  motor.texto(txt, 480 - tw / 2 + 18, y + 146, 44, cor.ouro, "esquerda", true)
  motor.retangulo(380, y + 236, 200, 52, cor.ouro, 26)
  motor.texto("Coletar", 480, y + 251, 22, "#3a2410", "centro", true)
end

-- Ciclo ---------------------------------------------------------------------------------

function UI.atualizar(dt)
  for _, lista in ipairs({ UI.brilho, UI.tremor }) do
    for id, t in pairs(lista) do
      t = t - dt
      lista[id] = t > 0 and t or nil
    end
  end
end

function UI.desenhar()
  painel()
  topo()
  motor.opacidade(0.5)
  motor.texto("versão " .. (motor.versao or "dev"), 10, 520, 11, cor.texto_fraco)
  motor.opacidade(1)
  efeitos()
  aviso()
  boas_vindas()
end

-- devolve true se o toque foi usado pela interface
function UI.tocar(x, y)
  if x < PX then return false end
  for i, id in ipairs(taverna.ORDEM_MELHORIAS) do
    if util.dentro(x, y, carta(i)) then
      if taverna.comprar(id) then
        UI.brilho[id] = 0.35
      elseif taverna.disponivel(id) and not taverna.no_maximo(id) then
        UI.tremor[id] = 0.3
      end
      return true
    end
  end
  return true
end

return UI
