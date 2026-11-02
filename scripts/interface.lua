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

-- medidas das cartas: mude aqui para abrir espaço para novas melhorias
local CARTA_TOPO, CARTA_ALTURA, CARTA_ESPACO = 136, 90, 6
local BOTAO_LARGURA, BOTAO_ALTURA = 92, 54

local TEM_MOUSE = motor.plataforma == "desktop"

function UI.iniciar()
  UI.brilho = {}     -- id -> tempo restante do brilho de compra
  UI.tremor = {}     -- id -> tempo restante do tremor de "sem ouro"
  UI.ouro_visivel = taverna.estado.ouro   -- o número do placar "corre" até o valor real
  UI.total_anterior = taverna.estado.total
  UI.pulso = 0       -- pulo do placar quando entra ouro
end

local function carta(i)
  return { x = PX + 12, y = CARTA_TOPO + (i - 1) * (CARTA_ALTURA + CARTA_ESPACO), w = PW - 24, h = CARTA_ALTURA }
end

-- 2.5 -> "2,5"
local function um_decimal(v)
  return (string.format("%.1f", v):gsub("%.", ","))
end

-- quanto tempo até juntar o que falta, no ritmo atual (nil se ainda não dá para estimar)
local function tempo_ate(falta, rps)
  if rps < 0.05 then return nil end
  local s = math.ceil(falta / rps)
  if s < 60 then return "em " .. s .. " s" end
  if s < 3600 then return "em " .. math.ceil(s / 60) .. " min" end
  if s < 360000 then return "em " .. math.ceil(s / 3600) .. " h" end
  return nil
end

-- O que a melhoria faz, com números reais: devolve o texto de agora e o do próximo nível.
-- Tudo vem do config.lua, então acompanha o balanceamento sozinho.
local function efeito(id)
  local nivel = taverna.estado.niveis[id]
  local m = config.melhorias[id]
  local maximo = taverna.no_maximo(id)
  if id == "mesa" then
    local n = taverna.num_mesas() * 2
    return "Lugares: " .. n, not maximo and (n + 2) or nil
  elseif id == "cardapio" then
    local v = taverna.valor_pedido()
    return "Pedido: " .. util.formatar(v), util.formatar(v * m.efeito)
  elseif id == "placa" then
    local v = taverna.intervalo_chegada()
    if maximo then return "Chegada: " .. um_decimal(v) .. " s" end
    return "Chegada: " .. um_decimal(v), um_decimal(v * m.efeito) .. " s"
  elseif id == "garconete" then
    if nivel == 0 then return m.descricao end
    local v = taverna.intervalo_garconete()
    if maximo then return "Atende: " .. um_decimal(v) .. " s" end
    return "Atende: " .. um_decimal(v), um_decimal(v * m.efeito) .. " s"
  end
  return m.descricao
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

local function indicador(x, w, rotulo, valor)
  motor.retangulo(x, 70, w, 36, "#00000030", 8)
  motor.texto(rotulo, x + 9, 72, 12, cor.texto_fraco)
  motor.texto(valor, x + 9, 86, 14, cor.texto, "esquerda", true)
end

local function topo()
  local e = taverna.estado
  local m = taverna.MOEDA_TOPO
  desenho.moeda(m.x, m.y, 22 + UI.pulso * 3)

  local tam = 38 + UI.pulso * 4
  motor.texto(util.formatar(UI.ouro_visivel), PX + 62, 28 - tam / 2 + 2, tam, cor.ouro, "esquerda", true)
  if e.rps < 0.05 then
    motor.texto("Sirva heróis para ganhar ouro", PX + 63, 50, 14, cor.texto_fraco)
  else
    local rps = e.rps < 10 and um_decimal(e.rps) or util.formatar(e.rps)
    motor.texto("+" .. rps .. " por segundo", PX + 63, 50, 14, cor.verde, "esquerda", true)
  end

  local ocupados = 0
  for _ in pairs(taverna.ocupacao) do ocupados = ocupados + 1 end
  local x, w = PX + 12, (PW - 24 - 12) / 3
  indicador(x, w, "Pedido", util.formatar(taverna.valor_pedido()))
  indicador(x + w + 6, w, "Lugares", ocupados .. "/" .. (taverna.num_mesas() * 2))
  indicador(x + (w + 6) * 2, w, "Servidos", util.formatar(e.servidos))
