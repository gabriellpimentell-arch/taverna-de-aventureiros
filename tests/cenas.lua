-- Leva o jogo real por todas as telas e tira uma captura de cada uma.
local J = require("jogo")
local A = require("arvore")
local T = require("telas")
local M = require("mundo")
local function comprar_tudo_ate(lista)
  for _, id in ipairs(lista) do
    local no = A.POR_ID[id]
    for _, p in ipairs(no.pre) do if J.nivel(p) < 1 then comprar_tudo_ate({ p }) end end
    J.estado.ouro = 1e40
    J.comprar_no(id)
  end
end
local function tudo()
  for _ = 1, 40 do
    for _, no in ipairs(A.NOS) do J.estado.ouro = 1e40; J.comprar_no(no.id) end
  end
end
J.sem_noticias = true
J.auto_colocar = true
local function Lj() return require("loja") end
-- dedo falso: o motor continua achando que o botão está apertado
local baixo0, mouse0 = motor.mouse_baixo, motor.mouse
local function segurar(x, y)
  motor.mouse_baixo = function() return true end
  motor.mouse = function() return x, y end
end
local function mover(x, y) motor.mouse = function() return x, y end end
local function largar(cancelar)
  motor.mouse_baixo, motor.mouse = baixo0, mouse0
  Lj().soltar(cancelar)
