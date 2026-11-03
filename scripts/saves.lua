-- =============================================================================
--  VAGAS DE SAVE
--  Cada vaga é um arquivo próprio. Os saves prontos (começo, metade, 100%) ficam
--  em assets/saves e são copiados para uma vaga própria ao serem abertos.
-- =============================================================================

local J = require("jogo")
local util = require("util")

local S = {}

S.VAGAS = {
  { arquivo = "progresso_v2.sav", nome = "Jogo 1" },
  { arquivo = "jogo2.sav", nome = "Jogo 2" },
  { arquivo = "jogo3.sav", nome = "Jogo 3" },
}

S.PRONTOS = {
  { arquivo = "teste_comeco.sav", asset = "saves/comeco.sav", nome = "Começo do jogo", desc = "A taverna recém-aberta" },
  { arquivo = "teste_metade.sav", asset = "saves/metade.sav", nome = "Metade do jogo", desc = "Mercadinho e produção abertos, primeiros contratados" },
  { arquivo = "teste_completo.sav", asset = "saves/completo.sav", nome = "Tudo 100%", desc = "Toda a árvore comprada, pronto para o Lorde Demônio" },
}

-- resumo do que há em um arquivo; nil se estiver vazio ou estragado
function S.resumo(arquivo)
  local d = util.desserializar(motor.ler_save(arquivo))
  if type(d) ~= "table" or d.versao ~= 2 then return nil end
  local ouro, tempo = tonumber(d.ouro) or 0, tonumber(d.tempo) or 0
  local nos = 0
  if type(d.nos) == "table" then
    for _, v in pairs(d.nos) do if type(v) == "number" then nos = nos + v end end
  end
  return { ouro = ouro, tempo = tempo, nos = nos, fim = d.fim == true }
end

function S.ultimo()
  local n = motor.ler_save("ultimo.txt")
  if n and n ~= "" and S.resumo(n) then return n end
  return nil
end

-- entra no jogo usando este arquivo
function S.abrir(arquivo)
  motor.usar_save(arquivo)
  motor.gravar_save("ultimo.txt", arquivo)
  J.em_menu = false
  J.iniciar()
end

function S.novo(arquivo)
  motor.apagar_save(arquivo)
  S.abrir(arquivo)
  J.comecar_endividado()
  J.salvar()
end

-- abre um save pronto; recomecar = true descarta o que foi jogado nele
function S.abrir_pronto(p, recomecar)
  if recomecar or not S.resumo(p.arquivo) then
    local texto = motor.ler_asset(p.asset)
    if not texto then return false end
    motor.gravar_save(p.arquivo, texto)
  end
  S.abrir(p.arquivo)
  return true
end

function S.voltar_ao_menu()
  J.salvar()
  J.em_menu = true
  J.iniciar()
end

return S
