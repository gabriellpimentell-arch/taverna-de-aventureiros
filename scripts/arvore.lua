-- =============================================================================
--  ÁRVORE DE HABILIDADES
--
--  Cada nó: pai (precisa ter ao menos 1 nível), custo, mult (custo por nível),
--  max (níveis), ef (efeitos por nível), p (profundidade no ramo), l (lado).
--  Efeitos "x_*" multiplicam a cada nível; os demais somam.
-- =============================================================================

local A = {}

A.RAMOS = {
  salao    = { nome = "Salão",            cor = "#c98a4e", angulo = 180 },
  servico  = { nome = "Serviço",          cor = "#57b0c2", angulo = 128 },
  bebidas  = { nome = "Produção",         cor = "#7cc56a", angulo = 77 },
  guilda   = { nome = "Guilda",           cor = "#d9685a", angulo = 26 },
  mercado  = { nome = "Mercadinho",       cor = "#c97bc2", angulo = -26 },
  herois   = { nome = "Heróis",           cor = "#7f8fe6", angulo = -77 },
  clientes = { nome = "Clientes",         cor = "#e0b04a", angulo = -128 },
}

-- arvore: a que árvore o nó pertence ("principal"; na Parte 3 entram as dos ambientes).
-- Revelação: o nó aparece quando TODOS os pré-requisitos (pai e req) foram comprados. Não há
-- estado salvo para isso: tudo sai das compras, então save antigo vê de imediato o que já tem.
-- em_breve: lugar reservado na sequência; aparece como "?" e ainda não pode ser comprado.
local n = {
  -- SALÃO -----------------------------------------------------------------------
  { id = "mesa", ramo = "salao", p = 1, l = 0, nome = "Mesas", desc = "A Loja passa a vender mesas: cada uma traz 2 lugares", custo = 20, mult = 1, max = 1, ef = {} },
  { id = "balcao", pai = "mesa", ramo = "salao", p = 2, l = 1, nome = "Bancos no balcão", desc = "+4 lugares no balcão", custo = 90, mult = 1, max = 1, ef = { balcao = 1 } },
  { id = "mestre_obras", pai = "mesa", ramo = "salao", p = 2, l = -1, nome = "Mestre de Obras", desc = "Libera aumentar e diminuir a taverna e as salas na Loja", custo = 35, mult = 1, max = 1, ef = { a_obras = 1 } },
  { id = "ricos", pai = "balcao", ramo = "salao", p = 3, l = 2, nome = "Clientes ricos", desc = "Pedidos rendem +20%", custo = 4000, mult = 3.5, max = 8, ef = { x_pedido = 1.2 } },
  { id = "segundo_andar", pai = "balcao", ramo = "salao", p = 3, l = 0, nome = "Segundo andar", desc = "Abre o segundo andar, com escada e um hall para novas salas", custo = 1000, mult = 1, max = 1, ef = { a_segundo_andar = 1 } },
  { id = "quartos", pai = "segundo_andar", ramo = "salao", p = 4, l = 1, nome = "Quartos", desc = "A ala de quartos vai para a Loja: +6 ouro por segundo, e mais quartos à venda", custo = 1500, mult = 1, max = 1, ef = { a_quartos = 1, renda_quartos = 6 } },
  { id = "sala_guilda", pai = "segundo_andar", req = "prateleira", ramo = "salao", p = 4, l = -1, nome = "Sala da guilda", desc = "Vai para a Loja: o gerente sobe e vira chefe da guilda", custo = 6000, mult = 1, max = 1, ef = { a_guilda = 1 } },
  { id = "subsolo", pai = "segundo_andar", ramo = "salao", p = 4, l = 0, nome = "Subsolo", desc = "Abre o subsolo: um andar de pedra para mudar salas de lugar", custo = 150000, mult = 1, max = 1, ef = { a_subsolo = 1 } },
  { id = "avaliacao", pai = "sala_guilda", ramo = "salao", p = 5, l = -1, nome = "Área de avaliação", desc = "Arena onde os contratados tentam subir de rank", custo = 500000, mult = 1, max = 1, ef = { a_avaliacao = 1 }, em_breve = true },

  -- CLIENTES -----------------------------------------------------------------------
  { id = "placa", ramo = "clientes", p = 1, l = 1, nome = "Placa na estrada", desc = "Clientes chegam 15% mais rápido", custo = 25, mult = 1.9, max = 10, ef = { x_chegada = 0.85 } },
  { id = "lareira", pai = "placa", ramo = "clientes", p = 2, l = 1, nome = "Lareira acesa", desc = "Clientes esperam +3 s", custo = 70, mult = 2, max = 5, ef = { paciencia = 3 } },
  { id = "fama_local", pai = "placa", ramo = "clientes", p = 2, l = 0, nome = "Fama no vilarejo", desc = "Pedidos rendem +15%", custo = 300, mult = 2.6, max = 6, ef = { x_pedido = 1.15 } },
  { id = "festa", pai = "fama_local", req = "prateleira", ramo = "clientes", p = 3, l = 0, nome = "Noite de festa", desc = "Quem volta de missão gasta +50%", custo = 12000, mult = 3, max = 5, ef = { festa = 0.5 } },
  { id = "conforto", pai = "cardapio", ramo = "clientes", p = 2, l = -1, nome = "Cadeiras confortáveis", desc = "Pedidos rendem +10%", custo = 150, mult = 2.4, max = 6, ef = { x_pedido = 1.1 } },
  { id = "decoracao", pai = "conforto", ramo = "clientes", p = 3, l = -1, nome = "Decoração", desc = "Pedidos rendem +15%", custo = 2500, mult = 3.4, max = 6, ef = { x_pedido = 1.15 } },
  { id = "ala_leste", pai = "decoracao", ramo = "clientes", p = 4, l = -1, nome = "Ala leste", desc = "Abre uma ala nova e +2 mesas", custo = 60000, mult = 1, max = 1, ef = { a_leste = 1, mesas = 2 } },

  -- SERVIÇO --------------------------------------------------------------------------
  { id = "garcom", pai = "mesa", ramo = "servico", p = 1, l = 0, custo = 60, mult = 1, max = 1, nome = "Garçom", desc = "A Loja passa a vender garçons, que servem sozinhos", ef = {} },
  { id = "agilidade", pai = "garcom", ramo = "servico", p = 2, l = 1, nome = "Treino da equipe", desc = "Garçons servem 15% mais rápido", custo = 350, mult = 2.2, max = 10, ef = { x_garcom = 0.85 } },
  { id = "bardo", pai = "garcom", ramo = "servico", p = 2, l = -1, nome = "Bardo", desc = "A música faz os pedidos renderem +15%", custo = 3000, mult = 3.2, max = 5, ef = { x_pedido = 1.15, bardo = 1 } },
  { id = "cozinha", pai = "garcom", ramo = "servico", p = 3, l = 0, nome = "Cozinha", desc = "Vai para a Loja. Faz pão na própria taverna: a comida custa bem menos", custo = 300, mult = 1, max = 1, ef = { a_cozinha = 1 } },
  { id = "moco", pai = "cozinha", ramo = "servico", p = 4, l = 1, nome = "Moço de cozinha", desc = "Traz a comida até o balcão: garçons 15% mais rápidos", custo = 500, mult = 1, max = 1, ef = { moco = 1, x_garcom = 0.85 } },
  { id = "cozinheiro", pai = "cozinha", req = "jardim", ramo = "servico", p = 4, l = -1, nome = "Cozinheiro", desc = "Usa o que você colhe: comida rende bem mais", custo = 8000, mult = 4, max = 6, ef = { cozinheiro = 1 } },

  -- BEBIDAS E COMIDA ---------------------------------------------------------------------
  { id = "cardapio", ramo = "clientes", p = 1, l = -1, nome = "Cardápio", desc = "Pedidos rendem +30%", custo = 15, mult = 2.15, max = 20, ef = { x_pedido = 1.3 } },
  { id = "fornecedor", pai = "cardapio", ramo = "clientes", p = 2, l = -2, nome = "Fornecedor fixo", desc = "Encomenda sozinho o que acabar, pelo dobro do preço da carroça", custo = 400, mult = 1, max = 1, ef = { fornecedor = 1 } },
  { id = "cervejaria", pai = "cozinha", ramo = "bebidas", p = 3, l = 0, nome = "Cervejaria", desc = "Vai para a Loja. Faz a própria cerveja: a bebida custa bem menos", custo = 1200, mult = 1, max = 1, ef = { a_cerveja = 1, bebida_casa = 1 } },
  { id = "cerveja_melhor", pai = "cervejaria", ramo = "bebidas", p = 4, l = 1, nome = "Receita da casa", desc = "A bebida feita em casa rende mais", custo = 6000, mult = 5, max = 5, ef = { bebida_casa = 1 } },
  { id = "especiais", pai = "cervejaria", ramo = "bebidas", p = 4, l = 2, nome = "Pratos especiais", desc = "Pedidos rendem +25%", custo = 2000000, mult = 4, max = 8, ef = { x_pedido = 1.25 } },
  { id = "jardim", pai = "cervejaria", ramo = "bebidas", p = 4, l = -1, nome = "Fazenda de sementes", desc = "Vai para a Loja. Planta trigo e lúpulo, que viram comida e bebida da casa", custo = 5000, mult = 1, max = 1, ef = { a_jardim = 1, canteiros = 2 } },
  { id = "canteiro", pai = "jardim", ramo = "bebidas", p = 5, l = 0, nome = "Mais canteiros", desc = "A Loja passa a vender canteiros", custo = 1000, mult = 1, max = 1, ef = {} },
  { id = "adubo", pai = "canteiro", ramo = "bebidas", p = 6, l = 0, nome = "Adubo", desc = "Colheitas rendem +30%", custo = 5000, mult = 3.2, max = 8, ef = { x_colheita = 1.3 } },
  { id = "fazendeiro", pai = "canteiro", ramo = "bebidas", p = 6, l = 1, nome = "Fazendeiro", desc = "Cuida da fazenda de sementes: colheitas rendem +25%", custo = 4000, mult = 3.2, max = 6, ef = { fazendeiro = 1, x_colheita = 1.25 } },
  { id = "irrigacao", pai = "adubo", ramo = "bebidas", p = 7, l = 0, nome = "Irrigação", desc = "As plantas crescem 15% mais rápido", custo = 16000, mult = 3, max = 6, ef = { x_ciclo = 0.85 } },
  { id = "pomar", pai = "jardim", ramo = "bebidas", p = 5, l = -2, nome = "Fazenda de árvores frutíferas", desc = "Vai para a Loja, com mais árvores à venda. Frutas para tortas e sucos: pedidos +10%", custo = 30000, mult = 1, max = 1, ef = { a_pomar = 1, frutas = 1, x_pedido = 1.1 } },
  { id = "fazenda", pai = "pomar", ramo = "bebidas", p = 6, l = -2, nome = "Fazenda de animais", desc = "Vai para a Loja, com vacas, porcos e galinhas à venda. Carne e ovos: +60 ouro por segundo e pedidos +15%", custo = 350000, mult = 1, max = 1, ef = { a_fazenda = 1, vacas = 1, renda_fazenda = 60, x_pedido = 1.15 } },

  -- GUILDA -----------------------------------------------------------------------------------
  { id = "prateleira", pai = "jardim", ramo = "guilda", p = 3, l = 0, nome = "Mural de missões", desc = "Vai para a Loja. Aventureiros pegam missões rank F", custo = 2500, mult = 1, max = 1, ef = { prateleira = 1, rank_max = 1 } },
  { id = "vagas", pai = "prateleira", ramo = "guilda", p = 4, l = 1, nome = "Mais missões", desc = "+1 missão ao mesmo tempo", custo = 800, mult = 2.1, max = 14, ef = { vagas = 1 } },
  { id = "rapidas", pai = "vagas", ramo = "guilda", p = 5, l = 1, nome = "Rotas conhecidas", desc = "Missões duram 10% menos", custo = 7000, mult = 2.6, max = 6, ef = { x_duracao = 0.9 } },
  { id = "comissao", pai = "vagas", ramo = "guilda", p = 5, l = 2, nome = "Melhor comissão", desc = "Missões pagam +20%", custo = 5000, mult = 3.2, max = 12, ef = { x_missao = 1.2 } },
  { id = "rank_e", pai = "prateleira", ramo = "guilda", p = 4, l = -1, nome = "Missões rank E", desc = "Abre o rank E", custo = 2000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_d", pai = "rank_e", ramo = "guilda", p = 5, l = -1, nome = "Missões rank D", desc = "Abre o rank D", custo = 15000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_c", pai = "rank_d", ramo = "guilda", p = 6, l = -1, nome = "Missões rank C", desc = "Abre o rank C", custo = 120000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_b", pai = "rank_c", ramo = "guilda", p = 7, l = -1, nome = "Missões rank B", desc = "Abre o rank B", custo = 1200000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_a", pai = "rank_b", ramo = "guilda", p = 8, l = -1, nome = "Missões rank A", desc = "Abre o rank A", custo = 15000000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_s", pai = "rank_a", ramo = "guilda", p = 9, l = -1, nome = "Missões rank S", desc = "Abre o rank S", custo = 100000000, mult = 1, max = 1, ef = { rank_max = 1 } },
  { id = "rank_ss", pai = "rank_s", ramo = "guilda", p = 10, l = -1, nome = "Missões rank SS", desc = "Abre o rank SS", custo = 1000000000, mult = 1, max = 1, ef = { rank_max = 1 } },

  -- MERCADINHO: cada rank novo de missões revela também o nível do mercadinho ---------------------
  { id = "mercadinho", pai = "prateleira", ramo = "mercado", p = 2, l = 0, nome = "Mercadinho", desc = "Vai para a Loja. Compra espólios do rank F", custo = 3000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_e", pai = "mercadinho", req = "rank_e", ramo = "mercado", p = 3, l = 1, nome = "Mercadinho rank E", desc = "Compra espólios até o rank E", custo = 6000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_d", pai = "merc_e", req = "rank_d", ramo = "mercado", p = 4, l = 1, nome = "Mercadinho rank D", desc = "Compra espólios até o rank D", custo = 50000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_c", pai = "merc_d", req = "rank_c", ramo = "mercado", p = 5, l = 1, nome = "Mercadinho rank C", desc = "Compra espólios até o rank C", custo = 400000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_b", pai = "merc_c", req = "rank_b", ramo = "mercado", p = 6, l = 1, nome = "Mercadinho rank B", desc = "Compra espólios até o rank B", custo = 4000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_a", pai = "merc_b", req = "rank_a", ramo = "mercado", p = 7, l = 1, nome = "Mercadinho rank A", desc = "Compra espólios até o rank A", custo = 50000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_s", pai = "merc_a", req = "rank_s", ramo = "mercado", p = 8, l = 1, nome = "Mercadinho rank S", desc = "Compra espólios até o rank S", custo = 200000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "merc_ss", pai = "merc_s", req = "rank_ss", ramo = "mercado", p = 9, l = 1, nome = "Mercadinho rank SS", desc = "Compra espólios até o rank SS", custo = 2000000000, mult = 1, max = 1, ef = { mercadinho = 1 } },
  { id = "negociar", pai = "mercadinho", ramo = "mercado", p = 3, l = -1, nome = "Negociação", desc = "Revenda de espólios rende +15%", custo = 15000, mult = 3.2, max = 10, ef = { x_espolio = 1.15 } },
  { id = "venda", pai = "negociar", ramo = "mercado", p = 4, l = -1, nome = "Aba de venda", desc = "Você passa a vender poções, armaduras e armas", custo = 700000, mult = 1, max = 1, ef = { venda = 1 } },
  { id = "pocoes", pai = "venda", ramo = "mercado", p = 5, l = -2, nome = "Poções", desc = "Vende poções: mais ouro por segundo", custo = 250000, mult = 2.2, max = 20, ef = { pocoes = 1 } },
  { id = "armaduras", pai = "venda", ramo = "mercado", p = 5, l = -1, nome = "Armaduras", desc = "Vende armaduras: mais ouro por segundo", custo = 5000000, mult = 2.2, max = 20, ef = { armaduras = 1 } },
  { id = "armas", pai = "armaduras", ramo = "mercado", p = 6, l = -1, nome = "Armas", desc = "Vende armas: mais ouro por segundo", custo = 100000000, mult = 2.2, max = 20, ef = { armas = 1 } },

  -- HERÓIS ------------------------------------------------------------------------------------------
  { id = "recrutador", pai = "rank_d", ramo = "herois", p = 2, l = 0, nome = "Recrutador", desc = "Abre a contratação de aventureiros", custo = 300000, mult = 1, max = 1, ef = { contratar = 1, vagas_contrato = 2 } },
  { id = "alojamento", pai = "recrutador", ramo = "herois", p = 3, l = -1, nome = "Alojamento", desc = "+2 vagas de contratados", custo = 1000000, mult = 3, max = 7, ef = { vagas_contrato = 2 } },
  { id = "party", pai = "recrutador", ramo = "herois", p = 3, l = 1, nome = "Parties", desc = "Junte 4 aventureiros em um grupo mais forte", custo = 3000000, mult = 1, max = 1, ef = { party = 1 } },
  { id = "heroi", pai = "party", ramo = "herois", p = 4, l = 1, nome = "Caminho do herói", desc = "Contratados de rank A podem virar heróis", custo = 40000000, mult = 1, max = 1, ef = { heroi = 1 } },
  { id = "propaganda", pai = "heroi", ramo = "herois", p = 5, l = 1, nome = "Propaganda", desc = "Abre a propaganda dos seus heróis", custo = 80000000, mult = 1, max = 1, ef = { propaganda = 1 } },
  { id = "cartazes", pai = "propaganda", ramo = "herois", p = 6, l = 0, nome = "Cartazes", desc = "Heróis ganham +50% de fama", custo = 300000000, mult = 3, max = 8, ef = { x_fama = 1.5 } },
  { id = "arautos", pai = "propaganda", ramo = "herois", p = 6, l = 2, nome = "Arautos do bardo", desc = "Heróis ganham o dobro de fama", custo = 500000000, mult = 3.5, max = 5, ef = { x_fama = 2 } },
  { id = "invocacao", pai = "propaganda", ramo = "herois", p = 7, l = 1, nome = "Círculo de invocação", desc = "Vai para a Loja. Invoca heróis de outro mundo", custo = 3000000000.0, mult = 1, max = 1, ef = { invocar = 1, a_circulo = 1 } },
  { id = "ritual", pai = "invocacao", ramo = "herois", p = 8, l = 1, nome = "Ritual aperfeiçoado", desc = "Invocados ficam 30% mais fortes", custo = 5000000000.0, mult = 3, max = 6, ef = { x_invocado = 1.3 } },
}

A.NOS = n
A.POR_ID = {}
for _, no in ipairs(n) do
  A.POR_ID[no.id] = no
  no.pre = {}
  if no.pai then no.pre[1] = no.pai end
  no.arvore = no.arvore or "principal"
  if no.req then no.pre[#no.pre + 1] = no.req end
end

-- filhos: quem cada compra pode revelar, na ordem da lista
for _, no in ipairs(n) do no.filhos = {} end
for _, no in ipairs(n) do
  for _, p in ipairs(no.pre) do
    local f = A.POR_ID[p].filhos
    f[#f + 1] = no.id
  end
end

-- Cada árvore que a tela sabe mostrar. A Parte 3 acrescenta aqui as dos ambientes (cozinha,
-- cervejaria, fazendas, invocação): a tela e as regras só usam nós, ramos e o centro da árvore.
A.ARVORES = { principal = { nome = "Principal", nos = n, ramos = A.RAMOS, ordem_ramos = { "clientes", "salao", "servico", "bebidas", "guilda", "mercado", "herois" } } }

-- posição na tela da árvore: cada ramo sai do centro em uma direção
for _, no in ipairs(n) do
  local a = math.rad(A.RAMOS[no.ramo].angulo)
  local dx, dy = math.cos(a), -math.sin(a)
  local d = 62 + no.p * 92
  no.x = dx * d + (-dy) * no.l * 58
  no.y = dy * d + dx * no.l * 58
end

return A
