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

local LISTA = { x = 8, y = 56, w = 158, h = 448 }
local ACOES = { x = 810, y = 56, w = 142, h = 440 }
local ITEM = 40       -- altura da linha (alvo de toque)
local VISIVEIS = 8    -- linhas inteiras visíveis na lista
local LISTA_TOPO = 74 -- categoria e título acima das linhas

-- objetos da categoria escolhida
local function itens()
  local l = {}
  for _, o in ipairs(L.OBJETOS) do
    if o.cat == E.cat then l[#l + 1] = o end
  end
  return l
end

local function msg(t) E.mensagem, E.tempo_msg = t, 3 end

function E.abrir()
  E.ativo = true
  E.sel, E.arrasto, E.confirmar = nil, nil, false
  E.rolagem, E.desfazer, E.grade, E.painel = 0, {}, true, true
  E.mudou = false
  E.cat = "Móveis"
  J.editando, J.previa = true, true
end

function E.fechar()
  E.ativo = false
  E.arrasto = nil
  J.editando, J.previa = false, false
  L.salvar()
  J.aplicar_layout()
  M.iniciar()
  local sem = J.lugares_sem_rota()
  if sem > 0 then J.avisar(sem .. " lugar(es) sem caminho livre: a pessoa atravessa os móveis para chegar.", 5) end
end

local function guardar()
  local copia = {}
  for id, d in pairs(L.dados) do copia[id] = { x = d.x, z = d.z, y = d.y, g = d.g } end
  copia._tamanho = {}
  for k, v in pairs(L.tamanho) do copia._tamanho[k] = v end
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
  L.limitar(E.sel)
  mudou()
end

function E.mover_para(id, x, z)
  if E.grade then
    x = math.floor(x * 4 + 0.5) / 4
    z = math.floor(z * 4 + 0.5) / 4
  end
  L.colocar(id, x, z)
  L.limitar(id)
  J.aplicar_visual()
end

function E.pegar(x, y)
  local melhor, md = nil, 34
  for _, o in ipairs(itens()) do
    local dx, dz = L.desloc(o.id)
    local sx, sy = motor.projetar(o.x + dx, 0.3, o.z + dz)
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
    local ax, az = L.desloc(id)
    E.arrasto = { id = id, ox = (gx or 0) - (o.x + ax), oz = (gz or 0) - (o.z + az), moveu = false, sx = x, sy = y }
  else
    E.sel = nil
    E.arrasto = nil
    E.pan = { x = x, y = y }   -- arrastar o chão vazio move a câmera (com zoom)
  end
end

function E.soltar()
  E.pan = nil
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
    local a = E.arrasto
    -- só um clique, sem arrastar, seleciona: não pode encaixar o objeto na grade
    if math.abs(mx - a.sx) + math.abs(my - a.sy) > 4 then a.saiu = true end
    if gx and a.saiu then
      E.mover_para(a.id, gx - a.ox, gz - a.oz)
      a.moveu = true
    end
  elseif E.arrasto then
    -- soltou com o mouse fora da janela
    E.soltar()
  end
  if E.pan and motor.mouse_baixo() then
    local px, py = motor.mouse()
    M.arrastar(px - E.pan.x, py - E.pan.y)
    E.pan.x, E.pan.y = px, py
  elseif E.pan then
    E.pan = nil
  end
  local r = motor.roda()
  if r ~= 0 then
    local mx = motor.mouse()
    if E.painel and mx < LISTA.x + LISTA.w then E.rolagem = E.rolagem - r * ITEM
    else M.rolar(r) end
  end
end

local function botao(id, y, texto, fn, o)
  U.botao(id, ACOES.x + 8, y, ACOES.w - 16, 40, texto, o or { cor = "#4a3627", cor_texto = cor.texto, tam = 14 }, fn)
end

local function pill(txt, tam)
  local cx = (LISTA.x + LISTA.w + ACOES.x) / 2
  local w = motor.largura_texto(txt, tam, true) + 28
  return cx, w
end

-- nome do objeto junto do marcador, sempre dentro da área livre da tela
local function etiqueta(nome, sx, sy, destaque)
  local w = motor.largura_texto(nome, 14, true) + 20
  local esq, dir = 8, 952
  if E.painel and not E.arrasto then esq, dir = LISTA.x + LISTA.w + 6, ACOES.x - 6 end
  local x = util.limitar(sx - w / 2, esq, math.max(esq, dir - w))
  local y = sy - 46
  if y < 52 then y = sy + 20 end
  motor.retangulo(x, y, w, 28, destaque and cor.ouro or "#21150ef5", 8)
  motor.texto(nome, x + w / 2, y + 5, 14, destaque and cor.texto_ouro or "#ffffff", "centro", true)
end

-- o que está sob o mouse: linha da lista ou marcador da cena
local function achar_sob_mouse()
  if motor.plataforma ~= "desktop" or E.arrasto then return nil end
  local mx, my = motor.mouse()
  if E.painel then
    if util.dentro(mx, my, LISTA) then
      local topo = LISTA.y + LISTA_TOPO
      if my >= topo and my < topo + VISIVEIS * ITEM then
        local o = itens()[math.floor((my - topo + E.rolagem) / ITEM) + 1]
        return o and o.id
      end
      return nil
    end
    if util.dentro(mx, my, ACOES) then return nil end
  end
  if my < 52 then return nil end
  return E.pegar(mx, my)
end

local function desenhar_marcadores(sob)
  local function posicao(o)
    local dx, dz = L.desloc(o.id)
    return motor.projetar(o.x + dx, 0.3, o.z + dz)
  end
  for _, o in ipairs(itens()) do
    if o.id ~= E.sel and o.id ~= sob then
      local sx, sy = posicao(o)
      if sx then
        motor.circulo(sx, sy, 6, "#000000b0")
        motor.circulo(sx, sy, 4, cor.ouro)
      end
    end
  end
  if E.sel then
    local o = L.POR_ID[E.sel]
    local sx, sy = posicao(o)
    if sx then
      motor.circulo(sx, sy, 10, cor.ouro)
      motor.anel(sx, sy, 10, 13, "#ffffff")
      etiqueta(o.nome, sx, sy, true)
    end
  end
  if sob and sob ~= E.sel then
    local o = L.POR_ID[sob]
    local sx, sy = posicao(o)
    if sx then
      motor.circulo(sx, sy, 8, "#ffffff")
      motor.anel(sx, sy, 8, 11, cor.ouro)
      etiqueta(o.nome, sx, sy, false)
    end
  end
end

-- rolagem sempre em linhas inteiras, para nenhum nome aparecer cortado
local function ajustar_rolagem()
  local alt = VISIVEIS * ITEM
  if E.sel ~= E.sel_visto then
    E.sel_visto = E.sel
    for i, o in ipairs(itens()) do
      if o.id == E.sel then
        if (i - 1) * ITEM < E.rolagem then E.rolagem = (i - 1) * ITEM
        elseif i * ITEM > E.rolagem + alt then E.rolagem = i * ITEM - alt end
      end
    end
  end
  local maximo = math.max(0, #itens() * ITEM - alt)
  E.rolagem = util.limitar(math.floor(E.rolagem / ITEM + 0.5) * ITEM, 0, maximo)
  return maximo
end

-- escolha do que editar: uma categoria de objetos ou o tamanho da taverna
local function seletor_categoria()
  local w = (LISTA.w - 18) / 2
  local function trocar(delta)
    local n = #L.CATEGORIAS
    for i, c in ipairs(L.CATEGORIAS) do
      if c == E.cat then
        E.cat = L.CATEGORIAS[(i - 1 + delta) % n + 1]
        E.rolagem, E.sel, E.sel_visto = 0, nil, nil
        break
      end
    end
  end
  U.botao("editor_cat_ant", LISTA.x + 4, LISTA.y + 4, 40, 40, "<", { cor = "#4a3627", cor_texto = cor.texto, tam = 15 }, function() trocar(-1) end)
  U.botao("editor_cat_prox", LISTA.x + LISTA.w - 44, LISTA.y + 4, 40, 40, ">", { cor = "#4a3627", cor_texto = cor.texto, tam = 15 }, function() trocar(1) end)
  motor.texto(E.cat, LISTA.x + LISTA.w / 2, LISTA.y + 5, 13, cor.ouro, "centro", true)
  local pos = 1
  for i, c in ipairs(L.CATEGORIAS) do if c == E.cat then pos = i end end
  motor.texto(pos .. " de " .. #L.CATEGORIAS, LISTA.x + LISTA.w / 2, LISTA.y + 24, 13, cor.texto_fraco, "centro")
  return w
end

local LADOS = { { "dir", "Direita" }, { "frente", "Frente" }, { "fundo", "Fundo" }, { "oeste", "Esquerda" } }
local SALAS = { { "jardim_l", "Jardim: largura" }, { "jardim_p", "Jardim: fundo" }, { "cerv_l", "Cervejaria: largura" },
  { "cerv_p", "Cervejaria: fundo" }, { "circ_l", "Invocação: largura" }, { "circ_p", "Invocação: fundo" } }

local function desenhar_tamanho(titulo, lados, passo)
  local y = LISTA.y + 48
  motor.texto(titulo, LISTA.x + 10, y, 13, cor.texto, "esquerda", true)
  y = y + 20
  for _, l in ipairs(lados) do
    local lado = l[1]
    local tam_lado = L.tamanho[lado]
    motor.texto(l[2] .. ": +" .. tam_lado .. " m", LISTA.x + 10, y, 13, tam_lado > 0 and cor.ouro or cor.texto, "esquerda", tam_lado > 0)
    if tam_lado >= L.TAMANHO_MAX then motor.texto("máx", LISTA.x + LISTA.w - 10, y, 13, cor.ouro, "direita", true) end
    local bw = (LISTA.w - 18) / 2
    local function estilo(ativo)
      return { ativo = ativo, cor = ativo and "#4a3627" or "#2a2019", cor_texto = ativo and cor.texto or cor.texto_fraco, tam = 15 }
    end
    local function muda(delta)
      guardar()
      L.mudar_tamanho(lado, delta)
      mudou()
      J.aplicar_visual()
    end
    U.botao("editor_tam_menos_" .. lado, LISTA.x + 6, y + 18, bw, 40, "-1 m", estilo(tam_lado > 0), function() muda(-1) end)
    U.botao("editor_tam_mais_" .. lado, LISTA.x + 12 + bw, y + 18, bw, 40, "+1 m", estilo(tam_lado < L.TAMANHO_MAX), function() muda(1) end)
    y = y + passo
  end
  if lados == LADOS then
    U.paragrafo("As paredes acompanham. Depois, ligue \"FPS e fluxo\" nas Configurações para medir.", LISTA.x + 10, y + 2, LISTA.w - 20, 13, cor.texto_fraco)
  end
end

local function desenhar_lista(sob, maximo)
  U.painel(LISTA.x, LISTA.y, LISTA.w, LISTA.h, "#21150ef0")
  U.zona("editor_fundo_lista", LISTA)
  seletor_categoria()
  if E.cat == "Tamanho" then
    desenhar_tamanho("Tamanho do salão", LADOS, 66)
    return
  elseif E.cat == "Salas" then
    desenhar_tamanho("Tamanho das salas", SALAS, 62)
    return
  end
  local objetos = itens()
  local primeiro = E.rolagem / ITEM + 1
  local ultimo = math.min(#objetos, primeiro + VISIVEIS - 1)
  motor.texto(string.format("Itens %d-%d de %d", primeiro, ultimo, #objetos), LISTA.x + 10, LISTA.y + 50, 13, cor.texto)
  local topo = LISTA.y + LISTA_TOPO
  local largura = LISTA.w - 20
  for i = primeiro, ultimo do
    local o = objetos[i]
    local y = topo + (i - primeiro) * ITEM
    local sel = o.id == E.sel
    motor.retangulo(LISTA.x + 6, y + 1, largura, ITEM - 3, sel and cor.ouro or (o.id == sob and "#5e4330" or "#3d291b"), 7)
    motor.texto(o.nome, LISTA.x + 12, y + 10, 13, sel and cor.texto_ouro or cor.texto, "esquerda", sel)
    U.zona("editor_item_" .. o.id, { x = LISTA.x + 6, y = y, w = largura, h = ITEM }, function() E.sel = o.id end)
  end
  -- barra de rolagem
  local alt = VISIVEIS * ITEM
  local bx = LISTA.x + LISTA.w - 11
  motor.retangulo(bx, topo, 5, alt - 3, "#00000060", 2)
  local h = math.min(alt - 3, math.max(24, alt * VISIVEIS / math.max(1, #objetos)))
  local p = maximo > 0 and E.rolagem / maximo or 0
  motor.retangulo(bx, topo + p * (alt - 3 - h), 5, h, cor.ouro, 2)
  -- botões de página, para quem não usa a roda
  local by = topo + alt + 6
  local bw = (LISTA.w - 18) / 2
  local function pagina(id, x, texto, ativo, delta)
    U.botao(id, x, by, bw, 40, texto, { ativo = ativo, cor = ativo and "#4a3627" or "#2a2019", cor_texto = ativo and cor.texto or cor.texto_fraco, tam = 13 },
      function() E.rolagem = E.rolagem + delta end)
  end
  pagina("editor_lista_acima", LISTA.x + 6, "Acima", E.rolagem > 0, -(VISIVEIS - 1) * ITEM)
  pagina("editor_lista_abaixo", LISTA.x + 12 + bw, "Abaixo", E.rolagem < maximo, (VISIVEIS - 1) * ITEM)
end

local function desenhar_acoes()
  U.painel(ACOES.x, ACOES.y, ACOES.w, ACOES.h, "#21150ef0")
  U.zona("editor_fundo_acoes", ACOES)
  local ax = ACOES.x + 8
  local meia = (ACOES.w - 22) / 2
  local ax2 = ax + meia + 6
  local ativo = E.sel ~= nil
  local od = { ativo = ativo, cor = ativo and "#4a3627" or "#2a2019", cor_texto = ativo and cor.texto or cor.texto_fraco, tam = 14 }
  motor.texto("Girar", ax, ACOES.y + 8, 13, cor.texto)
  U.botao("editor_girar_menos", ax, ACOES.y + 28, meia, 40, "-15°", od, function() acao(function(d) d.g = d.g - math.rad(15) end) J.aplicar_visual() end)
  U.botao("editor_girar_mais", ax2, ACOES.y + 28, meia, 40, "+15°", od, function() acao(function(d) d.g = d.g + math.rad(15) end) J.aplicar_visual() end)
  motor.texto("Altura", ax, ACOES.y + 74, 13, cor.texto)
  U.botao("editor_descer", ax, ACOES.y + 94, meia, 40, "Descer", od, function() acao(function(d) d.y = d.y - 0.1 end) end)
  U.botao("editor_subir", ax2, ACOES.y + 94, meia, 40, "Subir", od, function() acao(function(d) d.y = d.y + 0.1 end) end)
  botao("editor_restaurar", ACOES.y + 144, "Posição original", function()
    guardar(); L.restaurar(E.sel); mudou(); J.aplicar_visual()
  end, od)
  botao("editor_desfazer", ACOES.y + 190, "Desfazer (" .. #E.desfazer .. ")", function()
    local ultimo = table.remove(E.desfazer)
    if ultimo then
      L.tamanho = ultimo._tamanho
      ultimo._tamanho = nil
      L.dados = ultimo
      mudou()
      J.aplicar_visual()
    end
  end)
  botao("editor_grade", ACOES.y + 236, E.grade and "Encaixe: ligado" or "Encaixe: desligado", function() E.grade = not E.grade end)
  botao("editor_copiar", ACOES.y + 282, "Copiar posições", function()
    motor.copiar(L.texto())
    msg("Copiado! Cole na conversa para virar oficial.")
  end)

  if E.confirmar then
    motor.texto("Apagar tudo?", ax, ACOES.y + 330, 13, "#ff9a8a", "esquerda", true)
    U.botao("editor_tudo_nao", ax, ACOES.y + 350, meia, 40, "Não", { tam = 14 }, function() E.confirmar = false end)
    U.botao("editor_tudo_sim", ax2, ACOES.y + 350, meia, 40, "Sim", { cor = cor.vermelho, cor_texto = "#ffffff", tam = 14 }, function()
      guardar(); L.restaurar(); mudou(); J.aplicar_visual(); E.confirmar = false
    end)
  else
    botao("editor_tudo", ACOES.y + 340, "Restaurar tudo", function() E.confirmar = true end, { cor = "#5a2a22", cor_texto = "#ffb0a2", tam = 14 })
  end
  motor.texto("Roda: zoom", ax, ACOES.y + 398, 13, cor.texto)
  motor.texto("Jogo pausado", ax, ACOES.y + 416, 13, cor.texto)
end

function E.desenhar()
  local maximo = ajustar_rolagem()
  local sob = achar_sob_mouse()
  desenhar_marcadores(sob)

  U.limpar()
  U.botao("editor_painel", LISTA.x, 8, LISTA.w, 40, E.painel and "Esconder painéis" or "Mostrar painéis", { cor = "#21150ee8", cor_texto = cor.texto, tam = 14 },
    function() E.painel = not E.painel end)
  U.botao("editor_sair", ACOES.x, 8, ACOES.w, 40, "Sair e salvar", { tam = 15 }, function() E.fechar() end)

  local txt, tam, fundo, frente = nil, 14, "#21150ee8", cor.texto
  if E.mensagem then
    txt, fundo, frente = E.mensagem, cor.ouro, cor.texto_ouro
  elseif E.sel then
    local o = L.POR_ID[E.sel]
    local dx, dz = L.desloc(E.sel)
    txt = o.nome .. string.format("  x %.2f  z %.2f", o.x + dx, o.z + dz):gsub("%.", ",")
  else
    txt = "Arraste um ponto dourado para mover o objeto"
  end
  local cx, w = pill(txt, tam)
  motor.retangulo(cx - w / 2, 12, w, 32, fundo, 10)
  motor.texto(txt, cx, 18, tam, frente, "centro", true)

  -- enquanto arrasta, os painéis somem e a taverna fica inteira à vista
  if not E.painel or E.arrasto then return end
  desenhar_lista(sob, maximo)
  desenhar_acoes()
end

return E
