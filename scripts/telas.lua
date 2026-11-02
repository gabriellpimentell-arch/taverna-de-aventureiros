-- =============================================================================
--  HUD, abas e menus. A taverna ocupa a tela; a evolução fica em abas separadas.
-- =============================================================================

local J = require("jogo")
local A = require("arvore")
local C = require("config")
local util = require("util")
local U = require("ui")
local M = require("mundo")
local cor = util.cores
local fmt = util.formatar

local T = {}

local AREA = { x = 12, y = 62, w = 936, h = 412 }   -- conteúdo das abas

local function duracao_texto(s)
  s = math.max(0, math.floor(s))
  if s < 60 then return s .. " s" end
  local min = math.floor(s / 60)
  if min < 60 then return min .. " min" .. (s % 60 > 0 and (" " .. (s % 60) .. " s") or "") end
  local h = math.floor(min / 60)
  if h < 100 then return h .. " h " .. (min % 60) .. " min" end
  return h .. " h"
end

function T.iniciar()
  T.aba = "taverna"
  T.modal = nil
  T.ouro_visivel = J.estado.ouro
  T.total_antes = J.estado.total
  T.pulso = 0
  T.toque = nil
  T.arv = { x = 0, y = 0, zoom = 0.85, sel = nil }
  T.rolagem = { aventureiros = 0 }
  T.confirmar = false
  M.iniciar()
  T.aplicar_opcoes()
end

function T.aplicar_opcoes()
  local o = J.estado.opcoes
  motor.volume(o.efeitos, o.musica)
  motor.sombras(o.sombras)
end

-- Abas -----------------------------------------------------------------------------

