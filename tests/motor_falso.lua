-- Motor falso: deixa as regras e as telas rodarem sem janela.
local vazio = function() end
motor = setmetatable({
  largura = 960, altura = 540, plataforma = "desktop", versao = "teste",
  _save = false, _mouse = { 480, 270 }, _baixo = false, _roda = 0, _t = 0, _tela_cheia = true, _saiu = false,
}, { __index = function() return vazio end })
function motor.largura_texto(t, tam) return #t * (tam or 24) * 0.55 end
function motor.mouse() return motor._mouse[1], motor._mouse[2] end
function motor.mouse_baixo() return motor._baixo end
function motor.roda() local r = motor._roda; motor._roda = 0; return r end
function motor.tempo() return motor._t end
function motor.fps() return 60 end
function motor.tela_cheia() return motor._tela_cheia end
function motor.alternar_tela_cheia() motor._tela_cheia = not motor._tela_cheia end
function motor.sair() motor._saiu = true end
function motor.salvar(s)
  if motor._atual then motor._saves[motor._atual] = s else motor._save = s end
  return true
end
function motor.carregar()
  if motor._atual then return motor._saves[motor._atual] end
  local s = rawget(motor, "_save")
  return s or nil
end
function motor.chao(x, y) return (x - 480) / 30, (y - 300) / 26 end
function motor.layout_salvar(t) motor._layout = t; return true end
function motor.layout_carregar() local t = rawget(motor, "_layout"); return t or nil end
function motor.copiar(t) motor._copiado = t end
motor._saves = {}
motor._atual = false
function motor.usar_save(n) motor._atual = n end
function motor.ler_save(n) return motor._saves[n] end
function motor.gravar_save(n, t) motor._saves[n] = t end
function motor.apagar_save(n) motor._saves[n] = nil end
function motor.ler_asset(n)
  local f = io.open((rawget(motor, "_raiz") or ".") .. "/assets/" .. n, "rb")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  return s
end
function motor.projetar(x, y, z) return 480 + (x - z * 0.3) * 30, 300 + (z * 0.8 - y) * 26 end
