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

local function hud()
  local e = J.estado
  motor.retangulo(12, 10, 236, 44, "#21150ee8", 12)
  local p = T.pulso
  U.moeda(34, 32, 14 + p * 2)
  motor.texto(fmt(T.ouro_visivel), 54, 11, 22 + p * 2, cor.ouro, "esquerda", true)
  local rps = e.rps < 10 and (string.format("%.1f", e.rps):gsub("%.", ",")) or fmt(e.rps)
  motor.texto("+" .. rps .. " por segundo", 54, 35, 13, cor.verde, "esquerda", true)

  -- objetivo atual
  local obj = J.objetivo()
  local largura = util.limitar(motor.largura_texto(obj, 14, true) + 28, 200, 440)
  local ox = 480 - largura / 2 + 20
  motor.retangulo(ox, 12, largura, 32, "#21150ee8", 10)
  motor.texto(obj, ox + largura / 2, 18, motor.largura_texto(obj, 14, true) > largura - 16 and 12 or 14, cor.texto, "centro", true)

  -- botões de sistema
  U.botao("minimizar", 852, 10, 44, 44, nil, { cor = "#21150ee8" }, function() motor.minimizar() end)
  motor.retangulo(864, 36, 20, 3, cor.texto, 1)
  U.botao("config", 904, 10, 44, 44, nil, { cor = "#21150ee8" }, function() T.modal = "config"; T.confirmar = false end)
  U.engrenagem(926, 32, cor.texto)

  local nv = J.nivel_reputacao()
  if nv > 0 or J.ef("propaganda") > 0 then
    motor.retangulo(760, 12, 84, 40, "#21150ee8", 10)
    motor.texto("Reputação", 802, 13, 12, cor.texto_fraco, "centro")
    motor.texto("Nível " .. nv, 802, 28, 14, cor.ouro, "centro", true)
  end

  if e.opcoes.fps then
    motor.texto(motor.fps() .. " FPS", 948, 60, 13, cor.texto, "direita", true)
  end
  motor.opacidade(0.6)
  motor.texto("versão " .. (motor.versao or "dev"), 10, 524, 11, cor.texto_fraco)
  motor.opacidade(1)
end

local function aviso()
  local a = J.aviso
  if not a then return end
  local entrada = util.limitar(a.vida / 0.3, 0, 1)
  local saida = util.limitar((a.duracao - a.vida) / 0.4, 0, 1)
  motor.opacidade(math.min(entrada, saida))
  local tam = 16
  local w = math.min(880, motor.largura_texto(a.texto, tam, true) + 40)
  local y = 60 - (1 - util.suave(entrada)) * 20
  motor.retangulo(480 - w / 2, y + 3, w, 38, cor.sombra, 19)
  motor.retangulo(480 - w / 2, y, w, 38, cor.ouro, 19)
  motor.texto(a.texto, 480, y + 9, tam, cor.texto_ouro, "centro", true)
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

local function no_tela(no)
  local a = T.arv
  return 480 + a.x + no.x * a.zoom, 268 + a.y + no.y * a.zoom
end

