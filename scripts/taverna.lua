-- =============================================================================
--  Regras da taverna: ouro, heróis, mesas, melhorias e garçonete
-- =============================================================================

local config = require("config")
local util = require("util")

local T = {}

-- Posições fixas na tela (tela virtual deitada de 960 x 540) -------------------
-- O salão ocupa a parte esquerda (0 a 600); o painel fica à direita.
T.LARGURA_SALAO = 600
T.PORTA = { x = 300, y = 525 }
T.CASA_GARCONETE = { x = 545, y = 76 }
T.MOEDA_TOPO = { x = 640, y = 52 }
T.MAX_MESAS = 6

-- ordem em que as mesas novas aparecem
local POS_MESAS = {
  { x = 300, y = 235 }, { x = 100, y = 235 }, { x = 500, y = 235 },
  { x = 300, y = 405 }, { x = 100, y = 405 }, { x = 500, y = 405 },
}

T.CLASSES = {
  { nome = "guerreiro", corpo = "#b5483a", detalhe = "#a7b0ba" },
  { nome = "maga",      corpo = "#6d4bb3", detalhe = "#4a2f86" },
  { nome = "arqueiro",  corpo = "#4f8a3c", detalhe = "#3b6b2c" },
  { nome = "clerigo",   corpo = "#e6dcc3", detalhe = "#f2c14e" },
}
local PELES = { "#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a36" }

-- Estado ------------------------------------------------------------------------

local function estado_inicial()
  return {
    versao = 1,
    ouro = 0,
    total = 0,
    servidos = 0,
    rps = 0,                 -- média de ouro por segundo (para progresso offline)
    niveis = { mesa = 0, cardapio = 0, placa = 0, garconete = 0 },
    desbloqueios = {},
  }
end

function T.iniciar()
  T.estado = estado_inicial()
  T.herois = {}
  T.ocupacao = {}            -- assento -> herói sentado ou a caminho
  T.efeitos = {}
  T.garconete = nil
  T.aviso = nil
  T.offline = nil
  T.relogio_chegada = 2.0    -- o primeiro herói chega logo
  T.relogio_segundo = 0
  T.ganho_segundo = 0
  T.relogio_salvar = 0
  T.carregar()
  if T.estado.niveis.garconete > 0 then T.contratar_garconete() end
end

-- Mesas e assentos ----------------------------------------------------------------

function T.num_mesas() return 1 + T.estado.niveis.mesa end

function T.posicao_mesa(i) return POS_MESAS[i] end

-- cada mesa tem 2 assentos: esquerdo e direito
-- devolve x, y e o lado (-1 = esquerda da mesa, 1 = direita)
function T.assento(i)
  local m = POS_MESAS[math.ceil(i / 2)]
  local lado = (i % 2 == 1) and -1 or 1
  return m.x + lado * 62, m.y + 6, lado
end