end

-- Painel de melhorias ---------------------------------------------------------------

local function cadeado(x, y)
  motor.anel(x, y - 2, 4, 6.5, cor.texto_fraco, 180, 360)
  motor.retangulo(x - 8, y - 2, 16, 12, cor.texto_fraco, 3)
end

-- botão da direita: preço + estado (comprar, quanto falta, bloqueado ou máximo)
local function botao_preco(id, x, r, liberada, maximo, pode)
  local bw, bh = BOTAO_LARGURA, BOTAO_ALTURA
  local bx, by = x + r.w - bw - 10, r.y + (r.h - bh) / 2
  local cx = bx + bw / 2

  if maximo then
    motor.retangulo(bx, by, bw, bh, "#00000028", 10)
    motor.texto("Máximo", cx, by + bh / 2 - 10, 14, cor.texto_fraco, "centro", true)
    return
  end

  if not liberada then
    local preciso = config.melhorias[id].desbloqueio_mesas
    local tenho = taverna.num_mesas()
    motor.retangulo(bx, by, bw, bh, "#00000028", 10)
    cadeado(cx, by + 16)
    motor.texto(tenho .. "/" .. preciso .. " mesas", cx, by + 31, 13, cor.texto_fraco, "centro")
    return
  end

  local custo = taverna.custo(id)
  local ouro = taverna.estado.ouro
  motor.retangulo(bx, by, bw, bh, pode and cor.ouro or "#00000038", 10)
  if not pode then
    -- o próprio botão vai enchendo conforme o ouro se aproxima do preço
    local p = util.limitar(ouro / custo, 0, 1)
    if bw * p >= 3 then motor.retangulo(bx, by + bh - 5, bw * p, 5, cor.ouro_escuro, 2) end
  end

  local txt = util.formatar(custo)
  local tam = motor.largura_texto(txt, 16, true) > bw - 30 and 14 or 16
  local tw = motor.largura_texto(txt, tam, true)
  local quando = not pode and tempo_ate(custo - ouro, taverna.estado.rps)
  local centro = by + (quando and 19 or bh / 2)   -- preço sobe para abrir espaço à estimativa
  local inicio = cx - (tw + 20) / 2
  desenho.moeda(inicio + 8, centro, 8)
  local cor_preco = pode and cor.texto_ouro or (UI.tremor[id] and cor.vermelho or cor.texto)
  motor.texto(txt, inicio + 20, centro - tam * 0.58, tam, cor_preco, "esquerda", true)
  if quando then motor.texto(quando, cx, by + 30, 13, cor.texto_fraco, "centro") end
end

