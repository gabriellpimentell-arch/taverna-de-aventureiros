-- =============================================================================
--  HUD, abas e menus. A taverna ocupa a tela; a evolução fica em abas separadas.
-- =============================================================================

local J = require("jogo")
local A = require("arvore")
local C = require("config")
local util = require("util")
local U = require("ui")
local M = require("mundo")
local S = require("saves")
local Lj = require("loja")
local cor = util.cores
local fmt = util.formatar

local T = {}

local AREA = { x = 12, y = 62, w = 936, h = 412 }   -- conteúdo das abas

local function relogio(s)
  s = math.max(0, math.ceil(s))
  return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

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
  M.ao_tocar_carroca = function() T.abrir_carroca() end
  T.tela = J.em_menu and "titulo" or nil
  T.aba = "taverna"
  T.modal = nil
  T.ouro_visivel = J.estado.ouro
  T.total_antes = J.estado.total
  T.pulso = 0
  T.toque = nil
  T.arv = { x = 0, y = 0, zoom = 0.85, sel = nil, arvore = "principal", vistos = nil, anim = {}, novos = {} }
  T.rolagem = { aventureiros = 0 }
  T.confirmar = false
  Lj.iniciar()
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
  local l = { { id = "taverna", nome = "Taverna" }, { id = "loja", nome = "Loja" }, { id = "arvore", nome = "Árvore" } }
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
    -- selo da Loja: quantos itens comprados esperam um lugar
    local pendentes = a.id == "loja" and J.total_para_colocar() or 0
    if pendentes > 0 then
      local txt = pendentes > 99 and "99+" or tostring(pendentes)
      local sw = math.max(22, motor.largura_texto(txt, 13, true) + 10)
      motor.retangulo(x + w - sw + 4, 480, sw, 22, cor.vermelho, 11)
      motor.contorno(x + w - sw + 4, 480, sw, 22, "#ffffff", 1.5, 11)
      motor.texto(txt, x + w - sw / 2 + 4, 482, 13, "#ffffff", "centro", true)
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

-- carroça, despensa e dívida, logo abaixo do ouro
local function painel_divida()
  local e = J.estado
  local y = 58
  if J.pode_emprestimo() then
    local rot = (e.emprestimos or 0) > 0 and "Socorro de Bartolo: +" or "Empréstimo: +"
    U.botao("emprestimo", 12, y, 236, 40, rot .. C.emprestimo .. " de ouro", { cor = cor.ouro, cor_texto = "#2a1608", tam = 14 }, J.pegar_emprestimo)
    y = y + 44
  end
  -- a carroça: botão enquanto está na estrada, relógio enquanto está longe
  if J.carroca_presente() then
    U.botao("carroca_abrir", 12, y, 236, 40, "Carroça: comprar (" .. relogio(J.carroca_resta()) .. ")", { cor = cor.verde, cor_texto = "#10210c", tam = 14 }, function() T.abrir_carroca() end)
  else
    motor.retangulo(12, y, 236, 40, "#21150ee8", 10)
    motor.texto("Carroça volta em " .. relogio(J.carroca_resta()), 22, y + 11, 14, cor.texto_fraco, "esquerda", true)
  end
  y = y + 44
  if not e.mantimentos then return end
  motor.retangulo(12, y, 236, 36, "#21150ee8", 10)
  U.coxa(30, y + 18, 0.6)
  local qc, qb = e.mantimentos.comida or 0, e.mantimentos.bebida or 0
  motor.texto(fmt(qc), 46, y + 9, 14, qc < 1 and "#ff9a8a" or cor.texto, "esquerda", true)
  U.caneca(136, y + 18, 0.6)
  motor.texto(fmt(qb), 152, y + 9, 14, qb < 1 and "#ff9a8a" or cor.texto, "esquerda", true)
  y = y + 40
  if (e.divida or 0) > 0 then
    motor.retangulo(12, y, 236, 40, "#3a1610e8", 10)
    motor.texto("Dívida: " .. fmt(e.divida), 22, y + 11, 14, "#ff9a8a", "esquerda", true)
    U.botao("pagar_divida", 158, y + 4, 84, 32, "Pagar", { ativo = e.ouro >= 1, tam = 13 }, function() J.pagar_divida(e.ouro) end)
  end
end

