-- =============================================================================
--  BALANCEAMENTO
--  Números gerais do jogo. Os custos da árvore ficam em arvore.lua.
--  Mude um valor, salve o arquivo e o jogo recarrega na hora.
-- =============================================================================

local C = {}

-- Pedidos ----------------------------------------------------------------------
C.pedido_base   = 3      -- ouro por pedido no início
C.bonus_aventureiro = 1.3
C.bonus_rapido  = 1.5    -- servir logo rende mais
C.tempo_rapido  = 2.5
C.paciencia     = 15
C.tempo_comendo = 4
C.intervalo_chegada = 3.5
C.velocidade_pessoa = 2.6

-- Começo endividado: comprar de fora custa uma parte do valor do pedido; produzir em casa custa menos
C.divida_inicial = 200
C.emprestimo = 40
C.juros_emprestimo = 1.25      -- quanto se deve por ouro emprestado
C.parcela_divida = 0.15        -- parte de cada ganho que vai direto para o agiota
C.lote_mantimentos = 10
C.fracao_comida = { comprada = 0.4, cozinha = 0.25, jardim = 0.1 }
C.fracao_bebida = { comprada = 0.3, cervejaria = 0.2, jardim = 0.05 }
C.fornecedor_mult = 2          -- encomenda automática (nó Fornecedor fixo): dobro do preço da carroça
C.socorro_cesta = 5            -- comida e bebida que Bartolo traz quando a carroça está longe

-- Carroça do comerciante: chega a cada `intervalo` segundos e fica `fica` segundos.
-- O jogo começa com ela já parada na estrada. `lote`: quanto cada botão leva; `lote2`: compra grande.
-- filhote: `unidade` é o item da Loja que ele vira. raro: só no fim do jogo, um pacote por visita.
C.carroca_intervalo = 300
C.carroca_fica = 90
C.carroca_desconto = 0.8       -- filhote custa esta parte do preço da Loja
C.carroca_desconto_tardio = 0.5
C.carroca_tardio = "rank_b"    -- nó a partir do qual vêm os raros e o desconto maior
C.raro_usos = 20               -- quantos pedidos cada pacote raro melhora
C.raro_bonus = 2               -- quanto rende o pedido feito com item raro
C.raro_preco = 0.5             -- preço de cada uso, em valor de pedido
C.carroca = {
  { id = "bebida", nome = "Bebidas", desc = "Abastece a despensa", tipo = "mantimento", mantimento = "bebida", lote = 10, lote2 = 50, modelo = "item_bebida" },
  { id = "carne", nome = "Carne", desc = "Abastece a despensa", tipo = "mantimento", mantimento = "comida", lote = 10, lote2 = 50, modelo = "item_carne" },
  { id = "semente_lupulo", nome = "Sementes de bebida", desc = "Lúpulo: colheita dobrada", tipo = "semente", semente = "lupulo", sala = "jardim", lote = 10, lote2 = 50, modelo = "item_semente_lupulo" },
  { id = "semente_fruta", nome = "Sementes de fruta", desc = "Frutas: colheita dobrada", tipo = "semente", semente = "fruta", sala = "pomar", lote = 10, lote2 = 50, modelo = "item_semente_fruta" },
  { id = "filhote_vaca", nome = "Filhote de vaca", desc = "Vai para a Fazenda de animais", tipo = "filhote", unidade = "vaca", modelo = "vaca" },
  { id = "filhote_porco", nome = "Filhote de porco", desc = "Vai para a Fazenda de animais", tipo = "filhote", unidade = "porco", modelo = "porco" },
  { id = "filhote_galinha", nome = "Pintinho", desc = "Vai para a Fazenda de animais", tipo = "filhote", unidade = "galinha", modelo = "galinha" },
  { id = "raro_especiaria", nome = "Especiarias raras", desc = "Os próximos pratos rendem o dobro", tipo = "raro", raro = "comida", modelo = "item_especiaria" },
  { id = "raro_hidromel", nome = "Hidromel raro", desc = "As próximas bebidas rendem o dobro", tipo = "raro", raro = "bebida", modelo = "item_hidromel" },
}

-- Loja e obras: preço do metro = base * (1 + cresce * metros já aumentados na construção toda)
C.obra_metro_base = 40
C.obra_metro_cresce = 0.02
C.obra_devolucao = 0.5         -- quanto volta do que foi pago por um metro, ao diminuir
C.preco_decoracao = { banco = 15, caixote = 20, planta = 25, barril = 30, vela = 40, quadro = 50, tapete = 60, estante = 80 }

