-- =============================================================================
--  ÁRVORE DE HABILIDADES
--
--  Cada nó: pai (precisa ter ao menos 1 nível), custo, mult (custo por nível),
--  max (níveis), ef (efeitos por nível), p (profundidade no ramo), l (lado).
--  Efeitos "x_*" multiplicam a cada nível; os demais somam.
-- =============================================================================

local A = {}

A.RAMOS = {
  salao    = { nome = "Salão",           cor = "#c98a4e", angulo = 180 },
  clientes = { nome = "Clientes",        cor = "#e0b04a", angulo = 128 },
  servico  = { nome = "Serviço",         cor = "#57b0c2", angulo = 77 },
  bebidas  = { nome = "Bebidas e comida", cor = "#7cc56a", angulo = 26 },
  guilda   = { nome = "Guilda",          cor = "#d9685a", angulo = -26 },
  mercado  = { nome = "Mercadinho",      cor = "#c97bc2", angulo = -77 },
  herois   = { nome = "Heróis",          cor = "#7f8fe6", angulo = -128 },
}

local n = {
  -- SALÃO -----------------------------------------------------------------------
  { id = "mesa", ramo = "salao", p = 1, l = 0, nome = "Nova mesa", desc = "+1 mesa (2 lugares)", custo = 20, mult = 2.2, max = 5, ef = { mesas = 1 } },
  { id = "balcao", pai = "mesa", ramo = "salao", p = 2, l = -1, nome = "Bancos no balcão", desc = "+4 lugares no balcão", custo = 90, mult = 1, max = 1, ef = { balcao = 1 } },
  { id = "conforto", pai = "mesa", ramo = "salao", p = 2, l = 1, nome = "Cadeiras confortáveis", desc = "Pedidos rendem +10%", custo = 150, mult = 2.4, max = 6, ef = { x_pedido = 1.1 } },
  { id = "quartos", pai = "balcao", ramo = "salao", p = 3, l = -1, nome = "Quartos", desc = "+6 ouro por segundo", custo = 1500, mult = 2.8, max = 10, ef = { renda_quartos = 6 } },
  { id = "segundo_andar", pai = "quartos", ramo = "salao", p = 4, l = -1, nome = "Segundo andar", desc = "Abre o segundo andar, com os quartos e a sala do chefe da guilda", custo = 12000, mult = 1, max = 1, ef = { a_segundo_andar = 1 } },
  { id = "subsolo", pai = "segundo_andar", ramo = "salao", p = 5, l = -1, nome = "Subsolo", desc = "Abre o subsolo: um andar de pedra para mudar salas de lugar", custo = 150000, mult = 1, max = 1, ef = { a_subsolo = 1 } },
  { id = "ala_leste", pai = "conforto", ramo = "salao", p = 3, l = 1, nome = "Ala leste", desc = "Abre uma ala nova e +2 mesas", custo = 60000, mult = 1, max = 1, ef = { a_leste = 1, mesas = 2 } },
  { id = "decoracao", pai = "ala_leste", ramo = "salao", p = 4, l = 1, nome = "Decoração", desc = "Pedidos rendem +15%", custo = 90000, mult = 3.4, max = 6, ef = { x_pedido = 1.15 } },

  -- CLIENTES -----------------------------------------------------------------------
  { id = "placa", ramo = "clientes", p = 1, l = 0, nome = "Placa na estrada", desc = "Clientes chegam 15% mais rápido", custo = 25, mult = 1.9, max = 10, ef = { x_chegada = 0.85 } },
  { id = "lareira", pai = "placa", ramo = "clientes", p = 2, l = -1, nome = "Lareira acesa", desc = "Clientes esperam +3 s", custo = 70, mult = 2, max = 5, ef = { paciencia = 3 } },
  { id = "fama_local", pai = "placa", ramo = "clientes", p = 2, l = 1, nome = "Fama no vilarejo", desc = "Pedidos rendem +15%", custo = 300, mult = 2.6, max = 6, ef = { x_pedido = 1.15 } },
  { id = "festa", pai = "fama_local", ramo = "clientes", p = 3, l = 1, nome = "Noite de festa", desc = "Quem volta de missão gasta +50%", custo = 12000, mult = 3, max = 5, ef = { festa = 0.5 } },
  { id = "ricos", pai = "lareira", ramo = "clientes", p = 3, l = -1, nome = "Clientes ricos", desc = "Pedidos rendem +20%", custo = 8000, mult = 3.5, max = 8, ef = { x_pedido = 1.2 } },

  -- SERVIÇO --------------------------------------------------------------------------
  { id = "garcom", ramo = "servico", p = 1, l = 0, custo = 120, mult = 3.4, max = 4, nome = "Garçom", desc = "+1 garçom que serve sozinho", ef = { garcons = 1 } },
  { id = "agilidade", pai = "garcom", ramo = "servico", p = 2, l = -1, nome = "Treino da equipe", desc = "Garçons servem 15% mais rápido", custo = 350, mult = 2.2, max = 10, ef = { x_garcom = 0.85 } },
  { id = "bardo", pai = "garcom", ramo = "servico", p = 2, l = 1, nome = "Bardo", desc = "A música faz os pedidos renderem +15%", custo = 3000, mult = 3.2, max = 5, ef = { x_pedido = 1.15, bardo = 1 } },
  { id = "cozinha", pai = "garcom", ramo = "servico", p = 2, l = -2, nome = "Cozinha", desc = "Faz pão na própria taverna: a comida custa bem menos", custo = 300, mult = 1, max = 1, ef = { a_cozinha = 1 } },
  { id = "moco", pai = "cozinha", ramo = "servico", p = 3, l = -3, nome = "Moço de cozinha", desc = "Traz a comida até o balcão: garçons 15% mais rápidos", custo = 500, mult = 1, max = 1, ef = { moco = 1, x_garcom = 0.85 } },
  { id = "cozinheiro", pai = "cozinha", req = "jardim", ramo = "servico", p = 3, l = -2, nome = "Cozinheiro", desc = "Usa o que você colhe: comida rende bem mais", custo = 8000, mult = 4, max = 6, ef = { cozinheiro = 1 } },

  -- BEBIDAS E COMIDA ---------------------------------------------------------------------
  { id = "fornecedor", pai = "cardapio", ramo = "bebidas", p = 2, l = 0, nome = "Fornecedor fixo", desc = "Compra comida e bebida sozinho quando acabam", custo = 40, mult = 1, max = 1, ef = { fornecedor = 1 } },
  { id = "cardapio", ramo = "bebidas", p = 1, l = 0, nome = "Cardápio", desc = "Pedidos rendem +30%", custo = 15, mult = 2.15, max = 20, ef = { x_pedido = 1.3 } },
  { id = "jardim", pai = "cardapio", req = "cervejaria", ramo = "bebidas", p = 2, l = -1, nome = "Jardim", desc = "Planta trigo e lúpulo: comida e bebida quase de graça", custo = 5000, mult = 1, max = 1, ef = { a_jardim = 1, canteiros = 2 } },
  { id = "fazendeiro", pai = "jardim", ramo = "bebidas", p = 3, l = -3, nome = "Fazendeiro", desc = "Cuida do jardim: colheitas rendem +25%", custo = 4000, mult = 3.2, max = 6, ef = { fazendeiro = 1, x_colheita = 1.25 } },
  { id = "pomar", pai = "jardim", ramo = "bebidas", p = 3, l = 0, nome = "Jardim de frutas", desc = "Frutas para tortas e sucos: colheitas +40% e pedidos +10%", custo = 30000, mult = 3.2, max = 6, ef = { a_pomar = 1, frutas = 1, x_colheita = 1.4, x_pedido = 1.1 } },
  { id = "fazenda", pai = "pomar", ramo = "bebidas", p = 4, l = 0, nome = "Fazenda", desc = "Vacas dão carne para pratos novos: +60 ouro por segundo e pedidos +15%", custo = 350000, mult = 3.4, max = 8, ef = { a_fazenda = 1, vacas = 1, renda_fazenda = 60, x_pedido = 1.15 } },
  { id = "canteiro", pai = "jardim", ramo = "bebidas", p = 3, l = -2, nome = "Mais canteiros", desc = "+1 canteiro", custo = 2500, mult = 3, max = 8, ef = { canteiros = 1 } },
  { id = "adubo", pai = "jardim", ramo = "bebidas", p = 3, l = -1, nome = "Adubo", desc = "Colheitas rendem +30%", custo = 5000, mult = 3.2, max = 8, ef = { x_colheita = 1.3 } },
  { id = "irrigacao", pai = "canteiro", ramo = "bebidas", p = 4, l = -2, nome = "Irrigação", desc = "As plantas crescem 15% mais rápido", custo = 16000, mult = 3, max = 6, ef = { x_ciclo = 0.85 } },
  { id = "cervejaria", pai = "cardapio", ramo = "bebidas", p = 2, l = 1, req = "cozinha", nome = "Cervejaria", desc = "Faz a própria cerveja: a bebida custa bem menos", custo = 1200, mult = 5, max = 6, ef = { a_cerveja = 1, bebida_casa = 1 } },
  { id = "especiais", pai = "cervejaria", ramo = "bebidas", p = 3, l = 1, nome = "Pratos especiais", desc = "Pedidos rendem +25%", custo = 2000000, mult = 4, max = 8, ef = { x_pedido = 1.25 } },

  -- GUILDA -----------------------------------------------------------------------------------
  { id = "prateleira", ramo = "guilda", p = 1, l = 0, nome = "Prateleira de missões", desc = "Aventureiros pegam missões rank F", custo = 2500, mult = 1, max = 1, ef = { prateleira = 1, rank_max = 1 } },
  { id = "vagas", pai = "prateleira", ramo = "guilda", p = 2, l = -1, nome = "Mais missões", desc = "+1 missão ao mesmo tempo", custo = 800, mult = 2.1, max = 14, ef = { vagas = 1 } },
  { id = "rapidas", pai = "vagas", ramo = "guilda", p = 3, l = -2, nome = "Rotas conhecidas", desc = "Missões duram 10% menos", custo = 7000, mult = 2.6, max = 6, ef = { x_duracao = 0.9 } },
  { id = "comissao", pai = "vagas", ramo = "guilda", p = 3, l = -1, nome = "Melhor comissão", desc = "Missões pagam +20%", custo = 5000, mult = 3.2, max = 12, ef = { x_missao = 1.2 } },
  { id = "rank_e", pai = "prateleira", ramo = "guilda", p = 2, l = 1, nome = "Missões rank E", desc = "Abre o rank E", custo = 2000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_d", pai = "rank_e", ramo = "guilda", p = 3, l = 1, nome = "Missões rank D", desc = "Abre o rank D", custo = 15000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_c", pai = "rank_d", ramo = "guilda", p = 4, l = 1, nome = "Missões rank C", desc = "Abre o rank C", custo = 120000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_b", pai = "rank_c", ramo = "guilda", p = 5, l = 1, nome = "Missões rank B", desc = "Abre o rank B", custo = 1200000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_a", pai = "rank_b", ramo = "guilda", p = 6, l = 1, nome = "Missões rank A", desc = "Abre o rank A", custo = 15000000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_s", pai = "rank_a", ramo = "guilda", p = 7, l = 1, nome = "Missões rank S", desc = "Abre o rank S", custo = 100000000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_ss", pai = "rank_s", ramo = "guilda", p = 8, l = 1, nome = "Missões rank SS", desc = "Abre o rank SS", custo = 1000000000, mult = 1, max = 1, ef = { rank_max = 1 } },

  -- MERCADINHO ----------------------------------------------------------------------------------
  { id = "mercadinho", pai = "@prateleira", ramo = "mercado", p = 1, l = 0, nome = "Mercadinho", desc = "Abre a área e compra espólios do rank F", custo = 3000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_e", pai = "mercadinho", ramo = "mercado", p = 2, l = 1, nome = "Mercadinho rank E", desc = "Compra espólios até o rank E", custo = 6000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_d", pai = "merc_e", ramo = "mercado", p = 3, l = 1, nome = "Mercadinho rank D", desc = "Compra espólios até o rank D", custo = 50000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_c", pai = "merc_d", ramo = "mercado", p = 4, l = 1, nome = "Mercadinho rank C", desc = "Compra espólios até o rank C", custo = 400000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_b", pai = "merc_c", ramo = "mercado", p = 5, l = 1, nome = "Mercadinho rank B", desc = "Compra espólios até o rank B", custo = 4000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_a", pai = "merc_b", ramo = "mercado", p = 6, l = 1, nome = "Mercadinho rank A", desc = "Compra espólios até o rank A", custo = 50000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_s", pai = "merc_a", ramo = "mercado", p = 7, l = 1, nome = "Mercadinho rank S", desc = "Compra espólios até o rank S", custo = 200000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_ss", pai = "merc_s", ramo = "mercado", p = 8, l = 1, nome = "Mercadinho rank SS", desc = "Compra espólios até o rank SS", custo = 2000000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "negociar", pai = "mercadinho", ramo = "mercado", p = 2, l = -1, nome = "Negociação", desc = "Revenda de espólios rende +15%", custo = 15000, mult = 3.2, max = 10, ef = { x_espolio = 1.15 } },
  { id = "venda", pai = "negociar", ramo = "mercado", p = 3, l = -1, nome = "Aba de venda", desc = "Você passa a vender poções, armaduras e armas", custo = 700000, mult = 1, max = 1, ef = { venda = 1 } },
  { id = "pocoes", pai = "venda", ramo = "mercado", p = 4, l = -2, nome = "Poções", desc = "Vende poções: mais ouro por segundo", custo = 250000, mult = 2.2, max = 20, ef = { pocoes = 1 } },
  { id = "armaduras", pai = "venda", ramo = "mercado", p = 4, l = -1, nome = "Armaduras", desc = "Vende armaduras: mais ouro por segundo", custo = 5000000, mult = 2.2, max = 20, ef = { armaduras = 1 } },
  { id = "armas", pai = "armaduras", ramo = "mercado", p = 5, l = -1, nome = "Armas", desc = "Vende armas: mais ouro por segundo", custo = 100000000, mult = 2.2, max = 20, ef = { armas = 1 } },

  -- HERÓIS ------------------------------------------------------------------------------------------
  { id = "recrutador", pai = "@rank_d", ramo = "herois", p = 1, l = 0, nome = "Recrutador", desc = "Abre a contratação de aventureiros", custo = 300000, mult = 1, max = 1, ef = { contratar = 1, vagas_contrato = 2 } },
  { id = "alojamento", pai = "recrutador", ramo = "herois", p = 2, l = -1, nome = "Alojamento", desc = "+2 vagas de contratados", custo = 1000000, mult = 3, max = 7, ef = { vagas_contrato = 2 } },
  { id = "party", pai = "recrutador", ramo = "herois", p = 2, l = 1, nome = "Parties", desc = "Junte 4 aventureiros em um grupo mais forte", custo = 3000000, mult = 1, max = 1, ef = { party = 1 } },
  { id = "heroi", pai = "party", ramo = "herois", p = 3, l = 1, nome = "Caminho do herói", desc = "Contratados de rank A podem virar heróis", custo = 40000000, mult = 1, max = 1, ef = { heroi = 1 } },
  { id = "propaganda", pai = "heroi", ramo = "herois", p = 4, l = 1, nome = "Propaganda", desc = "Abre a propaganda dos seus heróis", custo = 80000000, mult = 1, max = 1, ef = { propaganda = 1 } },
  { id = "cartazes", pai = "propaganda", ramo = "herois", p = 5, l = 0, nome = "Cartazes", desc = "Heróis ganham +50% de fama", custo = 300000000, mult = 3, max = 8, ef = { x_fama = 1.5 } },
  { id = "arautos", pai = "propaganda", ramo = "herois", p = 5, l = 2, nome = "Arautos do bardo", desc = "Heróis ganham o dobro de fama", custo = 500000000, mult = 3.5, max = 5, ef = { x_fama = 2 } },
  { id = "invocacao", pai = "propaganda", ramo = "herois", p = 6, l = 1, nome = "Círculo de invocação", desc = "Invoca heróis de outro mundo", custo = 3000000000.0, mult = 1, max = 1, ef = { invocar = 1, a_circulo = 1 } },
  { id = "ritual", pai = "invocacao", ramo = "herois", p = 7, l = 1, nome = "Ritual aperfeiçoado", desc = "Invocados ficam 30% mais fortes", custo = 5000000000.0, mult = 3, max = 6, ef = { x_invocado = 1.3 } },
}

A.NOS = n
A.POR_ID = {}
for _, no in ipairs(n) do
  A.POR_ID[no.id] = no
  no.pre = {}
  if no.pai then no.pre[1] = no.pai:gsub("^@", "") end
  if no.req then no.pre[#no.pre + 1] = no.req end
end

-- posição na tela da árvore: cada ramo sai do centro em uma direção
for _, no in ipairs(n) do
  local a = math.rad(A.RAMOS[no.ramo].angulo)
  local dx, dy = math.cos(a), -math.sin(a)
  local d = 62 + no.p * 92
  no.x = dx * d + (-dy) * no.l * 58
  no.y = dy * d + dx * no.l * 58
end

return A