local function assentos_livres()
  local livres = {}
  for i = 1, T.num_mesas() * 2 do
    if not T.ocupacao[i] then livres[#livres + 1] = i end
  end
  return livres
end

-- Ganhos e efeitos visuais ---------------------------------------------------------

function T.flutuar(x, y, texto, cor, tamanho)
  T.efeitos[#T.efeitos + 1] = {
    tipo = "texto", x = x, y = y, texto = texto, cor = cor, tamanho = tamanho or 24,
    vida = 0, duracao = 1.1,
  }
end

function T.ganhar(valor, x, y)
  T.estado.ouro = T.estado.ouro + valor
  T.estado.total = T.estado.total + valor
  T.ganho_segundo = T.ganho_segundo + valor
  if x then
    T.flutuar(x, y, "+" .. util.formatar(valor), util.cores.ouro, 26)
    for i = 1, 3 do
      T.efeitos[#T.efeitos + 1] = {
        tipo = "moeda", x0 = x + math.random(-14, 14), y0 = y + math.random(-10, 10),
        vida = -0.08 * i, duracao = 0.7,
      }
    end
  end
end

-- Heróis -----------------------------------------------------------------------------

local function novo_heroi(assento)
  local ax, ay, lado = T.assento(assento)
  local h = {
    lado = lado,
    x = T.PORTA.x, y = T.PORTA.y,
    alvo_x = ax, alvo_y = ay,
    assento = assento,
    estado = "chegando",
    t = 0,
    classe = util.escolher(T.CLASSES),
    pele = util.escolher(PELES),
    pedido = math.random() < 0.5 and "bebida" or "comida",
    fase = math.random() * 6.28,   -- para a animação não ficar sincronizada
  }
  T.ocupacao[assento] = h
  T.herois[#T.herois + 1] = h
end

function T.valor_pedido()
  local c = config.melhorias.cardapio
  return config.pedido_base * c.efeito ^ T.estado.niveis.cardapio
end

function T.servir(h, pela_garconete)
  if h.estado ~= "esperando" then return false end
  local valor = T.valor_pedido()
  if not pela_garconete and h.t <= config.tempo_rapido then
    valor = valor * config.bonus_rapido
    T.flutuar(h.x, h.y - 120, "Rápido!", util.cores.verde, 20)
  end
  T.ganhar(valor, h.x, h.y - 90)
  T.estado.servidos = T.estado.servidos + 1
  h.estado = "comendo"
  h.t = 0
  h.reservado = false
  return true
end

local function ir_embora(h)
  T.ocupacao[h.assento] = nil
  h.estado = "saindo"
  h.alvo_x, h.alvo_y = T.PORTA.x, T.PORTA.y
end

-- move algo em direção ao alvo; devolve true quando chega
local function andar(o, alvo_x, alvo_y, velocidade, dt)
  local d = util.distancia(o.x, o.y, alvo_x, alvo_y)
  local passo = velocidade * dt
  if d <= passo then
    o.x, o.y = alvo_x, alvo_y
    return true
  end
  o.x = o.x + (alvo_x - o.x) / d * passo
  o.y = o.y + (alvo_y - o.y) / d * passo
  return false
end

local function atualizar_heroi(h, dt)
  h.t = h.t + dt
  if h.estado == "chegando" then
    if andar(h, h.alvo_x, h.alvo_y, config.velocidade_heroi, dt) then
      h.estado = "esperando"
      h.t = 0
    end
  elseif h.estado == "esperando" then
    if h.t >= config.paciencia then
      h.irritado = true
      T.flutuar(h.x, h.y - 100, "Desistiu...", util.cores.vermelho, 18)
      ir_embora(h)
    end
  elseif h.estado == "comendo" then
    if h.t >= config.tempo_comendo then ir_embora(h) end
  elseif h.estado == "saindo" then
    if andar(h, h.alvo_x, h.alvo_y, config.velocidade_heroi, dt) then
      h.removido = true
    end
  end
end

function T.intervalo_chegada()
  local p = config.melhorias.placa
  return config.intervalo_chegada * p.efeito ^ T.estado.niveis.placa
end

-- Garçonete ----------------------------------------------------------------------------

function T.contratar_garconete()
  if T.garconete then return end
  T.garconete = {
    x = T.CASA_GARCONETE.x, y = T.CASA_GARCONETE.y,
    estado = "parada", recarga = 1.0, alvo = nil,
  }
end

function T.intervalo_garconete()
  local g = config.melhorias.garconete
  return g.intervalo * g.efeito ^ (T.estado.niveis.garconete - 1)
end

local function atualizar_garconete(dt)
  local g = T.garconete
  if not g then return end
  local vel = config.melhorias.garconete.velocidade
  g.recarga = g.recarga - dt

  -- escolhe o herói que está esperando há mais tempo
  if g.estado ~= "indo" and g.recarga <= 0 then
    local melhor
    for _, h in ipairs(T.herois) do
      if h.estado == "esperando" and not h.reservado and (not melhor or h.t > melhor.t) then
        melhor = h
      end
    end
    if melhor then
      melhor.reservado = true
      g.alvo = melhor
      g.estado = "indo"
    end
  end

  if g.estado == "indo" then
    local h = g.alvo
    if not h or h.estado ~= "esperando" then
      -- o jogador serviu antes dela
      g.estado = "voltando"
      g.alvo = nil
    else
      -- para na frente do herói
      if andar(g, h.x, h.y + 34, vel, dt) then
        T.servir(h, true)
        g.alvo = nil
        g.estado = "voltando"
        g.recarga = T.intervalo_garconete()
      end
    end
  elseif g.estado == "voltando" then
    if andar(g, T.CASA_GARCONETE.x, T.CASA_GARCONETE.y, vel, dt) then
      g.estado = "parada"
    end
  end
end

-- Melhorias ------------------------------------------------------------------------------

T.ORDEM_MELHORIAS = { "mesa", "cardapio", "placa", "garconete" }

function T.custo(id)
  local m = config.melhorias[id]
  return math.floor(m.custo * m.multiplicador ^ T.estado.niveis[id])
end

function T.disponivel(id)
  local m = config.melhorias[id]
  if m.desbloqueio_mesas then return T.num_mesas() >= m.desbloqueio_mesas end
  return true
end

function T.no_maximo(id)
  local m = config.melhorias[id]
  return m.maximo ~= nil and T.estado.niveis[id] >= m.maximo
end

function T.pode_comprar(id)
  return T.disponivel(id) and not T.no_maximo(id) and T.estado.ouro >= T.custo(id)
end

function T.comprar(id)
  if not T.pode_comprar(id) then return false end
  T.estado.ouro = T.estado.ouro - T.custo(id)
  T.estado.niveis[id] = T.estado.niveis[id] + 1
  if id == "garconete" then T.contratar_garconete() end
  return true
end

local function verificar_desbloqueios()
  local d = T.estado.desbloqueios
  if not d.garconete and T.disponivel("garconete") then
    d.garconete = true
    T.aviso = { texto = "Novidade: Garçonete disponível!", vida = 0, duracao = 3.5 }
  end
end

-- Laço principal ------------------------------------------------------------------------

function T.atualizar(dt)
  if T.offline then return end   -- pausa enquanto mostra o "bem-vindo de volta"

  -- chegada de heróis
  local intervalo = T.intervalo_chegada()
  T.relogio_chegada = math.min(T.relogio_chegada + dt, intervalo)
  if T.relogio_chegada >= intervalo then
    local livres = assentos_livres()
    if #livres > 0 then
      novo_heroi(util.escolher(livres))
      T.relogio_chegada = 0
    end
  end

  for _, h in ipairs(T.herois) do atualizar_heroi(h, dt) end
  for i = #T.herois, 1, -1 do
    if T.herois[i].removido then table.remove(T.herois, i) end
  end

  atualizar_garconete(dt)

  -- efeitos visuais
  for i = #T.efeitos, 1, -1 do
    local e = T.efeitos[i]
    e.vida = e.vida + dt
    if e.vida >= e.duracao then table.remove(T.efeitos, i) end
  end
  if T.aviso then
    T.aviso.vida = T.aviso.vida + dt
    if T.aviso.vida >= T.aviso.duracao then T.aviso = nil end
  end

  -- média de ouro por segundo
  T.relogio_segundo = T.relogio_segundo + dt
  if T.relogio_segundo >= 1 then
    T.estado.rps = T.estado.rps * 0.85 + T.ganho_segundo * 0.15
    T.ganho_segundo = 0
    T.relogio_segundo = T.relogio_segundo - 1
  end

  verificar_desbloqueios()

  T.relogio_salvar = T.relogio_salvar + dt
  if T.relogio_salvar >= config.salvar_a_cada then
    T.relogio_salvar = 0
    T.salvar()
  end
end

-- Toque no salão: serve o herói mais perto do dedo
function T.tocar_salao(x, y)
  local melhor, melhor_d = nil, 60
  for _, h in ipairs(T.herois) do
    if h.estado == "esperando" then
      local d = math.min(util.distancia(x, y, h.x, h.y - 20), util.distancia(x, y, h.x, h.y - 92))
      if d < melhor_d then melhor, melhor_d = h, d end
    end
  end
  if melhor then return T.servir(melhor, false) end
  return false
end

-- Salvar e carregar ------------------------------------------------------------------------

function T.salvar()
  T.estado.salvo_em = os.time()
  motor.salvar(util.serializar(T.estado))
end

function T.carregar()
  local dados = util.desserializar(motor.carregar())
  if not dados then return end
  -- junta o que foi salvo com os valores padrão (versões novas podem ter campos novos)
  local e = estado_inicial()
  for k, v in pairs(dados) do
    if type(v) == "table" and type(e[k]) == "table" then
      for k2, v2 in pairs(v) do e[k][k2] = v2 end
    else
      e[k] = v
    end
  end
  T.estado = e

  -- progresso enquanto o jogo estava fechado (só com a garçonete contratada)
  if e.salvo_em and e.niveis.garconete > 0 then
    local ausente = os.time() - e.salvo_em
    if ausente >= config.offline_minimo then
      local segundos = math.min(ausente, config.offline_maximo)
      local ganho = math.floor(e.rps * segundos * config.offline_eficiencia)
      if ganho >= 1 then T.offline = { ganho = ganho, segundos = ausente } end
    end
  end
end

function T.coletar_offline()
  if not T.offline then return end
  T.ganhar(T.offline.ganho, 480, 300)
  T.offline = nil
end

return T
