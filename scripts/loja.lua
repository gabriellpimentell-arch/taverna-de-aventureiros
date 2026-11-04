-- =============================================================================
-- Loja: itens e cômodos com o jogo rodando.
--  LOJA: painel lateral com o jogo rodando (nada de J.editando, J.previa ou E.fechar).
--  Aba Itens: põe o que foi comprado na árvore e compra decoração.
--  Aba Cômodos: seleciona, arrasta a sala de graça e puxa as alças pagando por metro.
--  Só o fantasma anda durante o gesto; a obra acontece ao soltar ou ao confirmar.
--  As regras (preço, contadores) ficam em jogo.lua.
-- =============================================================================

local J = require("jogo")
local L = require("layout")
local C = require("config")
local M = require("mundo")
local U = require("ui")
local Ed = require("editor")
local util = require("util")
local cor = util.cores
local fmt = util.formatar

local Lj = {}

local P = { x = 708, y = 60, w = 244, h = 420 }
Lj.PAINEL = P
local VERDE, VERMELHO = "#5abf7c", "#e0533f"
local LADO = { oeste = "esquerda", fundo = "fundo", leste = "direita", frente = "frente" }
local TAM_ITEM = { mesa = 1.6, arvore = 1.4, vaca = 1.6, barril = 0.9, caixote = 0.9, planta = 0.7, vela = 0.5, tapete = 2.6, estante = 1.5, banco = 0.6, quadro = 1.0 }

function Lj.iniciar()
  Lj.aba, Lj.sel, Lj.colocando, Lj.arrasto, Lj.alca, Lj.camera = "itens", nil, nil, nil, nil, nil
  Lj.rol, Lj.rol_max = { itens = 0, comodos = 0 }, 0
end

local function alvo() return U.celular() and 56 or 48 end
local function saiu() return U.celular() and 12 or 4 end

local function nome_sala(id)
  if id == "taverna" then return "Taverna" end
  if id == "porta" then return "Porta da rua" end
  local internas, externas = L.salas()
  for _, lista in ipairs({ internas, externas }) do
    for _, b in ipairs(lista) do
      if b.id == id then return b.nome, b end
    end
  end
  return id
end

local function metros(v)
  local t = string.format("%.1f", v):gsub("%.0$", ""):gsub("%.", ",")
  return t
end

-- a câmera não pode andar durante o gesto, ou o fantasma foge do dedo
local function congelar()
  local q = M.quadro
  if q then Lj.camera = { x = q.x, z = q.z, escala = q.escala, painel = M.painel } end
end

function Lj.cancelar()
  Lj.colocando, Lj.arrasto, Lj.alca, Lj.camera = nil, nil, nil, nil
  M.quadro_extra = nil
end

-- Esc: desfaz o que está em andamento antes de sair da aba
function Lj.voltar()
  if Lj.colocando then Lj.colocando = nil; return true end
  if Lj.sel then Lj.sel = nil; return true end
  return false
end

function Lj.selecionar(id)
  Lj.sel = id
  if id == "taverna" or id == "porta" then L.mudar_andar(0)
  elseif id then L.mudar_andar(L.andar_de(id)) end
end

-- Colocar: fantasma nasce no lugar padrão; o dedo arrasta; só "Colocar aqui" muda algo --------------

local function validar(c)
  local ok, motivo, nx, nz
  if c.tipo == "sala" then
    ok, motivo, nx, nz = L.encaixe_valido(c.id, c.x, c.z, L.andar_ativo)
  else
    ok, motivo, nx, nz = J.lugar_item(c.tipo, c.x, c.z, c.extra)
    if ok and c.preco and J.estado.ouro < c.preco then
      ok, motivo = false, "Faltam " .. fmt(math.ceil(c.preco - J.estado.ouro)) .. " de ouro"
    end
  end
  c.ok, c.motivo, c.fx, c.fz = ok, motivo, nx or c.x, nz or c.z
end

local function tamanho_sala(c)
  local _, b = nome_sala(c.id)
  local x0, x1, z0, z1 = L.sala_mundo(c.id)
  if b then return x1 - x0, z1 - z0 end
  return 1, 1
end

