-- =============================================================================
--  TAVERNA DE AVENTUREIROS — branch do protótipo 3D
--
--  Aqui o jogo abre direto na cena low poly de scripts/prototipo3d.lua.
--  Esta versão não lê nem grava o progresso salvo.
-- =============================================================================

local prototipo = require("prototipo3d")

function iniciar()
  math.randomseed(os.time())
  prototipo.iniciar()
end

function atualizar(dt) prototipo.atualizar(dt) end
function desenhar() prototipo.desenhar() end
function tocar(x, y) prototipo.tocar(x, y) end
