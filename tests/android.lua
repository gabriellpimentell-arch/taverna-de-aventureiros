-- Conferências da versão Android que dão para fazer sem aparelho, lendo os arquivos do projeto.
local raiz = arg[1] or "."
local falhas = 0
local function ler(c)
  local f = assert(io.open(raiz .. "/" .. c, "rb"))
  local s = f:read("a")
  f:close()
  return s
end
local function ok(nome, cond, extra)
  if not cond then
    falhas = falhas + 1
    print("FALHOU " .. nome .. (extra and (": " .. tostring(extra)) or ""))
  end
end

local main, cmake, wf = ler("src/main.cpp"), ler("CMakeLists.txt"), ler(".github/workflows/build.yml")
local manifesto = ler("android/AndroidManifest.xml")

ok("o sistema acha a entrada do jogo", cmake:find("-u ANativeActivity_onCreate", 1, true))
ok("o build confere a entrada", wf:find("ANativeActivity_onCreate", 1, true))
ok("ajustes da raylib valem no build", wf:find("android/ajustar_raylib.sh", 1, true))
-- a raylib redefine fopen e não abre caminho absoluto no Android
ok("fonte é lida pela memória", main:find("LoadFontFromMemory", 1, true) and not main:find("LoadFontEx", 1, true))
ok("salva ao ir para segundo plano", main:find("APP_CMD_PAUSE", 1, true) and main:find('chamar("ao_sair", {}, true);\n        g_pausou', 1, true))
ok("música pausa em segundo plano", main:find("sons::pausar", 1, true))
ok("download não trava o jogo", main:find("baixarSemTravar", 1, true) and not main:find("atualizador::baixar(std::string(URL_ATUALIZACAO) + \"pacote", 1, true))
ok("sessão anterior não sobra", main:find("M = Motor{};", 1, true) and main:find("g_sair = false;", 1, true) and main:find("cena3d::E = cena3d::Estado{};", 1, true))
ok("JNI solta a linha", ler("src/android_sistema.h"):find("DetachCurrentThread", 1, true))
ok("APK de teste não se atualiza", wf:find("TAVERNA_PUBLICADO", 1, true) and main:find("#if defined(TAVERNA_PUBLICADO)", 1, true))
ok("só uma instância do jogo", manifesto:find('launchMode="singleTask"', 1, true))

-- o pacote publicado tem de ser o que este motor procura
local motorv = main:match('MOTOR_ANDROID = "(%d+)"')
ok("motor tem número", motorv)
for pac in wf:gmatch("pacote%-m(%d+)%.bin") do
  ok("pacote do workflow é o deste motor", pac == motorv, "m" .. pac .. " x m" .. tostring(motorv))
end

-- script novo com motor velho quebra: tudo que os scripts pedem precisa existir no motor
local registradas = {}
for nome in main:gmatch('{"([%w_]+)", l_') do registradas[nome] = true end
for nome in main:gmatch('lua_setfield%(L, %-2, "([%w_]+)"%)') do registradas[nome] = true end
local p = io.popen('ls "' .. raiz .. '/scripts"')
for arq in p:lines() do
  if arq:match("%.lua$") then
    local s = ler("scripts/" .. arq)
    for nome in s:gmatch("motor%.([%a_][%w_]*)") do
      ok("motor." .. nome .. " existe no motor (" .. arq .. ")", registradas[nome])
    end
  end
end
p:close()

-- ajustes da raylib: o script precisa continuar encontrando o que troca
for _, t in ipairs({ "EGL_CONTEXT_CLIENT_VERSION", "EGL_DEPTH_SIZE", "glDrawBuffersEXT", "texDepthWebGL" }) do
  ok("ajuste " .. t, ler("android/ajustar_raylib.sh"):find(t, 1, true))
end

if falhas > 0 then
  print("android: " .. falhas .. " falhas")
  os.exit(1)
end
print("android: ok")
