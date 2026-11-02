-- =============================================================================
--  TAVERNA DE AVENTUREIROS
--
--  Este é o ponto de entrada do jogo. O motor (C++) chama estas funções:
--    iniciar(), atualizar(dt), desenhar(), tocar(x, y) e ao_sair()
--
--  Organização dos scripts:
--    config.lua     números do balanceamento (preços, tempos, bônus)
--    taverna.lua    regras: heróis, mesas, ouro, melhorias, garçonete
--    desenho.lua    desenho do salão e dos personagens
--    interface.lua  placar, cartas de melhoria, avisos
--    util.lua       funções de apoio (formatar números, salvar...)
-- =============================================================================

local taverna = require("taverna")
local desenho = require("desenho")
local interface = require("interface")

function iniciar()
  math.randomseed(os.time())
  taverna.iniciar()
  interface.iniciar()
end

function atualizar(dt)
  taverna.atualizar(dt)
  interface.atualizar(dt)
end

function desenhar()
  desenho.salao()
  interface.desenhar()
end

function tocar(x, y)
  if taverna.offline then
    taverna.coletar_offline()
    return
  end
  if interface.tocar(x, y) then return end
  taverna.tocar_salao(x, y)
end

function ao_sair()
  taverna.salvar()
end