-- começa a pôr uma sala: internas seguem no andar à vista; as de andar fixo vão para o delas
function Lj.colocar_sala(id, mover)
  local _, b = nome_sala(id)
  if not b then return end
  local andar = L.andar_ativo
  if b.so_andar then andar = b.so_andar
  elseif not b.interna then andar = 0 end
  L.mudar_andar(andar)
  local x, z = L.vaga_sala(id, andar)
  Lj.colocando = { tipo = "sala", id = id, nome = b.nome, x = x, z = z, mover = mover }
  validar(Lj.colocando)
  -- só a vaga inicial entra no enquadramento: a câmera não persegue o dedo
  local w, d = tamanho_sala(Lj.colocando)
  M.quadro_extra = { x0 = x, x1 = x + w, z0 = z, z1 = z + d, andar = andar }
end

-- mercadinho ou mural: o primeiro escolhe onde fica o caminho; o segundo entra direto, ao lado
function Lj.colocar_fora(i)
  if J.sala_posta("caminho") then
    local ok, motivo = J.por_fora(i.id)
    if ok then J.avisar(i.nome .. " foi para o caminho de pedras")
    elseif motivo then J.avisar(motivo) end
    return
  end
  Lj.colocar_sala("caminho")
  Lj.colocando.nome = i.nome .. " e o caminho de pedras"
  Lj.colocando.fora = i.id
end

function Lj.colocar_item(i)
  if i.tipo == "canteiro" then
    -- canteiro não tem lugar livre: entra na próxima vaga da fileira do jardim
    local ok, motivo = J.por_item("canteiro")
    if not ok then J.avisar(motivo) end
    return
  end
  L.mudar_andar(0)
  local x, z = J.lugar_padrao(i.tipo)
  Lj.colocando = { tipo = i.tipo, nome = i.nome, x = x or 0, z = z or 0 }
  validar(Lj.colocando)
end

function Lj.colocar_decoracao(tipo)
  L.mudar_andar(0)
  local x0, x1, z0, z1 = L.sala_mundo("taverna")
  local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
  -- procura um lugar livre em volta do meio da taverna para o fantasma já nascer verde
  local bx, bz = cx, cz
  for r = 0, 6, 0.5 do
    local achou = false
    for k = 0, 7 do
      local a = k * math.pi / 4
      local px, pz = cx + math.cos(a) * r, cz + math.sin(a) * r
      if J.lugar_item("decor", px, pz, tipo) then bx, bz, achou = px, pz, true; break end
    end
    if achou then break end
  end
  Lj.colocando = { tipo = "decor", extra = tipo, nome = L.TIPOS_EXTRAS[tipo].nome, x = bx, z = bz, preco = C.preco_decoracao[tipo] }
  validar(Lj.colocando)
end

function Lj.confirmar()
  local c = Lj.colocando
  if not c then return false end
  validar(c)
  if not c.ok then
    if c.motivo then J.avisar(c.motivo) end
    return false
  end
  local ok, motivo
  if c.mover then ok, motivo = L.mover_sala(c.id, c.fx, c.fz, L.andar_ativo)
    if ok then L.salvar() end
  elseif c.fora then ok, motivo = J.por_fora(c.fora, c.fx, c.fz)
  elseif c.tipo == "sala" then ok, motivo = J.por_sala(c.id, c.fx, c.fz, L.andar_ativo)
  elseif c.tipo == "decor" then ok, motivo = J.comprar_decoracao(c.extra, c.fx, c.fz)
  else ok, motivo = J.por_item(c.tipo, c.fx, c.fz) end
  if not ok then
    if motivo then J.avisar(motivo) end
    return false
  end
  Lj.colocando = nil
  motor.som("compra")
  return true
end

-- Alças ---------------------------------------------------------------------------------------

local function prefixo_alca()
  if Lj.sel == "taverna" then return "salao_" end
  if Lj.sel and Lj.sel ~= "porta" then return Lj.sel .. "_" end
end