local function desenhar_carta(i, id)
  local m = config.melhorias[id]
  local r = carta(i)
  local nivel = taverna.estado.niveis[id]
  local liberada = taverna.disponivel(id)
  local maximo = taverna.no_maximo(id)
  local pode = taverna.pode_comprar(id)

  local dx = 0
  if UI.tremor[id] then dx = math.sin(UI.tremor[id] * 60) * 6 * (UI.tremor[id] / 0.3) end
  local x = r.x + dx

  local sobre = false
  if TEM_MOUSE and liberada and not maximo and not taverna.offline then
    local mx, my = motor.mouse()
    sobre = util.dentro(mx, my, r)
  end

  motor.retangulo(x, r.y, r.w, r.h, sobre and "#4d3423" or cor.carta, 12)
  motor.contorno(x, r.y, r.w, r.h, sobre and cor.ouro_escuro or cor.carta_borda, 2, 12)

  if not liberada then motor.opacidade(0.5) end
  motor.circulo(x + 36, r.y + r.h / 2, 24, cores_icone[id])
  icones[id](x + 36, r.y + r.h / 2)
  if not liberada then motor.opacidade(1) end

  -- nome, nível e o que a melhoria faz
  local tx = x + 70
  motor.texto(m.nome, tx, r.y + 10, 17, liberada and cor.texto or cor.texto_fraco, "esquerda", true)

  if liberada then
    local agora, depois = efeito(id)
    motor.texto(agora, tx, r.y + 34, 14, cor.texto)
    if depois then
      local w = motor.largura_texto(agora, 14)
      -- seta desenhada: a fonte Poppins não tem o caractere de seta
      local ax, ay = tx + w + 6, r.y + 43
      motor.linha(ax, ay, ax + 8, ay, 1.5, cor.texto_fraco)
      motor.triangulo(ax + 7, ay - 3.5, ax + 7, ay + 3.5, ax + 12, ay, cor.texto_fraco)
      motor.texto(tostring(depois), ax + 17, r.y + 34, 14, cor.verde, "esquerda", true)
    end
    local situacao
    if id == "mesa" then
      local n = taverna.num_mesas()
      situacao = n == 1 and "1 mesa" or (n .. " mesas")
    elseif nivel == 0 then situacao = "Ainda não comprado"
    else situacao = "Nível " .. nivel end
    motor.texto(situacao, tx, r.y + 58, 13, cor.ouro)
  else
    motor.texto("Compre " .. m.desbloqueio_mesas .. " mesas", tx, r.y + 34, 14, cor.texto_fraco)
    motor.texto("para desbloquear", tx, r.y + 52, 14, cor.texto_fraco)
  end

  botao_preco(id, x, r, liberada, maximo, pode)

  if UI.brilho[id] then
    motor.opacidade(UI.brilho[id] / 0.35 * 0.35)
    motor.retangulo(x, r.y, r.w, r.h, "#fff3c4", 12)
  end
  motor.opacidade(1)
end

local function painel()
  motor.retangulo(PX, 0, PW, 540, cor.painel)
  motor.retangulo(PX, 0, 4, 540, "#00000050")
  motor.texto("Melhorias", PX + 14, 111, 16, cor.texto, "esquerda", true)
  for i, id in ipairs(taverna.ORDEM_MELHORIAS) do desenhar_carta(i, id) end
end

-- No salão: comprar mesa pelo lugar vazio e dica do primeiro atendimento -------------

local function area_mesa_vazia()
  local n = taverna.num_mesas()
  if n >= taverna.MAX_MESAS or taverna.no_maximo("mesa") then return nil end
  local m = taverna.posicao_mesa(n + 1)
  return { x = m.x - 50, y = m.y - 30, w = 100, h = 66 }, m
end

local function preco_mesa_vazia()
  local _, m = area_mesa_vazia()
  if not m then return end
  local pode = taverna.pode_comprar("mesa")
  local txt = util.formatar(taverna.custo("mesa"))
  local w = motor.largura_texto(txt, 14, true) + 34
  local px, py = m.x - w / 2, m.y + 10
  motor.retangulo(px, py, w, 24, pode and cor.ouro or "#00000090", 12)
  desenho.moeda(px + 13, py + 12, 7)
  motor.texto(txt, px + 24, py + 3, 14, pode and cor.texto_ouro or cor.texto, "esquerda", true)
end

local function dica_primeiro_atendimento()
  if taverna.estado.servidos > 0 or taverna.offline then return end
  local alvo
  for _, h in ipairs(taverna.herois) do
    if h.estado == "esperando" then alvo = h break end
  end
  if not alvo then return end
  local txt = "Toque no balão para servir"
  local w = motor.largura_texto(txt, 15, true) + 28
  local topo_balao = alvo.y - 124
  local salto = math.abs(math.sin(motor.tempo() * 4)) * 5
  local cx = util.limitar(alvo.x, w / 2 + 8, taverna.LARGURA_SALAO - w / 2 - 8)
  local y = topo_balao - 46 - salto
  motor.retangulo(cx - w / 2, y, w, 30, cor.ouro, 15)
  motor.texto(txt, cx, y + 6, 15, cor.texto_ouro, "centro", true)
  motor.triangulo(alvo.x - 8, y + 29, alvo.x + 8, y + 29, alvo.x, y + 40, cor.ouro)
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
  local y = 10 - (1 - util.suave(entrada)) * 20
  local w = motor.largura_texto(a.texto, 18, true) + 40
  motor.retangulo(cx - w / 2, y + 3, w, 44, cor.sombra, 22)
  motor.retangulo(cx - w / 2, y, w, 44, cor.ouro, 22)
  motor.texto(a.texto, cx, y + 11, 18, cor.texto_ouro, "centro", true)
  motor.opacidade(1)
