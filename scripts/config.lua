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
C.colheita = 3                 -- unidades por canteiro em cada colheita
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