function Lj.alcas()
  local pre = prefixo_alca()
  local r = {}
  if not pre or Lj.colocando then return r end
  local raio = Ed.raio_alca()
  for _, p in ipairs(L.paredes()) do
    if p.id:sub(1, #pre) == pre then
      local sx, sy = motor.projetar(p.x, 0.1, p.z)
      if sx then
        r[#r + 1] = { p = p, ox = sx, oy = sy,
          x = util.limitar(sx, raio + 4, P.x - raio - 6),
          y = util.limitar(sy, 60 + raio, 480 - raio) }
      end
    end
  end
  return r
end

local function alca_em(x, y)
  local melhor, md = nil, Ed.raio_alca() + 4
  for _, a in ipairs(Lj.alcas()) do
    local d = util.distancia(x, y, a.x, a.y)
    if d <= md then melhor, md = a, d end
  end
  return melhor
end

-- Toque na cena ----------------------------------------------------------------------------------

-- a sala do andar à vista sob o ponto, sem a taverna (ela só anda depois de escolhida na lista)
local function sala_em(gx, gz)
  local achou
  for _, q in ipairs(L.blocos_visiveis()) do
    if gx >= q.x0 and gx <= q.x1 and gz >= q.z0 and gz <= q.z1 then
      if q.id ~= "taverna" then return q.id end
      if L.andar_ativo == 0 then achou = "taverna" end
    end
  end
  return achou
end

local function comecar_arrasto_sala(id, x, y, gx, gz)
  local px, pz = L.pos_sala(id)
  Lj.arrasto = { tipo = "sala", id = id, ox = gx - px, oz = gz - pz, sx = x, sy = y, saiu = false }
  congelar()
end

-- Devolve true se o toque ficou com a Loja (senão, arrastar move a câmera)
function Lj.tocar(x, y)
  local gx, gz = motor.chao(x, y)
  local c = Lj.colocando
  if c then
    if not gx then return true end
    local w, d = TAM_ITEM[c.extra or c.tipo] or 1, TAM_ITEM[c.extra or c.tipo] or 1
    local ox, oz = 0, 0
    if c.tipo == "sala" then
      w, d = tamanho_sala(c)
      -- tocou no próprio fantasma: anda a partir dali; fora dele, o centro vem para o dedo
      if gx >= c.fx and gx <= c.fx + w and gz >= c.fz and gz <= c.fz + d then ox, oz = gx - c.fx, gz - c.fz
      else ox, oz = w / 2, d / 2 end
    elseif math.abs(gx - c.fx) <= w and math.abs(gz - c.fz) <= d then
      ox, oz = gx - c.fx, gz - c.fz
    end
    Lj.arrasto = { tipo = "colocar", ox = ox, oz = oz, sx = x, sy = y, saiu = true }
    c.x, c.z = gx - ox, gz - oz
    validar(c)
    congelar()
    return true
  end
  if Lj.aba == "itens" then return M.tocar(x, y) and true or false end

  local a = alca_em(x, y)
  if a then
    Lj.alca = { p = a.p, gx = gx or 0, gz = gz or 0, sx = x, sy = y, passos = 0, moveu = false }
    Lj.alca.orc = J.orcar_obra(a.p.chave, 0)
    congelar()
    return true
  end
  if M.tocar(x, y) then return true end
  if not gx then return false end
  -- porta: selecionada, qualquer arrasto a leva; senão, um toque perto dela a escolhe
  local px, py = motor.projetar(J.PORTA.x, 1, J.PORTA.z)
  local perto_porta = L.andar_ativo == 0 and px and util.distancia(x, y, px, py) <= (U.celular() and 44 or 30)
  if Lj.sel == "porta" or perto_porta then
    if perto_porta then Lj.sel = "porta" end
    Lj.arrasto = { tipo = "porta", sx = x, sy = y, saiu = false }
    congelar()
    return true
  end
  local id = sala_em(gx, gz)
  if not id then
    Lj.arrasto = { tipo = "vazio", sx = x, sy = y }
    return false
  end
  if id == "taverna" and Lj.sel ~= "taverna" then
    Lj.arrasto = { tipo = "escolher", id = id, sx = x, sy = y }
    return false
  end
  Lj.sel = id
  comecar_arrasto_sala(id, x, y, gx, gz)
  return true
end

local function puxar_alca(h, mx, my)
  if math.abs(mx - h.sx) + math.abs(my - h.sy) > saiu() then h.moveu = true end
  if not h.moveu then return end
  local gx, gz = motor.chao(mx, my)
  if not gx then return end
  local andou = (h.p.eixo == "x" and gx - h.gx or gz - h.gz) * h.p.sinal
  h.passos = andou >= 0 and math.floor(andou + 0.5) or -math.floor(-andou + 0.5)
  h.orc = J.orcar_obra(h.p.chave, h.passos)
end

function Lj.atualizar(_)
  if Lj.camera and M.quadro then
    M.quadro.x, M.quadro.z, M.quadro.escala = Lj.camera.x, Lj.camera.z, Lj.camera.escala
    M.painel = Lj.camera.painel
    M.aplicar_camera()
  end
  local baixo = motor.mouse_baixo()
  local mx, my = motor.mouse()
  if Lj.alca then
    if baixo then puxar_alca(Lj.alca, mx, my) else Lj.soltar() end
  end
  local a = Lj.arrasto
  if not a then return end
  if not baixo then Lj.soltar() return end
  if math.abs(mx - a.sx) + math.abs(my - a.sy) > saiu() then a.saiu = true end
  local gx, gz = motor.chao(mx, my)
  if not (gx and a.saiu) then return end
  if a.tipo == "colocar" and Lj.colocando then
    local c = Lj.colocando
    c.x, c.z = gx - a.ox, gz - a.oz
    validar(c)
  elseif a.tipo == "sala" then
    local ok, motivo, nx, nz = L.encaixe_valido(a.id, gx - a.ox, gz - a.oz, L.andar_ativo)
    a.f = { x = nx or gx - a.ox, z = nz or gz - a.oz, ok = ok, motivo = motivo }
  elseif a.tipo == "porta" then
    local lado, t = L.porta_mais_perto(gx, gz)
    t = math.floor(t * 2 + 0.5) / 2
    local ok, motivo = L.porta_livre(lado, t)
    a.f = { lado = lado, t = t, ok = ok, motivo = motivo }
  end
end

function Lj.soltar(cancelado)
  Lj.camera = nil
  local h = Lj.alca
  Lj.alca = nil
  if h and h.moveu and h.passos ~= 0 and not cancelado then
    local ok, r = J.obra(h.p.chave, h.passos)
    if ok then
      if r.custo > 0 then
        J.avisar(string.format("%+d m: pagou %s de ouro", r.metros, fmt(r.custo)))
        motor.som("compra")
      elseif r.devolve > 0 then
        J.avisar(string.format("%+d m: voltaram %s de ouro", r.metros, fmt(r.devolve)))
      else
        J.avisar(string.format("%+d m: sem devolução", r.metros))
      end
    elseif r.falta > 0 then
      J.avisar("Faltam " .. fmt(math.ceil(r.falta)) .. " de ouro")
      motor.som("erro")
    end
  end
  local a = Lj.arrasto
  Lj.arrasto = nil
  if not a or cancelado then return end
  if a.tipo == "sala" then
    if a.saiu and a.f then
      if a.f.ok then
        local ok, motivo = L.mover_sala(a.id, a.f.x, a.f.z, L.andar_ativo)
        if ok then L.salvar() elseif motivo then J.avisar(motivo) end
      elseif a.f.motivo then
        J.avisar(a.f.motivo)
      end
    end
  elseif a.tipo == "porta" then
    if a.saiu and a.f then
      local ok, motivo = L.mover_porta(a.f.lado, a.f.t)
      if ok then L.salvar() elseif motivo then J.avisar(motivo) end
    end
  elseif a.tipo == "escolher" then
    if not a.saiu then Lj.sel = a.id end
  elseif a.tipo == "vazio" then
    if not a.saiu then Lj.sel = nil end
  end
end

function Lj.rolar(v)
  local mx = motor.mouse()
  if mx >= P.x then Lj.rolar_lista(v * 40) else M.rolar(v) end
end

function Lj.rolar_lista(dy)
  Lj.rol[Lj.aba] = util.limitar(Lj.rol[Lj.aba] - dy, 0, Lj.rol_max)
end

-- Desenho na cena --------------------------------------------------------------------------------

local function etiqueta(texto, sx, sy, fundo, frente)
  local w = motor.largura_texto(texto, 14, true) + 20
  -- nunca sobre o painel de dívida, à esquerda, nem sobre o painel da Loja
  local x = util.limitar(sx - w / 2, 256, math.max(256, P.x - 8 - w))
  local y = util.limitar(sy - 44, 60, 448)
  motor.retangulo(x, y, w, 28, fundo or "#21150ef5", 8)
  motor.texto(texto, x + w / 2, y + 5, 14, frente or "#ffffff", "centro", true)
end

-- retângulo no chão; devolve o centro e o topo na tela para pôr a etiqueta
local function fantasma(x0, x1, z0, z1, c)
  local p = {}
  for _, q in ipairs({ { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } }) do
    local sx, sy = motor.projetar(q[1], 0.05, q[2])
    if not sx then return nil end
    p[#p + 1] = { sx, sy }
  end
  motor.triangulo(p[1][1], p[1][2], p[2][1], p[2][2], p[3][1], p[3][2], c .. "55")
  motor.triangulo(p[1][1], p[1][2], p[3][1], p[3][2], p[4][1], p[4][2], c .. "55")
  for i, q in ipairs(p) do
    local n = p[i % 4 + 1]
    motor.linha(q[1], q[2], n[1], n[2], 3, c)
  end
  return (p[1][1] + p[3][1]) / 2, math.min(p[1][2], p[2][2])
end

local function contorno_sala(id)
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local p = {}
  for _, q in ipairs({ { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } }) do
    local sx, sy = motor.projetar(q[1], 0.05, q[2])
    if not sx then return end
    p[#p + 1] = { sx, sy }
  end
  for i, q in ipairs(p) do
    local n = p[i % 4 + 1]
    motor.linha(q[1], q[2], n[1], n[2], 5, "#000000a0")
    motor.linha(q[1], q[2], n[1], n[2], 3, cor.ouro)
  end
end

local function texto_orcamento(h)
  local o = h.orc
  if h.passos == 0 and o.metros == 0 then return "Arraste para mudar o tamanho" end
  local txt
  if o.metros > 0 then txt = string.format("+%d m · %s de ouro", o.metros, fmt(o.custo))
  elseif o.metros < 0 then
    txt = string.format("%d m · ", o.metros) .. (o.devolve > 0 and ("+" .. fmt(o.devolve) .. " de ouro") or "sem devolução")
  else txt = "0 m" end
  if o.falta > 0 then txt = txt .. " · faltam " .. fmt(math.ceil(o.falta))
  elseif o.limite then txt = txt .. " · limite" end
  return txt
end

local function desenhar_alca_ativa(h)
  local id = Lj.sel
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local m = h.orc.metros
  if h.p.eixo == "x" then
    if h.p.sinal > 0 then x1 = x1 + m else x0 = x0 - m end
  else
    if h.p.sinal > 0 then z1 = z1 + m else z0 = z0 - m end
  end
  local falhou = h.orc.falta > 0
  fantasma(x0, x1, z0, z1, falhou and VERMELHO or VERDE)
  local wx, wz = h.p.x, h.p.z
  if h.p.eixo == "x" then wx = wx + m * h.p.sinal else wz = wz + m * h.p.sinal end
  local sx, sy = motor.projetar(wx, 0.1, wz)
  if sx then
    if falhou then etiqueta(texto_orcamento(h), sx, sy, VERMELHO, "#ffffff")
    else etiqueta(texto_orcamento(h), sx, sy, cor.ouro, cor.texto_ouro) end
  end
end

local function ret_porta(lado, t)
  local x0, x1, z0, z1 = L.sala_mundo("taverna")
  if lado == "oeste" then return x0 - 0.3, x0 + 0.3, z0 + t - 0.95, z0 + t + 0.95 end
  if lado == "leste" then return x1 - 0.3, x1 + 0.3, z0 + t - 0.95, z0 + t + 0.95 end
  if lado == "fundo" then return x0 + t - 0.95, x0 + t + 0.95, z0 - 0.3, z0 + 0.3 end
  return x0 + t - 0.95, x0 + t + 0.95, z1 - 0.3, z1 + 0.3
end

local function desenhar_cena()
  local c = Lj.colocando
  if c then
    local sx, sy
    if c.tipo == "sala" then
      local w, d = tamanho_sala(c)
      sx, sy = fantasma(c.fx, c.fx + w, c.fz, c.fz + d, c.ok and VERDE or VERMELHO)
    else
      local m = (TAM_ITEM[c.extra or c.tipo] or 1) / 2
      sx, sy = fantasma(c.fx - m, c.fx + m, c.fz - m, c.fz + m, c.ok and VERDE or VERMELHO)
    end
    if sx then
      if c.ok then etiqueta(c.nome .. (c.preco and (": " .. fmt(c.preco) .. " de ouro") or ": lugar livre"), sx, sy, VERDE, "#10261a")
      else etiqueta(c.motivo or "Não dá aqui", sx, sy, VERMELHO, "#ffffff") end
    end
    return
  end
  if Lj.aba ~= "comodos" then return end
  if Lj.sel and Lj.sel ~= "porta" and (Lj.sel == "taverna" and L.andar_ativo == 0 or Lj.sel ~= "taverna" and L.andar_de(Lj.sel) == L.andar_ativo) then
    contorno_sala(Lj.sel)
  end
  local a = Lj.arrasto
  if a and a.f and a.saiu then
    if a.tipo == "sala" then
      local x0, x1, z0, z1 = L.sala_mundo(a.id)
      local sx, sy = fantasma(a.f.x, a.f.x + x1 - x0, a.f.z, a.f.z + z1 - z0, a.f.ok and VERDE or VERMELHO)
      if sx then
        if a.f.ok then etiqueta("Mover: grátis", sx, sy, VERDE, "#10261a")
        else etiqueta(a.f.motivo or "Não dá aqui", sx, sy, VERMELHO, "#ffffff") end
      end
    elseif a.tipo == "porta" then
      local x0, x1, z0, z1 = ret_porta(a.f.lado, a.f.t)
      local sx, sy = fantasma(x0, x1, z0, z1, a.f.ok and VERDE or VERMELHO)
      if sx then
        if a.f.ok then etiqueta("Parede: " .. LADO[a.f.lado] .. " · grátis", sx, sy, VERDE, "#10261a")
        else etiqueta(a.f.motivo or "Não dá aqui", sx, sy, VERMELHO, "#ffffff") end
      end
    end
  end
  if Lj.sel == "porta" and not (a and a.f) and L.andar_ativo == 0 then
    local x0, x1, z0, z1 = ret_porta(L.pos_porta())
    fantasma(x0, x1, z0, z1, cor.ouro:sub(1, 7))
  end
  if Lj.alca then
    desenhar_alca_ativa(Lj.alca)
  elseif not (a and a.saiu and a.tipo == "sala") then
    for _, h in ipairs(Lj.alcas()) do Ed.desenhar_alca(h, false) end
  end
end

-- Painel -----------------------------------------------------------------------------------------

local TOPO_LISTA = P.y + 58

-- linha da lista: título, e abaixo um texto ou preço. Só recebe toque se estiver toda à vista.
local function linha(id, y, base, topo, fim, titulo, sub, cor_sub, o, fn)
  local h = alvo()
  local vis = y + h > topo and y < fim
  if not vis then return end
  local ativo = o.ativo ~= false
  local inteira = y >= topo and y + h <= fim
  local fundo = o.sel and "#5c3f29" or (ativo and "#3d291b" or "#2a2019")
  motor.retangulo(base, y, P.w - 24, h, fundo, 8)
  if o.sel then motor.contorno(base, y, P.w - 24, h, cor.ouro, 2, 8) end
  motor.texto(titulo, base + 10, y + 5, 14, ativo and cor.texto or cor.texto_fraco, "esquerda", true)
  if o.preco then
    U.preco(o.preco, base + 8, y + 25, 14, cor_sub)
  elseif sub then
    motor.texto(sub, base + 10, y + 26, 14, cor_sub or cor.texto_fraco, "esquerda")
  end
  if inteira then
    U.zona(id, { x = base, y = y, w = P.w - 24, h = h }, function()
      if ativo then
        if fn then fn() end
        motor.som("clique")
      else
        motor.som("erro")
      end
    end, true)
  end
end

local function secao(txt, y, base, topo, fim)
  if y + 18 > topo and y < fim then motor.texto(txt, base, y, 14, cor.ouro, "esquerda", true) end
end

local function lista_itens(base, topo, fim)
  local a = alvo() + 6
  local y = topo - Lj.rol.itens
  local e = J.estado
  local itens = J.para_colocar()
  if J.manual() then
    secao("Para colocar", y, base, topo, fim)
    y = y + 22
    if #itens == 0 then
      if y + 40 > topo and y < fim then
        y = y + U.paragrafo("Nada esperando lugar. O que comprar na Árvore aparece aqui.", base, y, P.w - 24, 14, cor.texto_fraco) + 8
      else
        y = y + 46
      end
    end
    for _, i in ipairs(itens) do
      local sub = "para colocar: " .. i.n
      local c = cor.verde
      if i.requer then sub, c = "antes: " .. i.requer, "#ffb0a2" end
      linha("loja_item_" .. (i.id or i.tipo), y, base, topo, fim, i.nome, sub, c, { ativo = not i.requer }, function()
        if i.tipo == "sala" then Lj.colocar_sala(i.id)
        elseif i.tipo == "fora" then Lj.colocar_fora(i)
        else Lj.colocar_item(i) end
      end)
      y = y + a
    end
    y = y + 6
  end
  secao("Decoração", y, base, topo, fim)
  y = y + 22
  local tipos = {}
  for t, d in pairs(L.TIPOS_EXTRAS) do tipos[#tipos + 1] = { tipo = t, nome = d.nome, preco = C.preco_decoracao[t] or 50 } end
  table.sort(tipos, function(x, z) if x.preco ~= z.preco then return x.preco < z.preco end return x.tipo < z.tipo end)
  for _, t in ipairs(tipos) do
    local pode = e.ouro >= t.preco
    linha("loja_decor_" .. t.tipo, y, base, topo, fim, t.nome, nil, pode and cor.ouro or "#ff9a8a", { preco = t.preco, ativo = pode }, function()
      Lj.colocar_decoracao(t.tipo)
    end)
    y = y + a
  end
  return y + Lj.rol.itens - topo
end

local function subtitulo_sala(id)
  if id == "porta" then return "Parede: " .. LADO[(L.pos_porta())] end
  local x0, x1, z0, z1 = L.sala_mundo(id)
  local andar = id == "taverna" and 0 or L.andar_de(id)
  local nomes = { [0] = "Térreo", [1] = "2º andar", [-1] = "Subsolo" }
  return (nomes[andar] or "") .. " · " .. metros(x1 - x0) .. " x " .. metros(z1 - z0) .. " m"
end

local function lista_comodos(base, topo, fim)
  local a = alvo() + 6
  local y = topo - Lj.rol.comodos
  local function fileira(id)
    local nm = nome_sala(id)
    linha("loja_sala_" .. id, y, base, topo, fim, nm, subtitulo_sala(id), cor.texto_fraco, { sel = Lj.sel == id }, function()
      Lj.selecionar(Lj.sel == id and nil or id)
    end)
    y = y + a
  end
  fileira("taverna")
  local internas, externas = L.salas()
  for _, lista in ipairs({ internas, externas }) do
    for _, b in ipairs(lista) do
      if L.aberta(b.id) then fileira(b.id) end
    end
  end
  fileira("porta")
  return y + Lj.rol.comodos - topo
end

local function detalhe_comodos(base, y0)
  local id = Lj.sel
  local w = P.w - 24
  motor.retangulo(base - 4, y0 - 4, w + 8, P.y + P.h - y0, "#21150e", 8)
  if id == "porta" then
    U.paragrafo("Arraste até outra parede livre: é de graça.", base, y0 + 2, w, 14, cor.texto)
    return
  end
  local _, b = nome_sala(id)
  if not b or b.k then
    local preco = J.preco_metro()
    motor.texto("Metro novo:", base, y0, 14, cor.texto_fraco)
    U.preco(preco, base + motor.largura_texto("Metro novo:", 14) + 4, y0, 14, cor.ouro)
  end
  U.paragrafo(b and not b.k and "Arraste para mover, é de graça. O mercadinho e o mural vão junto." or "Arraste para mover, é de graça. Puxe as alças para mudar o tamanho.", base, y0 + 20, w, 14, cor.texto)
  -- sala em outro andar: traz para o andar à vista com o fantasma
  if b and b.interna and not b.so_andar and L.andar_de(id) ~= L.andar_ativo then
    U.botao("loja_trazer", base, P.y + P.h - 8 - 44, w, 44, "Trazer para este andar", { tam = 14 }, function() Lj.colocar_sala(id, true) end)
  elseif b and b.interna and not b.so_andar and #L.andares() > 1 then
    U.paragrafo("Mude de andar à esquerda para levá-la.", base, y0 + 76, w, 14, cor.texto_fraco)
  end
end

local function painel_colocando(base)
  local c = Lj.colocando
  local w = P.w - 24
  local y = P.y + 12
  motor.texto("Colocando", base, y, 14, cor.ouro, "esquerda", true)
  y = y + 22
  y = y + U.paragrafo(c.nome, base, y, w, 18, cor.texto, true) + 8
  if c.preco then
    U.preco(c.preco, base, y, 16, J.estado.ouro >= c.preco and cor.ouro or "#ff9a8a")
    y = y + 28
  end
  -- ok e motivo escritos também aqui: o fantasma pode estar sob o dedo
  if c.ok then
    y = y + U.paragrafo("Lugar livre.", base, y, w, 14, cor.verde, true) + 6
  else
    y = y + U.paragrafo(c.motivo or "Não dá para colocar aqui.", base, y, w, 14, "#ff9a8a", true) + 6
  end
  local dica = "Toque ou arraste na cena para escolher o lugar."
  if c.tipo == "sala" and #L.andares() > 1 then dica = dica .. " Os botões da esquerda trocam o andar." end
  U.paragrafo(dica, base, y, w, 14, cor.texto_fraco)
  local a = alvo()
  local rot = c.preco and "Comprar aqui" or (c.mover and "Trazer aqui" or "Colocar aqui")
  U.botao("loja_confirmar", base, P.y + P.h - 2 * a - 18, w, a, rot, { ativo = c.ok == true, tam = 15 }, function() Lj.confirmar() end)
  U.botao("loja_cancelar", base, P.y + P.h - a - 10, w, a, "Cancelar", { cor = "#4a3627", cor_texto = cor.texto, tam = 15 }, function() Lj.colocando = nil end)
end

function Lj.desenhar()
  if not Lj.colocando then M.quadro_extra = nil end
  -- a sala pode ter fechado (outro save, Restaurar tudo): a seleção não fica apontando para o nada
  if Lj.sel and Lj.sel ~= "taverna" and Lj.sel ~= "porta" and not L.aberta(Lj.sel) then Lj.sel = nil end
  if Lj.colocando then validar(Lj.colocando) end
  desenhar_cena()
  U.painel(P.x, P.y, P.w, P.h, "#21150ef5")
  U.zona("loja_fundo", { x = P.x, y = P.y, w = P.w, h = P.h })
  local base = P.x + 12
  if Lj.colocando then
    painel_colocando(base)
    return
  end
  local n = J.total_para_colocar()
  local meia = (P.w - 30) / 2
  local function aba(id, x, txt)
    local sel = Lj.aba == id
    U.botao("loja_aba_" .. id, x, P.y + 10, meia, 40, txt, { cor = sel and cor.ouro or "#3d291b", cor_texto = sel and cor.texto_ouro or cor.texto, tam = 14 }, function()
      Lj.aba = id
      Lj.alca, Lj.arrasto = nil, nil
    end)
  end
  aba("itens", base - 2, n > 0 and ("Itens (" .. n .. ")") or "Itens")
  aba("comodos", base + meia + 4, "Cômodos")
  local topo, fim = TOPO_LISTA, P.y + P.h - 8
  local det = Lj.aba == "comodos" and Lj.sel ~= nil
  if det then fim = fim - (Lj.sel == "porta" and 56 or 120) end
  motor.recorte(P.x, topo, P.w, fim - topo)
  local altura
  if Lj.aba == "itens" then altura = lista_itens(base, topo, fim)
  else altura = lista_comodos(base, topo, fim) end
  motor.recorte()
  Lj.rol_max = math.max(0, altura - (fim - topo))
  Lj.rol[Lj.aba] = util.limitar(Lj.rol[Lj.aba], 0, Lj.rol_max)
  if Lj.rol_max > 0 then
    -- barra fina: a lista continua abaixo
    local h = fim - topo
    local bh = math.max(24, h * h / (h + Lj.rol_max))
    local by = topo + (h - bh) * (Lj.rol[Lj.aba] / Lj.rol_max)
    motor.retangulo(P.x + P.w - 9, by, 4, bh, "#c9a24a90", 2)
  end
  if det then detalhe_comodos(base, fim + 8) end
end

return Lj