-- Loja: a árvore libera a função uma vez; aqui mora o preço de cada unidade.
-- preço = custo * mult ^ (quantas já foram compradas). ef: o que cada unidade dá, como nos nós da árvore.
-- lugar = true: o jogador escolhe onde fica. limite: quantos bonecos ou objetos entram em cena
-- (acima dele a compra continua valendo, sem objeto novo; garçom fica mais rápido).
C.loja = {
  { id = "mesa", nome = "Mesa", no = "mesa", custo = 20, mult = 2.2, ef = { mesas = 1 }, lugar = true, modelo = "mesa" },
  { id = "garcom", nome = "Garçom", no = "garcom", custo = 120, mult = 2.2, ef = { garcons = 1 }, modelo = "garcom" },
  { id = "quartos", nome = "Quarto", no = "quartos", custo = 4200, mult = 2.8, ef = { renda_quartos = 6 }, modelo = "quarto" },
  { id = "canteiro", nome = "Canteiro", no = "canteiro", custo = 2500, mult = 2.6, ef = { canteiros = 1 }, modelo = "canteiro" },
  { id = "arvore", nome = "Árvore frutífera", no = "pomar", custo = 96000, mult = 2.6, ef = { frutas = 1, x_pedido = 1.1 }, lugar = true, modelo = "arvore" },
  { id = "vaca", nome = "Vaca", no = "fazenda", custo = 1190000, mult = 2.8, ef = { vacas = 1, renda_fazenda = 60, x_pedido = 1.15 }, lugar = true, modelo = "vaca" },
  -- um fazendeiro por fazenda: o primeiro entra em cena; os outros níveis só treinam o mesmo, até `max`
  { id = "fazendeiro", nome = "Fazendeiro das plantações", no = "fazendeiro", custo = 4000, mult = 3.2, max = 6, sala = "jardim", ef = { fazendeiro = 1, x_colheita = 1.25 }, modelo = "fazendeiro" },
  { id = "fazendeiro_arvores", nome = "Fazendeiro das árvores", no = "fazendeiro_arvores", custo = 25000, mult = 3.2, max = 6, sala = "pomar", ef = { fazendeiro_arvores = 1, x_frutas = 1.25 }, modelo = "fazendeiro_arvores" },
  { id = "fazendeiro_animais", nome = "Fazendeiro dos animais", no = "fazendeiro_animais", custo = 300000, mult = 3.2, max = 6, sala = "fazenda", ef = { fazendeiro_animais = 1, x_animais = 1.25 }, modelo = "fazendeiro_animais" },
  { id = "porco", nome = "Porco", no = "fazenda", custo = 500000, mult = 2.6, ef = { porcos = 1, renda_fazenda = 25, x_pedido = 1.03 }, lugar = true, modelo = "porco" },
  { id = "galinha", nome = "Galinha", no = "fazenda", custo = 150000, mult = 2.4, ef = { galinhas = 1, renda_fazenda = 8, x_pedido = 1.01 }, lugar = true, modelo = "galinha" },
}
C.limite_mesas = 40            -- objetos prontos em layout.lua: fora isso, o limite é o espaço
C.limite_arvores = 20
C.limite_vacas = 20
C.limite_porcos = 12
C.limite_galinhas = 16
C.limite_garcons = 40          -- bonecos em cena; medido com tests/medir.lua (ver docs/plano-obras.md)
C.garcom_extra_intervalo = 0.05   -- cada garçom acima do limite tira 5% da espera dos outros, somando
C.garcom_extra_velocidade = 0.02  -- e 2% de velocidade, até o dobro
C.m2_por_quarto = 3.5          -- quartos cabem na área da sala: ampliar dá lugar a mais

-- Equipe -------------------------------------------------------------------------
C.garcom_intervalo = 4.0
C.garcom_velocidade = 3.4

-- Missões: do F ao SS; SSS é a final. "poder" é o exigido dos contratados.
C.ranks = {
  { nome = "F",  duracao = 30,  pagamento = 30,     espolio = 40,     poder = 0 },
  { nome = "E",  duracao = 40,  pagamento = 130,    espolio = 170,    poder = 25 },
  { nome = "D",  duracao = 50,  pagamento = 560,    espolio = 740,    poder = 70 },
  { nome = "C",  duracao = 60,  pagamento = 2400,   espolio = 3200,   poder = 180 },
  { nome = "B",  duracao = 75,  pagamento = 10500,  espolio = 14000,  poder = 450 },
  { nome = "A",  duracao = 90,  pagamento = 46000,  espolio = 61000,  poder = 1100 },
  { nome = "S",  duracao = 110, pagamento = 200000, espolio = 265000, poder = 2800 },
  { nome = "SS", duracao = 130, pagamento = 880000, espolio = 1160000, poder = 7000 },
}
C.sss = { nome = "SSS", duracao = 300, poder = 12000, descricao = "Derrotar o Lorde Demônio" }

C.vagas_missao = 2             -- missões ao mesmo tempo logo que a prateleira abre
C.intervalo_aventureiro = 9    -- segundos entre aventureiros atrás de missão

