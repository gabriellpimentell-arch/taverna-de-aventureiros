-- =============================================================================
--  MODO DE EDIÇÃO (F2 ou Configurações), no estilo The Sims
--  A cena é o editor: tocar seleciona qualquer item, arrastar move, as alças das
--  paredes mudam o tamanho. Os painéis só aparecem quando pedidos e somem ao arrastar.
--  As posições ficam salvas no aparelho e continuam valendo depois das atualizações.
-- =============================================================================

local J = require("jogo")
local L = require("layout")
local M = require("mundo")
local U = require("ui")
local util = require("util")
local cor = util.cores

local E = { ativo = false }

local MAX_EXTRAS, MAX_DESFAZER = L.MAX_EXTRAS, 30
-- salas inteiras: no toque, só contam se nada menor estiver perto
local SALAS = {}
do
  local internas, externas = L.salas()
  for _, lista in ipairs({ internas, externas }) do
    for _, b in ipairs(lista) do SALAS[b.id] = true end
  end
  SALAS.taverna = true
end

-- Medidas do toque: no celular (S24 FE deitado) 60 de tela virtual são cerca de 8 mm
local function alvo() return U.celular() and 60 or 40 end
local function folga() return U.celular() and 26 or 14 end       -- quão perto do item o toque ainda vale
local function raio_alca() return U.celular() and 34 or 22 end
local function saiu_do_toque() return U.celular() and 12 or 4 end
local function fundo_tela() return 540 - alvo() - 8 end          -- onde começa a fileira de baixo
local function topo_tela() return 8 + alvo() end                 -- onde termina a fileira de cima

-- Caixa de cada objeto, em metros, para o toque acertar o que se vê:
-- { meia largura, meio fundo, altura de cima, altura de baixo }
local CAIXAS = {
  palco = { 0.6, 0.6, 0.15 }, carga = { 0.6, 0.5, 1.0 }, carga_leste = { 0.6, 0.5, 1.0 },
  balcao = { 2.75, 0.5, 1.1 }, barrilete = { 0.25, 0.25, 1.6, 1.1 },
  fogao = { 0.7, 0.45, 1.3 }, cozinheiro = { 0.3, 0.3, 1.7 }, prateleira = { 2.4, 0.15, 2.6, 0.8 },
  porta = { 0.15, 0.6, 2.4 }, lampiao_porta = { 0.15, 0.15, 2.4, 1.9 },
  lareira = { 0.5, 0.9, 2.6 }, lenha = { 0.3, 0.3, 0.6 }, quadro = { 1.0, 0.1, 2.4, 1.2 },
  quartos = { 0.8, 0.6, 3.0 }, vassoura = { 0.15, 0.15, 1.4 }, bardo = { 0.3, 0.3, 1.7 },
  tapete1 = { 1.5, 1.0, 0.05 }, tapete2 = { 1.5, 1.0, 0.05 },
  barraca = { 2.4, 1.0, 2.6 }, estantes = { 2.0, 0.4, 2.0 },
  canteiros = { 2.5, 1.2, 0.4 }, cerca = { 3.4, 0.1, 0.8 },
  celeiro = { 2.0, 1.8, 3.6 }, cocho = { 0.9, 0.3, 0.5 }, feno = { 0.7, 0.7, 1.0 }, cesto = { 0.3, 0.3, 0.5 },
  panelas = { 1.0, 0.1, 2.6, 1.8 }, mesa_preparo = { 1.0, 0.5, 0.9 }, despensa = { 0.6, 0.5, 1.8 },
  tina = { 0.65, 0.65, 1.2 }, barril_grande = { 0.7, 0.7, 1.6 }, bancada = { 0.8, 0.35, 1.0 },
}
local CAIXAS_NOME = {  -- família: nome sem o número no fim
  mesa = { 0.88, 0.88, 0.8 }, vela = { 0.1, 0.1, 1.2, 0.9 }, barril = { 0.43, 0.43, 1.0 },
  caneca = { 0.1, 0.1, 1.3, 1.1 }, garrafa = { 0.08, 0.08, 1.8, 1.4 },
  lampiao = { 0.15, 0.15, 2.4, 1.9 }, janela = { 0.1, 0.6, 2.4, 1.2 }, flamula = { 0.25, 0.05, 3.0, 2.0 },
  moita = { 0.35, 0.35, 0.7 }, abobora = { 0.25, 0.25, 0.35 }, barril_c = { 0.36, 0.36, 1.0 },
  malte = { 0.3, 0.3, 0.5 }, pilar = { 0.25, 0.25, 1.0 }, arvore = { 0.7, 0.7, 3.0 }, vaca = { 0.7, 0.35, 1.1 },
}
local CAIXAS_EXTRA = {
  barril = { 0.43, 0.43, 1.0 }, caixote = { 0.42, 0.42, 0.76 }, planta = { 0.25, 0.25, 1.1 }, vela = { 0.2, 0.2, 1.3 },
  tapete = { 1.3, 0.85, 0.05 }, estante = { 0.75, 0.25, 2.0 }, banco = { 0.25, 0.25, 0.5 }, quadro = { 0.5, 0.1, 2.0, 1.2 },
}

local function caixa_de(o)
  if o.extra then return CAIXAS_EXTRA[o.extra] or { 0.4, 0.4, 1 } end
  return CAIXAS[o.id] or CAIXAS_NOME[o.id:gsub("%d+$", "")] or { 0.4, 0.4, 1 }
