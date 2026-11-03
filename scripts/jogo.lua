-- =============================================================================
--  REGRAS DO JOGO: ouro, árvore, clientes, missões, mercadinho, jardim,
--  contratados, parties, heróis, propaganda, invocação e final.
--  Nada aqui desenha: assim os testes conseguem jogar sem abrir janela.
-- =============================================================================

local C = require("config")
local A = require("arvore")
local util = require("util")
local L = require("layout")
local Cam = require("caminhos")

local J = {}

J.PORTA = { x = -6.4, z = 1.6 }
J.RUA_Z = 1.6
J.QUADRO = { x = -2.6, z = -3.7 }
J.BARRACA = { x = 9.3, z = -1.0 }

local POS_MESAS = {}
for i = 1, 8 do
  local o = L.POR_ID["mesa" .. i]
  POS_MESAS[i] = { x = o.x, z = o.z, id = o.id, bx = o.x, bz = o.z }
end
J.POS_MESAS = POS_MESAS
J.BANCOS_BALCAO = { 1.4, 2.5, 3.6, 4.7 }

J.TIPOS = {
  { nome = "comum",     corpo = "#b58a5a", perna = "#4b3b2c", braco = "#a57a4e", temperamento = "calmo" },
  { nome = "comum",     corpo = "#6f8f6a", perna = "#3e3a2e", braco = "#607f5b", temperamento = "calmo" },
  { nome = "comum",     corpo = "#b76f62", perna = "#3f3734", braco = "#a7625a", temperamento = "calmo" },
  { nome = "guerreiro", corpo = "#a8b4bf", perna = "#4d5560", braco = "#8e99a4", temperamento = "bravo" },
  { nome = "guerreiro", corpo = "#a8b4bf", perna = "#6d3f2a", braco = "#b5483a", temperamento = "bravo" },
  { nome = "mago",      corpo = "#6d4bb3", perna = "#4a2f86", braco = "#5e3fa0", temperamento = "sabio" },
  { nome = "mago",      corpo = "#3e6db3", perna = "#27487f", braco = "#355f9e", temperamento = "sabio" },
  { nome = "arqueiro",  corpo = "#4f8a3c", perna = "#4b3b2c", braco = "#437531", temperamento = "orgulhoso" },
  { nome = "clerigo",   corpo = "#eadfca", perna = "#c9b98f", braco = "#ddd0b6", temperamento = "sabio" },
}
local PELES = { "#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a36" }
local CHAPEUS = { "#6b4a2f", "#3e5a4b", false, "#7a3a3a" }
local NOMES = { "Bruno", "Lia", "Tomás", "Iara", "Caio", "Nina", "Davi", "Rosa", "Otávio", "Maia",
  "Heitor", "Clara", "Igor", "Luna", "Rui", "Vera", "Joel", "Alma" }

-- histórias do menestrel: incentivam os aventureiros a pegar missões
local FOFOCAS = {
  "do dragão que dorme sobre uma montanha de ouro ao norte",
  "da guilda que derrotou um exército de goblins com uma única emboscada",
  "do nobre que paga em ouro a quem escoltar a sua caravana",
  "da espada encantada escondida nas ruínas além da floresta",
  "dos heróis antigos que começaram com uma simples missão de rank F",
  "do rei que oferece recompensas por cada monstro derrotado",
}

