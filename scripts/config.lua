-- =============================================================================
--  BALANCEAMENTO
--
--  Todos os números que definem o ritmo do jogo ficam aqui.
--  Mude um valor, salve o arquivo e o jogo recarrega na hora.
-- =============================================================================

local config = {}

-- Pedidos --------------------------------------------------------------------
config.pedido_base   = 3     -- ouro que um herói paga por pedido, no início
config.bonus_rapido  = 1.5   -- multiplicador se o herói for servido logo
config.tempo_rapido  = 2.5   -- segundos para contar como "servido rápido"
config.paciencia     = 15    -- segundos que o herói espera antes de desistir
config.tempo_comendo = 4     -- segundos comendo/bebendo antes de ir embora

-- Chegada de heróis ----------------------------------------------------------
config.intervalo_chegada = 3.5   -- segundos entre a chegada de dois heróis
config.velocidade_heroi  = 220   -- pixels por segundo andando

-- Melhorias ------------------------------------------------------------------
-- custo do nível N = custo * multiplicador ^ N
config.melhorias = {
  mesa = {
    nome = "Nova mesa",
    descricao = "+2 lugares para heróis",
    custo = 20, multiplicador = 2.2,
    maximo = 5,                 -- a taverna começa com 1 mesa (máximo 6)
  },
  cardapio = {
    nome = "Cardápio",
    descricao = "Pedidos rendem +40%",
    custo = 15, multiplicador = 1.75,
    efeito = 1.4,               -- cada nível multiplica o valor do pedido
  },
  placa = {
    nome = "Placa na estrada",
    descricao = "Heróis chegam 15% mais rápido",
    custo = 25, multiplicador = 1.9,
    efeito = 0.85,              -- cada nível multiplica o intervalo de chegada
    maximo = 12,
  },
  garconete = {
    nome = "Garçonete",
    descricao = "Serve os heróis sozinha",
    descricao_nivel = "Serve 20% mais rápido",
    custo = 120, multiplicador = 2.2,
    desbloqueio_mesas = 3,      -- aparece quando a taverna tiver 3 mesas
    intervalo = 4.0,            -- segundos entre um atendimento e outro
    efeito = 0.8,               -- cada nível multiplica esse intervalo
    velocidade = 300,
    maximo = 10,
  },
}

-- Progresso enquanto o jogo está fechado --------------------------------------
config.offline_eficiencia = 0.5        -- ganha 50% do ritmo normal
config.offline_maximo     = 8 * 3600   -- no máximo 8 horas
config.offline_minimo     = 60         -- só conta se ficou fora 1 minuto ou mais

config.salvar_a_cada = 20              -- segundos entre salvamentos automáticos

return config