local function hud()
  local e = J.estado
  -- as outras abas ocupam a tela toda: o painel só fica onde não cobre o conteúdo
  if T.aba == "taverna" or T.aba == "loja" or T.aba == "arvore" then painel_divida() end
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

  if e.opcoes.fps and T.aba ~= "loja" then
    motor.retangulo(712, 58, 240, 42, "#21150ee8", 8)
    motor.texto(motor.fps() .. " FPS  •  " .. #J.pessoas .. " pessoas", 944, 60, 13, cor.texto, "direita", true)
    local trav = J.travados or 0
    motor.texto("Travados agora: " .. trav .. "  •  média " .. string.format("%.1f", J.media_travados or 0):gsub("%.", ","), 944, 78, 13, trav > 2 and "#ff9a8a" or cor.verde, "direita", true)
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

-- a árvore à vista: hoje só a principal; a Parte 3 troca T.arv.arvore pelas abas de ambiente
local function arvore_atual() return A.ARVORES[T.arv.arvore] or A.ARVORES.principal end

local function no_tela(no)
  local a = T.arv
  return 480 + a.x + no.x * a.zoom, 268 + a.y + no.y * a.zoom
end

local function no_visivel(no) return J.estado_no(no) ~= "oculto" end

local function limites_visiveis()
  local x0, y0, x1, y1, n = 0, 0, 0, 0, 0
  for _, no in ipairs(arvore_atual().nos) do
    if no_visivel(no) then
      n = n + 1
      x0, x1 = math.min(x0, no.x), math.max(x1, no.x)
      y0, y1 = math.min(y0, no.y), math.max(y1, no.y)
    end
  end
  return x0, y0, x1, y1, n
end

-- Onde a câmera precisa ficar para ver tudo o que está visível, com folga para nós e nomes.
local function quadro_ideal()
  local x0, y0, x1, y1, n = limites_visiveis()
  -- no começo, o painel da dívida ocupa a esquerda da tela
  local esq = J.estado.mantimentos and 256 or 0
  local zx = (960 - esq - 2 * 78) / math.max(1, x1 - x0)
  local zy = (416 - 44 - 62) / math.max(1, y1 - y0)
  local z = util.limitar(math.min(zx, zy), ZOOM_MIN, 1.05)
  return esq / 2 - z * (x0 + x1) / 2, 266 + 9 - 268 - z * (y0 + y1) / 2, z, n
end

local function enquadrar_arvore()
  local a = T.arv
  local x, y, z, n = quadro_ideal()
  a.x, a.y, a.zoom, a.manual, a.n_visiveis, a.alvo = x, y, z, false, n, nil
end

-- Mesmo enquadramento, deslizando: a câmera anda 350 ms e só então os nós novos nascem.
local function deslizar_para(x, y, z)
  local a = T.arv
  a.alvo = { x0 = a.x, y0 = a.y, z0 = a.zoom, x = x, y = y, z = z, ini = motor.tempo() }
end

-- Deixa arrastar só até o limite do que existe, em qualquer zoom.
local function limitar_arvore()
  local a = T.arv
  local x0, y0, x1, y1 = limites_visiveis()
  a.x = util.limitar(a.x, -x1 * a.zoom - 300, -x0 * a.zoom + 300)
  a.y = util.limitar(a.y, -y1 * a.zoom - 120, -y0 * a.zoom + 120)
end

-- A roda aproxima em torno do cursor: o que está sob ele fica no lugar.
local function zoom_no_cursor(roda)
  local a = T.arv
  local mx, my = motor.mouse()
  local z = util.limitar(a.zoom + roda * 0.08, ZOOM_MIN, ZOOM_MAX)
  local k = z / a.zoom
  a.x = (mx - 480) - ((mx - 480) - a.x) * k
  a.y = (my - 268) - ((my - 268) - a.y) * k
  a.zoom, a.manual, a.alvo = z, true, nil
  limitar_arvore()
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

local function desenhar_rotulo_no(r, no, custo, pode)
  motor.retangulo(r.x, r.y, r.w, r.h, "#1a110bd8", 4)
  local cx = r.x + r.w / 2
  motor.texto(no.nome, cx, r.y + 1, 13, cor.texto, "centro", true)
  if custo then
    U.rotulo_preco(nil, custo, r.x, r.y + 17, r.w, 17, 13, pode and cor.ouro or cor.texto_fraco)
  end
end

-- Quem mudou de estado desde o último quadro entra na fila da animação, 80 ms depois do anterior.
-- Compra em outra aba: a animação toca ao reabrir a árvore.
local function perceber_novidades()
  local a = T.arv
  local agora = motor.tempo()
  local primeira = a.vistos == nil
  a.vistos = a.vistos or {}
  local novos = {}
  for _, no in ipairs(arvore_atual().nos) do
    local est = J.estado_no(no)
    local antes = a.vistos[no.id]
    if not primeira and antes ~= est then
      if est == "comprado" then a.anel = { id = no.id, ini = agora } end
      if (est == "revelado" or est == "pista") and antes ~= "revelado" then novos[#novos + 1] = no end
    end
    a.vistos[no.id] = est
  end
  if #novos == 0 then return end
  a.anim = {}
  -- não cabem na tela: a câmera desliza primeiro; se o jogador mexeu nela, só aponta uma seta
  local espera = 0.1
  if not a.manual then
    local x, y, z, n = quadro_ideal()
    a.n_visiveis = n
    if math.abs(x - a.x) > 1 or math.abs(y - a.y) > 1 or math.abs(z - a.zoom) > 0.01 then
      deslizar_para(x, y, z)
      espera = 0.35
    end
  end
  for i, no in ipairs(novos) do
    a.anim[no.id] = agora + espera + (i - 1) * 0.08
    if J.estado_no(no) == "revelado" then a.novos[no.id] = agora end
  end
end

-- 0 = ainda não nasceu; 1 = pronto
local function fase_anim(no, atraso, dur)
  local ini = T.arv.anim[no.id]
  if not ini then return 1 end
  return util.limitar((motor.tempo() - ini - atraso) / dur, 0, 1)
end

-- passa de 1 e assenta: o nó "estala" ao nascer
local function escala_nascendo(f)
  if f >= 1 then return 1 end
  if f < 0.7 then return f / 0.7 * 1.1 end
  return 1.1 - (f - 0.7) / 0.3 * 0.1
end

local function ponto_visivel(x, y) return x > 20 and x < 940 and y > 76 and y < 460 end

local function linha_tracejada(x0, y0, x1, y1, esp, c)
  local d = math.max(1, util.distancia(x0, y0, x1, y1))
  local passos = math.max(1, math.floor(d / 14))
  for i = 0, passos - 1, 2 do
    local a, b = i / passos, (i + 1) / passos
    motor.linha(x0 + (x1 - x0) * a, y0 + (y1 - y0) * a, x0 + (x1 - x0) * b, y0 + (y1 - y0) * b, esp, c)
  end
end

-- toco que some aos poucos: o ramo continua, mas ainda não se sabe para onde
local function toco(x, y, tx, ty, raio, c)
  local d = math.max(1, util.distancia(x, y, tx, ty))
  local ux, uy = (tx - x) / d, (ty - y) / d
  local tam = math.min(d * 0.5, 34)
  local alfas = { "b0", "70", "30" }
  for i = 1, 3 do
    local a = raio + tam * (i - 1) / 3
    local b = raio + tam * i / 3
    motor.linha(x + ux * a, y + uy * a, x + ux * b, y + uy * b, 3, c:sub(1, 7) .. alfas[i])
  end
end

local function escurecer(c)
  local function canal(i) return string.format("%02x", math.floor(tonumber(c:sub(i, i + 1), 16) * 0.72)) end
  return "#" .. canal(2) .. canal(4) .. canal(6)
end

local function tela_arvore(entrando)
  local a = T.arv
  local arv = arvore_atual()
  if entrando then a.alvo = nil end
  if entrando and not a.manual then enquadrar_arvore() end
  perceber_novidades()
  if a.alvo then
    local f = util.limitar((motor.tempo() - a.alvo.ini) / 0.35, 0, 1)
    local s = f * f * (3 - 2 * f)
    a.x = a.alvo.x0 + (a.alvo.x - a.alvo.x0) * s
    a.y = a.alvo.y0 + (a.alvo.y - a.alvo.y0) * s
    a.zoom = a.alvo.z0 + (a.alvo.z - a.alvo.z0) * s
    if f >= 1 then a.alvo = nil end
  end
  local agora = motor.tempo()
  for id, ini in pairs(a.anim) do
    if agora - ini > 0.6 then a.anim[id] = nil end
  end
  motor.retangulo(0, 56, 960, 424, "#1a110bf4")
  motor.recorte(0, 56, 960, 424)
  local zoom = a.zoom
  local cx, cy = 480 + a.x, 268 + a.y

  -- ligações
  local function ponta_de(no)
    if no.pai then return no_tela(A.POR_ID[no.pre[1]]) end
    return cx, cy
  end
  for _, no in ipairs(arv.nos) do
    local est = J.estado_no(no)
    if est ~= "oculto" then
      local x, y = no_tela(no)
      local px, py = ponta_de(no)
      local cresce = fase_anim(no, 0, 0.25)
      local lx, ly = px + (x - px) * cresce, py + (y - py) * cresce
      if est == "comprado" then
        motor.linha(x, y, px, py, 4, arv.ramos[no.ramo].cor)
      elseif est == "revelado" then
        motor.linha(lx, ly, px, py, 2.5, "#a08c78")
      else
        linha_tracejada(px, py, lx, ly, 1.5, "#7c6a5a")
      end
      -- segundo pré-requisito: linha fina até ele, se estiver à vista
      local req = no.req and A.POR_ID[no.req]
      if req and J.estado_no(req) ~= "oculto" and est ~= "pista" then
        local rx, ry = no_tela(req)
        motor.linha(x, y, rx, ry, 1.5, "#8c7a6a70")
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
  local raio_pista = raio * 0.62
  local ocupado = { { x = cx - rc0 - 3, y = cy - rc0 - 3, w = rc0 * 2 + 6, h = rc0 * 2 + 6 } }
  for _, no in ipairs(arv.nos) do
    local est = J.estado_no(no)
    local x, y = no_tela(no)
    local rc = arv.ramos[no.ramo].cor
    -- tocos: só onde há continuação escondida
    if est == "comprado" or est == "revelado" then
      for _, f in ipairs(J.continuacoes_ocultas(no)) do
        local tx, ty = no_tela(f)
        toco(x, y, tx, ty, raio, rc)
      end
    end
    if est ~= "oculto" then
      local fase = fase_anim(no, 0.25, 0.15)
      local esc = escala_nascendo(fase)
      local r = (est == "pista" and raio_pista or raio) * esc
      -- o selo "Novo" fica em cima do nó: nome nenhum vai para lá
      local topo_selo = a.novos[no.id] and 16 or 0
      ocupado[#ocupado + 1] = { x = x - raio - 3, y = y - raio - 3 - topo_selo, w = raio * 2 + 6, h = raio * 2 + 6 + topo_selo }
      if fase > 0 then
        motor.circulo(x, y, r + 3, "#00000080")
        if est == "pista" then
          motor.circulo(x, y, r, "#241810")
          motor.anel(x, y, r - 1.5, r, "#6e5a48")
          motor.texto("?", x, y - 10, 16, cor.texto_fraco, "centro", true)
        elseif est == "revelado" then
          local pode = J.pode_comprar_no(no)
          motor.circulo(x, y, r, pode and "#4a3627" or "#2a2019")
          if pode then
            -- o único estado que pulsa
            local g = 1 + math.sin(agora * 5) * 0.08
            motor.anel(x, y, r * g, r * g + 3.5, cor.ouro)
          else
            motor.anel(x, y, r - 2, r, rc)
          end
          motor.texto("0/" .. no.max, x, y - 9, no.max >= 10 and 13 or 15, pode and cor.texto or cor.texto_fraco, "centro", true)
        else
          local nv = J.nivel(no.id)
          local cheio = J.no_maximo(no)
          motor.circulo(x, y, r, cheio and escurecer(rc) or rc)
          if J.pode_comprar_no(no) then
            local g = 1 + math.sin(agora * 5) * 0.08
            motor.anel(x, y, r * g, r * g + 3.5, cor.ouro)
          end
          if cheio then
            motor.texto("OK", x, y - 9, 15, "#21150e", "centro", true)
          else
            motor.texto(nv .. "/" .. no.max, x, y - 9, no.max >= 10 and 13 or 15, "#21150e", "centro", true)
          end
        end
        if a.sel == no.id then motor.anel(x, y, r + 4, r + 7, "#ffffff") end
        -- recém-revelado: some sozinho depois de visto por alguns segundos
        if a.novos[no.id] then
          if agora - a.novos[no.id] > 6 and ponto_visivel(x, y) then a.novos[no.id] = nil
          else
            motor.retangulo(x - 18, y - r - 13, 36, 17, cor.ouro, 8)
            motor.texto("Novo", x, y - r - 13, 13, cor.texto_ouro, "centro", true)
          end
        end
      end
      -- só a parte do nó dentro da área da árvore pode ser tocada
      local toque = math.max(r, 20)
      local z0, z1 = math.max(y - toque - 4, 56), math.min(y + toque + 4, 480)
      if z1 > z0 then
        U.zona("no_" .. no.id, { x = x - toque - 4, y = z0, w = toque * 2 + 8, h = z1 - z0 },
          function()
            a.sel, a.anim = no.id, {}
            a.novos[no.id] = nil
            motor.som("clique")
            -- o painel não fica em cima do nó escolhido
            if x > 640 and y < 360 then deslizar_para(a.x - (x - 620), a.y, a.zoom) end
          end, true)
      end
    end
  end
  -- anel que expande no nó recém-comprado
  if a.anel then
    local no = A.POR_ID[a.anel.id]
    local f = (agora - a.anel.ini) / 0.35
    if f >= 1 or not no then a.anel = nil
    else
      local x, y = no_tela(no)
      local c = cor.ouro:sub(1, 7) .. string.format("%02x", math.floor((1 - f) * 200))
      local r = raio + f * 22
      motor.anel(x, y, r, r + 3, c)
    end
  end

  -- nomes: primeiro o que dá para comprar, depois os ramos, por fim o que já está comprado
  local function nomes(comprados)
    for _, no in ipairs(arv.nos) do
      local est = J.estado_no(no)
      if ((est == "comprado") == comprados) and est ~= "oculto" and est ~= "pista" and fase_anim(no, 0.4, 0.15) >= 1 then
        local x, y = no_tela(no)
        local custo = not J.no_maximo(no) and J.custo_no(no) or nil
        local w = motor.largura_texto(no.nome, 13, true) + 8
        if custo then w = math.max(w, motor.largura_texto(fmt(custo), 13, true) + 28) end
        local r = colocar(candidatos_no(x, y, raio, w, custo and 35 or 18), ocupado)
        if r then desenhar_rotulo_no(r, no, custo, J.pode_comprar_no(no)) end
      end
    end
  end
  nomes(false)
  for _, id in ipairs(arv.ordem_ramos) do
    local ramo = arv.ramos[id]
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
    for _, no in ipairs(arv.nos) do
      local est = J.estado_no(no)
      if no.ramo == id and (est == "comprado" or est == "revelado") then visivel = true; break end
    end
    local r = visivel and colocar(cands, ocupado)
    if r then
      motor.retangulo(r.x, r.y, r.w, r.h, "#1a110be8", 9)
      motor.texto(ramo.nome, r.x + r.w / 2, r.y + 1, 13, ramo.cor, "centro", true)
    end
  end
  nomes(true)
  motor.recorte()

  -- jogador mexeu na câmera e surgiu novidade fora da vista: seta na borda, sem tomar o controle
  for id in pairs(a.novos) do
    local no = A.POR_ID[id]
    local x, y = no_tela(no)
    if not ponto_visivel(x, y) then
      local sx, sy = util.limitar(x, 34, 926), util.limitar(y, 90, 446)
      local d = math.max(1, util.distancia(sx, sy, x, y))
      local ux, uy = (x - sx) / d, (y - sy) / d
      motor.circulo(sx, sy, 20, "#21150ef0")
      motor.anel(sx, sy, 17, 20, cor.ouro)
      motor.triangulo(sx + ux * 12, sy + uy * 12, sx - ux * 6 - uy * 8, sy - uy * 6 + ux * 8, sx - ux * 6 + uy * 8, sy - uy * 6 - ux * 8, cor.ouro)
      U.zona("seta_novo", { x = sx - 22, y = sy - 22, w = 44, h = 44 }, function()
        deslizar_para(-no.x * a.zoom, -no.y * a.zoom, a.zoom)
        motor.som("clique")
      end, true)
      break
    end
  end

  -- instruções e ajuda
  local ajuda = U.celular() and "Arraste para navegar  •  Pinça: zoom" or "Arraste para navegar  •  Roda: zoom"
  -- no pé da tela: o painel da dívida não cobre
  motor.retangulo(124, 438, motor.largura_texto(ajuda, 13) + 20, 28, "#21150ee8", 8)
  motor.texto(ajuda, 134, 443, 13, cor.texto_fraco)
  U.botao("arvore_centro", 14, 432, 104, 40, "Centralizar", { cor = "#3d291b", cor_texto = cor.texto, tam = 13 },
    enquadrar_arvore)

  -- detalhe do nó escolhido
  local no = a.sel and A.POR_ID[a.sel]
  if no and J.estado_no(no) == "oculto" then no, a.sel = nil, nil end
  if no then
    local est = J.estado_no(no)
    local px, py, pw, ph = 672, 64, 276, 280
    U.painel(px, py, pw, ph, "#2c1d13f8", est == "pista" and "#6e5a48" or arv.ramos[no.ramo].cor)
    U.zona("painel_no", { x = px, y = py, w = pw, h = ph })
    if est == "pista" then
      -- sem nome nem custo: é uma surpresa
      U.paragrafo("?", px + 14, py + 30, pw - 58, 18, cor.texto, true)
      local txt = "Algo novo surge aqui."
      if no.em_breve and J.no_liberado(no) then txt = "Algo novo surge aqui, em uma próxima versão do jogo." end
      U.paragrafo(txt, px + 14, py + 60, pw - 28, 14, cor.texto_fraco)
      U.botao("fechar_no", px + pw - 44, py + 4, 40, 40, "x", { cor = "#3d291b", cor_texto = cor.texto, tam = 15 }, function() a.sel = nil end)
      return
    end
    local custo = J.custo_no(no)
    motor.texto(arv.ramos[no.ramo].nome, px + 14, py + 10, 13, arv.ramos[no.ramo].cor, "esquerda", true)
    local h = U.paragrafo(no.nome, px + 14, py + 30, pw - 28 - 30, 18, cor.texto, true)
    local y = py + 34 + h
    local bx, by, bw = px + 14, py + ph - 58, pw - 28
    y = y + U.paragrafo(no.desc, px + 14, y, pw - 28, 14, cor.texto_fraco) + 8
    if no.max > 1 then motor.texto("Nível " .. J.nivel(no.id) .. " de " .. no.max, px + 14, y, 14, cor.ouro, "esquerda", true) end
    if J.no_maximo(no) then
      U.botao("comprar_no", bx, by, bw, 46, no.max > 1 and "Nível máximo" or "Já comprado", { ativo = false, cor_texto = cor.verde })
    elseif J.no_liberado(no) then
      local pode = J.pode_comprar_no(no)
      U.botao("comprar_no", bx, by, bw, 46, "Comprar", { preco = custo, ativo = pode, cor_texto = pode and cor.texto_ouro or cor.texto, som = "compra", tam = 16 },
        function()
          a.anim = {}
          J.comprar_no(no.id)
        end)
      if not pode then
        motor.texto("Faltam " .. fmt(custo - J.estado.ouro) .. " de ouro", bx, by - 32, 13, cor.texto_fraco)
        U.barra(bx, by - 12, bw, 6, J.estado.ouro / custo, cor.ouro_escuro)
      end
    else
      -- save antigo: nível comprado sem o novo pré-requisito
      U.botao("comprar_no", bx, by, bw, 46, "Falta um passo", { ativo = false, tam = 14 })
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
  fundo_aba("Mural de missões", J.missoes_comuns_ativas() .. " de " .. J.vagas_missao() .. " vagas ocupadas por aventureiros  •  "
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
    motor.texto("História do menestrel: missões pagam +25% por " .. duracao_texto(J.buff), AREA.x + AREA.w - 8, y + 10, 14, cor.verde, "direita", true)
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

-- bloco de uma fazenda: nome, o que tem nela e o estoque de cada ingrediente, com imagem
local function bloco_fazenda(sala, nome, info, x, y, w, aberta)
  motor.retangulo(x, y, w, 104, "#3d291b", 8)
  motor.texto(nome, x + 10, y + 6, 15, aberta and cor.texto or cor.texto_fraco, "esquerda", true)
  motor.texto(info, x + 10, y + 27, 12, cor.texto_fraco)
  local e = J.estado
  local cx = x + 10
  local r = J.proxima_colheita()
  for _, d in ipairs(C.estoques) do
    if d.fazenda == sala then
      motor.retangulo(cx, y + 48, 138, 48, "#21150e", 6)
      M.miniatura(d.modelo, cx + 3, y + 51, 42, 42)
      motor.texto(d.nome, cx + 48, y + 52, 12, cor.texto_fraco)
      motor.texto(fmt(e.estoques[d.id]), cx + 48, y + 70, 15, cor.ouro, "esquerda", true)
      local q = r[d.id]
      if q and q > 0 then motor.texto("+" .. fmt(q), cx + 132, y + 72, 12, cor.verde, "direita") end
      cx = cx + 144
    end
  end
end

local function tela_producao()
  local e = J.estado
  fundo_aba("Produção", "As três fazendas enchem os estoques; a cozinha e a cervejaria servem o que há neles")
  M.gravar_miniaturas()

  U.painel(AREA.x, AREA.y + 56, 472, 340)
  local px = AREA.x + 12
  motor.texto("Próxima colheita em " .. duracao_texto(J.ciclo_jardim() - e.ciclo), px + 2, AREA.y + 62, 13, cor.texto_fraco)
  U.barra(px + 230, AREA.y + 66, 218, 8, e.ciclo / J.ciclo_jardim(), cor.verde)
  local yb, wb = AREA.y + 82, 448
  local function quem(ef) local n = J.ef(ef); return n > 0 and ("  •  fazendeiro nível " .. n) or "" end
  bloco_fazenda("jardim", "Fazenda de sementes",
    J.ef("canteiros") .. " canteiros  •  " .. fmt(e.sementes.lupulo) .. " sementes de lúpulo" .. quem("fazendeiro"), px, yb, wb, true)
  bloco_fazenda("pomar", "Fazenda de árvores frutíferas",
    J.ef("a_pomar") > 0 and ((J.ef("frutas") + 2) .. " árvores  •  " .. fmt(e.sementes.fruta) .. " sementes de fruta" .. quem("fazendeiro_arvores")) or "Libere na Árvore", px, yb + 104 + 3, wb, J.ef("a_pomar") > 0)
  bloco_fazenda("fazenda", "Fazenda de animais",
    J.ef("a_fazenda") > 0 and (J.ef("vacas") .. " vacas  •  " .. J.ef("porcos") .. " porcos  •  " .. J.ef("galinhas") .. " galinhas" .. quem("fazendeiro_animais")) or "Libere na Árvore", px, yb + 2 * 107, wb, J.ef("a_fazenda") > 0)

  U.painel(AREA.x + 484, AREA.y + 56, 452, 340)
  local qx = AREA.x + 498
  motor.texto("Cozinha", qx, AREA.y + 62, 16, cor.texto, "esquerda", true)
  local nc = J.ef("cozinheiro")
  local tc = nc > 0 and ("Comida da casa rende x" .. string.format("%.2f", C.bonus_cozinheiro + C.bonus_cozinheiro_nivel * (nc - 1)):gsub("%.", ",")) or "Serve o que há em estoque. Cozinheiro faz render mais"
  motor.texto(tc, qx, AREA.y + 84, 13, cor.texto_fraco)
  motor.texto("Cervejaria", qx, AREA.y + 110, 16, cor.texto, "esquerda", true)
  local nb = J.ef("bebida_casa")
  local tb = nb > 0 and ("Bebida da casa rende x" .. string.format("%.2f", C.bonus_bebida_casa + C.bonus_bebida_nivel * (nb - 1)):gsub("%.", ",")) or "Abra a Cervejaria para servir o que você colhe"
  motor.texto(tb, qx, AREA.y + 132, 13, cor.texto_fraco)
  local linhas = {
    { "Cozinheiro", "cozinheiro" },
    { "Receita da casa", J.nivel("cervejaria") > 0 and "cerveja_melhor" or "cervejaria" },
    { "Adubo", "adubo" },
    { "Irrigação", "irrigacao" },
    { "Cardápio", "cardapio" },
  }
  for i, l in ipairs(linhas) do
    local y = AREA.y + 156 + (i - 1) * 40
    motor.texto(l[1] .. " (nível " .. J.nivel(l[2]) .. ")", qx, y + 10, 14, cor.texto)
    atalho_no(l[2], qx + 288, y, 136)
  end
  U.botao("ir_loja_canteiro", qx + 180, AREA.y + 56, 244, 40, "Canteiros, árvores e animais: Loja", { tam = 13 }, function() T.aba = "loja" end)
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
    U.botao("investir_" .. c.id .. "_" .. id, px, y + 22, 118, 40, nil, { preco = custo, ativo = pode, cor_texto = pode and cor.texto_ouro or cor.texto, tam = 14, som = "compra", solto = true },
      function() J.investir(c, id) end)
  end
  if J.pode_promover(c) then
    local cp = J.custo_promover(c)
    U.botao("promover_" .. c.id, bx - 210, y + 22, 202, 44, "Virar herói", { preco = cp, ativo = J.estado.ouro >= cp, tam = 14, cor = "#7f8fe6", cor_texto = "#10131f", som = "compra", solto = true },
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
  -- botões cortados pela rolagem não existem para o toque (nem tapam o que está em volta)
  for i = #U.zonas, 1, -1 do
    local z = U.zonas[i]
    if (z.id:find("^investir_") or z.id:find("^promover_")) and (z.y + z.h > ly + lh or z.y < ly) then
      table.remove(U.zonas, i)
    end
  end
  if maximo > 0 then
    local p = T.rolagem.aventureiros / maximo
    motor.retangulo(lx + lw - 8, ly + p * (lh - 50), 6, 50, cor.texto_fraco, 3)
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
      U.botao("party_final", AREA.x + 16, y + 76, 240, 46, "Formar a party final", { cor = "#9c78ff", cor_texto = "#120c20" }, function() J.formar_party_final() end)
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

function T.abrir_carroca()
  if J.carroca_presente() then T.modal = "carroca"; motor.som("clique") end
end

-- A lista da carroça: imagem, nome e preço. O jogo segue rodando; ela se fecha quando a carroça parte.
local function janela_carroca()
  if not J.carroca_presente() then T.modal = nil; return end
  M.gravar_miniaturas()
  bloquear()
  local x, y, w, h = 56, 22, 848, 496
  U.painel(x, y, w, h, cor.carta, cor.ouro_escuro)
  U.zona("janela", { x = x, y = y, w = w, h = h })
  motor.texto("Carroça do comerciante", x + 24, y + 12, 22, cor.texto, "esquerda", true)
  motor.texto("Parte em " .. relogio(J.carroca_resta()) .. "  •  Volta a cada " .. math.floor(C.carroca_intervalo / 60) .. " minutos", x + 24, y + 42, 13, cor.texto_fraco)
  U.moeda(x + w - 200, y + 30, 11)
  motor.texto(fmt(J.estado.ouro), x + w - 184, y + 20, 16, cor.ouro, "esquerda", true)
  U.botao("carroca_fechar", x + w - 52, y + 8, 44, 44, "x", { cor = "#4a3627", cor_texto = cor.texto }, function() T.modal = nil end)
  local cw, ch, gx, gy = 404, 78, 16, 6
  local n = 0
  for _, d in ipairs(C.carroca) do
    local est = J.estado_carroca(d.id)
    if not est.sumir then
      local cx = x + 12 + (n % 2) * (cw + gx)
      local cy = y + 66 + math.floor(n / 2) * (ch + gy)
      n = n + 1
      motor.retangulo(cx, cy, cw, ch, "#3d291b", 8)
      motor.retangulo(cx + 6, cy + 6, ch - 12, ch - 12, "#21150e", 6)
      M.miniatura(d.modelo, cx + 6, cy + 6, ch - 12, ch - 12)
      local tx = cx + ch + 2
      motor.texto(d.nome, tx, cy + 7, 15, d.tipo == "raro" and "#c9a7ff" or cor.texto, "esquerda", true)
      motor.texto(d.desc, tx, cy + 29, 12, cor.texto_fraco)
      if est.motivo then
        motor.texto(est.motivo, tx, cy + 50, 13, "#ffb0a2", "esquerda", true)
      else
        local pode = J.estado.ouro >= est.preco
        local txt = fmt(est.preco) .. " de ouro"
        if d.lote then txt = d.lote .. " por " .. fmt(est.preco) end
        if d.tipo == "raro" then txt = C.raro_usos .. " usos por " .. fmt(est.preco) end
        motor.texto(txt, tx, cy + 50, 13, pode and cor.ouro or "#ff9a8a", "esquerda", true)
        local function comprar(mult)
          local ok, motivo = J.comprar_carroca(d.id, mult)
          if not ok and motivo then J.avisar(motivo) end
        end
        local bx = cx + cw - 78
        if d.lote2 then
          local k = d.lote2 / d.lote
          U.botao("carroca_" .. d.id .. "_2", bx, cy + 18, 70, 44, "+" .. d.lote2, { ativo = J.estado.ouro >= est.preco * k, tam = 14 }, function() comprar(k) end)
          bx = bx - 76
          U.botao("carroca_" .. d.id, bx, cy + 18, 70, 44, "+" .. d.lote, { ativo = pode, tam = 14 }, function() comprar(1) end)
        else
          U.botao("carroca_" .. d.id, bx, cy + 18, 70, 44, "Levar", { ativo = pode, tam = 14 }, function() comprar(1) end)
        end
      end
    end
  end
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
  if motor.plataforma == "desktop" then
    alternador("tela_cheia", "Tela cheia (F11)", cx, y + 156, motor.tela_cheia(), function() motor.alternar_tela_cheia() end)
  end
  -- sem a linha de tela cheia, as opções sobem para não deixar um buraco
  local ya = motor.plataforma == "desktop" and y + 204 or y + 156
  alternador("sombras", "Sombras (mais leve sem)", cx, ya, o.sombras, function() o.sombras = not o.sombras; T.aplicar_opcoes() end)
  alternador("mostrar_fps", "FPS e fluxo de pessoas", cx, ya + 48, o.fps, function() o.fps = not o.fps end)

  local bx = x + w - 230
  U.botao("minimizar2", bx, y + 60, 200, 44, "Minimizar", { cor = "#4a3627", cor_texto = cor.texto }, function() motor.minimizar() end)
  U.botao("estatisticas", bx, y + 112, 200, 44, "Estatísticas", { cor = "#4a3627", cor_texto = cor.texto }, function() T.modal = "stats" end)
  U.botao("creditos", bx, y + 164, 200, 44, "Créditos", { cor = "#4a3627", cor_texto = cor.texto }, function() T.modal = "creditos" end)
  U.botao("salvar", bx, y + 216, 200, 44, "Salvar agora", { cor = "#4a3627", cor_texto = cor.texto }, function()
    J.salvar()
    J.avisar("Progresso salvo!", 2)
    T.modal = nil
  end)

  motor.retangulo(cx, y + 322, w - 56, 2, "#00000050")
  if T.confirmar then
    motor.texto("Apagar todo o progresso? Não dá para desfazer.", cx, y + 334, 15, "#ff9a8a", "esquerda", true)
    U.botao("apagar_nao", cx, y + 362, 180, 46, "Não, manter", {}, function() T.confirmar = false end)
    U.botao("apagar_sim", cx + 192, y + 362, 180, 46, "Sim, apagar", { cor = cor.vermelho, cor_texto = "#ffffff" }, function()
      J.apagar_progresso()
      T.iniciar()
    end)
  else
    U.botao("apagar", cx, y + 334, 200, 46, "Apagar progresso", { cor = "#5a2a22", cor_texto = "#ffb0a2" }, function() T.confirmar = true end)
  end
  motor.texto("Versão " .. (motor.versao or "dev"), cx, y + h - 34, 13, cor.texto_fraco)
  U.botao("voltar_menu", x + 28, y + h - 62, 200, 48, "Tela inicial", { cor = "#4a3627", cor_texto = cor.texto }, function()
    S.voltar_ao_menu()
    T.iniciar()
  end)
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

-- Cor e desenho de cada tipo de novidade (só aparência)
local function icone_pessoa(x, y)
  motor.circulo(x, y - 9, 8, "#fff6e6")
  motor.retangulo(x - 12, y + 1, 24, 15, "#fff6e6", 7)
end
local function icone_estrela(x, y)
  for i = 0, 4 do
    local a = -math.pi / 2 + i * 2 * math.pi / 5
    local ax, ay = x + math.cos(a) * 19, y + math.sin(a) * 19
    local bx, by = x + math.cos(a - 0.63) * 8, y + math.sin(a - 0.63) * 8
    local cx, cy = x + math.cos(a + 0.63) * 8, y + math.sin(a + 0.63) * 8
    motor.triangulo(ax, ay, bx, by, cx, cy, "#fff6e6")
    motor.triangulo(ax, ay, cx, cy, bx, by, "#fff6e6")
  end
  motor.circulo(x, y, 8, "#fff6e6")
end
local function icone_casa(x, y)
  motor.triangulo(x + 18, y - 2, x - 18, y - 2, x, y - 18, "#fff6e6")
  motor.triangulo(x - 18, y - 2, x + 18, y - 2, x, y - 18, "#fff6e6")
  motor.retangulo(x - 12, y - 2, 24, 17, "#fff6e6", 2)
end
local function icone_planta(x, y)
  motor.linha(x, y + 15, x, y - 6, 4, "#fff6e6")
  motor.circulo(x - 8, y - 2, 7, "#fff6e6")
  motor.circulo(x + 8, y - 2, 7, "#fff6e6")
  motor.circulo(x, y - 11, 7, "#fff6e6")
end
local function icone_moeda(x, y) U.moeda(x, y, 18) end
local function icone_caneca(x, y) U.caneca(x - 2, y, 1.1) end
local function icone_coxa(x, y) U.coxa(x, y, 1) end

local TEMAS_NOTICIA = {
  obra = { c = "#e0964a", icone = icone_casa },
  gente = { c = "#6fb1e4", icone = icone_pessoa },
  comida = { c = "#7cc765", icone = icone_planta },
  comercio = { c = cor.ouro, icone = icone_moeda },
  fama = { c = "#ee7d5c", icone = icone_estrela },
  magia = { c = "#b892f0", icone = icone_estrela },
}
local TEMA_POR_ID = {
  mesa = "obra", prateleira = "obra", ala_leste = "obra",
  garcom = "gente", bardo = "gente", recrutador = "gente",
  jardim = "comida", fazendeiro = "comida", fazendeiro_arvores = "comida", fazendeiro_animais = "comida", cozinheiro = "comida", cervejaria = "comida",
  mercadinho = "comercio", venda = "comercio",
  party = "fama", heroi = "fama", propaganda = "fama",
  invocacao = "magia",
}
local ICONE_POR_ID = { cozinheiro = icone_coxa, cervejaria = icone_caneca }

-- Tela inicial ---------------------------------------------------------------------

local function cabecalho_menu()
  motor.retangulo(0, 0, 960, 540, "#0d0805a8")
  motor.texto("Taverna de Aventureiros", 482, 46, 46, "#00000090", "centro", true)
  motor.texto("Taverna de Aventureiros", 480, 44, 46, cor.ouro, "centro", true)
end

local function tela_titulo()
  cabecalho_menu()
  motor.texto("Do balcão de um vilarejo à guilda que salva o mundo", 481, 105, 17, "#000000a0", "centro")
  motor.texto("Do balcão de um vilarejo à guilda que salva o mundo", 480, 104, 17, cor.texto, "centro")
  local x, w, y, passo = 340, 280, 136, 58
  local ultimo = S.ultimo()
  U.botao("menu_continuar", x, y, w, 50, "Continuar", { ativo = ultimo ~= nil, tam = 19 }, function() S.abrir(ultimo); T.iniciar() end)
  local outro = { cor = "#3d291b", cor_texto = cor.texto, tam = 18 }
  U.botao("menu_novo", x, y + passo, w, 50, "Novo jogo", outro, function() T.tela = "novo"; T.confirmar = false end)
  U.botao("menu_carregar", x, y + passo * 2, w, 50, "Jogos salvos", outro, function() T.tela = "carregar"; T.confirmar = false end)
  local sy = y + passo * 3
  if motor.plataforma == "desktop" then
    U.botao("menu_tela", x, sy, w, 50, motor.tela_cheia() and "Modo janela" or "Tela cheia", outro, function() motor.alternar_tela_cheia() end)
    sy = sy + passo
  end
  U.botao("menu_sair", x, sy, w, 50, "Sair", { cor = "#5a2a22", cor_texto = "#ffb0a2", tam = 18 }, function() motor.sair() end)
  if motor.apk_velho then
    motor.texto("Há um APK novo: baixe-o de novo para receber as atualizações.", 480, 490, 14, "#ff9a8a", "centro", true)
  end
  motor.texto("Versão " .. (motor.versao or "dev"), 480, 512, 13, cor.texto_fraco, "centro")
end

local function texto_resumo(r)
  if r.fim then return "Lorde Demônio derrotado  •  " .. duracao_texto(r.tempo) end
  return fmt(r.ouro) .. " de ouro  •  " .. r.nos .. " melhorias  •  " .. duracao_texto(r.tempo)
end

local function cartao_vaga(id, x, y, w, nome, detalhe, fn, extra)
  motor.retangulo(x, y, w, 62, "#3d291bf4", 10)
  motor.contorno(x, y, w, 62, cor.carta_borda, 2, 10)
  motor.texto(nome, x + 16, y + 9, 17, cor.texto, "esquerda", true)
  motor.texto(detalhe, x + 16, y + 35, 14, cor.texto_fraco)
  U.zona(id, { x = x, y = y, w = w - (extra or 0), h = 62 }, fn)
end

local function voltar_menu_botao()
  U.botao("menu_voltar", 40, 484, 170, 44, "Voltar", { cor = "#3d291b", cor_texto = cor.texto }, function() T.tela = "titulo"; T.confirmar = false end)
end

local function tela_novo()
  cabecalho_menu()
  motor.texto("Novo jogo: escolha uma vaga", 480, 112, 22, cor.texto, "centro", true)
  local x, w = 230, 500
  for i, v in ipairs(S.VAGAS) do
    local y = 156 + (i - 1) * 72
    local r = S.resumo(v.arquivo)
    cartao_vaga("menu_vaga_" .. i, x, y, w, v.nome, r and ("Ocupada: " .. texto_resumo(r)) or "Vaga livre", function()
      if r then T.confirmar = v
      else
        S.novo(v.arquivo)
        T.iniciar()
      end
      motor.som("clique")
    end)
  end
  if T.confirmar then
    local v = T.confirmar
    motor.texto("Apagar " .. v.nome .. " e começar de novo?", 480, 386, 17, "#ff9a8a", "centro", true)
    U.botao("menu_apagar_nao", 300, 416, 170, 46, "Não", {}, function() T.confirmar = false end)
    U.botao("menu_apagar_sim", 490, 416, 170, 46, "Sim, apagar", { cor = cor.vermelho, cor_texto = "#ffffff" }, function()
      S.novo(v.arquivo)
      T.iniciar()
    end)
  end
  voltar_menu_botao()
end

local function tela_carregar()
  cabecalho_menu()
  local x, w = 40, 430
  motor.texto("Jogos salvos", x + w / 2, 112, 20, cor.texto, "centro", true)
  for i, v in ipairs(S.VAGAS) do
    local y = 146 + (i - 1) * 72
    local r = S.resumo(v.arquivo)
    if r then
      cartao_vaga("menu_abrir_" .. i, x, y, w, v.nome, texto_resumo(r), function()
        motor.som("clique")
        S.abrir(v.arquivo)
        T.iniciar()
      end)
    else
      cartao_vaga("menu_abrir_" .. i, x, y, w, v.nome, "Vazio", function() motor.som("erro") end)
    end
  end

  local px, pw = 490, 430
  motor.texto("Saves de teste", px + pw / 2, 112, 20, cor.ouro, "centro", true)
  for i, p in ipairs(S.PRONTOS) do
    local y = 146 + (i - 1) * 72
    local jogado = S.resumo(p.arquivo) ~= nil
    cartao_vaga("menu_pronto_" .. i, px, y, pw, p.nome, p.desc, function()
      motor.som("clique")
      if S.abrir_pronto(p) then T.iniciar() end
    end, jogado and 112 or 0)
    if jogado then
      U.botao("menu_pronto_refazer_" .. i, px + pw - 104, y + 11, 94, 40, "Recomeçar", { cor = "#4a3627", cor_texto = cor.texto, tam = 13 }, function()
        if S.abrir_pronto(p, true) then T.iniciar() end
      end)
    end
  end
  motor.texto("O progresso nos saves de teste fica guardado à parte.", px + pw / 2, 368, 14, cor.texto_fraco, "centro")
  voltar_menu_botao()
end

-- Notícia: o jogo para para contar que algo importante pode ser liberado
local function janela_noticia()
  local n = J.noticia
  if not n then return end
  bloquear()
  local x, y, w, h = 210, 96, 540, 330
  local rank = n.id and n.id:match("^rank_(%a+)$")
  local tema = TEMAS_NOTICIA[n.final and "magia" or (rank and "fama") or TEMA_POR_ID[n.id]] or TEMAS_NOTICIA.comercio
  U.painel(x, y, w, h, cor.carta, tema.c)
  U.zona("janela", { x = x, y = y, w = w, h = h })
  motor.retangulo(x + 2, y + 2, w - 4, 34, tema.c, 10)
  motor.texto("NOVIDADE NA TAVERNA", x + w / 2, y + 9, 15, "#2a1608", "centro", true)
  -- ícone com raios girando ao lado do título
  local tam = 28
  while tam > 20 and motor.largura_texto(n.titulo, tam, true) > w - 130 do tam = tam - 1 end
  local tw = motor.largura_texto(n.titulo, tam, true)
  local ix, iy = x + w / 2 - (tw + 74) / 2 + 28, y + 80
  local giro = motor.tempo() * 0.8
  for i = 0, 7 do
    local a = giro + i * math.pi / 4
    motor.linha(ix + math.cos(a) * 32, iy + math.sin(a) * 32, ix + math.cos(a) * 39, iy + math.sin(a) * 39, 3, tema.c)
  end
  motor.circulo(ix, iy, 28, tema.c)
  motor.circulo(ix, iy, 24, "#00000040")
  if rank then
    motor.texto(rank:upper(), ix, iy - 16, 24, "#fff6e6", "centro", true)
  else
    (ICONE_POR_ID[n.id] or tema.icone)(ix, iy)
  end
  motor.texto(n.titulo, ix + 46, iy - tam * 0.68, tam, cor.texto, "esquerda", true)
  U.paragrafo(n.texto, x + 34, y + 128, w - 68, 18, cor.texto, false, "centro")
  if n.final then
    U.botao("noticia_ver", x + 60, y + h - 76, 240, 54, "Ver a missão", { tam = 16 }, function()
      J.noticia = nil
      T.aba = "invocacao"
    end)
    U.botao("noticia_depois", x + 312, y + h - 76, 168, 54, "Depois", { cor = "#4a3627", cor_texto = cor.texto }, function() J.noticia = nil end)
    return
  end
  if n.id == "historia" then
    U.botao("noticia_emprestimo", x + w / 2 - 150, y + h - 76, 300, 54, "Pegar o empréstimo", { tam = 17, som = "compra" }, function()
      J.pegar_emprestimo()
      J.noticia = nil
    end)
    return
  end
  local no = A.POR_ID[n.id]
  local custo = J.custo_no(no)
  local rotulo_custo = "Custa " .. fmt(custo) .. " de ouro"
  U.moeda(x + w / 2 - motor.largura_texto(rotulo_custo, 15, true) / 2 - 14, y + h - 98, 9)
  motor.texto(rotulo_custo, x + w / 2, y + h - 108, 15, cor.ouro, "centro", true)
  U.botao("noticia_abrir", x + 60, y + h - 76, 240, 54, "Liberar agora", { tam = 17, som = "compra" }, function()
    J.comprar_no(n.id)
    J.noticia = nil
  end)
  U.botao("noticia_depois", x + 312, y + h - 76, 168, 54, "Depois", { cor = "#4a3627", cor_texto = cor.texto }, function() J.noticia = nil end)
end

-- Faixa do menestrel: conta a história sem parar o jogo
local function banner_menestrel()
  local b = J.banner
  if not b then return end
  local entrada = util.limitar(b.vida / 0.4, 0, 1)
  local saida = util.limitar((b.duracao - b.vida) / 0.5, 0, 1)
  motor.opacidade(math.min(entrada, saida))
  -- entra de baixo para não passar sobre o objetivo; desce se o painel de FPS estiver ligado
  local base = J.estado.opcoes.fps and 104 or 58
  local x, y, w, h = 150, base + (1 - util.suave(entrada)) * 12, 660, 84
  motor.retangulo(x, y + 3, w, h, cor.sombra, 14)
  U.painel(x, y, w, h, "#3a2415f8", "#c0562f")
  motor.circulo(x + 40, y + h / 2, 26, "#c0562f")
  motor.circulo(x + 34, y + h / 2 + 8, 7, "#fff6e6")
  motor.linha(x + 40, y + h / 2 + 8, x + 40, y + h / 2 - 14, 3, "#fff6e6")
  motor.linha(x + 40, y + h / 2 - 14, x + 52, y + h / 2 - 8, 3, "#fff6e6")
  motor.texto(b.titulo, x + 78, y + 8, 16, cor.ouro, "esquerda", true)
  U.paragrafo(b.texto, x + 78, y + 30, w - 92, 14, cor.texto)
  motor.opacidade(1)
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
  M.painel_alvo = (T.aba == "loja" and not T.tela) and 1 or 0
  if T.aba ~= "loja" then Lj.cancelar() end
  if T.tela then
    M.atualizar(dt)
    motor.roda()
    return
  end
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
  local bloqueado = T.modal or J.offline or J.estado.fim or J.noticia
  if roda ~= 0 and not bloqueado then
    if T.aba == "taverna" then M.rolar(roda)
    elseif T.aba == "loja" then Lj.rolar(roda)
    elseif T.aba == "arvore" then zoom_no_cursor(roda)
    elseif T.aba == "aventureiros" then T.rolagem.aventureiros = T.rolagem.aventureiros - roda * 40 end
  end
  if T.toque and motor.mouse_baixo() and not bloqueado then
    local mx, my = motor.mouse()
    local dx, dy = mx - T.toque.ux, my - T.toque.uy
    T.toque.ux, T.toque.uy = mx, my
    -- o dedo treme mais que o mouse: folga maior para um toque não virar arraste
    if math.abs(mx - T.toque.x) + math.abs(my - T.toque.y) > (U.celular() and 14 or 8) then T.toque.moveu = true end
    if T.aba == "arvore" then
      if T.toque.arrasta then
        T.arv.alvo = nil
        T.arv.x = T.arv.x + dx
        T.arv.y = T.arv.y + dy
        if T.toque.moveu then T.arv.manual = true end
        limitar_arvore()
      end
    elseif T.aba == "taverna" then M.arrastar(dx, dy)
    elseif T.aba == "loja" then
      if T.toque.no_painel then Lj.rolar_lista(dy)
      elseif T.toque.arrasta then M.arrastar(dx, dy) end
    elseif T.aba == "aventureiros" then T.rolagem.aventureiros = T.rolagem.aventureiros - dy end
  end
  if T.aba == "loja" then
    if bloqueado then Lj.soltar(true) else Lj.atualizar(dt) end
  end
end

function T.desenhar()
  U.limpar()
  if T.tela then
    M.desenhar_cena()
    if T.tela == "titulo" then tela_titulo()
    elseif T.tela == "novo" then tela_novo()
    else tela_carregar() end
    return
  end
  local aba_atual = T.aba
  M.desenhar_cena()
  if T.aba == "taverna" or T.aba == "loja" then
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
  if T.aba == "loja" then Lj.desenhar() end
  if T.aba == "taverna" or T.aba == "loja" then M.desenhar_botoes_andar() end
  dica()
  aviso()
  if T.modal == "carroca" then janela_carroca()
  elseif T.modal == "config" then janela_config()
  elseif T.modal == "stats" then janela_stats()
  elseif T.modal == "creditos" then janela_creditos()
  end
  banner_menestrel()
  if J.noticia and not T.modal and not J.offline then janela_noticia() end
  if J.offline then janela_offline() end
  if J.estado.fim and not T.modal then tela_final() end
end

function T.tocar(x, y)
  if T.tela then
    local z = U.achar(x, y)
    if z and z.fn then z.fn() end
    return
  end
  T.toque = { x = x, y = y, ux = x, uy = y, moveu = false, arrasta = false }
  local z = U.achar(x, y)
  if z then
    if z.id:find("^loja_") then T.toque.no_painel = true end
    if z.solto then
      T.toque.zona = z
      T.toque.arrasta = true
    elseif z.fn then
      z.fn()
    end
    return
  end
  T.toque.arrasta = true
  local livre = not T.modal and not J.offline and not J.estado.fim
  if T.aba == "taverna" and livre then M.tocar(x, y)
  elseif T.aba == "loja" and livre and Lj.tocar(x, y) then T.toque.arrasta = false end
end

function T.soltar(x, y)
  if T.tela then return end
  local t = T.toque
  T.toque = nil
  if T.aba == "loja" then Lj.soltar() end
  if t and t.zona and not t.moveu and t.zona.fn then
    local z = U.achar(x, y)
    if z and z.id == t.zona.id then z.fn() end
  end
end

-- o toque virou pinça: sem soltar, nada de disparar o botão que estava sob o dedo
function T.cancelar_toque()
  if T.tela then return end
  T.toque = nil
  Lj.soltar(true)
end

function T.esc()
  if T.tela then
    if T.tela ~= "titulo" then T.tela = "titulo"; T.confirmar = false end
    return
  end
  if J.offline then return end
  if J.noticia and not T.modal then J.noticia = nil return end
  if T.aba == "loja" and not T.modal and Lj.voltar() then return end
  if T.modal == "config" or T.modal == "carroca" then T.modal = nil
  elseif T.modal then T.modal = "config"
  elseif T.aba ~= "taverna" then T.aba = "taverna"
  else T.modal = "config"; T.confirmar = false end
end

return T