local function abas_visiveis()
  local l = { { id = "taverna", nome = "Taverna" }, { id = "arvore", nome = "Árvore" } }
  if J.prateleira_aberta() then l[#l + 1] = { id = "missoes", nome = "Missões" } end
  if J.mercadinho_aberto() then l[#l + 1] = { id = "mercadinho", nome = "Mercadinho" } end
  if J.jardim_aberto() then l[#l + 1] = { id = "producao", nome = "Produção" } end
  if J.pode_contratar_aberto() then l[#l + 1] = { id = "aventureiros", nome = "Aventureiros" } end
  if J.invocacao_aberta() then l[#l + 1] = { id = "invocacao", nome = "Invocação" } end
  return l
end

local function barra_abas()
  local l = abas_visiveis()
  local w = math.min(150, (960 - 24 - (#l - 1) * 6) / #l)
  local total = w * #l + (#l - 1) * 6
  local x = (960 - total) / 2
  for _, a in ipairs(l) do
    local sel = T.aba == a.id
    U.botao("aba_" .. a.id, x, 486, w, 44, a.nome,
      { cor = sel and cor.ouro or "#2c1d13f0", cor_texto = sel and cor.texto_ouro or cor.texto, tam = 15 },
      function() T.aba = a.id end)
    if a.id == "arvore" and J.tem_compra() then
      motor.circulo(x + w - 10, 496, 6, cor.vermelho)
      motor.anel(x + w - 10, 496, 5, 7, "#ffffff")
    end
    x = x + w + 6
  end
end

-- HUD --------------------------------------------------------------------------------

-- Faixa central do topo, entre o ouro e os botões. Texto longo usa duas linhas.
local function pilula(txt, y, fundo, frente, raio)
  local tw = motor.largura_texto(txt, 14, true)
  local maximo = 492
  local cx = 502
  if tw + 28 <= maximo then
    local w = math.max(200, tw + 28)
    motor.retangulo(cx - w / 2, y + 2, w, 40, fundo, raio or 10)
    motor.texto(txt, cx, y + 13, 14, frente, "centro", true)
  else
    motor.retangulo(cx - maximo / 2, y, maximo, 44, fundo, raio or 10)
    U.paragrafo(txt, cx - maximo / 2 + 12, y + 3, maximo - 24, 14, frente, true, "centro")
  end
end

local function hud()
  local e = J.estado
  motor.retangulo(12, 10, 236, 44, "#21150ee8", 12)
  local p = T.pulso
  U.moeda(34, 32, 14 + p * 2)
  motor.texto(fmt(T.ouro_visivel), 54, 11, 22 + p * 2, cor.ouro, "esquerda", true)
  local rps = e.rps < 10 and (string.format("%.1f", e.rps):gsub("%.", ",")) or fmt(e.rps)
  motor.texto("+" .. rps .. " por segundo", 54, 35, 13, cor.verde, "esquerda", true)

  -- objetivo atual (o aviso aparece neste mesmo lugar, sem cobrir o conteúdo)
  if not J.aviso then
    pilula(J.objetivo(), 10, "#21150ee8", cor.texto)
  end

  -- botões de sistema
  U.botao("minimizar", 852, 10, 44, 44, nil, { cor = "#21150ee8" }, function() motor.minimizar() end)
  motor.retangulo(864, 36, 20, 3, cor.texto, 1)
  U.botao("config", 904, 10, 44, 44, nil, { cor = "#21150ee8" }, function() T.modal = "config"; T.confirmar = false end)
  U.engrenagem(926, 32, cor.texto)

  local nv = J.nivel_reputacao()
  if nv > 0 or J.ef("propaganda") > 0 then
    motor.retangulo(760, 12, 84, 40, "#21150ee8", 10)
    motor.texto("Reputação", 802, 13, 13, cor.texto_fraco, "centro")
    motor.texto("Nível " .. nv, 802, 28, 14, cor.ouro, "centro", true)
  end

  if e.opcoes.fps then
    motor.texto(motor.fps() .. " FPS", 948, 60, 13, cor.texto, "direita", true)
  end
end

local function aviso()
  local a = J.aviso
  if not a then return end
  local entrada = util.limitar(a.vida / 0.3, 0, 1)
  local saida = util.limitar((a.duracao - a.vida) / 0.4, 0, 1)
  motor.opacidade(math.min(entrada, saida))
  pilula(a.texto, 10 - (1 - util.suave(entrada)) * 12, cor.ouro, cor.texto_ouro)
  motor.opacidade(1)
end

-- dica de primeiro atendimento
local function dica()
  if J.estado.servidos > 0 or T.aba ~= "taverna" or T.modal then return end
  for _, p in ipairs(J.pessoas) do
    if p.estado == "esperando" then
      local x, y = M.posicao_balao(p)
      if x then
        local txt = "Toque no balão para servir"
        local w = motor.largura_texto(txt, 15, true) + 28
        local salto = math.abs(math.sin(motor.tempo() * 4)) * 5
        local cx = util.limitar(x, w / 2 + 8, 952 - w / 2)
        local ty = y - 74 - salto
        motor.retangulo(cx - w / 2, ty, w, 30, cor.ouro, 15)
        motor.texto(txt, cx, ty + 6, 15, cor.texto_ouro, "centro", true)
        motor.triangulo(x - 8, ty + 29, x + 8, ty + 29, x, ty + 40, cor.ouro)
      end
      return
    end
  end
end

-- Árvore -----------------------------------------------------------------------------

local ZOOM_MIN, ZOOM_MAX = 0.6, 1.3
local ORDEM_RAMOS = { "salao", "clientes", "servico", "bebidas", "guilda", "mercado", "herois" }

local function no_tela(no)
  local a = T.arv
  return 480 + a.x + no.x * a.zoom, 268 + a.y + no.y * a.zoom
end

-- O jogador vê o que já tem, o que pode comprar e o passo seguinte (bloqueado).
local function no_visivel(no)
  if J.nivel(no.id) > 0 or J.no_liberado(no) then return true end
  local pai = no.pre[1] and A.POR_ID[no.pre[1]]
  return pai ~= nil and J.no_liberado(pai)
end

local function limites_visiveis()
  local x0, y0, x1, y1, n = 0, 0, 0, 0, 0
  for _, no in ipairs(A.NOS) do
    if no_visivel(no) then
      n = n + 1
      x0, x1 = math.min(x0, no.x), math.max(x1, no.x)
      y0, y1 = math.min(y0, no.y), math.max(y1, no.y)
    end
  end
  return x0, y0, x1, y1, n
end

-- Enquadra tudo o que está visível, descontando a folga para nós e nomes.
local function enquadrar_arvore()
  local a = T.arv
  local x0, y0, x1, y1, n = limites_visiveis()
  local zx = (960 - 2 * 78) / math.max(1, x1 - x0)
  local zy = (416 - 44 - 62) / math.max(1, y1 - y0)
  a.zoom = util.limitar(math.min(zx, zy), ZOOM_MIN, 1.05)
  a.x = -a.zoom * (x0 + x1) / 2
  a.y = 266 + 9 - 268 - a.zoom * (y0 + y1) / 2
  a.manual = false
  a.n_visiveis = n
end

-- Deixa arrastar só até o limite do que existe, em qualquer zoom.
local function limitar_arvore()
  local a = T.arv
  local x0, y0, x1, y1 = limites_visiveis()
  a.x = util.limitar(a.x, -x1 * a.zoom - 300, -x0 * a.zoom + 300)
  a.y = util.limitar(a.y, -y1 * a.zoom - 120, -y0 * a.zoom + 120)
end

-- Rótulos: cada um procura um lugar livre; se não houver, não é desenhado.
local function bate(r, lista)
  if r.x < 4 or r.x + r.w > 956 or r.y < 60 or r.y + r.h > 476 then return true end
  for _, o in ipairs(lista) do
    if r.x < o.x + o.w and r.x + r.w > o.x and r.y < o.y + o.h and r.y + r.h > o.y then return true end
  end
  return false
end

local function colocar(cands, ocupado)
  for _, r in ipairs(cands) do
    if not bate(r, ocupado) then
      ocupado[#ocupado + 1] = r
      return r
    end
  end
  return nil
end

local function candidatos_no(x, y, raio, w, h)
  local f = raio + 5
  return {
    { x = x - w / 2, y = y + f, w = w, h = h },
    { x = x - w / 2, y = y - f - h, w = w, h = h },
    { x = x + f, y = y - h / 2, w = w, h = h },
    { x = x - f - w, y = y - h / 2, w = w, h = h },
  }
end

local function desenhar_rotulo_no(r, no, lib, custo, pode)
  motor.retangulo(r.x, r.y, r.w, r.h, "#1a110bd8", 4)
  local cx = r.x + r.w / 2
  motor.texto(lib and no.nome or "???", cx, r.y + 1, 13, lib and cor.texto or cor.texto_fraco, "centro", true)
  if custo then
    U.rotulo_preco(nil, custo, r.x, r.y + 17, r.w, 17, 13, pode and cor.ouro or cor.texto_fraco)
  end
end

local function tela_arvore(entrando)
  local a = T.arv
  local _, _, _, _, nvis = limites_visiveis()
  if entrando or (not a.manual and nvis ~= a.n_visiveis) then enquadrar_arvore() end
  motor.retangulo(0, 56, 960, 424, "#1a110bf4")
  motor.recorte(0, 56, 960, 424)
  local zoom = a.zoom

  -- ligações
  local cx, cy = 480 + a.x, 268 + a.y
  for _, no in ipairs(A.NOS) do
    if no_visivel(no) then
      local x, y = no_tela(no)
      local tem = J.nivel(no.id) > 0
      local c = tem and A.RAMOS[no.ramo].cor or "#6e5a48"
      local esp = tem and 4 or 2.5
      if no.pai then
        local pai = A.POR_ID[no.pre[1]]
        motor.linha(x, y, select(1, no_tela(pai)), select(2, no_tela(pai)), esp, c)
      else
        motor.linha(x, y, cx, cy, esp, c)
      end
      if no.req and no_visivel(A.POR_ID[no.req]) then
        local r = A.POR_ID[no.req]
        motor.linha(x, y, select(1, no_tela(r)), select(2, no_tela(r)), 1.5, "#8c7a6a")
      end
    end
  end

  -- centro
  local rc0 = 34 * zoom
  motor.circulo(cx, cy, rc0, "#3d291b")
  motor.anel(cx, cy, rc0 - 3 * zoom, rc0, cor.ouro)
  U.caneca(cx - 1, cy, 1.1 * zoom)

  -- nós
  local raio = math.max(19, 25 * zoom)
  local ocupado = { { x = cx - rc0 - 3, y = cy - rc0 - 3, w = rc0 * 2 + 6, h = rc0 * 2 + 6 } }
  for _, no in ipairs(A.NOS) do
    if no_visivel(no) then
      local x, y = no_tela(no)
      ocupado[#ocupado + 1] = { x = x - raio - 3, y = y - raio - 3, w = raio * 2 + 6, h = raio * 2 + 6 }
      local nv = J.nivel(no.id)
      local lib = J.no_liberado(no)
      local pode = J.pode_comprar_no(no)
      local rc = A.RAMOS[no.ramo].cor
      motor.circulo(x, y, raio + 3, "#00000080")
      motor.circulo(x, y, raio, nv > 0 and rc or (lib and "#4a3627" or "#2a2019"))
      if pode then
        local g = 1 + math.sin(motor.tempo() * 5) * 0.08
        motor.anel(x, y, raio * g, raio * g + 3.5, cor.ouro)
      elseif lib then
        motor.anel(x, y, raio - 2, raio, rc)
      else
        motor.anel(x, y, raio - 2, raio, "#7c6a5a")
      end
      if a.sel == no.id then motor.anel(x, y, raio + 4, raio + 7, "#ffffff") end
      if not lib then
        U.cadeado(x, y, "#b09c88")
      elseif no.max == 1 and nv > 0 then
        motor.texto("OK", x, y - 9, 15, "#21150e", "centro", true)
      else
        motor.texto(nv .. "/" .. no.max, x, y - 9, no.max >= 10 and 13 or 15, nv > 0 and "#21150e" or cor.texto, "centro", true)
      end
      U.zona("no_" .. no.id, { x = x - raio - 4, y = y - raio - 4, w = raio * 2 + 8, h = raio * 2 + 8 },
        function() a.sel = no.id; motor.som("clique") end, true)
    end
  end

  -- nomes: primeiro o que dá para comprar, depois os ramos, por fim os bloqueados
  local function nomes(de_liberados)
    for _, no in ipairs(A.NOS) do
      if no_visivel(no) and J.no_liberado(no) == de_liberados then
        local x, y = no_tela(no)
        local lib = de_liberados
        local custo = lib and not J.no_maximo(no) and J.custo_no(no) or nil
        local txt = lib and no.nome or "???"
        local w = motor.largura_texto(txt, 13, true) + 8
        if custo then w = math.max(w, motor.largura_texto(fmt(custo), 13, true) + 28) end
        local r = colocar(candidatos_no(x, y, raio, w, custo and 35 or 18), ocupado)
        if r then desenhar_rotulo_no(r, no, lib, custo, J.pode_comprar_no(no)) end
      end
    end
  end
  nomes(true)
  for _, id in ipairs(ORDEM_RAMOS) do
    local ramo = A.RAMOS[id]
    local ang = math.rad(ramo.angulo)
    local dx, dy = math.cos(ang), -math.sin(ang)
    local w = motor.largura_texto(ramo.nome, 13, true) + 12
    local cands = {}
    for _, d in ipairs({ 86, 106, 66, 126, 146, 166, 186 }) do
      for _, lado in ipairs({ 0, 15, -15, 30, -30, 45, -45, 60, -60 }) do
        local px = cx + (dx * d - dy * lado) * zoom / 0.85
        local py = cy + (dy * d + dx * lado) * zoom / 0.85
        cands[#cands + 1] = { x = px - w / 2, y = py - 9, w = w, h = 18 }
      end
    end
    local visivel = false
    for _, no in ipairs(A.NOS) do
      if no.ramo == id and no_visivel(no) then visivel = true; break end
    end
    local r = visivel and colocar(cands, ocupado)
    if r then
      motor.retangulo(r.x, r.y, r.w, r.h, "#1a110be8", 9)
      motor.texto(ramo.nome, r.x + r.w / 2, r.y + 1, 13, ramo.cor, "centro", true)
    end
  end
  nomes(false)
  motor.recorte()

  -- instruções e ajuda
  motor.retangulo(14, 64, 250, 28, "#21150ee8", 8)
  motor.texto("Arraste para navegar  •  Roda: zoom", 24, 69, 13, cor.texto_fraco)
  U.botao("arvore_centro", 14, 96, 104, 40, "Centralizar", { cor = "#3d291b", cor_texto = cor.texto, tam = 13 },
    enquadrar_arvore)

  -- detalhe do nó escolhido
  local no = a.sel and A.POR_ID[a.sel]
  if no then
    local px, py, pw, ph = 672, 64, 276, 280
    U.painel(px, py, pw, ph, "#2c1d13f8", A.RAMOS[no.ramo].cor)
    U.zona("painel_no", { x = px, y = py, w = pw, h = ph })
    local lib = J.no_liberado(no)
    local custo = J.custo_no(no)
    motor.texto(A.RAMOS[no.ramo].nome, px + 14, py + 10, 13, A.RAMOS[no.ramo].cor, "esquerda", true)
    local h = U.paragrafo(lib and no.nome or "Habilidade bloqueada", px + 14, py + 30, pw - 28 - 30, 18, cor.texto, true)
    local y = py + 34 + h
    local bx, by, bw = px + 14, py + ph - 58, pw - 28
    if lib then
      y = y + U.paragrafo(no.desc, px + 14, y, pw - 28, 14, cor.texto_fraco) + 8
      if no.max > 1 then motor.texto("Nível " .. J.nivel(no.id) .. " de " .. no.max, px + 14, y, 14, cor.ouro, "esquerda", true) end
    else
      local falta = {}
      for _, p in ipairs(no.pre) do
        if J.nivel(p) < 1 then falta[#falta + 1] = A.POR_ID[p].nome end
      end
      y = y + U.paragrafo("Para liberar, compre: " .. table.concat(falta, ", "), px + 14, y, pw - 28, 14, cor.texto) + 8
      motor.texto("Custo depois:", px + 14, y, 14, cor.texto_fraco)
      U.preco(custo, px + 14 + motor.largura_texto("Custo depois:", 14) + 2, y, 14, cor.ouro)
    end
    if J.no_maximo(no) then
      U.botao("comprar_no", bx, by, bw, 46, no.max > 1 and "Nível máximo" or "Já comprado", { ativo = false, cor_texto = cor.verde })
    elseif lib then
      local pode = J.pode_comprar_no(no)
      U.botao("comprar_no", bx, by, bw, 46, "Comprar", { preco = custo, ativo = pode, cor_texto = pode and cor.texto_ouro or cor.texto, som = "compra", tam = 16 },
        function() J.comprar_no(no.id) end)
      if not pode then
        motor.texto("Faltam " .. fmt(custo - J.estado.ouro) .. " de ouro", bx, by - 32, 13, cor.texto_fraco)
        U.barra(bx, by - 12, bw, 6, J.estado.ouro / custo, cor.ouro_escuro)
      end
    else
      U.botao("comprar_no", bx, by, bw, 46, "Bloqueado", { ativo = false, icone = "cadeado" })
    end
    U.botao("fechar_no", px + pw - 44, py + 4, 40, 40, "x", { cor = "#3d291b", cor_texto = cor.texto, tam = 15 }, function() a.sel = nil end)
  end
end

-- Painéis das abas --------------------------------------------------------------------

local function fundo_aba(titulo, sub)
  motor.retangulo(0, 56, 960, 424, "#1a110bf4")
  motor.texto(titulo, AREA.x + 8, AREA.y, 22, cor.texto, "esquerda", true)
  if sub then motor.texto(sub, AREA.x + 8, AREA.y + 30, 14, cor.texto_fraco) end
end

local function atalho_no(id, x, y, w)
  local no = A.POR_ID[id]
  if not J.no_liberado(no) then
    U.botao("nó_" .. id, x, y, w, 40, nil, { ativo = false })
    local tw = motor.largura_texto("Bloqueado", 13, true)
    U.cadeado(x + w / 2 - tw / 2 - 4, y + 11, cor.texto_fraco)
    motor.texto("Bloqueado", x + w / 2 + 9, y + 3, 13, cor.texto_fraco, "centro", true)
    U.rotulo_preco(nil, J.custo_no(no), x, y + 19, w, 20, 13, cor.texto)
  elseif J.no_maximo(no) then
    U.botao("nó_" .. id, x, y, w, 40, "Máximo", { ativo = false, tam = 13 })
  else
    local pode = J.pode_comprar_no(no)
    U.botao("nó_" .. id, x, y, w, 40, nil, { preco = J.custo_no(no), ativo = pode, cor_texto = pode and cor.texto_ouro or cor.texto, som = "compra", tam = 14 },
      function() J.comprar_no(id) end)
  end
end

local function tela_missoes()
  local e = J.estado
  fundo_aba("Prateleira de missões", J.missoes_comuns_ativas() .. " de " .. J.vagas_missao() .. " vagas ocupadas por aventureiros  •  "
    .. e.feitas .. " concluídas  •  a recompensa só entra na volta")

  local colunas = { { "Rank", 30 }, { "Duração", 90 }, { "Pagamento", 200 }, { "Espólio", 330 }, { "Concluídas", 450 }, { "Em andamento", 570 } }
  for _, c in ipairs(colunas) do motor.texto(c[1], AREA.x + c[2], AREA.y + 54, 13, cor.texto_fraco, "esquerda", true) end

  local ativos = {}
  local proximo = {}
  for _, m in ipairs(e.missoes) do
    ativos[m.rank] = (ativos[m.rank] or 0) + 1
    if not proximo[m.rank] or m.resta < proximo[m.rank] then proximo[m.rank] = m.resta end
  end
  local aberto = J.ef("rank_max")
  for i, r in ipairs(C.ranks) do
    local y = AREA.y + 72 + (i - 1) * 33
    local lib = i <= aberto
    motor.retangulo(AREA.x, y, AREA.w, 29, lib and "#3d291b" or "#2a2019", 6)
    motor.retangulo(AREA.x + 6, y + 3, 44, 23, lib and cor.ouro or "#4a3627", 6)
    motor.texto(r.nome, AREA.x + 28, y + 5, 14, lib and cor.texto_ouro or cor.texto_fraco, "centro", true)
    if lib then
      motor.texto(duracao_texto(J.duracao_rank(i)), AREA.x + 90, y + 6, 14, cor.texto)
      U.preco(J.pagamento_rank(i), AREA.x + 192, y + 6, 14, cor.ouro)
      local esp = (J.mercadinho_aberto() and i <= J.ef("mercadinho")) and fmt(J.lucro_espolio(i)) or "-"
      motor.texto(esp, AREA.x + 330, y + 6, 14, cor.texto)
      motor.texto(fmt(e.feitas_rank[i] or 0), AREA.x + 450, y + 6, 14, cor.texto)
      local txt = ativos[i] and (ativos[i] .. " (próxima em " .. duracao_texto(proximo[i]) .. ")") or "-"
      motor.texto(txt, AREA.x + 570, y + 6, 14, ativos[i] and cor.verde or cor.texto_fraco)
    else
      motor.texto("Compre na árvore de habilidades, ramo Guilda", AREA.x + 90, y + 6, 14, cor.texto_fraco)
    end
  end

  local y = AREA.y + 72 + 8 * 33 + 4
  motor.texto("Vagas extras", AREA.x + 8, y + 10, 14, cor.texto)
  atalho_no("vagas", AREA.x + 110, y, 130)
  motor.texto("Comissão", AREA.x + 270, y + 10, 14, cor.texto)
  atalho_no("comissao", AREA.x + 350, y, 130)
  if J.buff > 0 then
    motor.texto("Fofoca: missões pagam +25% por " .. duracao_texto(J.buff), AREA.x + AREA.w - 8, y + 10, 14, cor.verde, "direita", true)
  end
end

local function tela_mercadinho()
  local e = J.estado
  fundo_aba("Mercadinho", "Você compra espólios dos aventureiros e eles são revendidos sozinhos")

  U.painel(AREA.x, AREA.y + 56, 448, 340)
  local px = AREA.x + 16
  motor.texto("Construção", px, AREA.y + 66, 16, cor.texto, "esquerda", true)
  local rk = J.ef("mercadinho")
  for i, r in ipairs(C.ranks) do
    local x = px + (i - 1) * 52
    motor.retangulo(x, AREA.y + 92, 46, 34, i <= rk and cor.ouro or "#2a2019", 8)
    motor.texto(r.nome, x + 23, AREA.y + 99, 15, i <= rk and cor.texto_ouro or cor.texto_fraco, "centro", true)
  end
  local ranks_ids = { "mercadinho", "merc_e", "merc_d", "merc_c", "merc_b", "merc_a", "merc_s", "merc_ss" }
  local proximo = ranks_ids[rk + 1]
  if proximo then
    motor.texto("Próximo: " .. A.POR_ID[proximo].nome, px, AREA.y + 138, 14, cor.texto)
    atalho_no(proximo, px + 280, AREA.y + 130, 136)
  else
    motor.texto("Mercadinho no rank máximo!", px, AREA.y + 138, 14, cor.verde, "esquerda", true)
  end
  motor.texto("Espólios comprados: " .. fmt(e.espolios), px, AREA.y + 186, 14, cor.texto)
  motor.texto("Lucro com revenda: " .. fmt(e.lucro_espolios), px, AREA.y + 208, 14, cor.ouro)
  if rk >= 1 then
    motor.texto("Lucro por espólio do rank " .. C.ranks[rk].nome .. ": " .. fmt(J.lucro_espolio(rk)), px, AREA.y + 230, 14, cor.texto)
  end
  motor.texto("Negociação (+30% na revenda)", px, AREA.y + 268, 14, cor.texto)
  atalho_no("negociar", px + 280, AREA.y + 258, 136)

  U.painel(AREA.x + 460, AREA.y + 56, 476, 340)
  local qx = AREA.x + 476
  motor.texto("Aba de venda", qx, AREA.y + 66, 16, cor.texto, "esquerda", true)
  if not J.venda_aberta() then
    U.paragrafo("Libere a venda para oferecer poções, armaduras e armas aos clientes. Isso também dobra o lucro da revenda de espólios.", qx, AREA.y + 96, 444, 14, cor.texto_fraco)
    atalho_no("venda", qx, AREA.y + 160, 180)
  else
    motor.texto("Renda da venda: +" .. fmt(J.renda_venda()) .. " por segundo", qx, AREA.y + 92, 14, cor.ouro, "esquerda", true)
    for i, id in ipairs({ "pocoes", "armaduras", "armas" }) do
      local y = AREA.y + 118 + (i - 1) * 74
      motor.retangulo(qx, y, 444, 66, "#2a2019", 8)
      motor.texto(C.venda[id].nome, qx + 12, y + 8, 16, cor.texto, "esquerda", true)
      motor.texto("Nível " .. J.nivel(id) .. "  •  +" .. fmt(C.venda[id].renda) .. " por segundo a cada nível", qx + 12, y + 34, 13, cor.texto_fraco)
      atalho_no(id, qx + 300, y + 13, 132)
    end
  end
end

local function tela_producao()
  local e = J.estado
  fundo_aba("Produção", "O jardim abastece a cozinha e a cervejaria: comida e bebida da casa rendem mais")

  U.painel(AREA.x, AREA.y + 56, 448, 340)
  local px = AREA.x + 16
  motor.texto("Jardim", px, AREA.y + 66, 16, cor.texto, "esquerda", true)
  motor.texto(J.ef("canteiros") .. " canteiros  •  " .. util.formatar(J.por_colheita()) .. " por colheita", px, AREA.y + 92, 14, cor.texto)
  motor.texto("Próxima colheita em " .. duracao_texto(J.ciclo_jardim() - e.ciclo), px, AREA.y + 114, 14, cor.texto_fraco)
  U.barra(px, AREA.y + 136, 416, 10, e.ciclo / J.ciclo_jardim(), cor.verde)
  motor.texto("Estoque de alimentos: " .. fmt(e.estoque), px, AREA.y + 158, 15, cor.ouro, "esquerda", true)
  local linhas = { { "Mais canteiros", "canteiro" }, { "Adubo", "adubo" }, { "Irrigação", "irrigacao" } }
  for i, l in ipairs(linhas) do
    local y = AREA.y + 186 + (i - 1) * 50
    motor.texto(l[1] .. " (nível " .. J.nivel(l[2]) .. ")", px, y + 10, 14, cor.texto)
    atalho_no(l[2], px + 280, y, 136)
  end

  U.painel(AREA.x + 460, AREA.y + 56, 476, 340)
  local qx = AREA.x + 476
  motor.texto("Cozinha", qx, AREA.y + 66, 16, cor.texto, "esquerda", true)
  local nc = J.ef("cozinheiro")
  local tc = nc > 0 and ("Comida rende x" .. string.format("%.2f", C.bonus_cozinheiro + C.bonus_cozinheiro_nivel * (nc - 1)):gsub("%.", ",") .. " usando o estoque") or "Contrate o cozinheiro para usar o que você colhe"
  motor.texto(tc, qx, AREA.y + 92, 14, cor.texto_fraco)
  motor.texto("Cozinheiro (nível " .. J.nivel("cozinheiro") .. ")", qx, AREA.y + 124, 14, cor.texto)
  atalho_no("cozinheiro", qx + 308, AREA.y + 114, 136)

  motor.texto("Cervejaria", qx, AREA.y + 176, 16, cor.texto, "esquerda", true)
  local nb = J.ef("bebida_casa")
  local tb = nb > 0 and ("Bebida rende x" .. string.format("%.2f", C.bonus_bebida_casa + C.bonus_bebida_nivel * (nb - 1)):gsub("%.", ",") .. " usando o estoque") or "Faça as próprias bebidas com o que você colhe"
  motor.texto(tb, qx, AREA.y + 202, 14, cor.texto_fraco)
  motor.texto("Cervejaria (nível " .. J.nivel("cervejaria") .. ")", qx, AREA.y + 234, 14, cor.texto)
  atalho_no("cervejaria", qx + 308, AREA.y + 224, 136)

  motor.texto("Cardápio (nível " .. J.nivel("cardapio") .. ")", qx, AREA.y + 296, 14, cor.texto)
  atalho_no("cardapio", qx + 308, AREA.y + 286, 136)
end

local function nome_contratado(c)
  local t = c.nome
  if c.invocado then t = t .. ", " .. c.titulo
  elseif c.heroi then t = t .. " (herói)" end
  return t
end

local ICONES_TIPO = { guerreiro = "#a8b4bf", mago = "#6d4bb3", arqueiro = "#4f8a3c", clerigo = "#eadfca" }
local NOMES_TIPO = { guerreiro = "Guerreiro", mago = "Mago", arqueiro = "Arqueiro", clerigo = "Clérigo" }

local function cartao_contratado(c, x, y, w)
  motor.retangulo(x, y, w, 84, "#3d291b", 8)
  motor.circulo(x + 28, y + 28, 19, ICONES_TIPO[c.tipo])
  motor.circulo(x + 28, y + 22, 9, c.pele)
  motor.texto(nome_contratado(c), x + 56, y + 6, 15, c.invocado and "#c9a7ff" or (c.heroi and cor.ouro or cor.texto), "esquerda", true)
  local rank = C.ranks[J.rank_contratado(c)].nome
  motor.texto(NOMES_TIPO[c.tipo] .. "  •  Rank " .. rank .. "  •  Poder " .. fmt(J.poder(c)), x + 56, y + 27, 13, cor.texto_fraco)
  local status = c.na_final and "Enfrentando o Lorde Demônio" or (c.em_missao and "Em missão" or "Na taverna")
  if c.party then status = status .. "  •  Em party" end
  motor.texto(status, x + 56, y + 46, 13, c.em_missao and cor.verde or cor.texto_fraco)
  if c.fama and c.fama > 0 then motor.texto("Fama " .. fmt(c.fama), x + 56, y + 63, 13, cor.ouro) end

  local bx = x + w - 3 * 126
  for i, id in ipairs({ "armadura", "arma", "magia" }) do
    local d = C.investir[id]
    local custo = J.custo_investir(c, id)
    local px = bx + (i - 1) * 124
    motor.texto(d.nome .. " " .. (c[id] or 0), px + 60, y + 4, 13, cor.texto, "centro")
    local pode = J.estado.ouro >= custo
    U.botao("investir_" .. c.id .. "_" .. id, px, y + 22, 118, 40, nil, { preco = custo, ativo = pode, cor_texto = pode and cor.texto_ouro or cor.texto, tam = 14, som = "compra" },
      function() J.investir(c, id) end)
  end
  if J.pode_promover(c) then
    local cp = J.custo_promover(c)
    U.botao("promover_" .. c.id, bx - 210, y + 22, 202, 44, "Virar herói", { preco = cp, ativo = J.estado.ouro >= cp, tam = 14, cor = "#7f8fe6", cor_texto = "#10131f", som = "compra" },
      function() J.promover(c) end)
  end
end

local function tela_aventureiros()
  local e = J.estado
  fundo_aba("Aventureiros", nil)
  local n, cap = J.num_contratos_normais(), J.vagas_contrato()
  motor.texto(n .. " de " .. cap .. " contratados", AREA.x + 180, AREA.y + 6, 14, cor.texto_fraco)

  local cheio = n >= cap
  local cc = J.custo_contratar()
  U.botao("contratar", AREA.x + 8, AREA.y + 32, 200, 44, cheio and "Sem vagas" or "Contratar", { preco = not cheio and cc or nil, ativo = not cheio and e.ouro >= cc, som = "compra" },
    function() J.contratar() end)

  if J.ef("party") > 0 then
    local ids = J.melhores_sem_party()
    U.botao("criar_party", AREA.x + 216, AREA.y + 32, 190, 44, "Formar party com 4", { ativo = #ids == 4, cor = #ids == 4 and "#57b0c2" or nil, cor_texto = "#0d1f24" },
      function() J.criar_party(ids) end)
    if #e.parties > 0 then
      U.botao("desfazer_party", AREA.x + 414, AREA.y + 32, 150, 44, "Desfazer última", { cor = "#3d291b", cor_texto = cor.texto, tam = 13 },
        function() J.desfazer_party(e.parties[#e.parties].id) end)
    end
  end

  -- propaganda e reputação
  if J.ef("propaganda") > 0 then
    local nv, limite = J.nivel_reputacao()
    motor.texto("Reputação nível " .. nv, AREA.x + 580, AREA.y + 30, 14, cor.ouro, "esquerda", true)
    U.barra(AREA.x + 580, AREA.y + 50, 200, 8, e.fama / limite, cor.ouro)
    motor.texto(fmt(e.fama) .. " / " .. fmt(limite), AREA.x + 580, AREA.y + 60, 13, cor.texto_fraco)
    atalho_no("cartazes", AREA.x + 796, AREA.y + 30, 132)
  else
    motor.texto("A propaganda abre quando um contratado virar herói", AREA.x + 580, AREA.y + 40, 13, cor.texto_fraco)
  end

  local lx, ly, lw, lh = AREA.x, AREA.y + 86, AREA.w, 322
  local itens = e.contratados
  local altura = #itens * 90
  local maximo = math.max(0, altura - lh)
  T.rolagem.aventureiros = util.limitar(T.rolagem.aventureiros, 0, maximo)
  T.limite_rolagem = maximo
  motor.recorte(lx, ly, lw, lh)
  if #itens == 0 then
    motor.texto("Ninguém contratado ainda. Contratados fazem missões e trazem mais ouro.", 480, ly + 40, 15, cor.texto_fraco, "centro")
  end
  local y = ly - T.rolagem.aventureiros
  for _, c in ipairs(itens) do
    if y + 90 >= ly and y <= ly + lh then cartao_contratado(c, lx, y, lw - 12) end
    y = y + 90
  end
  motor.recorte()
  -- botões cortados pela rolagem não podem ser tocados
  for _, z in ipairs(U.zonas) do
    if z.id:find("^investir_") or z.id:find("^promover_") then
      if z.y + z.h > ly + lh or z.y < ly then z.fn = nil end
    end
  end
  if maximo > 0 then
    local p = T.rolagem.aventureiros / maximo
    motor.retangulo(lx + lw - 8, ly + p * (lh - 50), 6, 50, cor.texto_fraco, 3)
    U.zona("area_rolagem", { x = lx, y = ly, w = lw, h = lh })
  end
end

local function tela_invocacao()
  local e = J.estado
  fundo_aba("Círculo de invocação", "Heróis de outro mundo, mais fortes que qualquer contratado. Reúna os quatro para enfrentar o Lorde Demônio.")
  for i, d in ipairs(C.invocados) do
    local x = AREA.x + (i - 1) * 234
    local y = AREA.y + 62
    U.painel(x, y, 222, 170, i <= e.invocados_feitos and "#2c2340" or "#2a2019", i <= e.invocados_feitos and "#9c78ff" or cor.carta_borda)
    if i <= e.invocados_feitos then
      motor.circulo(x + 111, y + 42, 28, ICONES_TIPO[d.tipo])
      motor.circulo(x + 111, y + 32, 13, "#f1c9a5")
      motor.texto(d.nome, x + 111, y + 80, 18, "#c9a7ff", "centro", true)
      motor.texto(d.titulo, x + 111, y + 104, 14, cor.texto_fraco, "centro")
      for _, c in ipairs(e.contratados) do
        if c.invocado and c.nome == d.nome then
          motor.texto("Poder " .. fmt(J.poder(c)), x + 111, y + 128, 14, cor.ouro, "centro", true)
        end
      end
    elseif i == e.invocados_feitos + 1 then
      motor.texto("Próximo chamado", x + 111, y + 30, 14, cor.texto_fraco, "centro")
      local custo = J.custo_invocar()
      U.botao("invocar", x + 16, y + 66, 190, 50, "Invocar", { preco = custo, ativo = e.ouro >= custo, cor = e.ouro >= custo and "#9c78ff" or nil, cor_texto = "#120c20" },
        function() J.invocar() end)
    else
      U.cadeado(x + 111, y + 72)
    end
  end

  local y = AREA.y + 244
  U.painel(AREA.x, y, AREA.w, 156, "#2a1414", "#b5403a")
  motor.texto("Missão SSS: " .. C.sss.descricao, AREA.x + 16, y + 10, 18, "#ff9a8a", "esquerda", true)
  if e.fim then
    motor.texto("O Lorde Demônio foi derrotado. O mundo está em paz.", AREA.x + 16, y + 44, 15, cor.verde, "esquerda", true)
  elseif e.final_resta then
    motor.texto("A party está em batalha: faltam " .. duracao_texto(e.final_resta), AREA.x + 16, y + 44, 15, cor.texto, "esquerda", true)
    U.barra(AREA.x + 16, y + 72, AREA.w - 32, 12, 1 - e.final_resta / C.sss.duracao, "#ff9a8a")
  else
    local pt = J.party_final()
    motor.texto((pt and "Party dos 4 invocados formada" or "Forme uma party com os 4 invocados") .. "  •  Poder exigido de cada um: " .. fmt(C.sss.poder), AREA.x + 16, y + 44, 14, cor.texto)
    if e.invocados_feitos == 4 and not pt and J.ef("party") > 0 then
      local ids = J.melhores_sem_party()
      U.botao("party_final", AREA.x + 16, y + 76, 240, 46, "Formar a party final", { cor = "#9c78ff", cor_texto = "#120c20" }, function() J.criar_party(ids) end)
    end
    if pt then
      local x = AREA.x + 16
      for _, id in ipairs(pt.membros) do
        local c = J.contratado_por_id(id)
        if c then
          local p = J.poder(c)
          motor.texto(c.nome, x, y + 68, 13, cor.texto, "esquerda", true)
          U.barra(x, y + 88, 130, 7, p / C.sss.poder, p >= C.sss.poder and cor.verde or cor.ouro)
          x = x + 150
        end
      end
    end
    local pode = J.pode_final()
    U.botao("iniciar_final", AREA.x + AREA.w - 276, y + 86, 260, 54, "Enfrentar o Lorde Demônio", { ativo = pode, cor = pode and "#e2604a" or nil, cor_texto = "#ffffff", som = "invocar" },
      function() J.iniciar_final() end)
  end
end

-- Janelas por cima de tudo -------------------------------------------------------------

local function bloquear()
  motor.retangulo(0, 0, 960, 540, "#000000b0")
  U.zona("fundo_modal", { x = 0, y = 0, w = 960, h = 540 })
end

local function controle_volume(id, rotulo, x, y, valor, mudar)
  motor.texto(rotulo, x, y + 10, 15, cor.texto)
  U.botao(id .. "_menos", x + 130, y, 44, 40, "-", { cor = "#4a3627", cor_texto = cor.texto, tam = 18 }, function() mudar(math.max(0, valor - 0.1)) end)
  U.barra(x + 182, y + 15, 130, 10, valor, cor.ouro)
  U.botao(id .. "_mais", x + 320, y, 44, 40, "+", { cor = "#4a3627", cor_texto = cor.texto, tam = 18 }, function() mudar(math.min(1, valor + 0.1)) end)
end

local function alternador(id, rotulo, x, y, ligado, fn)
  motor.texto(rotulo, x, y + 10, 15, cor.texto)
  U.botao(id, x + 280, y, 84, 40, ligado and "Ligado" or "Desligado", { cor = ligado and cor.verde or "#4a3627", cor_texto = ligado and "#10210c" or cor.texto, tam = 13 }, fn)
end

local function janela_config()
  bloquear()
  local o = J.estado.opcoes
  local x, y, w, h = 150, 26, 660, 488
  U.painel(x, y, w, h, cor.carta, cor.ouro_escuro)
  U.zona("janela", { x = x, y = y, w = w, h = h })
  motor.texto("Configurações", x + w / 2, y + 14, 24, cor.texto, "centro", true)
  U.botao("config_fechar", x + w - 52, y + 8, 44, 44, "x", { cor = "#4a3627", cor_texto = cor.texto }, function() T.modal = nil end)

  local cx = x + 28
  controle_volume("musica", "Música", cx, y + 60, o.musica, function(v) o.musica = v; T.aplicar_opcoes() end)
  controle_volume("efeitos", "Efeitos", cx, y + 108, o.efeitos, function(v) o.efeitos = v; T.aplicar_opcoes() end)
  alternador("tela_cheia", "Tela cheia (F11)", cx, y + 156, motor.tela_cheia(), function() motor.alternar_tela_cheia() end)
  alternador("sombras", "Sombras (mais leve sem)", cx, y + 204, o.sombras, function() o.sombras = not o.sombras; T.aplicar_opcoes() end)
  alternador("mostrar_fps", "Mostrar FPS", cx, y + 252, o.fps, function() o.fps = not o.fps end)

  local bx = x + w - 230
  U.botao("minimizar2", bx, y + 60, 200, 44, "Minimizar", { cor = "#4a3627", cor_texto = cor.texto }, function() motor.minimizar() end)
  U.botao("estatisticas", bx, y + 112, 200, 44, "Estatísticas", { cor = "#4a3627", cor_texto = cor.texto }, function() T.modal = "stats" end)
  U.botao("creditos", bx, y + 164, 200, 44, "Créditos", { cor = "#4a3627", cor_texto = cor.texto }, function() T.modal = "creditos" end)
  U.botao("salvar", bx, y + 216, 200, 44, "Salvar agora", { cor = "#4a3627", cor_texto = cor.texto }, function()
    J.salvar()
    J.avisar("Progresso salvo!", 2)
    T.modal = nil
  end)

  motor.retangulo(cx, y + 312, w - 56, 2, "#00000050")
  if T.confirmar then
    motor.texto("Apagar todo o progresso? Não dá para desfazer.", cx, y + 330, 15, "#ff9a8a", "esquerda", true)
    U.botao("apagar_nao", cx, y + 360, 180, 46, "Não, manter", {}, function() T.confirmar = false end)
    U.botao("apagar_sim", cx + 192, y + 360, 180, 46, "Sim, apagar", { cor = cor.vermelho, cor_texto = "#ffffff" }, function()
      J.apagar_progresso()
      T.iniciar()
    end)
  else
    U.botao("apagar", cx, y + 330, 200, 46, "Apagar progresso", { cor = "#5a2a22", cor_texto = "#ffb0a2" }, function() T.confirmar = true end)
  end
  motor.texto("Versão " .. (motor.versao or "dev"), cx, y + h - 34, 13, cor.texto_fraco)
  U.botao("sair", x + w - 230, y + h - 62, 200, 48, "Salvar e sair", { cor = cor.vermelho, cor_texto = "#ffffff" }, function()
    J.salvar()
    motor.sair()
  end)
end

local function janela_stats()
  bloquear()
  local e = J.estado
  local x, y, w, h = 240, 70, 480, 400
  U.painel(x, y, w, h, cor.carta, cor.ouro_escuro)
  U.zona("janela", { x = x, y = y, w = w, h = h })
  motor.texto("Estatísticas", x + w / 2, y + 16, 24, cor.texto, "centro", true)
  local nh = 0
  for _, c in ipairs(e.contratados) do if c.heroi or c.invocado then nh = nh + 1 end end
  local linhas = {
    { "Tempo de jogo", duracao_texto(e.tempo) },
    { "Ouro total ganho", fmt(e.total) },
    { "Clientes servidos", fmt(e.servidos) },
    { "Brigas separadas", fmt(e.brigas) },
    { "Missões concluídas", fmt(e.feitas) },
    { "Espólios comprados", fmt(e.espolios) },
    { "Alimentos colhidos", fmt(e.colhido) },
    { "Contratados", fmt(#e.contratados) },
    { "Heróis", fmt(nh) },
    { "Fama total", fmt(e.fama) },
  }
  for i, l in ipairs(linhas) do
    local ly = y + 54 + (i - 1) * 27
    motor.texto(l[1], x + 30, ly, 15, cor.texto_fraco)
    motor.texto(l[2], x + w - 30, ly, 15, cor.texto, "direita", true)
  end
  U.botao("stats_voltar", x + w / 2 - 80, y + h - 56, 160, 44, "Voltar", {}, function() T.modal = "config" end)
end

local function janela_creditos()
  bloquear()
  local x, y, w, h = 240, 110, 480, 320
  U.painel(x, y, w, h, cor.carta, cor.ouro_escuro)
  U.zona("janela", { x = x, y = y, w = w, h = h })
  motor.texto("Taverna de Aventureiros", x + w / 2, y + 22, 24, cor.texto, "centro", true)
  U.paragrafo("Criado por Gabriel Pimentel, com a ajuda do Claude.", x + 30, y + 70, w - 60, 15, cor.texto, false, "centro")
  U.paragrafo("Motor: raylib. Linguagem de scripts: Lua. Fonte: Poppins (licença OFL).", x + 30, y + 120, w - 60, 15, cor.texto_fraco, false, "centro")
  U.paragrafo("Música e efeitos gerados por código.", x + 30, y + 176, w - 60, 15, cor.texto_fraco, false, "centro")
  U.botao("creditos_voltar", x + w / 2 - 80, y + h - 62, 160, 44, "Voltar", {}, function() T.modal = "config" end)
end

local function janela_offline()
  local o = J.offline
  if not o then return end
  bloquear()
  local x, y, w, h = 260, 110, 440, 320
  U.painel(x, y, w, h, cor.carta, cor.ouro_escuro)
  motor.texto("Bem-vindo de volta!", 480, y + 28, 28, cor.texto, "centro", true)
  local fora = "Você ficou fora por " .. duracao_texto(o.segundos)
  if o.segundos > C.offline_maximo then fora = fora .. " (conta até 8 h)" end
  motor.texto(fora, 480, y + 82, 15, cor.texto_fraco, "centro")
  motor.texto("Os garçons cuidaram da taverna:", 480, y + 106, 15, cor.texto_fraco, "centro")
  local txt = "+" .. fmt(o.ganho)
  local tw = motor.largura_texto(txt, 42, true)
  U.moeda(480 - tw / 2 - 12, y + 170, 20)
  motor.texto(txt, 480 - tw / 2 + 18, y + 142, 42, cor.ouro, "esquerda", true)
  U.botao("coletar", 380, y + 236, 200, 52, "Coletar", { raio = 26, tam = 22, som = "moeda" }, function() J.coletar_offline() end)
end

local function tela_final()
  bloquear()
  local e = J.estado
  motor.retangulo(0, 0, 960, 540, "#0d0a14f0")
  local t = motor.tempo()
  for i = 1, 40 do
    motor.circulo((i * 73 + t * 12) % 960, (i * 137) % 540 + math.sin(t + i) * 4, 1 + i % 3, "#f2c14e80")
  end
  motor.texto("O Lorde Demônio foi derrotado!", 480, 110, 38, cor.ouro, "centro", true)
  U.paragrafo("Os quatro heróis voltaram à taverna onde tudo começou. O reino comemora, a música não para e o mundo, enfim, entra em paz.", 180, 174, 600, 18, cor.texto, false, "centro")
  motor.texto("Tempo de jogo: " .. duracao_texto(e.tempo), 480, 274, 16, cor.texto_fraco, "centro")
  motor.texto("Ouro ganho: " .. fmt(e.total) .. "  •  Missões: " .. fmt(e.feitas) .. "  •  Clientes: " .. fmt(e.servidos), 480, 300, 16, cor.texto_fraco, "centro")
  motor.texto("Fim", 480, 340, 26, cor.texto, "centro", true)
  U.botao("novo_jogo", 280, 396, 190, 52, "Jogar de novo", {}, function()
    J.apagar_progresso()
    T.iniciar()
  end)
  U.botao("final_sair", 490, 396, 190, 52, "Sair", { cor = "#4a3627", cor_texto = cor.texto }, function()
    J.salvar()
    motor.sair()
  end)
end

-- Ciclo --------------------------------------------------------------------------------

function T.atualizar(dt)
  local e = J.estado
  local d = e.ouro - T.ouro_visivel
  if math.abs(d) < 1 then T.ouro_visivel = e.ouro
  else T.ouro_visivel = T.ouro_visivel + d * math.min(1, dt * 10) end
  if e.total > T.total_antes then T.pulso = 1 end
  T.total_antes = e.total
  T.pulso = math.max(0, T.pulso - dt * 5)
  M.atualizar(dt)

  -- roda do mouse e arrastar
  local roda = motor.roda()
  if roda ~= 0 and not T.modal then
    if T.aba == "taverna" then M.rolar(roda)
    elseif T.aba == "arvore" then T.arv.zoom = util.limitar(T.arv.zoom + roda * 0.08, ZOOM_MIN, ZOOM_MAX); T.arv.manual = true; limitar_arvore()
    elseif T.aba == "aventureiros" then T.rolagem.aventureiros = T.rolagem.aventureiros - roda * 40 end
  end
  if T.toque and motor.mouse_baixo() then
    local mx, my = motor.mouse()
    local dx, dy = mx - T.toque.ux, my - T.toque.uy
    T.toque.ux, T.toque.uy = mx, my
    if math.abs(mx - T.toque.x) + math.abs(my - T.toque.y) > 8 then T.toque.moveu = true end
    if T.aba == "arvore" then
      if T.toque.arrasta then
        T.arv.x = T.arv.x + dx
        T.arv.y = T.arv.y + dy
        if T.toque.moveu then T.arv.manual = true end
        limitar_arvore()
      end
    elseif T.aba == "taverna" then M.arrastar(dx, dy)
    elseif T.aba == "aventureiros" then T.rolagem.aventureiros = T.rolagem.aventureiros - dy end
  end
end

function T.desenhar()
  U.limpar()
  local aba_atual = T.aba
  M.desenhar_cena()
  if T.aba == "taverna" then
    M.desenhar_baloes()
  elseif T.aba == "arvore" then tela_arvore(T.aba_anterior ~= "arvore")
  elseif T.aba == "missoes" then tela_missoes()
  elseif T.aba == "mercadinho" then tela_mercadinho()
  elseif T.aba == "producao" then tela_producao()
  elseif T.aba == "aventureiros" then tela_aventureiros()
  elseif T.aba == "invocacao" then tela_invocacao()
  end
  T.aba_anterior = aba_atual
  hud()
  barra_abas()
  dica()
  aviso()
  if T.modal == "config" then janela_config()
  elseif T.modal == "stats" then janela_stats()
  elseif T.modal == "creditos" then janela_creditos()
  end
  if J.offline then janela_offline() end
  if J.estado.fim and not T.modal then tela_final() end
end

function T.tocar(x, y)
  T.toque = { x = x, y = y, ux = x, uy = y, moveu = false, arrasta = false }
  local z = U.achar(x, y)
  if z then
    if z.solto then
      T.toque.zona = z
      T.toque.arrasta = true
    elseif z.fn then
      z.fn()
    end
    return
  end
  T.toque.arrasta = true
  if T.aba == "taverna" and not T.modal and not J.offline then M.tocar(x, y) end
end

function T.soltar(x, y)
  local t = T.toque
  T.toque = nil
  if t and t.zona and not t.moveu and t.zona.fn then
    local z = U.achar(x, y)
    if z and z.id == t.zona.id then z.fn() end
  end
end

function T.esc()
  if J.offline then return end
  if T.modal == "config" then T.modal = nil
  elseif T.modal then T.modal = "config"
  elseif T.aba ~= "taverna" then T.aba = "taverna"
  else T.modal = "config"; T.confirmar = false end
end

return T
