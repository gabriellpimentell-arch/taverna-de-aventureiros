-- =============================================================================
--  Kit de interface: cada botão desenhado registra uma área de toque naquele
--  quadro. O toque procura da última área para a primeira (a de cima vence).
-- =============================================================================

local util = require("util")
local cor = util.cores

local U = { zonas = {} }

function U.limpar() U.zonas = {} end

-- area: { x, y, w, h }. solto = true dispara ao soltar sem arrastar (usado na árvore).
function U.zona(id, r, fn, solto)
  U.zonas[#U.zonas + 1] = { id = id, x = r.x, y = r.y, w = r.w, h = r.h, fn = fn, solto = solto }
end

function U.achar(x, y)
  for i = #U.zonas, 1, -1 do
    local z = U.zonas[i]
    if util.dentro(x, y, z) then return z end
  end
  return nil
end

-- usado pelos testes: aperta um botão pelo nome
function U.apertar(id)
  for i = #U.zonas, 1, -1 do
    local z = U.zonas[i]
    if z.id == id then
      if z.fn then z.fn() end
      return true
    end
  end
  return false
end

function U.sobre(r)
  if motor.plataforma ~= "desktop" then return false end
  local mx, my = motor.mouse()
  local z = U.achar(mx, my)
  return util.dentro(mx, my, r) and z == nil
end

-- "Texto [moeda] 1.234" centralizado numa caixa; deixa claro que o número é ouro.
function U.rotulo_preco(texto, valor, x, y, w, h, tam, c)
  local num = util.formatar(valor)
  local pre = texto or ""
  local function largura(t)
    local l = motor.largura_texto(num, t, true) + t * 1.1 + 4
    if pre ~= "" then l = l + motor.largura_texto(pre, t, true) + 6 end
    return l
  end
  while tam > 13 and largura(tam) > w - 10 do tam = tam - 1 end
  local px = x + w / 2 - largura(tam) / 2
  local ty = y + h / 2 - tam * 0.68
  if pre ~= "" then
    motor.texto(pre, px, ty, tam, c, "esquerda", true)
    px = px + motor.largura_texto(pre, tam, true) + 6
  end
  local r = tam * 0.55
  local my = y + h / 2 - 1
  motor.circulo(px + r, my, r + 1, "#3a2410")
  U.moeda(px + r, my, r)
  motor.texto(num, px + r * 2 + 4, ty, tam, c, "esquerda", true)
end

-- botao(id, x, y, w, h, texto, { ativo, cor, cor_texto, tam, som, preco, icone, solto })
function U.botao(id, x, y, w, h, texto, o, fn)
  o = o or {}
  local ativo = o.ativo ~= false
  local r = { x = x, y = y, w = w, h = h }
  local fundo = o.cor or (ativo and cor.ouro or "#4a3627")
  local frente = o.cor_texto or (ativo and cor.texto_ouro or cor.texto_fraco)
  motor.retangulo(x, y + 2, w, h, "#00000055", o.raio or 10)
  motor.retangulo(x, y, w, h, fundo, o.raio or 10)
  if U.sobre(r) and ativo then motor.contorno(x, y, w, h, "#fff3c4", 2, o.raio or 10) end
  local tam = o.tam or 15
  if o.preco then
    U.rotulo_preco(texto, o.preco, x, y, w, h, tam, frente)
  elseif texto then
    local extra = o.icone == "cadeado" and 22 or 0
    while tam > 13 and motor.largura_texto(texto, tam, true) + extra > w - 10 do tam = tam - 1 end
    if extra > 0 then
      local tw = motor.largura_texto(texto, tam, true)
      U.cadeado(x + w / 2 - (tw + extra) / 2 + 8, y + h / 2 - 2, frente)
      motor.texto(texto, x + w / 2 + extra / 2, y + h / 2 - tam * 0.68, tam, frente, "centro", true)
    else
      motor.texto(texto, x + w / 2, y + h / 2 - tam * 0.68, tam, frente, "centro", true)
    end
  end
  U.zona(id, r, function()
    if ativo then
      if fn then fn() end
      motor.som(o.som or "clique")
    else
      motor.som("erro")
    end
  end, o.solto)
end

function U.painel(x, y, w, h, c, borda)
  motor.retangulo(x, y, w, h, c or cor.carta, 12)
  motor.contorno(x, y, w, h, borda or cor.carta_borda, 2, 12)
end

function U.barra(x, y, w, h, p, c)
  motor.retangulo(x, y, w, h, "#00000050", h / 2)
  p = util.limitar(p, 0, 1)
  if w * p >= 2 then motor.retangulo(x, y, w * p, h, c or cor.ouro, h / 2) end
end

-- quebra texto em linhas que cabem na largura; devolve a altura usada
function U.paragrafo(texto, x, y, w, tam, c, negrito, alinh)
  local linhas, atual = {}, ""
  for palavra in texto:gmatch("%S+") do
    local t = atual == "" and palavra or (atual .. " " .. palavra)
    if motor.largura_texto(t, tam, negrito) > w and atual ~= "" then
      linhas[#linhas + 1] = atual
      atual = palavra
    else
      atual = t
    end
  end
  if atual ~= "" then linhas[#linhas + 1] = atual end
  local lh = tam * 1.35
  for i, l in ipairs(linhas) do
    local px = alinh == "centro" and x + w / 2 or x
    motor.texto(l, px, y + (i - 1) * lh, tam, c or cor.texto, alinh or "esquerda", negrito)
  end
  return #linhas * lh
end

-- Ícones ---------------------------------------------------------------------------

function U.moeda(x, y, r)
  motor.circulo(x, y, r, cor.ouro_escuro)
  motor.circulo(x, y, r * 0.78, cor.ouro)
  motor.retangulo(x - r * 0.12, y - r * 0.45, r * 0.24, r * 0.9, cor.ouro_escuro, r * 0.1)
end

function U.caneca(x, y, e)
  e = e or 1
  motor.retangulo(x - 10 * e, y - 9 * e, 18 * e, 22 * e, "#e8a33d", 3 * e)
  motor.contorno(x + 5 * e, y - 5 * e, 10 * e, 12 * e, "#c98a2c", 3 * e, 4 * e)
  motor.retangulo(x - 11 * e, y - 14 * e, 20 * e, 8 * e, "#fff8ec", 4 * e)
end

function U.coxa(x, y, e)
  e = e or 1
  motor.linha(x + 2 * e, y + 2 * e, x + 12 * e, y + 12 * e, 5 * e, "#cdb78e")
  motor.circulo(x + 13 * e, y + 10 * e, 3.5 * e, "#cdb78e")
  motor.circulo(x + 10 * e, y + 13 * e, 3.5 * e, "#cdb78e")
  motor.circulo(x - 3 * e, y - 3 * e, 11 * e, "#b8642e")
  motor.circulo(x - 6 * e, y - 7 * e, 4 * e, "#d68a4f")
end

function U.cadeado(x, y, c)
  c = c or cor.texto_fraco
  motor.anel(x, y - 2, 4, 6.5, c, 180, 360)
  motor.retangulo(x - 8, y - 2, 16, 12, c, 3)
end

function U.engrenagem(x, y, c)
  for i = 0, 7 do
    local a = i * math.pi / 4
    motor.linha(x + math.cos(a) * 5, y + math.sin(a) * 5, x + math.cos(a) * 10, y + math.sin(a) * 10, 3.5, c)
  end
  motor.anel(x, y, 3.2, 7.5, c)
end

function U.preco(v, x, y, tam, c)
  U.moeda(x + 8, y + tam * 0.55, tam * 0.5)
  motor.texto(util.formatar(v), x + 8 + tam * 0.7, y - tam * 0.05, tam, c or cor.texto, "esquerda", true)
end

return U
