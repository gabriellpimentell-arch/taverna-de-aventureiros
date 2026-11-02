-- Robô que joga do início até derrotar o Lorde Demônio, sem trapaça.
local J = require("jogo")
local A = require("arvore")
local C = require("config")
local R = {}

-- desbloqueios importantes: como uma pessoa, junta ouro para eles se não demorar demais
local CHAVE = { "prateleira", "mercadinho", "jardim", "rank_e", "merc_e", "rank_d", "cozinheiro", "cervejaria", "merc_d", "rank_c", "recrutador", "merc_c", "venda", "rank_b", "party", "merc_b", "rank_a", "heroi", "propaganda", "merc_a", "rank_s", "invocacao", "merc_s", "rank_ss", "merc_ss" }

local function comprar_melhor()
  local rps = math.max(J.estado.rps, 1)
  -- na reta final, guarda ouro para invocar os heróis
  if J.invocacao_aberta() and J.estado.invocados_feitos < 4 then return false end
  for _, id in ipairs(CHAVE) do
    local no = A.POR_ID[id]
    if J.nivel(id) == 0 and J.no_liberado(no) then
      if J.estado.ouro >= J.custo_no(no) then return J.comprar_no(id) end
      if J.custo_no(no) / rps < 240 then return false end
    end
  end
  local melhor
  for _, no in ipairs(A.NOS) do
    if J.pode_comprar_no(no) and (not melhor or J.custo_no(no) < J.custo_no(melhor)) then melhor = no end
  end
  if melhor then return J.comprar_no(melhor.id) end
  return false
end

-- só gasta na árvore se o nó mais barato disponível já couber no bolso
local function jogar_contratados()
  local e = J.estado
  if J.pode_contratar_aberto() and J.num_contratos_normais() < J.vagas_contrato() then J.contratar() end
  if J.ef("party") > 0 and e.invocados_feitos == 0 then
    local ids = J.melhores_sem_party()
    if #ids == 4 then J.criar_party(ids) end
  end
  for _, c in ipairs(e.contratados) do
    if J.pode_promover(c) then J.promover(c) end
  end
  if J.invocacao_aberta() then
    if J.invocar() then
      -- os invocados precisam formar a party final
    end
    if e.invocados_feitos == 4 and not J.party_final() then
      local ids = {}
      for _, c in ipairs(e.contratados) do
        if c.invocado then
          if c.party then J.desfazer_party(c.party) end
          ids[#ids + 1] = c.id
        end
      end
      J.criar_party(ids)
    end
  end
  -- investe em quem está abaixo do exigido, do mais barato ao mais caro
  local melhor, id_m, custo_m
  for _, c in ipairs(e.contratados) do
    for id in pairs(C.investir) do
      local v = J.custo_investir(c, id)
      if not custo_m or v < custo_m then melhor, id_m, custo_m = c, id, v end
    end
  end
  if J.invocacao_aberta() and e.invocados_feitos < 4 then return end
  if melhor and e.ouro >= custo_m * 2 then J.investir(melhor, id_m) end
  if J.pode_final() then J.iniciar_final() end
end

function R.jogar(limite_horas, passo, marcos)
  passo = passo or 0.25
  local t, marcado = 0, {}
  while not J.estado.fim and t < limite_horas * 3600 do
    J.atualizar(passo)
    t = t + passo
    -- serve um cliente de vez em quando, como uma pessoa faria
    if not J.estado.nos.garcom or (t % 3) < passo then
      for _, p in ipairs(J.pessoas) do
        if p.estado == "esperando" then J.servir(p) break end
        if p.estado == "brigando" then J.separar_briga(p) break end
      end
    end
    if (t % 1) < passo then
      while comprar_melhor() do end
      jogar_contratados()
    end
    if marcos then
      for _, m in ipairs(marcos) do
        if not marcado[m] and J.nivel(m) > 0 then
          marcado[m] = true
          print(string.format("  %-14s %6.1f min  ouro/s %s", m, t / 60, require("util").formatar(J.estado.rps)))
        end
      end
    end
  end
  return t
end

return R