end

local function msg(t) E.mensagem, E.tempo_msg = t, 3 end

-- Contorno na tela --------------------------------------------------------------------

-- contorno convexo de uma lista de pontos da tela
local function envoltoria(p)
  table.sort(p, function(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end)
  local function giro(o, a, b) return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1]) end
  local function metade(de, ate, passo)
    local h = {}
    for i = de, ate, passo do
      while #h >= 2 and giro(h[#h - 1], h[#h], p[i]) <= 0 do h[#h] = nil end
      h[#h + 1] = p[i]
    end
    h[#h] = nil
    return h
  end
  local h = metade(1, #p, 1)
  for _, v in ipairs(metade(#p, 1, -1)) do h[#h + 1] = v end
  return h
end

-- o que o objeto ocupa na tela: a caixa dele, ou o chão inteiro, se for uma sala
local function contorno(o)
  local p = {}
  local function ponto(bx, bz, y)
    local wx, wz = L.t(o.id, bx, bz)
    local sx, sy = motor.projetar(wx, y, wz)
    if sx then p[#p + 1] = { sx, sy } end
  end
  if SALAS[o.id] then
    local xa, xb, za, zb = L.sala(o.id)
    ponto(xa, za, 0); ponto(xb, za, 0); ponto(xb, zb, 0); ponto(xa, zb, 0)
  else
    local c = caixa_de(o)
    local y = L.altura(o.id)
    for _, sx in ipairs({ -1, 1 }) do
      for _, sz in ipairs({ -1, 1 }) do
        ponto(o.x + sx * c[1], o.z + sz * c[2], y + (c[4] or 0))
        ponto(o.x + sx * c[1], o.z + sz * c[2], y + c[3])
      end
    end
  end
  if #p < 3 then return nil end
  return envoltoria(p)
end

E.contorno = contorno

-- sala ainda fechada não existe na cena, nem o que está dentro dela
local function fechado(o)
  if not L.no_andar_ativo(o.id) then return true end
  local sala = SALAS[o.id] and o.id
  local p = o
  while not sala and p and p.pai and p.pai:sub(1, 1) ~= "@" do
    if SALAS[p.pai] then sala = p.pai end
    p = L.POR_ID[p.pai]
  end
  return sala and not L.aberta(sala)
end

local function dist_segmento(x, y, a, b)
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local n = dx * dx + dy * dy
  local t = n > 0 and util.limitar(((x - a[1]) * dx + (y - a[2]) * dy) / n, 0, 1) or 0
  return util.distancia(x, y, a[1] + t * dx, a[2] + t * dy)
end

-- distância do ponto até o contorno (0 = dentro) e a área que ele ocupa na tela
local function medir(h, x, y)
  local dentro, menor, area = true, math.huge, 0
  for i, a in ipairs(h) do
    local b = h[i % #h + 1]
    local lado = (b[1] - a[1]) * (y - a[2]) - (b[2] - a[2]) * (x - a[1])
    if lado < 0 then dentro = false end
    menor = math.min(menor, dist_segmento(x, y, a, b))
    area = area + a[1] * b[2] - b[1] * a[2]
  end
  return dentro and 0 or menor, math.abs(area) / 2
end

-- Seleção -----------------------------------------------------------------------------

-- Tudo o que está sob o ponto, de QUALQUER tipo, do melhor para o pior: mais perto
-- vem antes e o menor desempata (vela antes da mesa). As salas só depois de tudo o mais.
function E.candidatos(x, y)
  local itens, salas = {}, {}
  for _, o in ipairs(L.OBJETOS) do
    if not L.oculto(o.id) and not fechado(o) then
      local h = contorno(o)
      if h then
        local d, area = medir(h, x, y)
        if SALAS[o.id] then
          if d == 0 then salas[#salas + 1] = { id = o.id, nota = area } end
        elseif d <= folga() then
          itens[#itens + 1] = { id = o.id, nota = 1.5 * d + 0.12 * math.sqrt(area) }
        end
      end
    end
  end
  local function por_nota(a, b)
    if a.nota ~= b.nota then return a.nota < b.nota end
    return a.id < b.id
  end
  table.sort(itens, por_nota)
  table.sort(salas, por_nota)
  local r = {}
  for _, c in ipairs(itens) do r[#r + 1] = c.id end
  for _, c in ipairs(salas) do r[#r + 1] = c.id end
  return r
end

function E.pegar(x, y) return E.candidatos(x, y)[1] end

-- a sala em que o objeto está, se ele é carregado por uma
local function sala_de(id)
  local o = L.POR_ID[id]
  while o and o.pai and o.pai:sub(1, 1) ~= "@" do
    if SALAS[o.pai] then return o.pai end
    o = L.POR_ID[o.pai]
  end
end

-- Alças das paredes -------------------------------------------------------------------

-- Sem nada selecionado, todas à vista; com uma sala selecionada, só as dela. Com um
-- item selecionado, nenhuma: a alça não rouba o toque de móveis junto à parede.
function E.alcas()
  if not L.paredes then return {} end
  if E.sel and not SALAS[E.sel] then return {} end
  local prefixo = E.sel and (E.sel .. "_")
  local r = {}
  local raio = raio_alca()
  for _, p in ipairs(L.paredes()) do
    if not prefixo or p.id:sub(1, #prefixo) == prefixo then
      local sx, sy = motor.projetar(p.x, 0.1, p.z)
      if sx then
        -- passou da borda, encosta na borda: nunca fica debaixo dos botões
        r[#r + 1] = { p = p, ox = sx, oy = sy,
          x = util.limitar(sx, raio + 4, 956 - raio),
          y = util.limitar(sy, topo_tela() + raio + 4, fundo_tela() - raio - 4) }
      end
    end
  end
  return r
end

local function alca_em(x, y)
  local melhor, md = nil, raio_alca()
  for _, a in ipairs(E.alcas()) do
    local d = util.distancia(x, y, a.x, a.y)
    if d <= md then melhor, md = a, d end
  end
  return melhor
end

-- Desfazer ----------------------------------------------------------------------------

local function guardar()
  local dados = {}
  for id, d in pairs(L.dados) do dados[id] = { x = d.x, z = d.z, y = d.y, g = d.g, oculto = d.oculto, orig = d.orig } end
  local tamanho = {}
  for k, v in pairs(L.tamanho) do tamanho[k] = v end
  E.desfazer[#E.desfazer + 1] = { dados = dados, _tamanho = tamanho, _extras = L.lista_extras(), blocos = L.estado_blocos() }
  if #E.desfazer > MAX_DESFAZER then table.remove(E.desfazer, 1) end
end

local function mudou()
  E.mudou = true
  L.salvar()
end

function E.voltar()
  local u = table.remove(E.desfazer)
  if not u then return end
  L.limpar_extras()
  for _, x in ipairs(u._extras) do L.adicionar(x.tipo, x.x, x.z, x.id) end
  L.dados = u.dados
  L.tamanho = u._tamanho
  L.definir_blocos(u.blocos)
  if E.sel and (not L.POR_ID[E.sel] or L.oculto(E.sel)) then E.sel = nil end
  mudou()
  J.aplicar_visual()
end

local function acao(fn)
  if not E.sel then return end
  guardar()
  fn(L.de(E.sel))
  L.limitar(E.sel)
  L.limitar_carregados(E.sel)
  mudou()
  J.aplicar_visual()
end

-- Abrir e fechar ----------------------------------------------------------------------

function E.abrir()
  E.ativo = true
  E.sel, E.arrasto, E.alca, E.pan, E.confirmar, E.painel = nil, nil, nil, nil, false, nil
  E.desfazer, E.grade, E.mudou = {}, true, false
  E.passo_giro, E.pagina_exc, E.dica = 45, 0, true
  E.ultimo_toque, E.mensagem, E.tempo_msg, E.camera = nil, nil, nil, nil
  J.editando, J.previa = true, true
end

function E.fechar()
  E.ativo = false
  E.arrasto, E.alca, E.pan, E.camera = nil, nil, nil, nil
  J.editando, J.previa = false, false
  L.salvar()
  J.aplicar_layout()
  M.iniciar()
  -- no Modo Layout, sair do editor volta para a tela inicial
  if E.ao_fechar then
    local fn = E.ao_fechar
    E.ao_fechar = nil
    fn()
    return
  end
  local sem = J.lugares_sem_rota()
  if sem > 0 then J.avisar(sem .. " lugar(es) sem caminho livre: a pessoa atravessa os móveis para chegar.", 5) end
end

-- Mover, excluir, adicionar -----------------------------------------------------------

function E.mover_para(id, x, z)
  if id == "porta" then
    -- a porta anda pelas paredes livres: solta longe, vai para a parede mais perto
    local ok, motivo = L.mover_porta(L.porta_mais_perto(x, z))
    if not ok then msg(motivo) end
    J.aplicar_visual()
    return
  end
  if SALAS[id] then
    -- x e z são o centro do objeto: mover a sala é levar o canto dela pelo mesmo tanto
    local o, dx, dz = L.POR_ID[id], L.desloc(id)
    local px, pz = L.pos_sala(id)
    local ok, motivo = L.mover_sala(id, px + x - (o.x + dx), pz + z - (o.z + dz))
    if not ok then msg(motivo) end
    J.aplicar_visual()
    return
  end
  if E.grade then
    x = math.floor(x * 4 + 0.5) / 4
    z = math.floor(z * 4 + 0.5) / 4
  end
  L.colocar(id, x, z)
  L.limitar(id)
  L.limitar_carregados(id)
  J.aplicar_visual()
end

local function filhos(id)
  local r = {}
  for _, o in ipairs(L.OBJETOS) do
    if o.pai == id then r[#r + 1] = o.id end
  end
  return r
end

function E.excluir(id)
  if not L.removivel(id) then return false end
  guardar()
  -- quem está em cima sai junto: garrafa não fica flutuando sem a prateleira
  local function tirar(i)
    for _, f in ipairs(filhos(i)) do tirar(f) end
    if L.removivel(i) then L.excluir(i) end
  end
  tirar(id)
  if E.sel == id then E.sel = nil end
  mudou()
  J.aplicar_visual()
  msg("Excluído. Desfazer traz de volta.")
  return true
end

function E.devolver(id)
  guardar()
  local function por(i)
    L.devolver(i)
    for _, f in ipairs(filhos(i)) do por(f) end
  end
  por(id)
  E.sel = id
  mudou()
  J.aplicar_visual()
end

function E.excluidos()
  local r = {}
  for _, o in ipairs(L.OBJETOS) do
    local pai = o.pai and o.pai:sub(1, 1) ~= "@" and o.pai
    if L.oculto(o.id) and not (pai and L.oculto(pai)) then r[#r + 1] = o end
  end
  return r
end

-- lugar livre mais próximo do centro da vista, para o item novo não nascer dentro de outro
local function lugar_livre(x, z)
  local function livre(px, pz)
    for _, o in ipairs(L.OBJETOS) do
      if not SALAS[o.id] and not L.oculto(o.id) then
        local dx, dz = L.desloc(o.id)
        if util.distancia(px, pz, o.x + dx, o.z + dz) < 0.8 then return false end
      end
    end
    return true
  end
  if livre(x, z) then return x, z end
  for anel = 1, 6 do
    for i = 0, 7 do
      local a = i * math.pi / 4
      local px, pz = x + math.cos(a) * anel * 0.75, z + math.sin(a) * anel * 0.75
      if livre(px, pz) then return px, pz end
    end
  end
  return x, z
end

function E.adicionar(tipo)
  local n = 0
  for _, o in ipairs(L.OBJETOS) do if o.extra then n = n + 1 end end
  if n >= MAX_EXTRAS then
    msg("Limite de " .. MAX_EXTRAS .. " itens novos. Exclua algum para pôr outro.")
    return nil
  end
  guardar()
  local cx, cz = motor.chao(480, 270)
  local x, z = lugar_livre(cx or 0, cz or 0)
  local o = L.adicionar(tipo, x, z)
  if not o then
    table.remove(E.desfazer)
    return nil
  end
  E.mover_para(o.id, x, z)
  E.sel, E.painel, E.dica = o.id, nil, false
  mudou()
  msg("Arraste para o lugar certo.")
  return o.id
end

-- Toque na cena -----------------------------------------------------------------------

-- a câmera recua conforme a taverna cresce: congelada no arrasto, a parede não foge do dedo
local function congelar_camera()
  local q = M.quadro
  if q then E.camera = { x = q.x, z = q.z, escala = q.escala } end
end

local function comecar_arrasto(id, x, y, cands, era_sel, sel_antes)
  local o = L.POR_ID[id]
  local gx, gz = motor.chao(x, y)
  local ax, az = L.desloc(id)
  E.arrasto = { id = id, ox = (gx or 0) - (o.x + ax), oz = (gz or 0) - (o.z + az), moveu = false, sx = x, sy = y,
    cands = cands, era_sel = era_sel, sel_antes = sel_antes }
  if SALAS[id] then
    local px, pz = L.pos_sala(id)
    E.arrasto.sala, E.arrasto.ox, E.arrasto.oz = true, (gx or 0) - px, (gz or 0) - pz
  end
  congelar_camera()
end

function E.tocar(x, y)
  E.painel, E.confirmar, E.dica = nil, false, false
  local cands = E.candidatos(x, y)
  -- a taverna inteira só responde depois de escolhida no painel Mais
  if E.sel == "taverna" then
    local h = contorno(L.POR_ID.taverna)
    if h and medir(h, x, y) == 0 then cands[#cands + 1] = "taverna" end
  end
  local a = alca_em(x, y)
  if a then
    local gx, gz = motor.chao(x, y)
    E.alca = { p = a.p, gx = gx or 0, gz = gz or 0, sx = x, sy = y, inicio = L.tamanho[a.p.chave] or 0,
      moveu = false, cands = cands }
    congelar_camera()
    return
  end
  local atual
  for _, id in ipairs(cands) do if id == E.sel then atual = id end end
  local id = atual or cands[1]
  if id then
    local era_sel, sel_antes = E.sel == id, E.sel
    E.sel = id
    comecar_arrasto(id, x, y, cands, era_sel, sel_antes)
  else
    E.pan = { x = x, y = y, sx = x, sy = y, moveu = false }   -- arrastar o chão vazio move a câmera (com zoom)
  end
end

-- toque curto: o melhor item do ponto; de novo no mesmo ponto, o que estiver empilhado embaixo
local function escolher(a, cx, cy)
  local u = E.ultimo_toque
  local mesmo = u and util.distancia(u.x, u.y, cx, cy) <= 16
  E.ultimo_toque = { x = cx, y = cy }
  if mesmo and a.era_sel and #a.cands > 1 then
    for i, id in ipairs(a.cands) do
      if id == E.sel then
        E.sel = a.cands[i % #a.cands + 1]
        return
      end
    end
  end
  E.sel = a.cands[1]
end

function E.soltar(cancelado)
  local p = E.pan
  E.pan, E.camera = nil, nil
  if p and not p.moveu and not cancelado then
    E.sel, E.ultimo_toque = nil, nil
  end
  local h = E.alca
  if h then
    E.alca = nil
    if h.moveu then
      if (L.tamanho[h.p.chave] or 0) == h.inicio and h.guardou then table.remove(E.desfazer)
      elseif h.guardou then mudou() end
    elseif not cancelado and h.cands[1] then
      -- tocou numa alça sem puxar, mas tinha um móvel ali: o toque era para ele
      E.sel = h.cands[1]
      E.ultimo_toque = { x = h.sx, y = h.sy }
    end
  end
  local a = E.arrasto
  if a then
    E.arrasto = nil
    if a.sala and a.moveu then
      -- sala só muda ao soltar: até lá anda o fantasma, verde ou vermelho
      local f = a.fantasma
      local ok, motivo = false, nil
      if f and not cancelado then ok, motivo = L.mover_sala(a.id, f.x, f.z) end
      if ok then
        mudou()
        J.aplicar_visual()
      else
        table.remove(E.desfazer)
        if motivo then msg(motivo) end
      end
    elseif a.moveu then mudou()
    elseif cancelado then E.sel = a.sel_antes   -- virou pinça: o dedo não queria escolher nada
    else escolher(a, a.sx, a.sy) end
  end
end

local function puxar_alca(h, mx, my)
  if math.abs(mx - h.sx) + math.abs(my - h.sy) > saiu_do_toque() then h.moveu = true end
  if not h.moveu then return end
  local gx, gz = motor.chao(mx, my)
  if not gx then return end
  local andou = (h.p.eixo == "x" and gx - h.gx or gz - h.gz) * h.p.sinal
  local passos = andou >= 0 and math.floor(andou + 0.5) or -math.floor(-andou + 0.5)
  local alvo_m = h.inicio + passos
  local chave = h.p.chave
  local agora = L.tamanho[chave] or 0
  if alvo_m ~= agora then
    if not h.guardou then guardar(); h.guardou = true end
    L.mudar_tamanho(chave, alvo_m - agora)
    J.aplicar_visual()
  end
  h.limite = (L.tamanho[chave] or 0) ~= alvo_m
end

function E.atualizar(dt)
  if E.tempo_msg then
    E.tempo_msg = E.tempo_msg - dt
    if E.tempo_msg <= 0 then E.mensagem, E.tempo_msg = nil, nil end
  end
  if E.camera and M.quadro then
    M.quadro.x, M.quadro.z, M.quadro.escala = E.camera.x, E.camera.z, E.camera.escala
    M.aplicar_camera()
  end
  local baixo = motor.mouse_baixo()
  local mx, my = motor.mouse()
  if E.alca then
    if baixo then puxar_alca(E.alca, mx, my) else E.soltar() end
  elseif E.arrasto then
    if baixo then
      local gx, gz = motor.chao(mx, my)
      local a = E.arrasto
      -- só um clique, sem arrastar, seleciona: não pode encaixar o objeto na grade
      if math.abs(mx - a.sx) + math.abs(my - a.sy) > saiu_do_toque() then a.saiu = true end
      if gx and a.saiu then
        if not a.moveu then guardar() end
        if a.sala then
          local ok, motivo, sx, sz = L.encaixe_valido(a.id, gx - a.ox, gz - a.oz)
          a.fantasma = { x = sx or gx - a.ox, z = sz or gz - a.oz, ok = ok, motivo = motivo }
        else
          E.mover_para(a.id, gx - a.ox, gz - a.oz)
        end
        a.moveu = true
      end
    else
      E.soltar()   -- soltou com o mouse fora da janela
    end
  elseif E.pan then
    if baixo then
      if math.abs(mx - E.pan.sx) + math.abs(my - E.pan.sy) > saiu_do_toque() then E.pan.moveu = true end
      if E.pan.moveu then M.arrastar(mx - E.pan.x, my - E.pan.y) end
      E.pan.x, E.pan.y = mx, my
    else
      E.soltar()
    end
  end
  local r = motor.roda()
  if r ~= 0 and not E.arrasto and not E.alca then
    if E.painel == "excluidos" and mx < 340 then E.pagina_exc = E.pagina_exc - (r > 0 and 1 or -1)
    else M.rolar(r) end
  end
end

-- Desenho na cena ---------------------------------------------------------------------

local function etiqueta(texto, sx, sy, destaque)
  local w = motor.largura_texto(texto, 14, true) + 20
  local x = util.limitar(sx - w / 2, 8, 952 - w)
  local y = util.limitar(sy - 36, 8, 504)
  motor.retangulo(x, y, w, 28, destaque and cor.ouro or "#21150ef5", 8)
  motor.texto(texto, x + w / 2, y + 5, 14, destaque and cor.texto_ouro or "#ffffff", "centro", true)
end

local function destacar(id, forte)
  local o = L.POR_ID[id]
  local h = o and contorno(o)
  if not h then return end
  local topo, cx, n = math.huge, 0, 0
  for i, a in ipairs(h) do
    local b = h[i % #h + 1]
    if forte then motor.linha(a[1], a[2], b[1], b[2], 5, "#000000a0") end
    motor.linha(a[1], a[2], b[1], b[2], forte and 3 or 2, forte and cor.ouro or "#ffffff")
    topo = math.min(topo, a[2])
    cx, n = cx + a[1], n + 1
  end
  etiqueta(o.nome, cx / n, topo, forte)
end

function E.raio_alca() return raio_alca() end

local function desenhar_alca(a, ativa)
  local r = raio_alca() * 0.68
  motor.circulo(a.x, a.y, r + 2, "#000000b0")
  motor.circulo(a.x, a.y, r, ativa and cor.ouro or "#3d291b")
  motor.anel(a.x, a.y, r - 2, r, cor.ouro)
  -- setas no rumo da parede, como aparece na tela
  local ex, ez = 0, 0
  if a.p.eixo == "x" then ex = 1 else ez = 1 end
  local px, py = motor.projetar(a.p.x + ex, 0.1, a.p.z + ez)
  local dx, dy = 1, 0
  if px then
    local n = math.max(util.distancia(px, py, a.ox, a.oy), 0.001)
    dx, dy = (px - a.ox) / n, (py - a.oy) / n
  end
  local c = ativa and cor.texto_ouro or "#ffffff"
  local s, t = r * 0.6, r * 0.32
  for _, l in ipairs({ 1, -1 }) do
    local bx, by = a.x + dx * s * l, a.y + dy * s * l
    motor.linha(a.x, a.y, bx, by, 2, c)
    motor.linha(bx, by, bx - dx * t * l - dy * t, by - dy * t * l + dx * t, 2, c)
    motor.linha(bx, by, bx - dx * t * l + dy * t, by - dy * t * l - dx * t, 2, c)
  end
end

E.desenhar_alca = desenhar_alca

local function medida(p)
  local v = L.tamanho[p.chave] or 0
  return string.format("%s: %+d m", p.nome, v)
end

-- fantasma da sala arrastada: mostra onde ela cairia e, em vermelho, por que não dá
local function desenhar_fantasma(a)
  local f = a.fantasma
  if not f then return end
  local x0, x1, z0, z1 = L.sala_mundo(a.id)
  local w, d = x1 - x0, z1 - z0
  local c = f.ok and "#5abf7c" or "#e0533f"
  local p = {}
  for _, q in ipairs({ { f.x, f.z }, { f.x + w, f.z }, { f.x + w, f.z + d }, { f.x, f.z + d } }) do
    local sx, sy = motor.projetar(q[1], 0.05, q[2])
    if not sx then return end
    p[#p + 1] = { sx, sy }
  end
  motor.triangulo(p[1][1], p[1][2], p[2][1], p[2][2], p[3][1], p[3][2], c .. "55")
  motor.triangulo(p[1][1], p[1][2], p[3][1], p[3][2], p[4][1], p[4][2], c .. "55")
  for i, q in ipairs(p) do
    local n = p[i % 4 + 1]
    motor.linha(q[1], q[2], n[1], n[2], 3, c)
  end
  if not f.ok and f.motivo then etiqueta(f.motivo, (p[1][1] + p[3][1]) / 2, math.min(p[1][2], p[2][2]), false) end
end

local function desenhar_cena_editor()
  local alcas = E.alcas()
  local mx, my = motor.mouse()
  local sob_alca
  if motor.plataforma == "desktop" and not E.alca and not E.arrasto and not U.achar(mx, my) then
    sob_alca = alca_em(mx, my)
  end
  for _, a in ipairs(alcas) do
    local ativa = E.alca and E.alca.p.chave == a.p.chave and E.alca.p.sinal == a.p.sinal
    if not E.alca or ativa then desenhar_alca(a, ativa or (sob_alca and sob_alca.p == a.p)) end
    if ativa then
      local txt = medida(a.p) .. (E.alca.limite and " (limite)" or "")
      etiqueta(txt, a.x, a.y - raio_alca(), not E.alca.limite)
    end
  end
  -- no PC, o que está sob o mouse aparece antes do clique
  if motor.plataforma == "desktop" and not E.arrasto and not E.alca and not E.pan and not sob_alca and my > topo_tela() then
    local sob = E.pegar(mx, my)
    if sob and sob ~= E.sel and not U.achar(mx, my) then destacar(sob, false) end
  end
  if E.sel and L.POR_ID[E.sel] then destacar(E.sel, true) end
  if E.arrasto and E.arrasto.sala then desenhar_fantasma(E.arrasto) end
end

-- Painéis -----------------------------------------------------------------------------

local ESC = { cor = "#4a3627", cor_texto = cor.texto, tam = 14 }
local function estilo(ativo)
  return { ativo = ativo, cor = ativo and "#4a3627" or "#2a2019", cor_texto = ativo and cor.texto or cor.texto_fraco, tam = 14 }
end
local function alternar(nome)
  E.painel = E.painel ~= nome and nome or nil
  E.confirmar = false
end

local function painel_mais()
  local a = alvo()
  local x, y, w = 8, topo_tela() + 6, 280
  local linhas = 5 + (E.sel and 1 or 0)
  local passo = a + 6
  U.painel(x, y, w, linhas * passo + 12, "#21150ef5")
  U.zona("editor_fundo_mais", { x = x, y = y, w = w, h = linhas * passo + 12 })
  local bx, bw, by = x + 8, w - 16, y + 8
  U.botao("editor_grade", bx, by, bw, a, E.grade and "Encaixe na grade: ligado" or "Encaixe na grade: desligado", ESC, function() E.grade = not E.grade end)
  by = by + passo
  U.botao("editor_passo_giro", bx, by, bw, a, "Girar de " .. E.passo_giro .. " em " .. E.passo_giro .. " graus", ESC, function()
    E.passo_giro = E.passo_giro == 45 and 15 or 45
  end)
  by = by + passo
  U.botao("editor_copiar", bx, by, bw, a, "Copiar posições", ESC, function()
    motor.copiar(L.texto())
    msg("Copiado! Cole na conversa para virar oficial.")
  end)
  by = by + passo
  U.botao("editor_taverna", bx, by, bw, a, "Mover a taverna inteira", ESC, function()
    L.mudar_andar(0)
    E.sel, E.painel = "taverna", nil
    msg("Arraste a taverna para o novo lugar.")
  end)
  by = by + passo
  if E.sel then
    U.botao("editor_restaurar", bx, by, bw, a, "Posição original deste item", ESC, function()
      guardar(); L.restaurar(E.sel); mudou(); J.aplicar_visual()
    end)
    by = by + passo
  end
  if E.confirmar then
    motor.texto("Apagar tudo?", bx, by + a / 2 - 9, 14, "#ffb0a2", "esquerda", true)
    local nx = bx + 104
    local bm = (bw - 104 - 6) / 2
    U.botao("editor_tudo_nao", nx, by, bm, a, "Não", { tam = 14 }, function() E.confirmar = false end)
    U.botao("editor_tudo_sim", nx + bm + 6, by, bm, a, "Sim", { cor = cor.vermelho, cor_texto = "#ffffff", tam = 14 }, function()
      guardar(); L.restaurar(); E.sel = nil; mudou(); J.aplicar_visual(); E.confirmar = false; E.painel = nil
    end)
  else
    U.botao("editor_tudo", bx, by, bw, a, "Restaurar tudo", { cor = "#5a2a22", cor_texto = "#ffb0a2", tam = 14 }, function() E.confirmar = true end)
  end
end

local function painel_adicionar()
  local tipos = {}
  for t, d in pairs(L.TIPOS_EXTRAS) do tipos[#tipos + 1] = { tipo = t, nome = d.nome } end
  table.sort(tipos, function(a, b) return a.nome < b.nome end)
  local a = alvo()
  local fil = math.ceil(#tipos / 2)
  local w, h = 348, fil * (a + 6) + 42
  local x, y = 952 - w, fundo_tela() - h - 6
  U.painel(x, y, w, h, "#21150ef5")
  U.zona("editor_fundo_adicionar", { x = x, y = y, w = w, h = h })
  motor.texto("Adicionar (nasce no centro da vista)", x + 12, y + 10, 14, cor.ouro, "esquerda", true)
  local bw = (w - 22) / 2
  for i, t in ipairs(tipos) do
    local c = (i - 1) % 2
    local l = math.floor((i - 1) / 2)
    U.botao("editor_add_" .. t.tipo, x + 8 + c * (bw + 6), y + 36 + l * (a + 6), bw, a, t.nome, ESC, function() E.adicionar(t.tipo) end)
  end
end

local function painel_excluidos()
  local a = alvo()
  local lista = E.excluidos()
  local por_pagina = U.celular() and 4 or 6
  local paginas = math.max(1, math.ceil(#lista / por_pagina))
  E.pagina_exc = util.limitar(E.pagina_exc, 0, paginas - 1)
  local x, y, w = 8, topo_tela() + 6, 324
  local h = 42 + math.min(#lista, por_pagina) * (a + 6) + (paginas > 1 and a + 6 or 0)
  if paginas > 1 then h = 42 + por_pagina * (a + 6) + a + 6 end
  if #lista == 0 then h = 76 end
  U.painel(x, y, w, h, "#21150ef5")
  U.zona("editor_fundo_excluidos", { x = x, y = y, w = w, h = h })
  motor.texto("Excluídos: toque para devolver", x + 12, y + 10, 14, cor.ouro, "esquerda", true)
  if #lista == 0 then
    motor.texto("Nada foi excluído.", x + 12, y + 40, 14, cor.texto, "esquerda")
    return
  end
  local by = y + 36
  for i = E.pagina_exc * por_pagina + 1, math.min(#lista, (E.pagina_exc + 1) * por_pagina) do
    local o = lista[i]
    U.botao("editor_devolver_" .. o.id, x + 8, by, w - 16, a, o.nome, ESC, function() E.devolver(o.id) end)
    by = by + a + 6
  end
  if paginas > 1 then
    local by2 = y + 36 + por_pagina * (a + 6)
    local bw = 86
    U.botao("editor_exc_ant", x + 8, by2, bw, a, "Acima", estilo(E.pagina_exc > 0), function() E.pagina_exc = E.pagina_exc - 1 end)
    U.botao("editor_exc_prox", x + w - 8 - bw, by2, bw, a, "Abaixo", estilo(E.pagina_exc < paginas - 1), function() E.pagina_exc = E.pagina_exc + 1 end)
    motor.texto((E.pagina_exc + 1) .. " de " .. paginas, x + w / 2, by2 + a / 2 - 9, 14, cor.texto, "centro")
  end
end

-- barra fina do item selecionado: mover é arrastar, o resto são estes botões
local function barra_item(meio_x, meio_w)
  local o = L.POR_ID[E.sel]
  if not o then return end
  local a = alvo()
  local h = contorno(o)
  local baixo = 0
  if h then for _, p in ipairs(h) do baixo = math.max(baixo, p[2]) end end
  -- item lá embaixo: a barra sobe, para não cobrir o que se está editando
  local y = baixo > fundo_tela() - 8 and not SALAS[E.sel] and topo_tela() + 6 or fundo_tela()
  local bw, gap = 88, 6
  local sala = sala_de(E.sel)
  local n = sala and 5 or 4
  -- sala interna que pode trocar de andar: subir e descer passam a valer para ela inteira
  local andar_sel
  if SALAS[E.sel] and E.sel ~= "taverna" then andar_sel = select(3, L.pos_sala(E.sel)) end
  local nome_w = meio_w - n * (bw + gap) - 8
  U.painel(meio_x, y, meio_w, a, "#21150ef0")
  U.zona("editor_fundo_barra", { x = meio_x, y = y, w = meio_w, h = a })
  local tam = 14
  local linhas = motor.largura_texto(o.nome, tam, true) > nome_w - 16 and 2 or 1
  U.paragrafo(o.nome, meio_x + 10, y + a / 2 - (linhas == 2 and 19 or 9), nome_w - 16, tam, cor.ouro, true)
  local x = meio_x + nome_w
  if sala then
    U.botao("editor_sala", x, y + 2, bw, a - 4, "Sala inteira", ESC, function() E.sel = sala end)
    x = x + bw + gap
  end
  U.botao("editor_girar", x, y + 2, bw, a - 4, "Girar", ESC, function()
    acao(function(d) d.g = d.g + math.rad(E.passo_giro) end)
  end)
  x = x + bw + gap
  local d = L.dados[E.sel]
  local yo = d and d.y or 0
  if andar_sel then
    -- leva a sala para a primeira vaga do outro andar e vai junto com ela
    local function trocar(novo)
      local vx, vz = L.vaga_sala(E.sel, novo)
      local ok, motivo = L.encaixe_valido(E.sel, vx or 0, vz or 0, novo)
      if not ok then msg(motivo) return end
      guardar()
      L.mover_sala(E.sel, vx, vz, novo)
      L.mudar_andar(novo)
      mudou()
      J.aplicar_visual()
    end
    U.botao("editor_andar_cima", x, y + 2, bw, a - 4, "Andar +", estilo(L.andar_existe(andar_sel + 1)), function() if L.andar_existe(andar_sel + 1) then trocar(andar_sel + 1) end end)
    x = x + bw + gap
    U.botao("editor_andar_baixo", x, y + 2, bw, a - 4, "Andar -", estilo(L.andar_existe(andar_sel - 1)), function() if L.andar_existe(andar_sel - 1) then trocar(andar_sel - 1) end end)
  else
    U.botao("editor_subir", x, y + 2, bw, a - 4, "Subir", estilo(yo < 6), function() acao(function(k) k.y = k.y + 0.1 end) end)
    x = x + bw + gap
    U.botao("editor_descer", x, y + 2, bw, a - 4, "Descer", estilo(yo > -1), function() acao(function(k) k.y = k.y - 0.1 end) end)
  end
  x = x + bw + gap
  if L.removivel(E.sel) then
    U.botao("editor_excluir", x, y + 2, bw, a - 4, "Excluir", { cor = "#5a2a22", cor_texto = "#ffb0a2", tam = 14 }, function() E.excluir(E.sel) end)
  else
    local cabe = motor.largura_texto("Só pode mover", 14) <= bw
    U.paragrafo("Só pode mover", x, y + a / 2 - (cabe and 9 or 19), bw, 14, cor.texto, false, "centro")
  end
end

function E.desenhar()
  if E.sel and not L.POR_ID[E.sel] then E.sel = nil end
  desenhar_cena_editor()
  U.limpar()
  -- enquanto arrasta, tudo some e a taverna fica inteira à vista
  if E.arrasto and E.arrasto.saiu or E.alca and E.alca.moveu or E.pan and E.pan.moveu then return end

  local a = alvo()
  -- fileira de cima
  local x = 8
  local n_exc = #E.excluidos()
  U.botao("editor_excluidos", x, 8, 124, a, "Excluídos (" .. n_exc .. ")", ESC, function() alternar("excluidos") end)
  x = x + 124 + 8
  U.botao("editor_mais", x, 8, 80, a, "Mais", ESC, function() alternar("mais") end)
  U.botao("editor_sair", 952 - 136, 8, 136, a, "Sair e salvar", { tam = 15 }, function() E.fechar() end)
  local msgx, msgw = x + 88, 952 - 136 - 8 - (x + 88)
  local txt, fundo, frente
  if E.mensagem then
    txt, fundo, frente = E.mensagem, cor.ouro, cor.texto_ouro
  elseif E.dica then
    txt, fundo, frente = "Toque num item e arraste. Puxe as alças das paredes.", "#21150ee8", cor.texto
  end
  if txt then
    local w = math.min(msgw, motor.largura_texto(txt, 14, true) + 24)
    motor.retangulo(msgx + (msgw - w) / 2, 8 + a / 2 - 16, w, 32, fundo, 10)
    motor.texto(txt, msgx + msgw / 2, 8 + a / 2 - 10, 14, frente, "centro", true)
  end

  -- fileira de baixo: polegares nos cantos, item selecionado no meio
  local canto = 118
  U.botao("editor_desfazer", 8, fundo_tela(), canto, a, "Desfazer (" .. #E.desfazer .. ")", estilo(#E.desfazer > 0), function() E.voltar() end)
  U.botao("editor_adicionar", 952 - canto, fundo_tela(), canto, a, "Adicionar", ESC, function() alternar("adicionar") end)
  if E.sel then barra_item(8 + canto + 8, 960 - 2 * (8 + canto + 8)) end
  M.desenhar_botoes_andar()

  if E.painel == "mais" then painel_mais()
  elseif E.painel == "adicionar" then painel_adicionar()
  elseif E.painel == "excluidos" then painel_excluidos() end
end

return E
