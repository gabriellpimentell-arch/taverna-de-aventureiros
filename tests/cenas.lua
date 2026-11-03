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
local passos = {
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
  { 1, function() T.modal = "config" end, "15_config" },
  { 0.5, function() T.confirmar = true end, "16_apagar" },
  { 0.5, function() T.confirmar = false; T.modal = "stats" end, "17_stats" },
  { 0.5, function() T.modal = "creditos" end, "18_creditos" },
  { 0.5, function() T.modal = nil; require("editor").abrir() end, "18b_editor" },
  { 0.5, function() local E = require("editor"); E.sel = "mesa2"; E.mover_para("mesa2", 1.5, -0.5) end, "18c_editor_movido" },
  { 0.5, function() local E = require("editor"); E.cat = "Tamanho"; E.sel = nil end, "18d_editor_tamanho" },
  { 1.5, function() local L = require("layout"); L.mudar_tamanho("dir", 6); L.mudar_tamanho("frente", 4); require("jogo").aplicar_visual() end, "18e_editor_maior" },
  { 0.5, function() local E = require("editor"); E.cat = "Paredes" end, "18f_editor_paredes" },
  { 0.5, function() local E = require("editor"); local L = require("layout"); L.restaurar(); E.fechar() end, "18g_editor_fim" },
  { 0.4, function() J.fofoca_conta = 11; J.chamar_menestrel() end, "18h_menestrel_entra" },
  { 7, function() end, "18i_menestrel_banner" },
  { 0.4, function() J.noticia = J.NOTICIAS[6] end, "18j_noticia" },
  { 0.3, function() J.noticia = nil end, "18k_fim" },
  { 0.5, function() T.modal = nil; J.offline = { ganho = 48250, segundos = 11520 } end, "19_offline" },
  { 0.5, function() J.offline = nil; J.estado.fim = true end, "20_final" },
}
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