end

local function duracao(segundos)
  local min = math.floor(segundos / 60)
  if min < 60 then return min .. " min" end
  local h = math.floor(min / 60)
  if min % 60 == 0 then return h .. " h" end
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
  local fora = "Você ficou fora por " .. duracao(o.segundos) .. "."
  if o.segundos > config.offline_maximo then
    fora = "Você ficou fora por " .. duracao(o.segundos) .. " (conta até " .. duracao(config.offline_maximo) .. ")"
  end
  motor.texto(fora, 480, y + 82, 16, cor.texto_fraco, "centro")
  motor.texto("A garçonete cuidou da taverna:", 480, y + 106, 16, cor.texto_fraco, "centro")
  local txt = "+" .. util.formatar(o.ganho)
  local tw = motor.largura_texto(txt, 44, true)
  desenho.moeda(480 - tw / 2 - 12, y + 175, 20)
  motor.texto(txt, 480 - tw / 2 + 18, y + 146, 44, cor.ouro, "esquerda", true)
  motor.retangulo(380, y + 236, 200, 52, cor.ouro, 26)
  motor.texto("Coletar", 480, y + 247, 22, cor.texto_ouro, "centro", true)
end

-- Ciclo ---------------------------------------------------------------------------------

function UI.atualizar(dt)
  for _, lista in ipairs({ UI.brilho, UI.tremor }) do
    for id, t in pairs(lista) do
      t = t - dt
      lista[id] = t > 0 and t or nil
    end
  end

  -- o número do placar corre até o valor real
  local e = taverna.estado
  local d = e.ouro - UI.ouro_visivel
  if math.abs(d) < 1 then UI.ouro_visivel = e.ouro
  else UI.ouro_visivel = UI.ouro_visivel + d * math.min(1, dt * 10) end

  if e.total > UI.total_anterior then UI.pulso = 1 end
  UI.total_anterior = e.total
  UI.pulso = math.max(0, UI.pulso - dt * 5)
end

function UI.desenhar()
  preco_mesa_vazia()
  painel()
  topo()
  motor.opacidade(0.6)
  motor.texto("versão " .. (motor.versao or "dev"), 10, 520, 11, cor.texto_fraco)
  motor.opacidade(1)
  dica_primeiro_atendimento()
  efeitos()
  aviso()
  boas_vindas()
end

local function tentar_comprar(id, r)
  if taverna.comprar(id) then
    UI.brilho[id] = 0.35
    local nivel = taverna.estado.niveis[id]
    local msg = "Nível " .. nivel .. "!"
    if id == "mesa" then msg = "Nova mesa!"
    elseif id == "garconete" and nivel == 1 then msg = "Contratada!" end
    taverna.flutuar(r.x + r.w / 2 - 40, r.y + 34, msg, cor.verde, 18)
  elseif taverna.disponivel(id) and not taverna.no_maximo(id) then
    UI.tremor[id] = 0.3
  end
end

-- devolve true se o toque foi usado pela interface
function UI.tocar(x, y)
  if x < PX then
    -- o lugar da próxima mesa também é um botão de compra
    local area = area_mesa_vazia()
    if area and util.dentro(x, y, area) then
      local i = 1
      for j, id in ipairs(taverna.ORDEM_MELHORIAS) do if id == "mesa" then i = j end end
      tentar_comprar("mesa", carta(i))
      return true
    end
    return false
  end
  for i, id in ipairs(taverna.ORDEM_MELHORIAS) do
    local r = carta(i)
    if util.dentro(x, y, r) then
      tentar_comprar(id, r)
      return true
    end
  end
  return true
end

return UI
