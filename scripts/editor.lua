-- =============================================================================
--  MODO DE EDIÇÃO (F2 ou Configurações)
--  Arraste os objetos direto na taverna. As posições ficam salvas neste
--  computador e continuam valendo depois das atualizações do jogo.
-- =============================================================================

local J = require("jogo")
local L = require("layout")
local M = require("mundo")
local U = require("ui")
local util = require("util")
local cor = util.cores

local E = { ativo = false }

local LISTA = { x = 8, y = 56, w = 214, h = 476 }
local ACOES = { x = 738, y = 56, w = 214, h = 476 }
local ITEM = 34

local function msg(t) E.mensagem, E.tempo_msg = t, 3 end

function E.abrir()
  E.ativo = true
  E.sel, E.arrasto, E.confirmar = nil, nil, false
  E.rolagem, E.desfazer, E.grade, E.painel = 0, {}, true, true
  E.mudou = false
  J.editando, J.previa = true, true
end

function E.fechar()
  E.ativo = false
  E.arrasto = nil
  J.editando, J.previa = false, false
  L.salvar()
  J.aplicar_layout()
  M.iniciar()
end

local function guardar()
  local copia = {}
  for id, d in pairs(L.dados) do copia[id] = { x = d.x, z = d.z, y = d.y, g = d.g } end
  E.desfazer[#E.desfazer + 1] = copia
  if #E.desfazer > 30 then table.remove(E.desfazer, 1) end
end

local function mudou()
  E.mudou = true
  L.salvar()
end

local function acao(fn)
  if not E.sel then return end
  guardar()
  fn(L.de(E.sel))
  mudou()
end

function E.mover_para(id, x, z)
  local o, d = L.POR_ID[id], L.de(id)
  if E.grade then
    x = math.floor(x * 4 + 0.5) / 4
    z = math.floor(z * 4 + 0.5) / 4
  end
  d.x, d.z = x - o.x, z - o.z
  J.aplicar_visual()
end

function E.pegar(x, y)
  local melhor, md = nil, 34
  for _, o in ipairs(L.OBJETOS) do
    local d = L.dados[o.id]
    local sx, sy = motor.projetar(o.x + (d and d.x or 0), 0.3, o.z + (d and d.z or 0))
    if sx then
      local dist = util.distancia(x, y, sx, sy)
      if dist < md then melhor, md = o.id, dist end
    end
  end
  return melhor
end

function E.tocar(x, y)
  local id = E.pegar(x, y)
  if id then
    E.sel = id
    guardar()
    local d = L.de(id)
    local o = L.POR_ID[id]
    local gx, gz = motor.chao(x, y)
    E.arrasto = { id = id, ox = (gx or 0) - (o.x + d.x), oz = (gz or 0) - (o.z + d.z), moveu = false }
  else
    E.sel = nil
    E.arrasto = nil
  end
end

function E.soltar()
  if E.arrasto then
    if E.arrasto.moveu then mudou() else table.remove(E.desfazer) end
    E.arrasto = nil
  end
end

function E.atualizar(dt)
  if E.tempo_msg then
    E.tempo_msg = E.tempo_msg - dt
    if E.tempo_msg <= 0 then E.mensagem, E.tempo_msg = nil, nil end
  end
  if E.arrasto and motor.mouse_baixo() then
    local mx, my = motor.mouse()
    local gx, gz = motor.chao(mx, my)
    if gx then
      local a = E.arrasto
      E.mover_para(a.id, gx - a.ox, gz - a.oz)
      a.moveu = true
    end
  end
  local r = motor.roda()
  if r ~= 0 then
    local mx = motor.mouse()
    if E.painel and mx < LISTA.x + LISTA.w then E.rolagem = E.rolagem - r * ITEM
    else M.rolar(r) end
  end
end

local function botao(id, y, texto, fn, o)
  U.botao(id, ACOES.x + 10, y, ACOES.w - 20, 40, texto, o or { cor = "#4a3627", cor_texto = cor.texto, tam = 14 }, fn)
end

function E.desenhar()
  -- marcadores dos objetos
  for _, o in ipairs(L.OBJETOS) do
    local d = L.dados[o.id]
    local sx, sy = motor.projetar(o.x + (d and d.x or 0), 0.3, o.z + (d and d.z or 0))
    if sx then
      local sel = o.id == E.sel
      motor.circulo(sx, sy, sel and 11 or 7, sel and cor.ouro or "#00000088")
      motor.anel(sx, sy, sel and 11 or 6, sel and 14 or 8, sel and "#ffffff" or cor.ouro)
    end
  end

  U.limpar()
  U.botao("editor_sair", 372, 8, 216, 40, "Sair e salvar", { tam = 15 }, function() E.fechar() end)
  U.botao("editor_painel", 8, 8, 214, 40, E.painel and "Esconder painéis" or "Mostrar painéis", { cor = "#21150ee8", cor_texto = cor.texto, tam = 14 },
    function() E.painel = not E.painel end)

  if E.mensagem then
    local w = motor.largura_texto(E.mensagem, 15, true) + 32
    motor.retangulo(480 - w / 2, 54, w, 32, cor.ouro, 14)
    motor.texto(E.mensagem, 480, 60, 15, cor.texto_ouro, "centro", true)
  elseif E.sel then
    local d = L.de(E.sel)
    local o = L.POR_ID[E.sel]
    local txt = o.nome .. string.format("  x %.2f  z %.2f", o.x + d.x, o.z + d.z):gsub("%.", ",")
    local w = motor.largura_texto(txt, 14, true) + 28
    motor.retangulo(480 - w / 2, 54, w, 30, "#21150ee8", 10)
    motor.texto(txt, 480, 60, 14, cor.texto, "centro", true)
  else
    local txt = "Arraste um ponto dourado para mover o objeto"
    local w = motor.largura_texto(txt, 14, true) + 28
    motor.retangulo(480 - w / 2, 54, w, 30, "#21150ee8", 10)
    motor.texto(txt, 480, 60, 14, cor.texto, "centro", true)
  end

  if not E.painel then return end

  -- lista de objetos
  U.painel(LISTA.x, LISTA.y, LISTA.w, LISTA.h, "#21150ef0")
  U.zona("editor_fundo_lista", LISTA)
  local total = #L.OBJETOS * ITEM
  local maximo = math.max(0, total - (LISTA.h - 12))
  E.rolagem = util.limitar(E.rolagem, 0, maximo)
  motor.recorte(LISTA.x, LISTA.y + 6, LISTA.w, LISTA.h - 12)
  local y = LISTA.y + 6 - E.rolagem
  for _, o in ipairs(L.OBJETOS) do
    if y + ITEM > LISTA.y + 6 and y < LISTA.y + LISTA.h - 6 then
      local sel = o.id == E.sel
      motor.retangulo(LISTA.x + 6, y + 1, LISTA.w - 12, ITEM - 3, sel and cor.ouro or "#3d291b", 7)
      motor.texto(o.nome, LISTA.x + 14, y + 8, 13, sel and cor.texto_ouro or cor.texto, "esquerda", sel)
      if y >= LISTA.y and y + ITEM <= LISTA.y + LISTA.h then
        U.zona("editor_item_" .. o.id, { x = LISTA.x + 6, y = y + 1, w = LISTA.w - 12, h = ITEM - 3 }, function() E.sel = o.id end)
      end
    end
    y = y + ITEM
  end
  motor.recorte()

  -- ações
  U.painel(ACOES.x, ACOES.y, ACOES.w, ACOES.h, "#21150ef0")
  U.zona("editor_fundo_acoes", ACOES)
  local ax = ACOES.x + 10
  local ativo = E.sel ~= nil
  local od = { ativo = ativo, cor = ativo and "#4a3627" or "#2a2019", cor_texto = ativo and cor.texto or cor.texto_fraco, tam = 14 }
  motor.texto("Girar", ax, ACOES.y + 10, 13, cor.texto_fraco)
  U.botao("editor_girar_menos", ax, ACOES.y + 28, 92, 40, "-15°", od, function() acao(function(d) d.g = d.g - math.rad(15) end) J.aplicar_visual() end)
  U.botao("editor_girar_mais", ax + 102, ACOES.y + 28, 92, 40, "+15°", od, function() acao(function(d) d.g = d.g + math.rad(15) end) J.aplicar_visual() end)
  motor.texto("Altura", ax, ACOES.y + 74, 13, cor.texto_fraco)
  U.botao("editor_descer", ax, ACOES.y + 92, 92, 40, "Descer", od, function() acao(function(d) d.y = d.y - 0.1 end) end)
  U.botao("editor_subir", ax + 102, ACOES.y + 92, 92, 40, "Subir", od, function() acao(function(d) d.y = d.y + 0.1 end) end)
  botao("editor_restaurar", ACOES.y + 142, "Voltar à posição original", function()
    guardar(); L.restaurar(E.sel); mudou(); J.aplicar_visual()
  end, od)
  botao("editor_desfazer", ACOES.y + 190, "Desfazer (" .. #E.desfazer .. ")", function()
    local ultimo = table.remove(E.desfazer)
    if ultimo then L.dados = ultimo; mudou(); J.aplicar_visual() end
  end)
  botao("editor_grade", ACOES.y + 238, E.grade and "Encaixe: ligado" or "Encaixe: desligado", function() E.grade = not E.grade end)
  botao("editor_copiar", ACOES.y + 286, "Copiar posições", function()
    motor.copiar(L.texto())
    msg("Copiado! Cole na conversa para virar oficial.")
  end, { tam = 14 })

  if E.confirmar then
    motor.texto("Apagar suas edições?", ax, ACOES.y + 340, 13, "#ff9a8a", "esquerda", true)
    U.botao("editor_tudo_nao", ax, ACOES.y + 362, 92, 40, "Não", { tam = 14 }, function() E.confirmar = false end)
    U.botao("editor_tudo_sim", ax + 102, ACOES.y + 362, 92, 40, "Sim", { cor = cor.vermelho, cor_texto = "#ffffff", tam = 14 }, function()
      guardar(); L.restaurar(); mudou(); J.aplicar_visual(); E.confirmar = false
    end)
  else
    botao("editor_tudo", ACOES.y + 340, "Restaurar tudo", function() E.confirmar = true end, { cor = "#5a2a22", cor_texto = "#ffb0a2", tam = 14 })
  end
  motor.texto("Roda do mouse: zoom", ax, ACOES.y + 416, 13, cor.texto_fraco)
  motor.texto("O jogo fica pausado aqui", ax, ACOES.y + 436, 13, cor.texto_fraco)
end

return E
