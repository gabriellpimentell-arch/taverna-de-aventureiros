-- =============================================================================
--  TAVERNA DE AVENTUREIROS
--
--  O motor (C++) chama: iniciar(), atualizar(dt), desenhar(), tocar(x, y),
--  soltar(x, y), tecla_esc(), tecla_f2() e ao_sair().
--
--    config.lua   números do balanceamento
--    arvore.lua   árvore de habilidades
--    jogo.lua     regras (não desenha nada)
--    mundo.lua    taverna em 3D
--    ui.lua       botões, textos e ícones
--    telas.lua    HUD, abas e menus
--    layout.lua   posições dos objetos (modo de edição)
--    caminhos.lua rotas e colisões
--    editor.lua   modo de edição
--    util.lua     funções de apoio
-- =============================================================================

local jogo = require("jogo")
local telas = require("telas")

function iniciar()
  math.randomseed(os.time())
  jogo.tocar_som = motor.som
  jogo.iniciar()
  telas.iniciar()
end

function atualizar(dt)
  jogo.atualizar(dt)
  telas.atualizar(dt)
end

function desenhar() telas.desenhar() end
function tocar(x, y) telas.tocar(x, y) end
function soltar(x, y) telas.soltar(x, y) end
function tecla_esc() telas.esc() end
function tecla_f2() telas.f2() end
function ao_sair() jogo.salvar() end