end
local passos = {
  { 1.5, function() end, "00_titulo" },
  { 0.3, function() T.tela = "carregar" end, "00b_carregar" },
  { 0.3, function() T.tela = "novo" end, "00c_novo" },
  -- Loja com o jogo rodando: jogo novo com colocação manual. Conferir: painel à direita, fantasma, etiqueta, selo.
  { 1.2, function()
      local S = require("saves"); J.auto_colocar = false; S.novo("jogo2.sav"); T.iniciar(); J.noticia = nil
      comprar_tudo_ate({ "mesa", "mesa", "garcom", "cozinha", "cervejaria", "prateleira", "mercadinho" }); J.estado.ouro = 900; J.estado.mantimentos.comida = 20; J.estado.mantimentos.bebida = 20
      T.aba = "loja" end, "40_loja_itens" },
  { 0.3, function() Lj().colocar_sala("cozinha") end, "41_colocar_sala_verde" },
  { 0.3, function() local c = Lj().colocando; c.x = c.x - 40 end, "42_colocar_sala_vermelha" },
  { 0.3, function() local c = Lj().colocando; c.x, c.z = require("layout").vaga_sala("cozinha", 0); assert(Lj().confirmar()); Lj().colocar_item({ tipo = "mesa", nome = "Mesa" }) end, "43_colocar_mesa" },
  { 0.6, function() assert(Lj().confirmar()); Lj().colocar_decoracao("planta") end, "44_decoracao" },
  { 0.6, function() Lj().confirmar(); Lj().aba = "comodos"; Lj().selecionar("cozinha") end, "45_comodos" },
  { 0.3, function()
      local L = require("layout"); local a; for _, h in ipairs(Lj().alcas()) do if h.p.chave == "coz_l" then a = h end end
      segurar(a.x, a.y); T.tocar(a.x, a.y); mover(a.x + 90, a.y) end, "46_alca_aumenta" },
  { 0.3, function() J.estado.ouro = 60; local a = Lj().alca; mover(a.sx + 140, a.sy) end, "47_alca_sem_ouro" },
  { 0.3, function() J.estado.ouro = 900; largar(true); local L = require("layout"); local x0, x1, z0, z1 = L.sala_mundo("cozinha")
      local px, py = motor.projetar((x0 + x1) / 2, 0, (z0 + z1) / 2); segurar(px, py); T.tocar(px, py); mover(px - 500, py + 30) end, "48_mover_vermelho" },
  { 0.3, function() local L = require("layout"); local _, _, _, zb = L.salao(); local x0, x1 = L.sala_mundo("cozinha")
      local px, py = motor.projetar((x0 + x1) / 2 - 7, 0, zb + 5); mover(px, py) end, "49_mover_verde" },
  { 0.3, function() largar(true); Lj().selecionar("porta"); local px, py = 480, 300; segurar(px, py); T.tocar(px, py)
      local L = require("layout"); local x0, x1, z0, z1 = L.sala_mundo("taverna"); local qx, qy = motor.projetar((x0 + x1) / 2 - 2, 0, z1 + 0.5); mover(qx, qy) end, "50_porta" },
  { 0.3, function() largar(true); Lj().iniciar(); T.aba = "loja"; Lj().aba = "itens"; comprar_tudo_ate({ "mesa", "mesa", "balcao", "quartos", "segundo_andar" }) end, "51_itens_varios" },
  -- aba Mover: item selecionado, fantasma verde e vermelho, decoração com Excluir
  { 0.4, function() Lj().aba = "mover"; Lj().item = "balcao" end, "53_mover_selecionado" },
  { 0.3, function() local L = require("layout"); local o, dx, dz = L.POR_ID.balcao, L.desloc("balcao"); local px, py = motor.projetar(o.x + dx, 0.5, o.z + dz)
      segurar(px, py); T.tocar(px, py); mover(px - 40, py + 50) end, "54_mover_fantasma" },
  { 0.3, function() local a = Lj().arrasto; mover(a.sx + 2000, a.sy) end, "55_mover_fantasma_fora" },
  { 0.3, function() largar(true); J.estado.ouro = 5000; local x0, x1, z0, z1 = require("layout").sala_mundo("taverna"); local _, _, id = J.comprar_decoracao("barril", x0 + 3, z1 - 1); Lj().item = id end, "56_mover_decoracao" },
  { 0.3, function() T.aba = "taverna"; J.auto_colocar = true; require("layout").restaurar(); M.iniciar() end, "52_fim_loja" },
  { 0.2, function() local S = require("saves"); S.novo("jogo3.sav"); T.iniciar(); J.noticia = nil end, "00d_entrou" },
  { 3, function() end, "01_inicio" },
  { 1, function() T.aba = "arvore" end, "02_arvore_inicio" },
  { 1, function() T.arv.sel = "cardapio" end, "03_arvore_no" },
  { 7, function() T.aba = "taverna"; comprar_tudo_ate({ "mesa", "balcao", "garcom", "prateleira", "placa" }); J.estado.ouro = 1200; J.estado.rps = 14; J.estado.servidos = 30 end, "04_meio" },
  { 0.1, function() J.relogio_aventureiro = 99 end, "04b_indo_quadro" },
  { 2.2, function() end, "04c_no_quadro" },
  { 1.0, function() end, "04d_papel" },
  { 1.0, function() end, "04e_com_papel" },
  { 1, function() T.aba = "missoes" end, "05_missoes" },
  { 7, function() T.aba = "taverna"; comprar_tudo_ate({ "mercadinho", "merc_e", "jardim", "cozinheiro", "cervejaria", "bardo", "canteiro", "canteiro", "ala_leste" }); J.estado.ouro = 88000; J.estado.rps = 320 end, "06_areas" },
  { 1, function() T.aba = "mercadinho" end, "07_mercadinho" },
  { 1, function() T.aba = "producao" end, "08_producao" },
  { 1, function() comprar_tudo_ate({ "venda", "pocoes", "armaduras" }); J.estado.ouro = 2e6; T.aba = "mercadinho" end, "09_venda" },
  { 1, function() T.aba = "aventureiros"; comprar_tudo_ate({ "recrutador", "alojamento", "alojamento", "party" }); J.estado.ouro = 5e9; for _ = 1, 6 do J.contratar() end end, "10_aventureiros" },
  { 1, function() tudo(); J.estado.ouro = 5e12; for _, c in ipairs(J.estado.contratados) do for _ = 1, 26 do J.investir(c, "magia") end J.estado.ouro = 5e12; J.promover(c) end; J.estado.fama = 300 end, "11_herois" },
  { 1, function() T.aba = "arvore"; T.arv.zoom = 0.5 end, "12_arvore_toda" },
  { 1, function() T.aba = "invocacao"; J.invocar(); J.estado.ouro = 1e14; J.invocar() end, "13_invocacao" },
  { 3, function() T.aba = "taverna"; M.zoom_alvo = 1 end, "14_tudo_aberto" },
  { 2, function() local L = require("layout"); L.mudar_tamanho("jardim_l", 3); L.mudar_tamanho("jardim_p", 2); L.mudar_tamanho("cerv_l", 2); L.mudar_tamanho("circ_p", 2) end, "14b_salas_maiores" },
  { 0.5, function() require("layout").restaurar() end, "14c_salas_normais" },
  -- blocos: as salas nos quatro lados da taverna. Conferir: nada escondido, nada sobreposto.
  { 1.2, function() local L = require("layout"); L.restaurar(); local _, xb, za, zb = L.salao(); local xa = select(1, L.salao())
      assert(L.mover_sala("circulo", xa - 5.5, za)); assert(L.mover_sala("cervejaria", xa, za - 9.2)); M.iniciar() end, "30_atras_e_esquerda" },
  { 1.2, function() local L = require("layout"); local xa, _, za, zb = L.salao(); assert(L.mover_sala("caminho", xa - 12, zb + 6)); assert(L.mover_sala("jardim", xa - 8, zb + 0.5)); assert(L.mover_sala("fazenda", xa + 19, zb + 0.5)); assert(L.mover_sala("pomar", xa + 9, zb + 0.5)); assert(L.mover_sala("cozinha", xa + 3, zb)); M.iniciar() end, "31_frente" },
  { 1.2, function() local L = require("layout"); local ok, m = L.mover_porta("leste", 4); assert(ok, m); J.aplicar_obra(); M.iniciar() end, "32_porta_movida" },
  { 1.2, function() local L = require("layout"); local xa, xb, za, zb = L.salao(); assert(L.mover_sala("pomar", xb + 1, za - 7)); assert(L.mover_sala("jardim", xa - 13, za)); M.iniciar() end, "33_externas_em_volta" },
  { 1.2, function() local L = require("layout"); L.restaurar(); assert(L.mudar_andar(1)); M.iniciar() end, "34_segundo_andar" },
  { 1.2, function() local L = require("layout"); assert(L.mudar_andar(-1)); M.iniciar() end, "35_subsolo" },
  { 1.2, function() local L = require("layout"); local x, z = L.vaga_sala("circulo", -1); assert(L.mover_sala("circulo", x, z, -1)); x, z = L.vaga_sala("cervejaria", -1); assert(L.mover_sala("cervejaria", x, z, -1)); M.iniciar() end, "36_subsolo_salas" },
  { 1.2, function() local L = require("layout"); L.restaurar(); L.mudar_andar(0); J.aplicar_layout(); M.iniciar() end, "37_terreo_volta" },
  { 1, function() T.modal = "config" end, "15_config" },
  { 0.5, function() T.confirmar = true end, "16_apagar" },
  { 0.5, function() T.confirmar = false; T.modal = "stats" end, "17_stats" },
  { 0.5, function() T.modal = "creditos" end, "18_creditos" },
  { 0.4, function() T.modal = nil; J.fofoca_conta = 11; J.chamar_menestrel() end, "18h_menestrel_entra" },
  { 7, function() end, "18i_menestrel_banner" },
  { 0.4, function() J.noticia = J.NOTICIAS[6] end, "18j_noticia" },
  { 0.3, function() J.noticia = nil end, "18k_fim" },
  { 0.5, function() T.modal = nil; J.offline = { ganho = 48250, segundos = 11520 } end, "19_offline" },
  { 0.5, function() J.offline = nil; J.estado.fim = true end, "20_final" },
}
-- CENAS_SO=loja: só as capturas da Loja (mais rápido para conferir)
local so = os.getenv("CENAS_SO")
if so then
  local l = {}
  for _, p in ipairs(passos) do
    if p[3]:match("^[45][0-9]") then l[#l + 1] = p end
  end
  passos = l
end
local i, t, fase = 0, 0, "ir"
function teste(dt)
  if fase == "ir" then
    i = i + 1
    if not passos[i] then os.exit(0) end
    passos[i][2](); t = 0; fase = "esperar"
  elseif fase == "esperar" then
    t = t + dt
    if t >= passos[i][1] then motor.captura(passos[i][3] .. ".png"); fase = "pausa"; t = 0 end
  else
    t = t + dt
    if t > 0.12 then fase = "ir" end
  end
end