-- O que merece parar o jogo: "agora você pode liberar isto"
J.NOTICIAS = {
  { id = "mesa", titulo = "Mais espaço na taverna!", texto = "Agora você pode comprar uma Nova mesa. Mais lugares significam mais clientes ao mesmo tempo e mais ouro." },
  { id = "garcom", titulo = "Contrate um garçom!", texto = "Agora você pode contratar um Garçom. Ele serve os clientes sozinho e a taverna continua rendendo mesmo quando você não toca." },
  { id = "prateleira", titulo = "A prateleira de missões!", texto = "Agora você pode construir a Prateleira de missões. Aventureiros vão pegar missões e pagar quando voltarem." },
  { id = "bardo", titulo = "Um bardo na taverna!", texto = "Agora você pode chamar um Bardo. A música faz cada pedido render mais." },
  { id = "mercadinho", titulo = "O mercadinho!", texto = "Agora você pode abrir o Mercadinho. Os aventureiros voltam com espólios, você compra e revende com lucro." },
  { id = "jardim", titulo = "O jardim!", texto = "Agora você pode plantar o Jardim. Ele produz alimentos que abastecem a cozinha e a cervejaria." },
  { id = "fazendeiro", titulo = "Um fazendeiro!", texto = "Agora você pode contratar um Fazendeiro. Ele só cuida do jardim e cada colheita rende mais." },
  { id = "cozinheiro", titulo = "Um cozinheiro!", texto = "Agora você pode contratar um Cozinheiro. Ele usa o que você colhe e a comida passa a render bem mais." },
  { id = "cervejaria", titulo = "A cervejaria!", texto = "Agora você pode abrir a Cervejaria, com um cervejeiro próprio. As bebidas da casa rendem bem mais." },
  { id = "ala_leste", titulo = "Uma ala nova!", texto = "Agora você pode construir a Ala leste. A taverna cresce e ganha mais duas mesas." },
  { id = "venda", titulo = "A aba de venda!", texto = "Agora você pode vender poções, armaduras e armas. O lucro do mercadinho também dobra." },
  { id = "recrutador", titulo = "O recrutador chegou!", texto = "Agora você pode trazer o Recrutador e contratar aventureiros próprios, que evoluem e trazem mais ouro." },
  { id = "party", titulo = "Parties!", texto = "Agora você pode juntar quatro aventureiros em uma party, um grupo mais forte que vai junto nas missões." },
  { id = "heroi", titulo = "O caminho do herói!", texto = "Agora seus contratados de rank A podem virar heróis e ganhar muito mais." },
  { id = "propaganda", titulo = "Propaganda!", texto = "Agora você pode divulgar seus heróis. A fama traz reputação, e a reputação atrai aventureiros de rank mais alto." },
  { id = "invocacao", titulo = "O círculo de invocação!", texto = "Agora você pode construir o Círculo e invocar heróis de outro mundo, os únicos capazes de enfrentar o Lorde Demônio." },
}
for _, r in ipairs({ { "rank_e", "E" }, { "rank_d", "D" }, { "rank_c", "C" }, { "rank_b", "B" }, { "rank_a", "A" }, { "rank_s", "S" }, { "rank_ss", "SS" } }) do
  J.NOTICIAS[#J.NOTICIAS + 1] = { id = r[1], titulo = "Missões rank " .. r[2] .. "!", texto = "Agora você pode abrir as missões rank " .. r[2] .. ". Elas pagam muito mais do que as anteriores." }
end

function J.procurar_noticia()
  local e = J.estado
  if J.noticia or J.em_menu or J.sem_noticias or J.editando or J.offline or e.fim then return end
  for _, n in ipairs(J.NOTICIAS) do
    local no = A.POR_ID[n.id]
    if not e.noticias[n.id] and J.nivel(n.id) == 0 and J.no_liberado(no) and e.ouro >= J.custo_no(no) then
      e.noticias[n.id] = true
      J.noticia = n
      J.som("missao")
      return
    end
  end
  if J.pode_final() and not e.noticias._final then
    e.noticias._final = true
    J.noticia = { final = true, titulo = "Chegou a hora!", texto = "A party dos quatro heróis invocados está pronta para enfrentar o Lorde Demônio. Quando quiser, envie-os na aba Invocação." }
    J.som("invocar")
  end
end

-- O menestrel aparece, canta no meio da taverna e as missões passam a render mais
function J.chamar_menestrel()
  J.indice_fofoca = (J.indice_fofoca or 0) % #FOFOCAS + 1
  local historia = FOFOCAS[J.indice_fofoca]
  for _, p in ipairs(J.pessoas) do
    if p.menestrel then
      -- já tem um na taverna: emenda outra história
      J.comecar_historia(historia)
      return
    end
  end
  if #J.pessoas >= J.MAX_PESSOAS then
    J.comecar_historia(historia)
    return
  end
  local p = {
    x = J.PORTA.x, y = 0, z = J.PORTA.z, giro = math.pi / 2, fase = 0, t = 0, rota = {},
    tipo = { nome = "comum", corpo = "#c0562f", perna = "#3b2a3a", braco = "#a94a29", temperamento = "calmo" },
    pele = "#e0ac7e", chapeu = "#3a7a55", menestrel = true, estado = "menestrel_indo", historia = historia, pedido = "bebida",
  }
  local x, z = L.t("palco", -1.65, 0.2)
  J.vir_de_fora(p, 0)
  J.pessoas[#J.pessoas + 1] = p
  J.caminho(p, x, z)
  -- num salão enorme a caminhada é longa; o limite só existe para ele não ficar preso
  p.limite_palco = math.max(15, 3 * util.distancia(p.x, p.z, x, z) / C.velocidade_pessoa)
  J.flutuar(J.PORTA.x + 0.8, 2.5, J.PORTA.z, "Um menestrel chegou!", util.cores.verde, 18)
end

function J.comecar_historia(historia)
  J.buff = C.fofoca_duracao
  J.banner = {
    titulo = "O menestrel contou uma história",
    texto = "Ele cantou " .. historia .. ". Animados, os aventureiros correm atrás de missões: elas ficam mais rentáveis por " .. C.fofoca_duracao .. " segundos!",
    vida = 0, duracao = 8,
  }
  J.som("missao")
end


local function tipo_de(nome)
  local l = {}
  for _, t in ipairs(J.TIPOS) do if t.nome == nome then l[#l + 1] = t end end
  return util.escolher(l)
end

local function estado_inicial()
  return {
    versao = 2,
    ouro = 0, total = 0, servidos = 0, rps = 0, tempo = 0,
    nos = {},
    missoes = {},           -- { rank, resta, contratado = id }
    feitas = 0, feitas_rank = {},
    espolios = 0, lucro_espolios = 0,
    contratados = {},
    parties = {},
    prox_id = 1,
    invocados_feitos = 0,
    fama = 0,
    estoque = 0, ciclo = 0, colhido = 0,
    brigas = 0,
    final_resta = nil, fim = false,
    opcoes = { musica = 0.4, efeitos = 0.7, sombras = true, fps = false, fluxo = false },
    noticias = {},
  }
end

-- Efeitos da árvore -----------------------------------------------------------------

local ef = {}

local function recalcular()
  ef = {}
  for _, no in ipairs(A.NOS) do
    local nv = J.estado.nos[no.id] or 0
    if nv > 0 then
      for k, v in pairs(no.ef) do
        if k:sub(1, 2) == "x_" then ef[k] = (ef[k] or 1) * v ^ nv
        else ef[k] = (ef[k] or 0) + v * nv end
      end
    end
  end
end

-- no modo de edição tudo aparece, para dar para mover até o que ainda não foi comprado
local PREVIA = { a_leste = 1, a_jardim = 1, a_cerveja = 1, a_circulo = 1, mesas = 7, balcao = 1, cozinheiro = 1, bardo = 1,
  prateleira = 1, mercadinho = 8, canteiros = 10, venda = 1, pocoes = 1, armaduras = 1, armas = 1 }

function J.ef(k)
  if J.previa and PREVIA[k] then return PREVIA[k] end
  return ef[k] or (k:sub(1, 2) == "x_" and 1 or 0)
end
function J.nivel(id)
  if J.previa and id == "quartos" then return 1 end
  return J.estado.nos[id] or 0
end

function J.custo_no(no) return math.floor(no.custo * no.mult ^ J.nivel(no.id)) end

function J.no_liberado(no)
  for _, p in ipairs(no.pre) do
    if J.nivel(p) < 1 then return false end
  end
  return true
end

function J.no_maximo(no) return J.nivel(no.id) >= no.max end

function J.pode_comprar_no(no)
  return J.no_liberado(no) and not J.no_maximo(no) and J.estado.ouro >= J.custo_no(no)
end

local AVISOS = {
  prateleira = "A prateleira de missões abriu! Aba Missões liberada.",
  mercadinho = "O mercadinho abriu! Os aventureiros vão vender espólios.",
  venda = "Aba de venda liberada no Mercadinho!",
  jardim = "O jardim abriu! Aba Produção liberada.",
  recrutador = "O recrutador chegou! Aba Aventureiros liberada.",
  propaganda = "Propaganda liberada: seus heróis podem ficar famosos!",
  invocacao = "O círculo de invocação foi construído!",
}

function J.comprar_no(id)
  local no = A.POR_ID[id]
  if not no or not J.pode_comprar_no(no) then return false end
  J.estado.ouro = J.estado.ouro - J.custo_no(no)
  J.estado.nos[id] = J.nivel(id) + 1
  recalcular()
  J.ajustar_equipe()
  if AVISOS[id] then J.avisar(AVISOS[id]) end
  return true
end

function J.tem_compra()
  for _, no in ipairs(A.NOS) do if J.pode_comprar_no(no) then return true end end
  return false
end

function J.avisar(texto, duracao)
  J.aviso = { texto = texto, vida = 0, duracao = duracao or 3.5 }
end

function J.flutuar(x, y, z, texto, cor, tam)
  J.efeitos[#J.efeitos + 1] = { x = x, y = y, z = z, texto = texto, cor = cor or util.cores.ouro, tam = tam or 22, vida = 0 }
end

function J.ganhar(v, x, y, z)
  local e = J.estado
  e.ouro = e.ouro + v
  e.total = e.total + v
  J.ganho_segundo = J.ganho_segundo + v
  if x then J.flutuar(x, y, z, "+" .. util.formatar(v)) end
end

-- Lugares ---------------------------------------------------------------------------

function J.num_mesas() return math.min(1 + J.ef("mesas"), #POS_MESAS) end

function J.reconstruir_lugares()
  local velhos = J.lugares or {}
  local l = {}
  for i = 1, J.num_mesas() do
    local m = POS_MESAS[i]
    local g = L.giro(m.id)
    local ax, az = L.t(m.id, m.bx - 1.25, m.bz)
    local bx, bz = L.t(m.id, m.bx + 1.25, m.bz)
    l[#l + 1] = { x = ax, z = az, giro = math.pi / 2 + g, y = 0.42, mesa = i }
    l[#l + 1] = { x = bx, z = bz, giro = -math.pi / 2 + g, y = 0.42, mesa = i }
  end
  if J.ef("balcao") > 0 then
    for _, x in ipairs(J.BANCOS_BALCAO) do
      local bx, bz = L.t("balcao", x, -1.42)
      l[#l + 1] = { x = bx, z = bz, giro = math.pi + L.giro("balcao"), y = 0.42, balcao = true }
    end
  end
  -- quem está sentado continua no mesmo lugar: a ordem da lista muda, a posição não
  for _, v in ipairs(velhos) do
    if v.dono then
      for _, n in ipairs(l) do
        if n.x == v.x and n.z == v.z then
          n.dono = v.dono
          v.dono.lugar = n
          break
        end
      end
    end
  end
  J.lugares = l
end

-- enche do fundo para a frente: quem chega não precisa passar pelo meio de quem já sentou
local function lugar_livre()
  local melhor, md
  for _, l in ipairs(J.lugares) do
    if not l.dono then
      local d = util.distancia(l.x, l.z, J.PORTA.x, J.PORTA.z) + math.random() * 3
      if not md or d > md then melhor, md = l, d end
    end
  end
  return melhor
end

local CASAS_GARCOM = { { -0.35, -1.6 }, { -0.35, -2.4 }, { -0.35, -3.2 }, { -1.1, -2.4 }, { -1.1, -3.2 }, { -1.1, -1.6 } }

function J.ajustar_equipe()
  local n = J.ef("garcons")
  for i = #J.garcons + 1, n do
    -- ficam ao lado do balcão, longe de quem está sentado
    local c = CASAS_GARCOM[(i - 1) % #CASAS_GARCOM + 1]
    J.garcons[i] = { x = c[1], z = c[2], casa = c[1], casa_z = c[2], giro = 0, fase = 0, estado = "parada", recarga = 1 + i * 0.5, rota = {} }
  end
  if #J.lugares < J.num_mesas() * 2 + (J.ef("balcao") > 0 and 4 or 0) then J.reconstruir_lugares() end
  J.montar_mapa()
end

-- Mapa de colisão: tudo que ocupa o chão, já nas posições editadas
function J.montar_mapa()
  local obs = {}
  local function circulo(id, x, z, r)
    local wx, wz = L.t(id, x, z)
    obs[#obs + 1] = { x = wx, z = wz, r = r }
  end
  local function caixa(id, x, z, ex, ez)
    obs[#obs + 1] = { id = id, x = x, z = z, ex = ex, ez = ez, base = L.base, mundo = L.t }
  end
  for i = 1, J.num_mesas() do
    local m = POS_MESAS[i]
    circulo(m.id, m.bx, m.bz, 0.88)
    circulo(m.id, m.bx - 1.25, m.bz, 0.03)
    circulo(m.id, m.bx + 1.25, m.bz, 0.03)
  end
  caixa("balcao", 3.05, -2.15, 5.5, 0.95)
  if J.ef("balcao") > 0 then
    for _, x in ipairs(J.BANCOS_BALCAO) do circulo("balcao", x, -1.42, 0.03) end
  end
  caixa("lareira", -5.9, -3.2, 1.3, 2.6)
  caixa("lenha", -6.05, -1.95, 0.7, 0.95)
  caixa("prateleira", 3.05, -4.3, 5.4, 0.5)
  for i = 1, 5 do
    local o = L.POR_ID["barril" .. i]
    circulo(o.id, o.x, o.z, 0.43)
  end
  caixa("carga", 5.5, 4.1, 1.4, 0.8)
  if J.ef("cozinheiro") > 0 then caixa("fogao", 0.95, -3.55, 1.1, 0.9) end
  if J.ef("bardo") > 0 then circulo("bardo", -5.1, -1.25, 0.32) end
  if J.nivel("quartos") > 0 then caixa("quartos", -4.65, -3.9, 1.4, 0.8) end
  local sa, sb, sc, sd = L.salao()
  local xmax = sb - 0.2
  if J.ef("a_leste") > 0 then
    xmax = sb + 5.6   -- o banco direito da mesa 8 fica perto do fim da ala: precisa dar para chegar nele
    caixa("carga_leste", 11.2, -0.4, 1.4, 0.8)
    if J.mercadinho_aberto() then caixa("barraca", 9.3, -2.15, 4.5, 1.7) end
  end
  Cam.montar({ sa + 0.2, xmax, sc + 0.25, sd - 0.2 }, obs)
end

-- bancos que a pessoa só alcança atravessando móveis (usado para avisar no editor)
function J.lugares_sem_rota()
  local n = 0
  for _, l in ipairs(J.lugares) do
    if not Cam.rota(J.PORTA.x, J.PORTA.z, l.x, l.z) then n = n + 1 end
  end
  return n
end

-- A porta em coordenadas de origem (a parede fica entre x = -6.9 e -6.5): L.t acompanha o editor.
-- soleira é o primeiro ponto livre dentro do salão; fora é atrás da parede, longe do mapa de colisões.
local function soleira_da_porta(dz)
  local x, z = L.t("porta", -5.9, 1.6 + dz)
  -- móvel na frente da porta: a rota começa na própria porta, como sempre foi
  if Cam.bloqueado(x, z) then return J.PORTA.x, J.PORTA.z end
  return x, z
end

-- Coloca a pessoa atrás da parede: ela atravessa o vão em linha reta e só então segue a rota
function J.vir_de_fora(p, dz)
  local sx, sz = soleira_da_porta(dz)
  p.x, p.z = L.t("porta", -7.7, 1.6 + dz)
  p.giro = math.pi / 2 + L.giro("porta")
  p.vao = { { x = sx, z = sz } }
end

-- Quem está andando perto da porta (ou no vão) a mantém aberta; sentados e garçons não contam
function J.alguem_na_porta()
  for _, p in ipairs(J.pessoas or {}) do
    if p.vao or (p.andando and not p.sentado and util.distancia(p.x, p.z, J.PORTA.x, J.PORTA.z) < 1.5) then return true end
  end
  return false
end

-- Está atrás da parede? (o boneco tem 0,3 de raio: aqui ele ainda fica todo dentro dela)
function J.fora_da_porta(p)
  if not p.vao then return false end
  return (L.base("porta", p.x, p.z)) < -6.85
end

-- Monta os caminhos desviando dos objetos; se não houver saída, a pessoa atravessa
function J.caminho(p, x, z)
  -- quem ainda vem pelo vão está fora do mapa: a rota começa no fim do vão
  local vao, fx, fz = p.vao, p.x, p.z
  if vao then p.x, p.z = vao[#vao].x, vao[#vao].z end
  local r = Cam.rota(p.x, p.z, x, z)
  if not r then
    -- empurrado para dentro de um móvel: sai pelo ponto livre mais próximo e segue a rota dali
    for raio = 0.3, 0.6, 0.3 do
      for k = 0, 7 do
        local a = k * math.pi / 4
        local ax, az = p.x + math.cos(a) * raio, p.z + math.sin(a) * raio
        if not Cam.bloqueado(ax, az) then
          r = Cam.rota(ax, az, x, z)
          if r then
            table.insert(r, 1, { x = ax, z = az })
            break
          end
        end
      end
      if r then break end
    end
  end
  p.sem_rota = not r
  p.fantasma = not r or nil
  if not r then
    r = { { x = x, z = z } }
    J.sem_caminho = (J.sem_caminho or 0) + 1
  end
  p.rota, p.andando, p.preso, p.destino_x, p.destino_z = r, true, 0, x, z
  p.origem_x, p.origem_z = p.x, p.z
  if vao then p.x, p.z, p.fantasma = fx, fz, true end
end

-- Só atualiza onde as coisas estão, para o editor mostrar o resultado na hora
function J.aplicar_visual()
  for _, m in ipairs(POS_MESAS) do m.x, m.z = L.t(m.id, m.bx, m.bz) end
end

-- Coloca em uso as posições editadas: quem estava na taverna sai, o resto continua
function J.aplicar_layout()
  for _, m in ipairs(POS_MESAS) do m.x, m.z = L.t(m.id, m.bx, m.bz) end
  J.PORTA.x, J.PORTA.z = L.t("porta", -6.4, 1.6)
  J.QUADRO.x, J.QUADRO.z = L.t("quadro", -2.6, -3.7)
  J.BARRACA.x, J.BARRACA.z = L.t("barraca", 9.3, -1.0)
  for _, l in ipairs(J.lugares or {}) do l.dono = nil end
  -- o menestrel que ainda não tinha cantado não leva a história embora
  for _, p in ipairs(J.pessoas) do
    if p.estado == "menestrel_indo" then J.comecar_historia(p.historia) end
  end
  J.pessoas = {}
  J.reconstruir_lugares()
  J.montar_mapa()
  for _, g in ipairs(J.garcons or {}) do
    g.x, g.z, g.estado, g.rota, g.alvo, g.levando, g.andando = g.casa, g.casa_z, "parada", {}, nil, false, false
    g.fantasma, g.sem_rota, g.preso = nil, nil, 0
  end
end

function J.ocupados()
  local n = 0
  for _, l in ipairs(J.lugares) do if l.dono then n = n + 1 end end
  return n, #J.lugares
end

-- Valor dos pedidos -----------------------------------------------------------------

function J.valor_pedido() return C.pedido_base * J.ef("x_pedido") end

function J.intervalo_chegada() return C.intervalo_chegada * J.ef("x_chegada") end

function J.paciencia() return C.paciencia + J.ef("paciencia") end

function J.intervalo_garcom() return C.garcom_intervalo * J.ef("x_garcom") end

-- Pessoas ---------------------------------------------------------------------------

local function nova_pessoa(tipo)
  local p = {
    x = J.PORTA.x, y = 0, z = J.PORTA.z, giro = math.pi / 2, fase = math.random() * 6, t = 0,
    tipo = tipo, pele = util.escolher(PELES),
    chapeu = tipo.nome == "comum" and util.escolher(CHAPEUS) or nil,
    pedido = math.random() < 0.5 and "bebida" or "comida",
    rota = {}, andando = true, estado = "entrando",
  }
  J.vir_de_fora(p, (math.random() - 0.5) * 0.6)
  return p
end

local function rota_ate(p, x, z) J.caminho(p, x, z) end

local function rota_saida(p)
  J.caminho(p, soleira_da_porta(0))
  p.estado = "saindo"
end

local function sentar_cliente(p, lugar)
  p.lugar = lugar
  lugar.dono = p
  rota_ate(p, lugar.x, lugar.z)
  p.estado = "entrando"
end

function J.porta_lotada()
  local n = 0
  for _, p in ipairs(J.pessoas) do
    -- quem está sentado perto da porta não atrapalha a entrada
    if p.andando and not p.sentado and not p.vao and util.distancia(p.x, p.z, J.PORTA.x, J.PORTA.z) < 2.2 then n = n + 1 end
  end
  return n >= 3
end

function J.novo_cliente()
  if J.porta_lotada() and (J.espera_porta or 0) < 6 then return nil end
  local lugar = lugar_livre()
  if not lugar then return nil end
  -- no começo só gente comum e alguns aventureiros; depois mais aventureiros
  local aventura = J.ef("prateleira") > 0 and 0.6 or 0.3
  local nome = math.random() < aventura and util.escolher({ "guerreiro", "mago", "arqueiro", "clerigo" }) or "comum"
  local p = nova_pessoa(tipo_de(nome))
  sentar_cliente(p, lugar)
  J.pessoas[#J.pessoas + 1] = p
  return p
end

local function liberar(p)
  if p.lugar then
    p.lugar.dono = nil
    p.lugar = nil
  end
  p.sentado, p.bebendo, p.y = false, false, 0
end

local function companheiro(p)
  if not (p.lugar and p.lugar.mesa) then return nil end
  for _, l in ipairs(J.lugares) do
    if l.mesa == p.lugar.mesa and l.dono and l.dono ~= p and l.dono.sentado then return l.dono end
  end
  return nil
end

-- guerreiro e arqueiro não se bicam; mago e clérigo se dão muito bem
local function combina(a, b)
  local x, y = a.tipo.temperamento, b.tipo.temperamento
  if (x == "bravo" and y == "orgulhoso") or (x == "orgulhoso" and y == "bravo") then return "briga" end
  if a.tipo.nome ~= b.tipo.nome and x == "sabio" and y == "sabio" then return "combo" end
  return nil
end

function J.servir(p, por_garcom)
  if p.estado ~= "esperando" then return false end
  local e = J.estado
  local v = J.valor_pedido()
  if p.tipo.nome ~= "comum" then v = v * C.bonus_aventureiro end
  if not por_garcom and p.t <= C.tempo_rapido then
    v = v * C.bonus_rapido
    J.flutuar(p.x, 2.7, p.z, "Rápido!", util.cores.verde, 18)
  end
  -- comida e bebida feitas em casa usam o que foi colhido
  if p.pedido == "comida" and J.ef("cozinheiro") > 0 and e.estoque >= 1 then
    e.estoque = e.estoque - 1
    v = v * (C.bonus_cozinheiro + C.bonus_cozinheiro_nivel * (J.ef("cozinheiro") - 1))
  elseif p.pedido == "bebida" and J.ef("bebida_casa") > 0 and e.estoque >= 1 then
    e.estoque = e.estoque - 1
    v = v * (C.bonus_bebida_casa + C.bonus_bebida_nivel * (J.ef("bebida_casa") - 1))
  end
  local par = companheiro(p)
  if par and combina(p, par) == "combo" then
    v = v * C.combo_mesa
    J.flutuar(p.x, 2.95, p.z, "Combo!", "#c9a7ff", 18)
  end
  if p.festa then
    v = v * (2 + J.ef("festa"))
    J.flutuar(p.x, 2.95, p.z, "Festa!", util.cores.verde, 18)
  end
  J.ganhar(v, p.x, 2.3, p.z)
  e.servidos = e.servidos + 1
  p.estado, p.t, p.reservado, p.festa = "comendo", 0, false, false
  J.som("moeda")
  return true
end

function J.som(nome) if J.tocar_som then J.tocar_som(nome) end end

function J.separar_briga(p)
  if p.estado ~= "brigando" then return false end
  local par = p.oponente
  local v = J.valor_pedido() * C.briga_recompensa
  J.ganhar(v, p.x, 2.3, p.z)
  J.flutuar(p.x, 2.95, p.z, "Briga separada!", util.cores.verde, 18)
  J.estado.brigas = J.estado.brigas + 1
  for _, q in ipairs({ p, par }) do
    if q and q.estado == "brigando" then
      q.estado, q.t, q.oponente, q.sem_briga = "esperando", 0, nil, true
      q.andando = false
    end
  end
  J.som("moeda")
  return true
end

local function andar(o, dx, dz, vel, dt)
  local ax, az = dx - o.x, dz - o.z
  local d = math.sqrt(ax * ax + az * az)
  if d < 0.04 then return true end
  local passo = math.min(vel * dt, d)
  o.x, o.z = o.x + ax / d * passo, o.z + az / d * passo
  local alvo = math.atan(ax, az)
  local dif = (alvo - o.giro + math.pi) % (2 * math.pi) - math.pi
  o.giro = o.giro + dif * math.min(1, dt * 12)
  o.fase = o.fase + dt
  return false
end

-- Empurrado por alguém, o caminho reto até o próximo ponto pode cruzar uma mesa: calcula de novo
local function refazer_se_for_bater(p, alvo, vel, dt)
  p.espera_rota = (p.espera_rota or 0) - dt
  if p.fantasma or not p.destino_x or p.espera_rota > 0 then return alvo end
  local ax, az = alvo.x - p.x, alvo.z - p.z
  local d = math.sqrt(ax * ax + az * az)
  if d < 0.01 then return alvo end
  local passo = math.min(d, math.max(vel * dt, 0.2))
  local nx, nz = p.x + ax / d * passo, p.z + az / d * passo
  if not Cam.bloqueado(nx, nz) then return alvo end
  -- em volta do banco e de onde saiu o caminho é liberado de propósito
  if util.distancia(nx, nz, p.destino_x, p.destino_z) < 0.45 or util.distancia(nx, nz, p.origem_x, p.origem_z) < 0.45 then return alvo end
  p.espera_rota = 0.3
  local preso = p.preso
  J.caminho(p, p.destino_x, p.destino_z)
  p.preso = preso
  return p.rota[1]
end

local function seguir_rota(p, dt, vel)
  local alvo = p.rota[1]
  if not alvo then return true end
  alvo = refazer_se_for_bater(p, alvo, vel, dt)
  -- empurrado por outros, ninguém acerta um ponto exato: chegar perto já basta
  local dx, dz = alvo.x - p.x, alvo.z - p.z
  local tol = #p.rota > 1 and 0.3 or 0.15
  if p.estado == "saindo" and #p.rota == 1 then tol = 0.8 end
  if dx * dx + dz * dz < tol * tol or andar(p, alvo.x, alvo.z, vel, dt) then table.remove(p.rota, 1) end
  return #p.rota == 0
end

local function iniciar_missao_visual(p, dados)
  p.estado = "indo_quadro"
  p.dados_missao = dados
  -- cada um vai a um ponto do quadro e pega o papel com a mão
  local ox = util.escolher({ -0.9, -0.3, 0.3, 0.9 })
  local x, z = L.t("quadro", -2.6 + ox, -3.7)
  p.papel_x = ox
  rota_ate(p, x, z)
end

-- Reta pelo vão, sem colisões: as paredes do mapa bloqueiam tudo o que fica fora do salão
local function atravessar_vao(p, dt)
  local a = p.vao[1]
  if andar(p, a.x, a.z, C.velocidade_pessoa, dt) then table.remove(p.vao, 1) end
  if #p.vao > 0 then return end
  p.vao, p.fantasma = nil, p.sem_rota or nil
  -- só some depois de passar pela porta
  if p.estado == "saindo" then p.removido = true end
end

local function atualizar_pessoa(p, dt)
  p.t = p.t + dt
  if p.vao then return atravessar_vao(p, dt) end
  if p.estado == "entrando" then
    if seguir_rota(p, dt, C.velocidade_pessoa) then
      p.estado, p.t, p.andando, p.sentado = "esperando", 0, false, true
      p.fantasma = nil
      if p.lugar then p.x, p.z, p.y, p.giro = p.lugar.x, p.lugar.z, p.lugar.y, p.lugar.giro end
    end
  elseif p.estado == "esperando" then
    -- temperamentos incompatíveis na mesma mesa acabam em briga
    if not p.sem_briga and p.t >= C.briga_inicio then
      local par = companheiro(p)
      if par and par.estado == "esperando" and not par.sem_briga and combina(p, par) == "briga" then
        p.estado, p.oponente, p.t = "brigando", par, 0
        par.estado, par.oponente, par.t = "brigando", p, 0
        J.flutuar(p.x, 2.8, p.z, "Briga!", util.cores.vermelho, 20)
        J.som("briga")
        return
      end
    end
    if p.t >= J.paciencia() then
      J.flutuar(p.x, 2.5, p.z, "Desistiu...", util.cores.vermelho, 16)
      liberar(p)
      rota_saida(p)
    end
  elseif p.estado == "brigando" then
    p.fase = p.fase + dt
    if p.t >= C.briga_espera then
      J.flutuar(p.x, 2.5, p.z, "Foram embora!", util.cores.vermelho, 16)
      p.oponente = nil
      liberar(p)
      rota_saida(p)
    end
  elseif p.estado == "comendo" then
    p.bebendo = (p.t % 2) < 1.2
    if p.t > C.tempo_comendo then
      liberar(p)
      rota_saida(p)
    end
  elseif p.estado == "menestrel_indo" then
    if seguir_rota(p, dt, C.velocidade_pessoa) or p.t > (p.limite_palco or 15) then
      p.estado, p.t, p.andando = "menestrel_canta", 0, false
      p.fantasma = nil
      p.giro = 0
      J.comecar_historia(p.historia)
    end
  elseif p.estado == "menestrel_canta" then
    p.fase = p.fase + dt
    if p.t > C.menestrel_canta then rota_saida(p) end
  elseif p.estado == "indo_quadro" then
    if seguir_rota(p, dt, C.velocidade_pessoa) then
      p.estado, p.t, p.andando = "pegando", 0, false
      p.fantasma = nil
      p.giro = math.pi + L.giro("quadro")
    end
  elseif p.estado == "pegando" then
    -- estica o braço, arranca o papel e sai com ele na mão
    if p.t > 0.55 and not p.com_papel then
      p.com_papel = true
      J.flutuar(p.x, 2.5, p.z, "Missão " .. (p.rank_missao or "") .. "!", util.cores.ouro, 18)
      J.som("clique")
    end
    if p.t > 1.3 then rota_saida(p) end
  elseif p.estado == "indo_barraca" then
    if seguir_rota(p, dt, C.velocidade_pessoa) then
      J.vender_espolio(p)
      p.estado, p.t, p.andando = "vendendo", 0, false
      p.fantasma = nil
      p.giro = math.pi + L.giro("barraca")
    end
  elseif p.estado == "vendendo" then
    if p.t > 1.0 then
      local lugar = lugar_livre()
      if lugar and p.festa then sentar_cliente(p, lugar) else rota_saida(p) end
    end
  elseif p.estado == "saindo" then
    if seguir_rota(p, dt, C.velocidade_pessoa) then
      -- volta ao centro da soleira e cruza a porta em linha reta
      local sx, sz = soleira_da_porta(0)
      local fx, fz = L.t("porta", -7.7, 1.6)
      p.vao, p.fantasma = { { x = sx, z = sz }, { x = fx, z = fz } }, true
    end
  end
end

-- Garçons ---------------------------------------------------------------------------

-- Onde parar para atender: com a mesa ou o balcão girados, o lado de sempre pode estar dentro do móvel
local function ponto_de_servir(g, p)
  local dz = p.z < J.RUA_Z and 0.72 or -0.72
  for _, o in ipairs({ { 0, dz }, { 0, -dz }, { 0.72, 0 }, { -0.72, 0 } }) do
    local x, z = p.x + o[1], p.z + o[2]
    if not Cam.bloqueado(x, z) and Cam.rota(g.x, g.z, x, z) then return x, z end
  end
  return p.x, p.z + dz
end

local function atualizar_garcom(g, dt)
  g.recarga = g.recarga - dt
  g.andando = false
  if g.estado == "parada" then
    if g.recarga <= 0 then
      local melhor
      for _, p in ipairs(J.pessoas) do
        if p.estado == "esperando" and not p.reservado and (not melhor or p.t > melhor.t) then melhor = p end
      end
      if melhor then
        melhor.reservado = true
        g.alvo, g.estado, g.levando = melhor, "indo", true
        J.caminho(g, ponto_de_servir(g, melhor))
      end
    end
  else
    g.andando = true
    if seguir_rota(g, dt, C.garcom_velocidade) then
      if g.estado == "indo" then
        local p = g.alvo
        if p and p.estado == "esperando" then J.servir(p, true) end
        if p then p.reservado = false end
        g.alvo, g.levando, g.estado = nil, false, "voltando"
        g.recarga = J.intervalo_garcom()
        J.caminho(g, g.casa, g.casa_z)
      else
        g.estado = "parada"
        g.fantasma = nil
      end
    end
  end
end

-- Missões ---------------------------------------------------------------------------

function J.prateleira_aberta() return J.ef("prateleira") > 0 end

function J.vagas_missao() return C.vagas_missao + J.ef("vagas") end

function J.missoes_comuns_ativas()
  local n = 0
  for _, m in ipairs(J.estado.missoes) do if not m.contratado then n = n + 1 end end
  return n
end

function J.duracao_rank(r) return C.ranks[r].duracao * J.ef("x_duracao") end

function J.nivel_reputacao()
  local f = J.estado.fama
  local n, limite = 0, C.reputacao_base
  while f >= limite and n < 60 do
    n = n + 1
    limite = limite * C.reputacao_mult
  end
  return n, limite
end

function J.multiplicador_missao()
  local m = J.ef("x_missao") * (1 + C.bonus_reputacao * J.nivel_reputacao())
  if J.buff and J.buff > 0 then m = m * C.fofoca_bonus end
  return m
end

function J.pagamento_rank(r) return C.ranks[r].pagamento * J.multiplicador_missao() end

-- reputação atrai aventureiros de rank mais alto: S e SS dependem dela
function J.rank_aventureiro()
  local r = J.ef("rank_max")
  local teto = 6
  local nv = J.nivel_reputacao()
  if nv >= 2 then teto = 7 end
  if nv >= 4 then teto = 8 end
  return math.min(r, teto)
end

local function pagamento_contratado(c, r)
  local v = J.pagamento_rank(r) * C.ganho_contratado
  if c.party then v = v * C.bonus_party end
  if c.heroi then v = v * C.ganho_heroi end
  if c.invocado then v = v * C.ganho_invocado end
  return v
end

local function concluir_missao(m)
  local e = J.estado
  local r = m.rank
  e.feitas = e.feitas + 1
  e.feitas_rank[r] = (e.feitas_rank[r] or 0) + 1
  J.fofoca_conta = (J.fofoca_conta or 0) + 1
  if J.fofoca_conta >= C.fofoca_a_cada then
    J.fofoca_conta = 0
    J.chamar_menestrel()
  end

  local c = m.contratado and J.contratado_por_id(m.contratado) or nil
  local v
  if c then
    c.em_missao = false
    c.missoes = (c.missoes or 0) + 1
    v = pagamento_contratado(c, r)
    if c.heroi or c.invocado then
      if J.ef("propaganda") > 0 then
        local f = C.fama_por_missao * r * J.ef("x_fama")
        c.fama = (c.fama or 0) + f
        e.fama = e.fama + f
      end
    end
  else
    v = J.pagamento_rank(r)
  end

  -- a pessoa volta pela porta e paga; se a taverna estiver lotada de gente, só o ouro entra
  if #J.pessoas < J.MAX_PESSOAS then
    local tipo = c and J.TIPOS_POR_NOME(c.tipo) or tipo_de(util.escolher({ "guerreiro", "mago", "arqueiro", "clerigo" }))
    local p = nova_pessoa(tipo)
    p.contratado = c
    if c then p.pele = c.pele end
    p.rank_volta = r
    p.festa = true
    J.pessoas[#J.pessoas + 1] = p
    J.ganhar(v, J.PORTA.x + 0.8, 2.3, J.PORTA.z)
    if J.mercadinho_aberto() and r <= J.ef("mercadinho") then
      p.estado = "indo_barraca"
      rota_ate(p, J.BARRACA.x + (math.random() - 0.5) * 2.5, J.BARRACA.z)
      p.leva_espolio = r
    else
      local lugar = lugar_livre()
      if lugar then sentar_cliente(p, lugar) else rota_saida(p) end
    end
  else
    J.ganhar(v)
    if J.mercadinho_aberto() and r <= J.ef("mercadinho") then J.vender_espolio({ leva_espolio = r }) end
  end
  J.som("missao")
end

local function partir_visual(tipo, c, rank)
  if #J.pessoas >= J.MAX_PESSOAS then return end
  local p = nova_pessoa(tipo)
  p.rank_missao = rank
  if c then p.pele = c.pele; p.contratado = c end
  iniciar_missao_visual(p, true)
  J.pessoas[#J.pessoas + 1] = p
end

function J.iniciar_missao_comum(r)
  local e = J.estado
  e.missoes[#e.missoes + 1] = { rank = r, resta = J.duracao_rank(r) }
  partir_visual(tipo_de(util.escolher({ "guerreiro", "mago", "arqueiro", "clerigo" })), nil, C.ranks[r].nome)
end

local function atualizar_missoes(dt)
  local e = J.estado
  for i = #e.missoes, 1, -1 do
    local m = e.missoes[i]
    m.resta = m.resta - dt
    if m.resta <= 0 then
      table.remove(e.missoes, i)
      concluir_missao(m)
    end
  end

  if J.prateleira_aberta() then
    J.relogio_aventureiro = J.relogio_aventureiro + dt
    if J.relogio_aventureiro >= C.intervalo_aventureiro and J.missoes_comuns_ativas() < J.vagas_missao() then
      J.relogio_aventureiro = 0
      J.iniciar_missao_comum(J.rank_aventureiro())
    end
  end
  J.mandar_contratados()
end

-- Mercadinho ---------------------------------------------------------------------------

function J.mercadinho_aberto() return J.ef("mercadinho") > 0 end
function J.venda_aberta() return J.ef("venda") > 0 end

function J.lucro_espolio(r)
  local m = C.margem_espolio * J.ef("x_espolio")
  if J.venda_aberta() then m = m * C.margem_com_venda end
  return C.ranks[r].espolio * m
end

function J.vender_espolio(p)
  local r = p.leva_espolio
  if not r then return end
  p.leva_espolio = nil
  local v = J.lucro_espolio(r)
  J.estado.espolios = J.estado.espolios + 1
  J.estado.lucro_espolios = J.estado.lucro_espolios + v
  if p.x then J.ganhar(v, p.x, 2.4, p.z) else J.ganhar(v) end
end

function J.renda_venda()
  local t = 0
  for id, d in pairs(C.venda) do t = t + J.ef(id) * d.renda end
  return t
end

function J.renda_passiva() return J.ef("renda_quartos") + J.renda_venda() end

-- Jardim ---------------------------------------------------------------------------------

function J.jardim_aberto() return J.ef("a_jardim") > 0 end
function J.ciclo_jardim() return C.ciclo_jardim * J.ef("x_ciclo") end
function J.por_colheita() return J.ef("canteiros") * C.colheita * J.ef("x_colheita") end

local function atualizar_jardim(dt)
  if not J.jardim_aberto() then return end
  local e = J.estado
  e.ciclo = e.ciclo + dt
  if e.ciclo >= J.ciclo_jardim() then
    e.ciclo = 0
    local q = J.por_colheita()
    e.estoque = math.min(C.estoque_maximo * (1 + J.ef("canteiros") * 0.25), e.estoque + q)
    e.colhido = e.colhido + q
  end
end

-- Contratados e heróis ----------------------------------------------------------------------

-- sempre o mesmo visual para o mesmo contratado (é chamado a cada quadro no círculo)
function J.TIPOS_POR_NOME(nome)
  for _, t in ipairs(J.TIPOS) do if t.nome == nome then return t end end
end

function J.contratado_por_id(id)
  for _, c in ipairs(J.estado.contratados) do if c.id == id then return c end end
  return nil
end

function J.pode_contratar_aberto() return J.ef("contratar") > 0 end
function J.vagas_contrato() return J.ef("vagas_contrato") end

function J.num_contratos_normais()
  local n = 0
  for _, c in ipairs(J.estado.contratados) do if not c.invocado then n = n + 1 end end
  return n
end

function J.custo_contratar()
  return math.floor(C.contratar_custo * C.contratar_mult ^ J.num_contratos_normais())
end

function J.contratar()
  local e = J.estado
  if not J.pode_contratar_aberto() or J.num_contratos_normais() >= J.vagas_contrato() then return nil end
  local custo = J.custo_contratar()
  if e.ouro < custo then return nil end
  e.ouro = e.ouro - custo
  local i = e.prox_id
  e.prox_id = i + 1
  local tipos = { "guerreiro", "mago", "arqueiro", "clerigo" }
  local c = {
    id = i, nome = NOMES[(i - 1) % #NOMES + 1], tipo = tipos[(i - 1) % 4 + 1],
    pele = PELES[(i - 1) % #PELES + 1],
    armadura = 0, arma = 0, magia = 0, fama = 0, missoes = 0,
  }
  e.contratados[#e.contratados + 1] = c
  return c
end

function J.poder(c)
  local p = c.invocado and C.poder_invocado * J.ef("x_invocado") or C.poder_inicial
  for id, d in pairs(C.investir) do p = p + (c[id] or 0) * d.poder * (c.invocado and 4 or 1) end
  if c.party then p = p * C.bonus_party end
  if c.heroi then p = p * 1.5 end
  return p
end

function J.rank_contratado(c)
  local p, r = J.poder(c), 1
  for i, d in ipairs(C.ranks) do if p >= d.poder then r = i end end
  return r
end

function J.custo_investir(c, id)
  local d = C.investir[id]
  return math.floor(d.custo * d.mult ^ (c[id] or 0) * (c.invocado and 100 or 1))
end

function J.investir(c, id)
  local custo = J.custo_investir(c, id)
  if J.estado.ouro < custo then return false end
  J.estado.ouro = J.estado.ouro - custo
  c[id] = (c[id] or 0) + 1
  return true
end

function J.custo_promover(c) return math.floor(C.ranks[J.rank_contratado(c)].pagamento * C.promover_custo_mult) end

function J.pode_promover(c)
  return J.ef("heroi") > 0 and not c.heroi and not c.invocado and J.rank_contratado(c) >= C.rank_para_heroi
end

function J.promover(c)
  if not J.pode_promover(c) or J.estado.ouro < J.custo_promover(c) then return false end
  J.estado.ouro = J.estado.ouro - J.custo_promover(c)
  c.heroi = true
  J.avisar(c.nome .. " agora é um herói!")
  return true
end

-- Parties ---------------------------------------------------------------------------------------

function J.criar_party(ids)
  if J.ef("party") <= 0 or #ids ~= 4 then return false end
  local e = J.estado
  local num = e.prox_id
  e.prox_id = num + 1
  for _, id in ipairs(ids) do
    local c = J.contratado_por_id(id)
    if not c or c.party then return false end
  end
  for _, id in ipairs(ids) do J.contratado_por_id(id).party = num end
  e.parties[#e.parties + 1] = { id = num, membros = ids }
  return true
end

function J.desfazer_party(num)
  local e = J.estado
  for i, p in ipairs(e.parties) do
    if p.id == num then
      for _, id in ipairs(p.membros) do
        local c = J.contratado_por_id(id)
        if c then c.party = nil end
      end
      table.remove(e.parties, i)
      return true
    end
  end
  return false
end

-- junta os 4 invocados, tirando-os de qualquer outra party
function J.formar_party_final()
  if J.ef("party") <= 0 then return false end
  local ids = {}
  for _, c in ipairs(J.estado.contratados) do
    if c.invocado then ids[#ids + 1] = c.id end
  end
  if #ids ~= 4 then return false end
  for _, id in ipairs(ids) do
    local c = J.contratado_por_id(id)
    if c.party then J.desfazer_party(c.party) end
  end
  return J.criar_party(ids)
end

-- monta uma party com os 4 mais fortes disponíveis (invocados primeiro, se houver 4)
function J.melhores_sem_party()
  local l = {}
  for _, c in ipairs(J.estado.contratados) do if not c.party then l[#l + 1] = c end end
  table.sort(l, function(a, b)
    if (a.invocado or false) ~= (b.invocado or false) then return a.invocado or false end
    return J.poder(a) > J.poder(b)
  end)
  local ids = {}
  for i = 1, math.min(4, #l) do ids[i] = l[i].id end
  return ids
end

local function livre_para_missao(c) return not c.em_missao and not c.na_final end

function J.mandar_contratados()
  local e = J.estado
  if e.final_resta then return end
  -- parties vão juntas
  for _, pt in ipairs(e.parties) do
    local todos = true
    local rank = 99
    for _, id in ipairs(pt.membros) do
      local c = J.contratado_por_id(id)
      if not c or not livre_para_missao(c) then todos = false break end
      rank = math.min(rank, J.rank_contratado(c))
    end
    if todos then
      rank = math.min(rank, math.max(1, J.ef("rank_max")))
      for _, id in ipairs(pt.membros) do
        local c = J.contratado_por_id(id)
        c.em_missao = true
        e.missoes[#e.missoes + 1] = { rank = rank, resta = J.duracao_rank(rank), contratado = c.id }
        partir_visual(J.TIPOS_POR_NOME(c.tipo), c, C.ranks[rank].nome)
      end
    end
  end
  if J.ef("rank_max") < 1 then return end
  for _, c in ipairs(e.contratados) do
    if not c.party and livre_para_missao(c) then
      local rank = math.min(J.rank_contratado(c), J.ef("rank_max"))
      c.em_missao = true
      e.missoes[#e.missoes + 1] = { rank = rank, resta = J.duracao_rank(rank), contratado = c.id }
      partir_visual(J.TIPOS_POR_NOME(c.tipo), c, C.ranks[rank].nome)
    end
  end
end

-- Invocação e final --------------------------------------------------------------------------------

function J.invocacao_aberta() return J.ef("invocar") > 0 end

function J.custo_invocar() return C.invocar_custo * C.invocar_mult ^ J.estado.invocados_feitos end

function J.invocar()
  local e = J.estado
  if not J.invocacao_aberta() or e.invocados_feitos >= #C.invocados then return nil end
  local custo = J.custo_invocar()
  if e.ouro < custo then return nil end
  e.ouro = e.ouro - custo
  e.invocados_feitos = e.invocados_feitos + 1
  local d = C.invocados[e.invocados_feitos]
  local i = e.prox_id
  e.prox_id = i + 1
  local c = {
    id = i, nome = d.nome, titulo = d.titulo, tipo = d.tipo, pele = "#f1c9a5", invocado = true,
    armadura = 0, arma = 0, magia = 0, fama = 0, missoes = 0,
  }
  e.contratados[#e.contratados + 1] = c
  J.avisar(d.nome .. " atravessou o portal!", 4)
  J.som("invocar")
  return c
end

-- a missão SSS exige uma party de 4 invocados, todos com poder suficiente
function J.party_final()
  for _, pt in ipairs(J.estado.parties) do
    local ok = #pt.membros == 4
    for _, id in ipairs(pt.membros) do
      local c = J.contratado_por_id(id)
      if not (c and c.invocado) then ok = false end
    end
    if ok then return pt end
  end
  return nil
end

function J.pode_final()
  local pt = J.party_final()
  if not pt or J.estado.final_resta or J.estado.fim then return false end
  for _, id in ipairs(pt.membros) do
    local c = J.contratado_por_id(id)
    if J.poder(c) < C.sss.poder then return false end
  end
  return true
end

function J.iniciar_final()
  if not J.pode_final() then return false end
  local e = J.estado
  e.final_resta = C.sss.duracao
  for _, id in ipairs(J.party_final().membros) do
    local c = J.contratado_por_id(id)
    c.na_final = true
    -- quem estava em missão abandona o trabalho e parte para a batalha final
    for i = #e.missoes, 1, -1 do
      if e.missoes[i].contratado == c.id then table.remove(e.missoes, i) end
    end
    c.em_missao = nil
    partir_visual(J.TIPOS_POR_NOME(c.tipo), c, C.sss.nome)
  end
  J.avisar("A party partiu para enfrentar o Lorde Demônio!", 5)
  return true
end

-- Objetivo atual, para o jogador sempre saber o que buscar ---------------------------------------------

local OBJETIVOS = {
  { "servidos", "Toque nos balões para servir os clientes" },
  { "mesa", "Abra a Árvore e compre uma Nova mesa" },
  { "garcom", "Contrate um Garçom na Árvore" },
  { "prateleira", "Construa a Prateleira de missões" },
  { "mercadinho", "Abra o Mercadinho" },
  { "jardim", "Plante o Jardim" },
  { "cozinheiro", "Contrate o Cozinheiro" },
  { "venda", "Libere a Aba de venda" },
  { "recrutador", "Traga o Recrutador" },
  { "party", "Libere as Parties" },
  { "heroi", "Libere o Caminho do herói" },
  { "propaganda", "Abra a Propaganda" },
  { "invocacao", "Construa o Círculo de invocação" },
}

function J.objetivo()
  local e = J.estado
  if e.fim then return "O mundo está em paz!" end
  if e.final_resta then return "A party enfrenta o Lorde Demônio..." end
  for _, o in ipairs(OBJETIVOS) do
    if o[1] == "servidos" then
      if e.servidos < 5 then return o[2] end
    elseif J.nivel(o[1]) < 1 then
      return o[2]
    end
  end
  if e.invocados_feitos < #C.invocados then return "Invoque os 4 heróis de outro mundo" end
  if not J.party_final() then return "Forme uma party com os 4 invocados" end
  if not J.pode_final() then return "Fortaleça os invocados até " .. util.formatar(C.sss.poder) .. " de poder" end
  return "Envie a party para a missão SSS!"
end

-- Ciclo ----------------------------------------------------------------------------------------------

function J.iniciar()
  J.pronto = false
  J.estado = estado_inicial()
  J.pessoas = {}
  J.garcons = {}
  J.lugares = {}
  J.efeitos = {}
  J.aviso = nil
  J.offline = nil
  J.buff = 0
  J.MAX_PESSOAS = 60
  J.relogio_chegada = 2
  J.relogio_aventureiro = 5
  J.relogio_segundo = 0
  J.ganho_segundo = 0
  J.relogio_salvar = 0
  J.fofoca_conta = 0
  J.sem_caminho, J.socorros, J.relogio_preso = 0, 0, 0
  J.noticia, J.banner, J.travados, J.media_travados = nil, nil, 0, 0
  J.espera_porta = 0
  L.carregar()
  if not J.em_menu then J.carregar() end
  recalcular()
  J.reconstruir_lugares()
  J.ajustar_equipe()
  J.calcular_offline()
  J.aplicar_layout()
  J.pronto = true
end

-- Colisão entre bonecos, e socorro para quem ficar preso muito tempo
local function atualizar_colisoes(dt)
  local lista = {}
  for _, p in ipairs(J.pessoas) do lista[#lista + 1] = p end
  for _, g in ipairs(J.garcons) do lista[#lista + 1] = g end
  Cam.separar(lista, dt)
  J.relogio_preso = (J.relogio_preso or 0) + dt
  if J.relogio_preso < 1 then return end
  J.relogio_preso = 0
  -- medidor: gente que queria andar e não conseguiu no último segundo
  local travados = 0
  for _, p in ipairs(lista) do
    if p.andando and p.rota and #p.rota > 0 and (p.preso or 0) >= 1 then travados = travados + 1 end
  end
  J.travados = travados
  J.media_travados = (J.media_travados or 0) * 0.95 + travados * 0.05
  for _, p in ipairs(lista) do
    if p.andando and p.rota and #p.rota > 0 and not p.sentado then
      -- mede a partir de um ponto fixo: quem só treme no lugar, empurrado pelos outros, também está preso
      local dx, dz = p.x - (p.ult_x or 1e9), p.z - (p.ult_z or 1e9)
      if dx * dx + dz * dz < 0.36 then
        p.preso = (p.preso or 0) + 1
        if p.preso == 3 and p.destino_x then
          J.caminho(p, p.destino_x, p.destino_z)
          p.preso = 3
        elseif p.preso >= 8 then
          p.fantasma = true
          J.socorros = (J.socorros or 0) + 1
        end
      else
        p.preso = 0
        p.ult_x, p.ult_z = p.x, p.z
        if not p.sem_rota and not p.vao then p.fantasma = nil end
      end
    end
  end
end

function J.atualizar(dt)
  local e = J.estado
  if J.offline or J.editando then return end
  -- notícia na tela: tudo espera o jogador ler
  if J.noticia then return end
  -- depois do final o mundo para: nada de ouro, sons ou tempo correndo atrás da tela final
  if e.fim then
    J.aviso, J.efeitos = nil, {}
    return
  end
  e.tempo = e.tempo + dt

  if not e.fim then
    J.relogio_chegada = math.min(J.relogio_chegada + dt, J.intervalo_chegada())
    if J.relogio_chegada >= J.intervalo_chegada() then
      -- a porta pode segurar a chegada por alguns segundos, nunca para sempre
      if J.novo_cliente() then J.relogio_chegada, J.espera_porta = 0, 0
      elseif J.porta_lotada() then J.espera_porta = (J.espera_porta or 0) + dt end
    end
  end

  for _, p in ipairs(J.pessoas) do atualizar_pessoa(p, dt) end
  for i = #J.pessoas, 1, -1 do
    if J.pessoas[i].removido then table.remove(J.pessoas, i) end
  end
  for _, g in ipairs(J.garcons) do atualizar_garcom(g, dt) end
  atualizar_colisoes(dt)
  J.relogio_noticia = (J.relogio_noticia or 0) + dt
  if J.relogio_noticia >= 0.5 then
    J.relogio_noticia = 0
    J.procurar_noticia()
  end
  if J.banner then
    J.banner.vida = J.banner.vida + dt
    if J.banner.vida >= J.banner.duracao then J.banner = nil end
  end
  atualizar_missoes(dt)
  atualizar_jardim(dt)

  local passiva = J.renda_passiva()
  if passiva > 0 then J.ganhar(passiva * dt) end
  if J.buff > 0 then J.buff = J.buff - dt end

  if e.final_resta then
    e.final_resta = e.final_resta - dt
    if e.final_resta <= 0 then
      e.final_resta = nil
      e.fim = true
      J.noticia = nil
      for _, c in ipairs(e.contratados) do c.na_final = nil end
      J.som("invocar")
      J.salvar()
    end
  end

  for i = #J.efeitos, 1, -1 do
    local f = J.efeitos[i]
    f.vida = f.vida + dt
    if f.vida >= 1.1 then table.remove(J.efeitos, i) end
  end
  if J.aviso then
    J.aviso.vida = J.aviso.vida + dt
    if J.aviso.vida >= J.aviso.duracao then J.aviso = nil end
  end

  J.relogio_segundo = J.relogio_segundo + dt
  if J.relogio_segundo >= 1 then
    e.rps = e.rps * 0.85 + J.ganho_segundo * 0.15
    J.ganho_segundo = 0
    J.relogio_segundo = J.relogio_segundo - 1
  end

  J.relogio_salvar = J.relogio_salvar + dt
  if J.relogio_salvar >= C.salvar_a_cada then
    J.relogio_salvar = 0
    J.salvar()
  end
end

-- Salvar e carregar ------------------------------------------------------------------------------------

function J.salvar()
  if J.em_menu then return end   -- a taverna atrás da tela inicial não é progresso de ninguém
  -- se o início falhou, o estado está vazio: gravar agora apagaria o progresso de verdade
  if not J.pronto then return end
  -- quem sai sem coletar não perde o ganho do tempo fora
  if J.offline then J.coletar_offline() end
  local e = J.estado
  e.salvo_em = os.time()
  motor.salvar(util.serializar(e))
end

local function copiar_sobre(destino, origem)
  for k, v in pairs(origem) do
    if type(v) == "table" and type(destino[k]) == "table" then copiar_sobre(destino[k], v)
    elseif destino[k] == nil or type(destino[k]) == type(v) then destino[k] = v end
  end
end

-- números inválidos em um save danificado não podem travar o jogo
local limpar_contratados

local function saneado(v, padrao)
  if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return padrao end
  return v
end

-- contratado estragado sai do save; party incompleta é desfeita (sem isso, os membros nunca mais saem em missão)
local TIPOS_CONTRATADO = { guerreiro = true, mago = true, arqueiro = true, clerigo = true }

function limpar_contratados(e)
  local maior = 0
  for i = #e.contratados, 1, -1 do
    local c = e.contratados[i]
    if type(c) ~= "table" or not saneado(c.id, nil) or not TIPOS_CONTRATADO[c.tipo] then
      table.remove(e.contratados, i)
    else
      maior = math.max(maior, c.id)
      if type(c.nome) ~= "string" then c.nome = "Aventureiro" end
      if type(c.titulo) ~= "string" then c.titulo = c.invocado and "Herói" or nil end
      if type(c.pele) ~= "string" then c.pele = PELES[1] end
      for _, k in ipairs({ "armadura", "arma", "magia", "fama", "missoes" }) do c[k] = math.max(0, saneado(c[k], 0)) end
    end
  end
  local por_id, em_party = {}, {}
  for _, c in ipairs(e.contratados) do por_id[c.id] = c; c.party = nil end
  for i = #e.parties, 1, -1 do
    local p = e.parties[i]
    local boa = type(p) == "table" and saneado(p.id, nil) and type(p.membros) == "table" and #p.membros == 4
    if boa then
      for _, id in ipairs(p.membros) do
        if not por_id[id] or em_party[id] then boa = false end
      end
    end
    if boa then
      maior = math.max(maior, p.id)
      for _, id in ipairs(p.membros) do em_party[id] = true; por_id[id].party = p.id end
    else
      table.remove(e.parties, i)
    end
  end
  e.prox_id = math.max(math.floor(e.prox_id), maior + 1)
end

function J.carregar()
  local dados = util.desserializar(motor.carregar())
  if type(dados) ~= "table" or dados.versao ~= 2 then return end
  local e = estado_inicial()
  copiar_sobre(e, dados)
  e.ouro = math.max(0, saneado(e.ouro, 0))
  e.total = math.max(0, saneado(e.total, 0))
  e.rps = math.max(0, saneado(e.rps, 0))
  e.fama = math.max(0, saneado(e.fama, 0))
  e.estoque = math.max(0, saneado(e.estoque, 0))
  for k, v in pairs(estado_inicial()) do
    if type(v) == "number" then e[k] = saneado(e[k], v) end
  end
  e.salvo_em = saneado(e.salvo_em, nil)
  e.final_resta = saneado(e.final_resta, nil)
  if e.fim then e.final_resta = nil end
  if e.final_resta then e.final_resta = util.limitar(e.final_resta, 0, C.sss.duracao) end
  e.invocados_feitos = util.limitar(math.floor(e.invocados_feitos), 0, #C.invocados)
  for r, n in pairs(e.feitas_rank) do
    if type(n) ~= "number" then e.feitas_rank[r] = nil end
  end
  -- ignora nós que não existem mais e níveis acima do máximo
  for id, nv in pairs(e.nos) do
    local no = A.POR_ID[id]
    nv = saneado(nv, 0)
    if not no or nv < 1 then e.nos[id] = nil
    else e.nos[id] = math.min(math.floor(nv), no.max) end
  end
  limpar_contratados(e)
  -- ninguém fica preso em uma missão que sumiu do save
  local em, ids = {}, {}
  for _, c in ipairs(e.contratados) do ids[c.id] = true end
  for i = #e.missoes, 1, -1 do
    local m = e.missoes[i]
    if type(m) ~= "table" or not (C.ranks[m.rank]) or (m.contratado and not ids[m.contratado]) then table.remove(e.missoes, i)
    else
      m.resta = util.limitar(saneado(m.resta, 1), 0, C.ranks[m.rank].duracao)
      if m.contratado then em[m.contratado] = true end
    end
  end
  for _, c in ipairs(e.contratados) do
    c.em_missao = em[c.id] or nil
    if not e.final_resta then c.na_final = nil end
  end
  J.estado = e
  -- save de antes das notícias: o que já dava para comprar não vira uma fila de janelas
  if type(dados.noticias) ~= "table" then
    for _, n in ipairs(J.NOTICIAS) do
      local no = A.POR_ID[n.id]
      if J.nivel(n.id) == 0 and J.no_liberado(no) and e.ouro >= J.custo_no(no) then e.noticias[n.id] = true end
    end
  end
end

function J.calcular_offline()
  local e = J.estado
  if not e.salvo_em or J.ef("garcons") < 1 or e.fim then return end
  local fora = os.time() - e.salvo_em
  if fora < C.offline_minimo then return end
  local s = math.min(fora, C.offline_maximo)
  local ganho = math.floor(e.rps * s * C.offline_eficiencia)
  -- as missões em andamento também avançam
  for _, m in ipairs(e.missoes) do m.resta = math.max(0, m.resta - s) end
  if e.final_resta then e.final_resta = math.max(1, e.final_resta - s) end
  if ganho >= 1 then J.offline = { ganho = ganho, segundos = fora } end
end

-- O celular congela o jogo em segundo plano: ao voltar, o tempo parado conta como tempo fora.
function J.ao_voltar()
  if J.em_menu or J.editando or J.offline or not J.pronto then return end
  J.calcular_offline()
end

function J.coletar_offline()
  if not J.offline then return end
  -- entra de uma vez, mas não conta como renda por segundo: senão o próximo tempo fora rende muito mais
  local g = J.offline.ganho
  J.ganhar(g)
  J.ganho_segundo = J.ganho_segundo - g
  J.offline = nil
end

function J.apagar_progresso()
  motor.salvar("")
  J.estado = nil
  J.pessoas, J.lugares = {}, nil
  J.iniciar()
end

return J
