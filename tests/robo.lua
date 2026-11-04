-- Robô que joga do início até derrotar o Lorde Demônio, sem trapaça.
local J = require("jogo")
local A = require("arvore")
local C = require("config")
local R = {}
J.auto_colocar = true   -- o robô não escolhe lugar: tudo vai para o padrão

-- desbloqueios importantes: como uma pessoa, junta ouro para eles se não demorar demais
local CHAVE = { "fornecedor", "mesa", "garcom", "cozinha", "cervejaria", "prateleira", "mercadinho", "jardim", "rank_e", "merc_e", "rank_d", "cozinha", "cozinheiro", "cervejaria", "merc_d", "rank_c", "recrutador", "merc_c", "venda", "rank_b", "party", "merc_b", "rank_a", "heroi", "propaganda", "merc_a", "rank_s", "invocacao", "merc_s", "rank_ss", "merc_ss" }

local sem_lugar = {}
local function comprar_melhor()
  -- como uma pessoa: despensa vazia e carroça na estrada, guarda o ouro para ela
  local em = J.estado.mantimentos
  if em and J.ef("fornecedor") < 1 and J.carroca_presente() and (em.comida < 3 or em.bebida < 3) then return false end
  local rps = math.max(J.estado.rps, 1)
  -- na reta final, guarda ouro para os sacerdotes e para invocar os heróis
  if J.invocacao_aberta() and J.estado.invocados_feitos < 4 then
    if J.nivel("ordem_sacerdotes") < 1 then return J.comprar_no("ordem_sacerdotes") end
    return false
  end
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
  -- a Loja entra na mesma conta: compra o mais barato de tudo, como sempre fez com os níveis
  local tipo, preco = nil, melhor and J.custo_no(melhor) or math.huge
  for _, d in ipairs(C.loja) do
    local est = J.estado_unidade(d.id)
    if not est.motivo and est.preco <= J.estado.ouro and est.preco < preco and not ((sem_lugar[d.id] or 0) > J.estado.tempo) then
      tipo, preco = d.id, est.preco
    end
  end
  if tipo then
    if J.comprar_unidade(tipo) then return true end
    -- não coube: procurar lugar custa caro, então só tenta de novo depois de um tempo
    sem_lugar[tipo] = J.estado.tempo + 600
    return true
  end
  if melhor then return J.comprar_no(melhor.id) end
  return false
end

-- Receitas, como uma pessoa: experimenta os pares ainda não tentados e monta o cardápio pelo que rende
-- e tem produção, com pelo menos uma bebida e uma comida.
local function jogar_receitas()
  if not J.receitas_abertas() then return end
  local rec = J.estado.receitas
  for i, da in ipairs(C.estoques) do
    for j = i, #C.estoques do
      local db = C.estoques[j]
      if J.ingrediente_conhecido(da.id) and J.ingrediente_conhecido(db.id) and not J.par_tentado(da.id, db.id) then
        J.combinar(da.id, db.id)
      end
    end
  end
  local colheita = J.proxima_colheita()
  local boas = {}
  for id in pairs(rec.descobertas) do
    local r = J.RECEITA[id]
    if (colheita[r.a] or 0) > 0 and (colheita[r.b] or 0) > 0 then boas[#boas + 1] = r end
  end
  table.sort(boas, function(a, b)
    local va, vb = J.bonus_receita(a), J.bonus_receita(b)
    if va ~= vb then return va > vb end
    return a.id < b.id
  end)
  local novo, vagas, tem = {}, J.vagas_cardapio(), {}
  for _, r in ipairs(boas) do
    if not tem[r.pedido] and #novo < vagas then novo[#novo + 1] = r.id; tem[r.pedido] = true end
  end
  for _, r in ipairs(boas) do
    local esta = false
    for _, id in ipairs(novo) do if id == r.id then esta = true end end
    if not esta and #novo < vagas then novo[#novo + 1] = r.id end
  end
  if #novo > 0 then rec.cardapio = novo end
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
    -- os pilares primeiro: sem os quatro acesos, não há invocação
    while J.contratar_sacerdote() do end
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

-- cada(t): chamada a cada passo; se devolver true, o robô para ali
function R.jogar(limite_horas, passo, marcos, cada)
  passo = passo or 0.25
  local t, marcado = 0, {}
  while not J.estado.fim and t < limite_horas * 3600 do
    -- notícia pausa o jogo: o robô fecha a janela, como uma pessoa faria
    if J.noticia then J.noticia = nil end
    J.atualizar(passo)
    t = t + passo
    -- começo endividado: pega o empréstimo, repõe a despensa e paga o agiota quando sobra
    local ee = J.estado
    if ee.mantimentos then
      if J.pode_emprestimo() then J.pegar_emprestimo() end
      -- compra na carroça enquanto ela está na estrada: o bastante para a volta dela,
      -- medido pelo que a taverna vem servindo, sem passar da metade do ouro depois do começo
      if J.carroca_presente() then
        local ritmo = ee.servidos / math.max(60, ee.tempo)
        local alvo = math.min(600, math.max(30, ritmo * C.carroca_intervalo))
        for _, tipo in ipairs({ "comida", "bebida" }) do
          local id = tipo == "comida" and "carne" or "bebida"
          local d = J.CARROCA[id]
          while ee.mantimentos[tipo] < alvo do
            local p = J.preco_carroca(id)
            if ee.ouro < p or (ee.mantimentos[tipo] >= 30 and p > ee.ouro * 0.5) then break end
            if not J.comprar_carroca(id) then break end
          end
        end
      end
    end
    -- filhotes em conta, sementes e raros: só com ouro de sobra
    if J.carroca_presente() and (t % 5) < passo then
      for _, d in ipairs(C.carroca) do
        if d.tipo ~= "mantimento" then
          local est = J.estado_carroca(d.id)
          if not est.sumir and not est.motivo and est.preco < ee.ouro * 0.25 then J.comprar_carroca(d.id) end
        end
      end
    end
    -- serve um cliente de vez em quando, como uma pessoa faria
    if J.ef("garcons") < 1 or (t % 3) < passo then
      for _, p in ipairs(J.pessoas) do
        if p.estado == "esperando" then J.servir(p) break end
        if p.estado == "brigando" then J.separar_briga(p) break end
      end
    end
    if (t % 1) < passo then
      while comprar_melhor() do end
      jogar_contratados()
      if (t % 30) < passo then jogar_receitas() end
    end
    if cada and cada(t) then break end
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