local function tela_arvore()
  local a = T.arv
  motor.retangulo(0, 56, 960, 424, "#1a110bf4")
  motor.recorte(0, 56, 960, 424)
  local zoom = a.zoom

  -- ligações
  local cx, cy = 480 + a.x, 268 + a.y
  for _, no in ipairs(A.NOS) do
    local x, y = no_tela(no)
    local tem = J.nivel(no.id) > 0
    local c = tem and A.RAMOS[no.ramo].cor or "#5c4a3a"
    local esp = tem and 4 or 2.5
    if no.pai then
      local pai = A.POR_ID[no.pre[1]]
      motor.linha(x, y, select(1, no_tela(pai)), select(2, no_tela(pai)), esp, c)
    else
      motor.linha(x, y, cx, cy, esp, c)
    end
    if no.req then
      local r = A.POR_ID[no.req]
      motor.linha(x, y, select(1, no_tela(r)), select(2, no_tela(r)), 1.5, "#7c6a5a")
    end
  end

  -- centro
  motor.circulo(cx, cy, 34 * zoom, "#3d291b")
  motor.anel(cx, cy, 31 * zoom, 34 * zoom, cor.ouro)
  U.caneca(cx - 1, cy, 1.1 * zoom)

  -- nomes dos ramos
  for _, r in pairs(A.RAMOS) do
    local ang = math.rad(r.angulo)
    motor.texto(r.nome, cx + math.cos(ang) * 96 * zoom, cy - math.sin(ang) * 96 * zoom - 8, 13, r.cor, "centro", true)
  end

  -- nós
  local raio = 25 * zoom
  for _, no in ipairs(A.NOS) do
    local x, y = no_tela(no)
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
      motor.anel(x, y, raio - 2, raio, "#5c4a3a")
    end
    if T.arv.sel == no.id then motor.anel(x, y, raio + 4, raio + 7, "#ffffff") end
    if not lib then
      U.cadeado(x, y, "#7c6a5a")
    elseif no.max == 1 then
      motor.texto(nv > 0 and "OK" or "?", x, y - 9, 16, nv > 0 and "#21150e" or cor.texto, "centro", true)
    else
      motor.texto(nv .. "/" .. no.max, x, y - 9, 15, nv > 0 and "#21150e" or cor.texto, "centro", true)
    end
    if zoom >= 0.7 then
      local txt = lib and no.nome or "???"
      local t2 = 12
      motor.texto(txt, x + 1, y + raio + 5, t2, "#000000", "centro", true)
      motor.texto(txt, x, y + raio + 4, t2, lib and cor.texto or cor.texto_fraco, "centro", true)
    end
    U.zona("no_" .. no.id, { x = x - raio - 4, y = y - raio - 4, w = raio * 2 + 8, h = raio * 2 + 8 },
      function() T.arv.sel = no.id; motor.som("clique") end, true)
  end
  motor.recorte()

  -- instruções e ajuda
  motor.retangulo(14, 64, 250, 28, "#21150ed0", 8)
  motor.texto("Arraste para navegar  •  Roda: zoom", 24, 69, 13, cor.texto_fraco)
  U.botao("arvore_centro", 14, 96, 104, 40, "Centralizar", { cor = "#3d291b", cor_texto = cor.texto, tam = 13 },
    function() a.x, a.y, a.zoom = 0, 0, 0.85 end)

  -- detalhe do nó escolhido
  local no = a.sel and A.POR_ID[a.sel]
  if no then
    local px, py, pw, ph = 672, 64, 276, 262
    U.painel(px, py, pw, ph, "#2c1d13f8", A.RAMOS[no.ramo].cor)
    U.zona("painel_no", { x = px, y = py, w = pw, h = ph })
    local lib = J.no_liberado(no)
    motor.texto(A.RAMOS[no.ramo].nome, px + 14, py + 10, 13, A.RAMOS[no.ramo].cor, "esquerda", true)
    local h = U.paragrafo(lib and no.nome or "Habilidade bloqueada", px + 14, py + 30, pw - 28, 18, cor.texto, true)
    local y = py + 32 + h
    if lib then
      y = y + U.paragrafo(no.desc, px + 14, y, pw - 28, 14, cor.texto_fraco) + 8
      if no.max > 1 then motor.texto("Nível " .. J.nivel(no.id) .. " de " .. no.max, px + 14, y, 14, cor.ouro) end
    else
      local falta = {}
      for _, p in ipairs(no.pre) do
        if J.nivel(p) < 1 then falta[#falta + 1] = A.POR_ID[p].nome end
      end
      U.paragrafo("Precisa de: " .. table.concat(falta, ", "), px + 14, y, pw - 28, 14, cor.texto_fraco)
    end
    if J.no_maximo(no) then
      U.botao("comprar_no", px + 14, py + ph - 58, pw - 28, 46, "Já comprado", { ativo = false })
    elseif lib then
      local pode = J.pode_comprar_no(no)
      local custo = J.custo_no(no)
      U.botao("comprar_no", px + 14, py + ph - 58, pw - 28, 46, "Comprar por " .. fmt(custo), { ativo = pode, som = "compra", tam = 16 },
        function() J.comprar_no(no.id) end)
      if not pode then
        U.barra(px + 14, py + ph - 70, pw - 28, 6, J.estado.ouro / custo, cor.ouro_escuro)
      end
    else
      U.botao("comprar_no", px + 14, py + ph - 58, pw - 28, 46, "Bloqueado", { ativo = false })
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
    U.botao("nó_" .. id, x, y, w, 40, "Bloqueado", { ativo = false, tam = 13 })
  elseif J.no_maximo(no) then
    U.botao("nó_" .. id, x, y, w, 40, "Máximo", { ativo = false, tam = 13 })
  else
    U.botao("nó_" .. id, x, y, w, 40, fmt(J.custo_no(no)), { ativo = J.pode_comprar_no(no), som = "compra", tam = 14 },
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
      motor.texto(fmt(J.pagamento_rank(i)), AREA.x + 200, y + 6, 14, cor.ouro, "esquerda", true)
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
    U.botao("investir_" .. c.id .. "_" .. id, px, y + 22, 118, 40, fmt(custo), { ativo = J.estado.ouro >= custo, tam = 14, som = "compra" },
      function() J.investir(c, id) end)
  end
  if J.pode_promover(c) then
    local cp = J.custo_promover(c)
    U.botao("promover_" .. c.id, bx, y + 64 - 2, 366, 20, "Virar herói: " .. fmt(cp), { ativo = J.estado.ouro >= cp, tam = 12, cor = "#7f8fe6", cor_texto = "#10131f", raio = 6, som = "compra" },
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
  U.botao("contratar", AREA.x + 8, AREA.y + 32, 200, 44, cheio and "Sem vagas" or ("Contratar: " .. fmt(cc)), { ativo = not cheio and e.ouro >= cc, som = "compra" },
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
      U.botao("invocar", x + 16, y + 66, 190, 50, "Invocar: " .. fmt(custo), { ativo = e.ouro >= custo, cor = e.ouro >= custo and "#9c78ff" or nil, cor_texto = "#120c20" },
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
    elseif T.aba == "arvore" then T.arv.zoom = util.limitar(T.arv.zoom + roda * 0.08, 0.45, 1.3)
    elseif T.aba == "aventureiros" then T.rolagem.aventureiros = T.rolagem.aventureiros - roda * 40 end
  end
  if T.toque and motor.mouse_baixo() then
    local mx, my = motor.mouse()
    local dx, dy = mx - T.toque.ux, my - T.toque.uy
    T.toque.ux, T.toque.uy = mx, my
    if math.abs(mx - T.toque.x) + math.abs(my - T.toque.y) > 8 then T.toque.moveu = true end
    if T.aba == "arvore" then
      if T.toque.arrasta then
        T.arv.x = util.limitar(T.arv.x + dx, -800, 800)
        T.arv.y = util.limitar(T.arv.y + dy, -620, 620)
      end
    elseif T.aba == "taverna" then M.arrastar(dx, dy)
    elseif T.aba == "aventureiros" then T.rolagem.aventureiros = T.rolagem.aventureiros - dy end
  end
end

function T.desenhar()
  U.limpar()
  M.desenhar_cena()
  if T.aba == "taverna" then
    M.desenhar_baloes()
  elseif T.aba == "arvore" then tela_arvore()
  elseif T.aba == "missoes" then tela_missoes()
  elseif T.aba == "mercadinho" then tela_mercadinho()
  elseif T.aba == "producao" then tela_producao()
  elseif T.aba == "aventureiros" then tela_aventureiros()
  elseif T.aba == "invocacao" then tela_invocacao()
  end
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