-- Mercadinho ------------------------------------------------------------------------
C.margem_espolio = 0.12        -- lucro sobre cada espólio na revenda automática
C.margem_com_venda = 2         -- a aba de venda multiplica esse lucro

-- Aba de venda: ouro por segundo em cada nível
C.venda = {
  pocoes    = { nome = "Poções",    renda = 100 },
  armaduras = { nome = "Armaduras", renda = 3000 },
  armas     = { nome = "Armas",     renda = 60000 },
}

-- Jardim e produção ---------------------------------------------------------------------
C.ciclo_jardim = 20            -- segundos para colher
C.colheita = 3                 -- unidades por canteiro em cada colheita (metade trigo, metade lúpulo)
C.frutas_por_arvore = 2
C.carne_por_vaca = 1
C.carne_por_porco = 1.5
C.ovos_por_galinha = 1
C.semente_preco = 0.12         -- preço de cada semente, em valor de pedido
C.semente_bonus = 2            -- quanto rende o canteiro ou a árvore que recebeu semente
-- Cada ingrediente tem o próprio estoque. usa: que pedido ele atende; fazenda: quem produz.
C.estoques = {
  { id = "trigo", nome = "Trigo", usa = { comida = true }, fazenda = "jardim", modelo = "item_trigo" },
  { id = "lupulo", nome = "Lúpulo", usa = { bebida = true }, fazenda = "jardim", modelo = "item_lupulo" },
  { id = "frutas", nome = "Frutas", usa = { comida = true, bebida = true }, fazenda = "pomar", modelo = "item_fruta" },
  { id = "carne_vaca", nome = "Carne de vaca", usa = { comida = true }, fazenda = "fazenda", modelo = "item_carne" },
  { id = "carne_porco", nome = "Carne de porco", usa = { comida = true }, fazenda = "fazenda", modelo = "item_carne_porco" },
  { id = "ovos", nome = "Ovos", usa = { comida = true }, fazenda = "fazenda", modelo = "item_ovos" },
}
C.estoque_maximo = 300
C.bonus_cozinheiro = 1.6       -- comida feita com o que foi colhido rende mais
C.bonus_cozinheiro_nivel = 0.25
C.bonus_bebida_casa = 1.6
C.bonus_bebida_nivel = 0.25

-- Contratados ------------------------------------------------------------------------------
C.contratar_custo = 60000
C.contratar_mult = 4
C.investir = {
  armadura = { nome = "Armadura", custo = 8000, mult = 1.45, poder = 12 },
  arma     = { nome = "Arma",     custo = 10000, mult = 1.45, poder = 16 },
  magia    = { nome = "Magia",    custo = 13000, mult = 1.45, poder = 22 },
}
C.poder_inicial = 10
C.ganho_contratado = 2         -- pagamento em relação a um aventureiro comum
C.bonus_party = 1.5
C.ganho_heroi = 2
C.ganho_invocado = 4
C.promover_custo_mult = 8      -- custo de virar herói = pagamento do rank atual * isto
C.rank_para_heroi = 6          -- A

-- Invocação ------------------------------------------------------------------------------------
C.invocar_custo = 1.5e9
C.invocar_mult = 3
C.poder_invocado = 2200
C.invocados = {
  { nome = "Akira",  tipo = "guerreiro", titulo = "Espadachim" },
  { nome = "Yuki",   tipo = "mago",      titulo = "Maga" },
  { nome = "Ren",    tipo = "arqueiro",  titulo = "Arqueiro" },
  { nome = "Hana",   tipo = "clerigo",   titulo = "Sacerdotisa" },
}

-- Reputação: nível N exige reputacao_base * reputacao_mult ^ (N - 1)
C.reputacao_base = 20
C.reputacao_mult = 3
C.bonus_reputacao = 0.1        -- renda de missões por nível
C.fama_por_missao = 1          -- multiplicada pelo índice do rank

-- Eventos ---------------------------------------------------------------------------------------
C.briga_espera = 12            -- segundos até os brigões irem embora
C.briga_inicio = 2.5           -- segundos à mesa até a briga começar
C.briga_recompensa = 4         -- pedidos pagos por separar a briga
C.combo_mesa = 1.5             -- mago + clérigo na mesma mesa
C.fofoca_a_cada = 12           -- missões até o menestrel aparecer
C.fofoca_duracao = 60          -- segundos em que as missões rendem mais
C.menestrel_canta = 7         -- segundos contando a história
C.fofoca_bonus = 1.25

-- Fora do jogo -------------------------------------------------------------------------------------
C.offline_eficiencia = 0.5
C.offline_maximo = 8 * 3600
C.offline_minimo = 60
C.salvar_a_cada = 20

return C
