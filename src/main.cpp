// =============================================================================
//  Taverna de Aventureiros — motor
//
//  O motor em C++ cuida do "trabalho pesado": janela, desenho, toque/clique,
//  fontes e arquivos. Toda a regra do jogo fica nos scripts Lua da pasta
//  `scripts/`, que o motor carrega e chama a cada quadro:
//
//      iniciar()          uma vez, quando os scripts são carregados
//      atualizar(dt)      a cada quadro (dt = segundos desde o quadro anterior)
//      desenhar()         a cada quadro, depois de atualizar
//      tocar(x, y)        quando o jogador toca na tela ou clica
//      ao_sair()          antes de fechar ou recarregar (hora de salvar)
//
//  O jogo é desenhado numa tela virtual deitada (16:9) de 960 x 540, que o
//  motor escala para caber na tela. No computador ele abre em tela cheia
//  (F11 ou Alt+Enter alternam com o modo janela).
//
//  Na versão distribuída, os scripts e as fontes vão embutidos no final do
//  próprio .exe (um "pacote"). Ao abrir, o jogo confere no GitHub se existe
//  versão nova; se existir, baixa o .exe novo, troca e reinicia sozinho.
//
//  Durante o desenvolvimento (sem pacote embutido), o jogo usa as pastas
//  scripts/ e assets/, e salvar qualquer .lua recarrega na hora. F5 também.
// =============================================================================

#include "raylib.h"
#include "atualizador.h"
#include "cena3d.h"
#include "sons.h"
#include "android_sistema.h"
#include "toques.h"

extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

namespace fs = std::filesystem;

static const float LARGURA = 960.0f;
static const float ALTURA = 540.0f;

struct Motor {
    lua_State* L = nullptr;
    fs::path pastaScripts;
    fs::path pastaAssets;
    fs::path arquivoSave;
    Font fonteNormal{};
    Font fonteNegrito{};
    bool fontesProprias = false;
    std::string erro;
    Camera2D camera{};
    float opacidade = 1.0f;
    std::map<std::string, long long> datasScripts;
    float relogioVigia = 0.0f;
    std::string arquivoTeste;
    std::string versao = "dev";
    bool apkVelho = false;
};

static Motor M;

// -----------------------------------------------------------------------------
//  Utilidades
// -----------------------------------------------------------------------------

// Cores chegam do Lua como texto hexadecimal: "#RRGGBB" ou "#RRGGBBAA".
static Color corDeLua(lua_State* L, int idx, Color padrao) {
    Color c = padrao;
    if (!lua_isnoneornil(L, idx)) {
        const char* s = luaL_checkstring(L, idx);
        if (*s == '#') s++;
        size_t n = strlen(s);
        unsigned long v = strtoul(s, nullptr, 16);
        if (n == 6) {
            c = Color{(unsigned char)((v >> 16) & 255), (unsigned char)((v >> 8) & 255),
                      (unsigned char)(v & 255), 255};
        } else if (n == 8) {
            c = Color{(unsigned char)((v >> 24) & 255), (unsigned char)((v >> 16) & 255),
                      (unsigned char)((v >> 8) & 255), (unsigned char)(v & 255)};
        } else {
            c = MAGENTA;  // cor inválida: fica bem visível para corrigir
        }
    }
    c.a = (unsigned char)(c.a * std::clamp(M.opacidade, 0.0f, 1.0f));
    return c;
}

static float num(lua_State* L, int idx) { return (float)luaL_checknumber(L, idx); }
static float numOpc(lua_State* L, int idx, float padrao) {
    return (float)luaL_optnumber(L, idx, padrao);
}

static Font fonte(bool negrito) { return negrito ? M.fonteNegrito : M.fonteNormal; }

static float espacamento(float tamanho) { return M.fontesProprias ? 0.0f : tamanho / 10.0f; }

static bool lerArquivo(const fs::path& p, std::string& saida) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return false;
    std::stringstream ss;
    ss << f.rdbuf();
    saida = ss.str();
    return true;
}

// -----------------------------------------------------------------------------
//  API "motor" exposta ao Lua
// -----------------------------------------------------------------------------

// motor.retangulo(x, y, largura, altura, cor, raio)
static int l_retangulo(lua_State* L) {
    Rectangle r{num(L, 1), num(L, 2), num(L, 3), num(L, 4)};
    Color c = corDeLua(L, 5, WHITE);
    float raio = numOpc(L, 6, 0);
    float menor = std::min(r.width, r.height);
    if (raio <= 0 || menor <= 0) {
        DrawRectangleRec(r, c);
    } else {
        DrawRectangleRounded(r, std::min(1.0f, raio * 2.0f / menor), 12, c);
    }
    return 0;
}

// motor.contorno(x, y, largura, altura, cor, espessura, raio)
static int l_contorno(lua_State* L) {
    Rectangle r{num(L, 1), num(L, 2), num(L, 3), num(L, 4)};
    Color c = corDeLua(L, 5, WHITE);
    float esp = numOpc(L, 6, 2);
    float raio = numOpc(L, 7, 0);
    float menor = std::min(r.width, r.height);
    if (raio <= 0 || menor <= 0) {
        DrawRectangleLinesEx(r, esp, c);
    } else {
        DrawRectangleRoundedLinesEx(r, std::min(1.0f, raio * 2.0f / menor), 12, esp, c);
    }
    return 0;
}

// motor.circulo(x, y, raio, cor)
static int l_circulo(lua_State* L) {
    DrawCircleV(Vector2{num(L, 1), num(L, 2)}, num(L, 3), corDeLua(L, 4, WHITE));
    return 0;
}

// motor.anel(x, y, raio_interno, raio_externo, cor, angulo_inicial, angulo_final)
static int l_anel(lua_State* L) {
    DrawRing(Vector2{num(L, 1), num(L, 2)}, num(L, 3), num(L, 4), numOpc(L, 6, 0),
             numOpc(L, 7, 360), 36, corDeLua(L, 5, WHITE));
    return 0;
}

// motor.elipse(x, y, raio_x, raio_y, cor)
static int l_elipse(lua_State* L) {
    DrawEllipse((int)num(L, 1), (int)num(L, 2), num(L, 3), num(L, 4), corDeLua(L, 5, WHITE));
    return 0;
}

// motor.triangulo(x1, y1, x2, y2, x3, y3, cor)
static int l_triangulo(lua_State* L) {
    Vector2 a{num(L, 1), num(L, 2)}, b{num(L, 3), num(L, 4)}, c{num(L, 5), num(L, 6)};
    Color cor = corDeLua(L, 7, WHITE);
    // A raylib só desenha triângulos numa ordem de vértices; testamos as duas
    // para o Lua não precisar se preocupar com isso.
    float cruz = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (cruz < 0) DrawTriangle(a, b, c, cor);
    else DrawTriangle(a, c, b, cor);
    return 0;
}

// motor.linha(x1, y1, x2, y2, espessura, cor)
static int l_linha(lua_State* L) {
    DrawLineEx(Vector2{num(L, 1), num(L, 2)}, Vector2{num(L, 3), num(L, 4)}, numOpc(L, 5, 2),
               corDeLua(L, 6, WHITE));
    return 0;
}

// motor.texto(texto, x, y, tamanho, cor, alinhamento, negrito)
//   alinhamento: "esquerda" (padrão), "centro" ou "direita"
static int l_texto(lua_State* L) {
    const char* t = luaL_checkstring(L, 1);
    float x = num(L, 2), y = num(L, 3);
    float tam = numOpc(L, 4, 24);
    Color c = corDeLua(L, 5, WHITE);
    const char* alinh = luaL_optstring(L, 6, "esquerda");
    Font f = fonte(lua_toboolean(L, 7));
    float esp = espacamento(tam);
    Vector2 med = MeasureTextEx(f, t, tam, esp);
    if (strcmp(alinh, "centro") == 0) x -= med.x / 2.0f;
    else if (strcmp(alinh, "direita") == 0) x -= med.x;
    DrawTextEx(f, t, Vector2{x, y}, tam, esp, c);
    return 0;
}

// motor.largura_texto(texto, tamanho, negrito) -> largura
static int l_largura_texto(lua_State* L) {
    const char* t = luaL_checkstring(L, 1);
    float tam = numOpc(L, 2, 24);
    Vector2 med = MeasureTextEx(fonte(lua_toboolean(L, 3)), t, tam, espacamento(tam));
    lua_pushnumber(L, med.x);
    return 1;
}

// motor.opacidade(0..1): vale para tudo que for desenhado depois
static int l_opacidade(lua_State* L) {
    M.opacidade = numOpc(L, 1, 1);
    return 0;
}

// motor.mouse() -> x, y (posição do cursor na tela virtual)
static int l_mouse(lua_State* L) {
    Vector2 p = GetScreenToWorld2D(GetMousePosition(), M.camera);
    lua_pushnumber(L, p.x);
    lua_pushnumber(L, p.y);
    return 2;
}

// motor.tempo() -> segundos desde que o jogo abriu
static int l_tempo(lua_State* L) {
    lua_pushnumber(L, GetTime());
    return 1;
}

// motor.salvar(texto): grava o progresso
static int l_salvar(lua_State* L) {
    size_t n = 0;
    const char* dados = luaL_checklstring(L, 1, &n);
    std::error_code ec;
    fs::create_directories(M.arquivoSave.parent_path(), ec);
    fs::path temp = M.arquivoSave;
    temp += ".tmp";
    {
        std::ofstream f(temp, std::ios::binary | std::ios::trunc);
        if (!f) {
            lua_pushboolean(L, 0);
            return 1;
        }
        f.write(dados, (std::streamsize)n);
    }
    // grava num arquivo temporário e troca: se o jogo fechar no meio, o save antigo continua inteiro
    fs::rename(temp, M.arquivoSave, ec);
    if (ec) {
        fs::remove(M.arquivoSave, ec);
        fs::rename(temp, M.arquivoSave, ec);
    }
    lua_pushboolean(L, !ec);
    return 1;
}

// motor.carregar() -> texto salvo, ou nil se não houver
static int l_carregar(lua_State* L) {
    std::string dados;
    if (lerArquivo(M.arquivoSave, dados)) lua_pushlstring(L, dados.data(), dados.size());
    else lua_pushnil(L);
    return 1;
}

// motor.log(...): mensagem no console
static int l_log(lua_State* L) {
    std::string s;
    int n = lua_gettop(L);
    for (int i = 1; i <= n; i++) {
        if (i > 1) s += " ";
        s += luaL_tolstring(L, i, nullptr);
        lua_pop(L, 1);
    }
    TraceLog(LOG_INFO, "LUA: %s", s.c_str());
    return 0;
}

// motor.captura(arquivo): salva uma imagem da tela (usado em testes)
static int l_captura(lua_State* L) {
    TakeScreenshot(luaL_checkstring(L, 1));
    return 0;
}

// --- Cena 3D low poly (ver cena3d.h) ------------------------------------------

static int l_cena_camera(lua_State* L) {
    cena3d::E.camPos = Vector3{num(L, 1), num(L, 2), num(L, 3)};
    cena3d::E.camAlvo = Vector3{num(L, 4), num(L, 5), num(L, 6)};
    cena3d::E.fov = numOpc(L, 7, 28);
    return 0;
}

// motor.cena_sombra(x, z, raio): área coberta pelas sombras (acompanha o tamanho da taverna)
static int l_cena_sombra(lua_State* L) {
    cena3d::E.sombraX = num(L, 1);
    cena3d::E.sombraZ = num(L, 2);
    cena3d::E.sombraRaio = std::max(10.0f, num(L, 3));
    return 0;
}

static int l_cena_luz(lua_State* L) {
    int i = (int)luaL_checkinteger(L, 1) - 1;
    if (i < 0 || i >= cena3d::MAX_LUZES) return 0;
    cena3d::Luz& l = cena3d::E.luzes[i];
    l.pos[0] = num(L, 2); l.pos[1] = num(L, 3); l.pos[2] = num(L, 4);
    l.cor[0] = num(L, 5); l.cor[1] = num(L, 6); l.cor[2] = num(L, 7);
    l.alcance = num(L, 8);
    return 0;
}

// motor.peca(forma, x, y, z, ex, ey, ez, giro, cor, inclina_x, inclina_z, brilho)
static int l_peca(lua_State* L) {
    const char* f = luaL_checkstring(L, 1);
    cena3d::Peca p;
    p.forma = f[0] == 'c' ? (f[1] == 'a' ? cena3d::CAIXA : (f[1] == 'i' ? cena3d::CILINDRO : cena3d::CONE))
                          : cena3d::ESFERA;
    Vector3 pos{num(L, 2), num(L, 3), num(L, 4)};
    Vector3 esc{num(L, 5), num(L, 6), num(L, 7)};
    float giro = numOpc(L, 8, 0);
    float sal = M.opacidade;
    M.opacidade = 1.0f;
    p.cor = corDeLua(L, 9, WHITE);
    M.opacidade = sal;
    float rx = numOpc(L, 10, 0), rz = numOpc(L, 11, 0);
    p.brilho = numOpc(L, 12, 0);
    Matrix m = MatrixScale(esc.x, esc.y, esc.z);
    if (rx != 0) m = MatrixMultiply(m, MatrixRotateX(rx));
    if (rz != 0) m = MatrixMultiply(m, MatrixRotateZ(rz));
    if (giro != 0) m = MatrixMultiply(m, MatrixRotateY(giro));
    p.m = MatrixMultiply(m, MatrixTranslate(pos.x, pos.y, pos.z));
    cena3d::E.pecas.push_back(p);
    return 0;
}

static void reiniciarModo2D();

static int l_cena_desenhar(lua_State*) {
    int x = (int)M.camera.offset.x, y = (int)M.camera.offset.y;
    int w = (int)std::ceil(LARGURA * M.camera.zoom), h = (int)std::ceil(ALTURA * M.camera.zoom);
    EndScissorMode();
    EndMode2D();
    Matrix proj = rlGetMatrixProjection();
    Matrix vista = rlGetMatrixModelview();
    cena3d::desenhar(x, y, w, h, GetScreenHeight());
    rlSetMatrixProjection(proj);
    rlSetMatrixModelview(vista);
    rlViewport(0, 0, GetScreenWidth(), GetScreenHeight());
    reiniciarModo2D();
    return 0;
}

static int l_projetar(lua_State* L) {
    float sx = 0, sy = 0;
    bool ok = cena3d::projetar(Vector3{num(L, 1), num(L, 2), num(L, 3)}, LARGURA, ALTURA, sx, sy);
    if (!ok) return 0;
    lua_pushnumber(L, sx);
    lua_pushnumber(L, sy);
    return 2;
}

static bool g_sair = false;

// Janela e opções -------------------------------------------------------------

#if defined(__ANDROID__)
static int l_minimizar(lua_State*) { android_sistema::minimizar(); return 0; }
#else
static int l_minimizar(lua_State*) { MinimizeWindow(); return 0; }
#endif
static int l_sair(lua_State*) { g_sair = true; return 0; }
#if defined(__ANDROID__)
static int l_alternar_tela_cheia(lua_State*) { return 0; }
#else
static int l_alternar_tela_cheia(lua_State*) { ToggleBorderlessWindowed(); return 0; }
#endif
static int l_tela_cheia(lua_State* L) { lua_pushboolean(L, IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)); return 1; }
#if defined(__ANDROID__)
static toques::Rastreador g_toques;
static int l_mouse_baixo(lua_State* L) { lua_pushboolean(L, g_toques.baixo()); return 1; }
// no celular, o zoom vem do movimento de pinça com dois dedos
static int l_roda(lua_State* L) {
    static float distanciaAntes = -1;
    float delta = 0;
    if (GetTouchPointCount() == 2) {
        Vector2 a = GetTouchPosition(0), b = GetTouchPosition(1);
        float d = std::hypot(a.x - b.x, a.y - b.y);
        // medido na tela virtual: o gesto vale o mesmo em qualquer resolução
        if (distanciaAntes > 0) delta = (d - distanciaAntes) / std::max(M.camera.zoom, 0.01f) * 0.05f;
        distanciaAntes = d;
    } else {
        distanciaAntes = -1;
    }
    lua_pushnumber(L, delta);
    return 1;
}
#else
static int l_mouse_baixo(lua_State* L) { lua_pushboolean(L, IsMouseButtonDown(MOUSE_BUTTON_LEFT)); return 1; }
static int l_roda(lua_State* L) { lua_pushnumber(L, GetMouseWheelMove()); return 1; }
#endif
// motor.recorte(x, y, w, h): só desenha dentro desta área; sem argumentos, volta à tela toda
static int l_recorte(lua_State* L) {
    float z = M.camera.zoom;
    EndScissorMode();
    if (lua_gettop(L) >= 4) {
        BeginScissorMode((int)(M.camera.offset.x + num(L, 1) * z), (int)(M.camera.offset.y + num(L, 2) * z),
                         (int)std::ceil(num(L, 3) * z), (int)std::ceil(num(L, 4) * z));
    } else {
        BeginScissorMode((int)M.camera.offset.x, (int)M.camera.offset.y, (int)std::ceil(LARGURA * z),
                         (int)std::ceil(ALTURA * z));
    }
    return 0;
}

// motor.chao(x, y) -> ponto do chão 3D sob esta posição da tela virtual
static int l_chao(lua_State* L) {
    Vector3 r;
    if (!cena3d::chao(num(L, 1), num(L, 2), LARGURA, ALTURA, r)) return 0;
    lua_pushnumber(L, r.x);
    lua_pushnumber(L, r.z);
    return 2;
}

// Posições editadas: ficam fora da pasta do jogo, assim sobrevivem às atualizações.
static fs::path g_layout;
static fs::path arquivoLayout() { return g_layout; }

// Vagas de save: só nomes simples, sempre dentro da pasta de dados.
static bool nomeValido(const std::string& n) {
    if (n.empty() || n.size() > 40 || n.find("..") != std::string::npos) return false;
    for (char c : n) {
        if (!isalnum((unsigned char)c) && c != '_' && c != '.') return false;
    }
    return true;
}

static int l_usar_save(lua_State* L) {
    std::string n = luaL_checkstring(L, 1);
    if (nomeValido(n)) M.arquivoSave = g_layout.parent_path() / n;
    return 0;
}

static int l_ler_save(lua_State* L) {
    std::string n = luaL_checkstring(L, 1), d;
    if (nomeValido(n) && lerArquivo(g_layout.parent_path() / n, d)) lua_pushlstring(L, d.data(), d.size());
    else lua_pushnil(L);
    return 1;
}

static int l_gravar_save(lua_State* L) {
    std::string n = luaL_checkstring(L, 1);
    size_t t = 0;
    const char* d = luaL_checklstring(L, 2, &t);
    if (!nomeValido(n)) return 0;
    std::error_code ec;
    fs::create_directories(g_layout.parent_path(), ec);
    std::ofstream f(g_layout.parent_path() / n, std::ios::binary | std::ios::trunc);
    if (f) f.write(d, (std::streamsize)t);
    return 0;
}

static int l_apagar_save(lua_State* L) {
    std::string n = luaL_checkstring(L, 1);
    std::error_code ec;
    if (nomeValido(n)) fs::remove(g_layout.parent_path() / n, ec);
    return 0;
}

// motor.ler_asset("saves/metade.sav"): arquivos que acompanham o jogo
static int l_ler_asset(lua_State* L) {
    std::string n = luaL_checkstring(L, 1), d;
    if (n.find("..") == std::string::npos && lerArquivo(M.pastaAssets / fs::u8path(n), d)) lua_pushlstring(L, d.data(), d.size());
    else lua_pushnil(L);
    return 1;
}

static int l_layout_salvar(lua_State* L) {
    size_t n = 0;
    const char* d = luaL_checklstring(L, 1, &n);
    std::error_code ec;
    fs::create_directories(M.arquivoSave.parent_path(), ec);
    std::ofstream f(arquivoLayout(), std::ios::binary | std::ios::trunc);
    if (f) f.write(d, (std::streamsize)n);
    lua_pushboolean(L, (bool)f);
    return 1;
}

static int l_layout_carregar(lua_State* L) {
    std::string d;
    if (lerArquivo(arquivoLayout(), d)) lua_pushlstring(L, d.data(), d.size());
    else lua_pushnil(L);
    return 1;
}

static int l_copiar(lua_State* L) {
#if defined(__ANDROID__)
    android_sistema::copiar(luaL_checkstring(L, 1));
#else
    SetClipboardText(luaL_checkstring(L, 1));
#endif
    return 0;
}

static int l_sombras(lua_State* L) { cena3d::E.sombras = lua_toboolean(L, 1); return 0; }
static int l_som(lua_State* L) { sons::tocar(luaL_checkstring(L, 1)); return 0; }
static int l_volume(lua_State* L) { sons::volumes(num(L, 1), num(L, 2)); return 0; }

static int l_fps(lua_State* L) {
    lua_pushinteger(L, GetFPS());
    return 1;
}

static void registrarApi(lua_State* L) {
    static const luaL_Reg funcoes[] = {
        {"retangulo", l_retangulo}, {"contorno", l_contorno},
        {"circulo", l_circulo},     {"anel", l_anel},
        {"elipse", l_elipse},       {"triangulo", l_triangulo},
        {"linha", l_linha},         {"texto", l_texto},
        {"largura_texto", l_largura_texto},
        {"opacidade", l_opacidade}, {"mouse", l_mouse},
        {"tempo", l_tempo},         {"salvar", l_salvar},
        {"carregar", l_carregar},   {"log", l_log},
        {"captura", l_captura},
        {"cena_sombra", l_cena_sombra}, {"cena_camera", l_cena_camera}, {"cena_luz", l_cena_luz},
        {"peca", l_peca},           {"cena_desenhar", l_cena_desenhar},
        {"projetar", l_projetar},   {"fps", l_fps},
        {"minimizar", l_minimizar}, {"sair", l_sair},
        {"alternar_tela_cheia", l_alternar_tela_cheia}, {"tela_cheia", l_tela_cheia},
        {"mouse_baixo", l_mouse_baixo}, {"roda", l_roda},
        {"usar_save", l_usar_save}, {"ler_save", l_ler_save},
        {"gravar_save", l_gravar_save}, {"apagar_save", l_apagar_save},
        {"ler_asset", l_ler_asset}, {"chao", l_chao},           {"layout_salvar", l_layout_salvar},
        {"layout_carregar", l_layout_carregar}, {"copiar", l_copiar},
        {"recorte", l_recorte},     {"sombras", l_sombras},     {"som", l_som}, {"volume", l_volume},
        {nullptr, nullptr},
    };
    luaL_newlib(L, funcoes);
    lua_pushnumber(L, LARGURA);
    lua_setfield(L, -2, "largura");
    lua_pushnumber(L, ALTURA);
    lua_setfield(L, -2, "altura");
#if defined(__ANDROID__)
    lua_pushstring(L, "android");
#else
    lua_pushstring(L, "desktop");
#endif
    lua_setfield(L, -2, "plataforma");
    lua_pushstring(L, M.versao.c_str());
    lua_setfield(L, -2, "versao");
    lua_pushboolean(L, M.apkVelho);
    lua_setfield(L, -2, "apk_velho");
    lua_setglobal(L, "motor");
}

// -----------------------------------------------------------------------------
//  Carregar e chamar os scripts
// -----------------------------------------------------------------------------

static int rastreio(lua_State* L) {
    const char* msg = lua_tostring(L, 1);
    luaL_traceback(L, L, msg ? msg : "erro desconhecido", 1);
    return 1;
}

// Chama uma função global do Lua, se ela existir. Erros vão para a tela de erro.
static void chamar(const char* nome, std::initializer_list<double> args = {}, bool mesmoComErro = false) {
    lua_State* L = M.L;
    if (!L || (!M.erro.empty() && !mesmoComErro)) return;
    int topo = lua_gettop(L);
    lua_pushcfunction(L, rastreio);
    lua_getglobal(L, nome);
    if (lua_isfunction(L, -1)) {
        for (double a : args) lua_pushnumber(L, a);
        if (lua_pcall(L, (int)args.size(), 0, topo + 1) != LUA_OK && M.erro.empty()) {
            M.erro = lua_tostring(L, -1);
            TraceLog(LOG_WARNING, "Erro em %s(): %s", nome, M.erro.c_str());
        }
    }
    lua_settop(L, topo);
    M.opacidade = 1.0f;
}

static bool executarArquivo(const fs::path& arquivo) {
    lua_State* L = M.L;
    int topo = lua_gettop(L);
    lua_pushcfunction(L, rastreio);
    std::string codigo;
    bool ok = false;
    if (!lerArquivo(arquivo, codigo)) {
        M.erro = "Não encontrei o arquivo " + arquivo.string();
    } else {
        std::string nome = "@" + arquivo.filename().string();
        if (luaL_loadbuffer(L, codigo.data(), codigo.size(), nome.c_str()) != LUA_OK ||
            lua_pcall(L, 0, 0, topo + 1) != LUA_OK) {
            M.erro = lua_tostring(L, -1);
        } else {
            ok = true;
        }
    }
    lua_settop(L, topo);
    return ok;
}

static std::map<std::string, long long> lerDatasScripts() {
    std::map<std::string, long long> datas;
    std::error_code ec;
    for (const auto& e : fs::recursive_directory_iterator(M.pastaScripts, ec)) {
        if (e.path().extension() == ".lua") {
            datas[e.path().string()] = (long long)fs::last_write_time(e.path(), ec).time_since_epoch().count();
        }
    }
    return datas;
}

static void carregarScripts() {
    if (M.L) {
        chamar("ao_sair", {}, true);  // salva o progresso antes de recarregar
        lua_close(M.L);
    }
    M.erro.clear();
    M.opacidade = 1.0f;
    M.L = luaL_newstate();
    luaL_openlibs(M.L);
    registrarApi(M.L);

    // require("config") procura config.lua dentro da pasta de scripts
    lua_getglobal(M.L, "package");
    std::string caminho = (M.pastaScripts / "?.lua").string();
    lua_pushstring(M.L, caminho.c_str());
    lua_setfield(M.L, -2, "path");
    lua_pop(M.L, 1);

    M.datasScripts = lerDatasScripts();
    if (!executarArquivo(M.pastaScripts / "main.lua")) return;
    if (!M.arquivoTeste.empty() && !executarArquivo(M.arquivoTeste)) return;
    chamar("iniciar");
    TraceLog(LOG_INFO, "Scripts carregados de %s", M.pastaScripts.string().c_str());
}

// -----------------------------------------------------------------------------
//  Tela de erro (mostra o problema em vez de fechar o jogo)
// -----------------------------------------------------------------------------

static std::vector<std::string> quebrarLinhas(const std::string& texto, float tam, float largura) {
    std::vector<std::string> linhas;
    std::stringstream ss(texto);
    std::string paragrafo;
    while (std::getline(ss, paragrafo)) {
        std::replace(paragrafo.begin(), paragrafo.end(), '\t', ' ');
        std::string atual;
        std::stringstream palavras(paragrafo);
        std::string p;
        while (palavras >> p) {
            std::string teste = atual.empty() ? p : atual + " " + p;
            if (!atual.empty() &&
                MeasureTextEx(M.fonteNormal, teste.c_str(), tam, espacamento(tam)).x > largura) {
                linhas.push_back(atual);
                atual = p;
            } else {
                atual = teste;
            }
        }
        linhas.push_back(atual);
    }
    return linhas;
}

static void desenharErro() {
    DrawRectangle(0, 0, (int)LARGURA, (int)ALTURA, Color{40, 14, 14, 255});
    DrawTextEx(M.fonteNegrito, "Erro no script", Vector2{24, 28}, 30, espacamento(30), Color{255, 120, 100, 255});
    float y = 80;
    for (const auto& linha : quebrarLinhas(M.erro, 16, LARGURA - 48)) {
        if (y > ALTURA - 110) break;
        DrawTextEx(M.fonteNormal, linha.c_str(), Vector2{24, y}, 16, espacamento(16), Color{245, 225, 215, 255});
        y += 21;
    }
    DrawTextEx(M.fonteNormal, "Corrija o arquivo e salve: o jogo recarrega sozinho.", Vector2{24, ALTURA - 80}, 16,
               espacamento(16), Color{200, 170, 160, 255});
    DrawTextEx(M.fonteNormal, "Ou toque na tela / aperte F5 para tentar de novo.", Vector2{24, ALTURA - 56}, 16,
               espacamento(16), Color{200, 170, 160, 255});
}

// -----------------------------------------------------------------------------
//  Pastas e fontes
// -----------------------------------------------------------------------------

// Procura uma pasta ao lado do executável ou em pastas acima (útil no desenvolvimento).
static fs::path procurarPasta(const std::string& nome, const std::string& marcador) {
    fs::path base = fs::u8path(GetApplicationDirectory()).lexically_normal();
    if (!base.has_filename()) base = base.parent_path();
    for (int i = 0; i < 5 && !base.empty(); i++) {
        if (fs::exists(base / nome / marcador)) return base / nome;
        fs::path pai = base.parent_path();
        if (pai == base) break;
        base = pai;
    }
    std::error_code ec;
    if (fs::exists(fs::path(nome) / marcador)) return fs::absolute(nome, ec);
    return {};
}

static fs::path pastaDeDados() {
#if defined(__ANDROID__)
    return fs::path(android_sistema::pastaInterna());
#endif
#if defined(_WIN32)
    const wchar_t* appdata = _wgetenv(L"APPDATA");
    if (appdata) return fs::path(appdata) / "TavernaDeAventureiros";
#else
    const char* xdg = getenv("XDG_DATA_HOME");
    if (xdg && *xdg) return fs::path(xdg) / "taverna-de-aventureiros";
    const char* home = getenv("HOME");
    if (home) return fs::path(home) / ".local" / "share" / "taverna-de-aventureiros";
#endif
    return fs::path(".");
}

static Font carregarFonte(const fs::path& arquivo) {
    std::vector<int> letras;
    for (int c = 32; c <= 255; c++) letras.push_back(c);  // inclui acentos: á, ç, õ...
    for (int c : {0x2022, 0x2026, 0x2013, 0x2014, 0x2191, 0x2192}) letras.push_back(c);
    // pela memória: no Android, a raylib procura caminho absoluto dentro da pasta de dados e não acha
    std::string dados;
    if (!lerArquivo(arquivo, dados) || dados.empty()) return GetFontDefault();
    Font f = LoadFontFromMemory(".ttf", (const unsigned char*)dados.data(), (int)dados.size(), 64, letras.data(),
                                (int)letras.size());
    if (f.texture.id == 0) return GetFontDefault();
    if (f.texture.id != GetFontDefault().texture.id) {
        GenTextureMipmaps(&f.texture);
        SetTextureFilter(f.texture, TEXTURE_FILTER_TRILINEAR);
    }
    return f;
}

// -----------------------------------------------------------------------------
//  Programa principal
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//  Pacote embutido e atualização automática
//
//  Formato (gerado por tools/empacotar.py no final do .exe):
//    "TAVPAK01", quantidade (u32), e para cada arquivo:
//    tamanho do nome (u32), nome, tamanho dos dados (u32), dados
//  seguido de: tamanho do pacote (u64) e "TAVPAKFT"
// -----------------------------------------------------------------------------

static const char* URL_ATUALIZACAO =
    "https://github.com/gabriellpimentell-arch/taverna-de-aventureiros/releases/download/teste/";

struct Pacote {
    std::string versao;
    std::vector<std::pair<std::string, std::string>> arquivos;
};

static bool lerPacote(const std::string& b, Pacote& p) {
    if (b.size() < 16 || memcmp(b.data() + b.size() - 8, "TAVPAKFT", 8) != 0) return false;
    uint64_t tam = 0;
    memcpy(&tam, b.data() + b.size() - 16, 8);
    if (tam + 16 > b.size() || tam < 12) return false;
    size_t fim = b.size() - 16, pos = fim - (size_t)tam;
    if (memcmp(b.data() + pos, "TAVPAK01", 8) != 0) return false;
    pos += 8;
    auto u32 = [&](uint32_t& v) {
        if (pos + 4 > fim) return false;
        memcpy(&v, b.data() + pos, 4);
        pos += 4;
        return true;
    };
    auto bloco = [&](std::string& s) {
        uint32_t n = 0;
        if (!u32(n) || pos + n > fim) return false;
        s.assign(b.data() + pos, n);
        pos += n;
        return true;
    };
    uint32_t qtd = 0;
    if (!u32(qtd)) return false;
    p.arquivos.clear();
    for (uint32_t i = 0; i < qtd; i++) {
        std::string nome, dados;
        if (!bloco(nome) || !bloco(dados)) return false;
        if (nome == "versao.txt") p.versao = dados;
        else p.arquivos.emplace_back(nome, dados);
    }
    while (!p.versao.empty() && isspace((unsigned char)p.versao.back())) p.versao.pop_back();
    return !p.versao.empty();
}

// Extrai o pacote para a pasta de dados (só quando a versão muda).
static bool extrairPacote(const Pacote& p, const fs::path& pasta) {
    std::string atual;
    if (lerArquivo(pasta / "versao.txt", atual) && atual == p.versao) return true;
    // Extrai ao lado e só troca no fim: com o disco cheio, a versão que já funcionava continua inteira.
    std::error_code ec;
    fs::path temp = pasta;
    temp += ".novo";
    fs::remove_all(temp, ec);
    for (const auto& [nome, dados] : p.arquivos) {
        if (nome.find("..") != std::string::npos) continue;
        fs::path destino = temp / fs::u8path(nome);
        fs::create_directories(destino.parent_path(), ec);
        std::ofstream f(destino, std::ios::binary | std::ios::trunc);
        f.write(dados.data(), (std::streamsize)dados.size());
        f.flush();
        if (!f) return false;
    }
    {
        std::ofstream v(temp / "versao.txt", std::ios::binary | std::ios::trunc);
        v << p.versao;
        v.flush();
        if (!v) return false;
    }
    fs::remove_all(pasta, ec);
    fs::rename(temp, pasta, ec);
    return !ec;
}

static void atualizarCamera();

static void reiniciarModo2D() {
    BeginMode2D(M.camera);
    BeginScissorMode((int)M.camera.offset.x, (int)M.camera.offset.y, (int)std::ceil(LARGURA * M.camera.zoom),
                     (int)std::ceil(ALTURA * M.camera.zoom));
}

// Desenha uma tela simples de aviso (usada antes de o jogo carregar).
static void mostrarMensagem(const char* titulo, const char* detalhe) {
    for (int i = 0; i < 2; i++) {  // dois quadros: garante que aparece na tela
        atualizarCamera();
        BeginDrawing();
        ClearBackground(Color{18, 12, 8, 255});
        BeginMode2D(M.camera);
        DrawRectangle(0, 0, (int)LARGURA, (int)ALTURA, Color{33, 21, 14, 255});
        float t1 = 30, t2 = 16;
        Vector2 m1 = MeasureTextEx(M.fonteNegrito, titulo, t1, espacamento(t1));
        Vector2 m2 = MeasureTextEx(M.fonteNormal, detalhe, t2, espacamento(t2));
        DrawTextEx(M.fonteNegrito, titulo, Vector2{(LARGURA - m1.x) / 2, ALTURA / 2 - 34}, t1, espacamento(t1),
                   Color{246, 234, 216, 255});
        DrawTextEx(M.fonteNormal, detalhe, Vector2{(LARGURA - m2.x) / 2, ALTURA / 2 + 10}, t2, espacamento(t2),
                   Color{191, 165, 138, 255});
        EndMode2D();
        EndDrawing();
    }
}

// Devolve true se a versão nova foi aberta (aí esta deve fechar).
static bool verificarAtualizacao(const std::string& versaoLocal, const fs::path& exe) {
    mostrarMensagem("Taverna de Aventureiros", "Procurando atualizações...");
    std::string remota;
    if (!atualizador::baixar(std::string(URL_ATUALIZACAO) + "versao.txt", remota, 4000)) return false;
    while (!remota.empty() && isspace((unsigned char)remota.back())) remota.pop_back();
    if (remota.empty() || remota.size() > 64 || remota == versaoLocal) return false;

    mostrarMensagem("Atualizando...", "Baixando a versão nova do jogo.");
    std::string novo;
    if (!atualizador::baixar(std::string(URL_ATUALIZACAO) + "TavernaDeAventureiros.exe", novo, 20000)) return false;
    Pacote conferir;
    if (!lerPacote(novo, conferir) || conferir.versao != remota) return false;  // download incompleto

    fs::path temp = exe;
    temp += ".novo";
    {
        std::ofstream f(temp, std::ios::binary | std::ios::trunc);
        if (!f) return false;
        f.write(novo.data(), (std::streamsize)novo.size());
        if (!f) return false;
    }
    mostrarMensagem("Atualizado!", "Abrindo a versão nova...");
    if (atualizador::trocarExecutavelEReiniciar(exe, temp)) return true;
    std::error_code ec;
    fs::remove(temp, ec);
    return false;
}

#if defined(__ANDROID__)
// Muda quando o motor mudar: um APK antigo não pode rodar scripts que pedem funções novas.
static const char* MOTOR_ANDROID = "1";

// Baixa em outra linha de execução. Se o jogo ficasse parado esperando a internet, o sistema
// mostraria "o app não responde" ao receber um toque ou ao ir para o segundo plano.
static bool baixarSemTravar(const std::string& url, std::string& saida, int limiteMs, int& codigo, const char* titulo,
                            const char* detalhe) {
    struct Pedido {
        std::atomic<bool> pronto{false};
        bool ok = false;
        int codigo = 0;
        std::string dados;
    };
    auto p = std::make_shared<Pedido>();
    std::thread([p, url, limiteMs] {
        p->ok = android_sistema::baixar(url, p->dados, limiteMs, &p->codigo);
        p->pronto = true;
    }).detach();
    double inicio = GetTime();
    while (!p->pronto) {
        if (WindowShouldClose() || GetTime() - inicio > limiteMs * 3 / 1000.0) return false;  // desiste; o jogo segue
        mostrarMensagem(titulo, detalhe);
    }
    codigo = p->codigo;
    saida = std::move(p->dados);
    return p->ok;
}

static std::string g_versaoApk;

// O pacote baixado vale só para o APK que o baixou: instalar um APK novo por cima não pode
// fazer os scripts antigos voltarem no lugar dos que vieram nele.
static bool lerPacoteBaixado(Pacote& p) {
    fs::path bin = pastaDeDados() / "pacote_baixado.bin", origem = pastaDeDados() / "pacote_baixado.apk";
    std::string bytes, apk;
    if (!lerArquivo(bin, bytes)) return false;
    if (lerArquivo(origem, apk) && apk == g_versaoApk && lerPacote(bytes, p)) return true;
    std::error_code ec;
    fs::remove(bin, ec);
    fs::remove(origem, ec);
    return false;
}

#if defined(TAVERNA_PUBLICADO)
// Baixa só os scripts novos, sem reinstalar. Sem internet, segue com os que já tem.
static void atualizarScriptsAndroid(Pacote& pacote) {
    const char* procurando = "Procurando atualizações...";
    std::string remota;
    int codigo = 0;
    if (!baixarSemTravar(std::string(URL_ATUALIZACAO) + "versao.txt", remota, 4000, codigo, "Taverna de Aventureiros", procurando)) return;
    while (!remota.empty() && isspace((unsigned char)remota.back())) remota.pop_back();
    if (remota.empty() || remota.size() > 64 || remota == pacote.versao) return;
    std::string bytes;
    Pacote novo;
    bool baixou = baixarSemTravar(std::string(URL_ATUALIZACAO) + "pacote-m" + MOTOR_ANDROID + ".bin", bytes, 20000, codigo,
                                  "Atualizando...", "Baixando a versão nova do jogo.");
    if (!baixou) {
        // 404: o arquivo deste motor não existe mais e só um APK novo resolve. Internet ruim não conta.
        M.apkVelho = codigo == 404;
        return;
    }
    if (!lerPacote(bytes, novo) || novo.versao != remota) return;
    fs::path pasta = pastaDeDados() / "jogo";
    if (!extrairPacote(novo, pasta)) return;
    pacote = novo;
    M.versao = novo.versao;
    std::error_code ec;
    fs::path bin = pastaDeDados() / "pacote_baixado.bin", temp = bin;
    temp += ".tmp";
    std::ofstream f(temp, std::ios::binary | std::ios::trunc);
    f.write(bytes.data(), (std::streamsize)bytes.size());
    f.close();
    if (f) {
        fs::rename(temp, bin, ec);
        std::ofstream o(pastaDeDados() / "pacote_baixado.apk", std::ios::binary | std::ios::trunc);
        o << g_versaoApk;
    } else {
        fs::remove(temp, ec);
    }
}
#endif

// O sistema avisa pela mesma fila de eventos que a raylib lê dentro de EndDrawing, ou seja, entre
// dois quadros: é seguro chamar o Lua daqui. Em segundo plano o laço do jogo fica parado e a
// Android pode matar o processo sem aviso, então este é o último momento certo para salvar.
static void (*g_comandoRaylib)(android_app*, int32_t) = nullptr;
static int32_t (*g_entradaRaylib)(android_app*, AInputEvent*) = nullptr;
static bool g_pausou = false, g_voltou = false, g_botaoVoltar = false;

static void comandoAndroid(android_app* app, int32_t cmd) {
    g_comandoRaylib(app, cmd);
    if (cmd == APP_CMD_PAUSE) {
        g_toques.cancelar();
        sons::pausar();
        chamar("ao_sair", {}, true);
        g_pausou = true;
    } else if (cmd == APP_CMD_RESUME) {
        sons::retomar();
        if (g_pausou) g_voltou = true;
    } else if (cmd == APP_CMD_LOST_FOCUS) {
        g_toques.cancelar();
    }
}

static int32_t entradaAndroid(android_app* app, AInputEvent* ev) {
    int32_t r = g_entradaRaylib(app, ev);
    // Aqui, e não com IsKeyPressed: o gesto de voltar aperta e solta no mesmo quadro. Segurar não repete.
    if (AInputEvent_getType(ev) == AINPUT_EVENT_TYPE_KEY && AKeyEvent_getKeyCode(ev) == AKEYCODE_BACK &&
        AKeyEvent_getAction(ev) == AKEY_EVENT_ACTION_DOWN && AKeyEvent_getRepeatCount(ev) == 0) {
        g_botaoVoltar = true;
    }
    if (AInputEvent_getType(ev) == AINPUT_EVENT_TYPE_MOTION && (AInputEvent_getSource(ev) & AINPUT_SOURCE_CLASS_POINTER)) {
        Vector2 p = GetMousePosition();
        switch (AMotionEvent_getAction(ev) & AMOTION_EVENT_ACTION_MASK) {
            case AMOTION_EVENT_ACTION_DOWN: g_toques.descer(p.x, p.y, GetTime()); break;
            case AMOTION_EVENT_ACTION_POINTER_DOWN: g_toques.outroDedo(); break;
            case AMOTION_EVENT_ACTION_UP: g_toques.subir(p.x, p.y); break;
            case AMOTION_EVENT_ACTION_CANCEL: g_toques.cancelar(); break;
            default: break;
        }
    }
    return r;
}
#endif

static void atualizarCamera() {
    float lw = (float)GetScreenWidth(), lh = (float)GetScreenHeight();
    float escala = std::min(lw / LARGURA, lh / ALTURA);
    M.camera.zoom = escala;
    M.camera.offset = Vector2{std::floor((lw - LARGURA * escala) / 2.0f), std::floor((lh - ALTURA * escala) / 2.0f)};
    M.camera.target = Vector2{0, 0};
    M.camera.rotation = 0;
}

int main() {
#if defined(__ANDROID__)
    // O sistema pode abrir o jogo de novo no mesmo processo: nada da sessão anterior pode sobrar.
    M = Motor{};
    cena3d::E = cena3d::Estado{};
    g_sair = false;
    g_toques = toques::Rastreador{};
    g_pausou = g_voltou = g_botaoVoltar = false;
#endif
    unsigned int flags = FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT;
    if (!getenv("TAVERNA_TESTE")) flags |= FLAG_MSAA_4X_HINT;  // bordas mais suaves
    SetConfigFlags(flags);
#if defined(__ANDROID__)
    InitWindow(0, 0, "Taverna de Aventureiros");  // a tela toda do celular
    g_comandoRaylib = GetAndroidApp()->onAppCmd;
    g_entradaRaylib = GetAndroidApp()->onInputEvent;
    GetAndroidApp()->onAppCmd = comandoAndroid;
    GetAndroidApp()->onInputEvent = entradaAndroid;
#else
    InitWindow(1280, 720, "Taverna de Aventureiros");
    SetWindowMinSize(480, 270);
#endif
    SetExitKey(KEY_NULL);  // ESC não fecha o jogo
    SetTargetFPS(60);

#if !defined(__ANDROID__)
    // modo janela (F11): 80% da largura do monitor, centralizada
    int monitor = GetCurrentMonitor();
    int mh = GetMonitorHeight(monitor), mw = GetMonitorWidth(monitor);
    if (getenv("TAVERNA_TESTE")) {
        SetWindowSize((int)LARGURA, (int)ALTURA);
    } else {
        if (mh > 0 && mw > 0) {
            int w = (int)(mw * 0.8f), h = (int)(w * ALTURA / LARGURA);
            if (h > mh * 0.85f) { h = (int)(mh * 0.85f); w = (int)(h * LARGURA / ALTURA); }
            SetWindowSize(w, h);
            SetWindowPosition((mw - w) / 2, (mh - h) / 2);
        }
        ToggleBorderlessWindowed();  // começa em tela cheia
    }
#endif

    // Versão distribuída: scripts e fontes embutidos no próprio .exe
    fs::path exe = atualizador::caminhoExecutavel();
    atualizador::limparVersaoAntiga(exe);
    Pacote pacote;
    bool temPacote = false;
#if defined(__ANDROID__)
    // No celular, o pacote vem dentro do APK; o baixado depois tem prioridade.
    {
        std::string bytes;
        temPacote = android_sistema::lerAsset("pacote.bin", bytes) && lerPacote(bytes, pacote);
        g_versaoApk = pacote.versao;
        Pacote baixado;
        if (lerPacoteBaixado(baixado)) {
            pacote = baixado;
            temPacote = true;
        }
    }
#else
    {
        std::string bytes;
        temPacote = !exe.empty() && lerArquivo(exe, bytes) && lerPacote(bytes, pacote);
    }
#endif
    if (temPacote) {
        fs::path pasta = pastaDeDados() / "jogo";
        if (extrairPacote(pacote, pasta)) {
            M.versao = pacote.versao;
            M.pastaScripts = pasta / "scripts";
            M.pastaAssets = pasta / "assets";
        } else {
            temPacote = false;
        }
    }
    if (!temPacote) {  // desenvolvimento: usa as pastas ao lado do executável
        M.pastaScripts = procurarPasta("scripts", "main.lua");
        M.pastaAssets = procurarPasta("assets", "fontes");
    }
    M.arquivoSave = pastaDeDados() / "progresso_v2.sav";  // o save do jogo 2D fica intacto
    if (const char* teste = getenv("TAVERNA_TESTE")) M.arquivoTeste = teste;
    if (const char* save = getenv("TAVERNA_SAVE")) M.arquivoSave = save;
    g_layout = M.arquivoSave;
    g_layout += ".layout";

    M.fonteNormal = carregarFonte(M.pastaAssets / "fontes" / "Poppins-Regular.ttf");
    M.fonteNegrito = carregarFonte(M.pastaAssets / "fontes" / "Poppins-Bold.ttf");
    M.fontesProprias = M.fonteNormal.texture.id != GetFontDefault().texture.id &&
                       M.fonteNegrito.texture.id != GetFontDefault().texture.id;
    if (!M.fontesProprias) {
        M.fonteNormal = GetFontDefault();
        M.fonteNegrito = GetFontDefault();
    }

#if defined(__ANDROID__)
#if defined(TAVERNA_PUBLICADO)
    if (temPacote) atualizarScriptsAndroid(pacote);
#endif
#else
    if (temPacote && !getenv("TAVERNA_SEM_ATUALIZAR") && verificarAtualizacao(M.versao, exe)) {
        if (M.fontesProprias) {
            UnloadFont(M.fonteNormal);
            UnloadFont(M.fonteNegrito);
        }
        CloseWindow();
        return 0;  // a versão nova já está abrindo
    }
#endif

    sons::iniciar();

    if (M.pastaScripts.empty()) {
        M.erro = "Não encontrei a pasta 'scripts' com o main.lua.\nEla precisa ficar ao lado do executável.";
    } else {
        carregarScripts();
    }

    while (!WindowShouldClose() && !g_sair) {
        sons::atualizar();
        float dt = std::min(GetFrameTime(), 0.1f);

#if !defined(__ANDROID__)  // no celular os scripts só mudam ao atualizar
        // recarrega sozinho quando algum .lua muda
        M.relogioVigia += dt;
        if (!M.pastaScripts.empty() && M.relogioVigia > 0.5f) {
            M.relogioVigia = 0;
            if (lerDatasScripts() != M.datasScripts) carregarScripts();
        }
#endif
        if (IsKeyPressed(KEY_F5) && !M.pastaScripts.empty()) carregarScripts();

        // F11 ou Alt+Enter: alterna entre tela cheia e janela
        bool alt = IsKeyDown(KEY_LEFT_ALT) || IsKeyDown(KEY_RIGHT_ALT);
#if !defined(__ANDROID__)
        if (IsKeyPressed(KEY_F11) || (alt && IsKeyPressed(KEY_ENTER))) ToggleBorderlessWindowed();
#else
        (void)alt;
#endif

        atualizarCamera();

        auto tocou = [](Vector2 p) {
            if (p.x >= 0 && p.y >= 0 && p.x <= LARGURA && p.y <= ALTURA) {
                if (M.erro.empty()) chamar("tocar", {p.x, p.y});
                else if (!M.pastaScripts.empty()) carregarScripts();
            }
        };
#if defined(__ANDROID__)
        if (g_voltou) {
            g_voltou = false;
            chamar("ao_voltar");
        }
        for (const toques::Evento& ev : g_toques.quadro(GetTime())) {
            Vector2 p = GetScreenToWorld2D(Vector2{ev.x, ev.y}, M.camera);
            if (ev.tipo == toques::TOCAR) tocou(p);
            else if (ev.tipo == toques::SOLTAR) { if (M.erro.empty()) chamar("soltar", {p.x, p.y}); }
            else chamar("cancelar_toque");
        }
        if (g_botaoVoltar) {
            g_botaoVoltar = false;
            chamar("tecla_esc");
        }
#else
        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) tocou(GetScreenToWorld2D(GetMousePosition(), M.camera));

        if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT) && M.erro.empty()) {
            Vector2 p = GetScreenToWorld2D(GetMousePosition(), M.camera);
            chamar("soltar", {p.x, p.y});
        }
        if (IsKeyPressed(KEY_ESCAPE)) chamar("tecla_esc");
#endif
        if (IsKeyPressed(KEY_F2)) chamar("tecla_f2");

        chamar("atualizar", {dt});
        chamar("teste", {dt});

        BeginDrawing();
        ClearBackground(Color{18, 12, 8, 255});
        BeginMode2D(M.camera);
        BeginScissorMode((int)M.camera.offset.x, (int)M.camera.offset.y, (int)std::ceil(LARGURA * M.camera.zoom),
                         (int)std::ceil(ALTURA * M.camera.zoom));
        if (M.erro.empty()) chamar("desenhar");
        if (!M.erro.empty()) desenharErro();
        EndScissorMode();
        EndMode2D();
        EndDrawing();
    }

    chamar("ao_sair", {}, true);
    if (M.L) lua_close(M.L);
    M.L = nullptr;
    sons::encerrar();
#if defined(__ANDROID__)
    // só depois disto a raylib zera o próprio estado, o que permite abrir de novo no mesmo processo
    android_sistema::fecharAtividade();
#endif
    if (M.fontesProprias) {
        UnloadFont(M.fonteNormal);
        UnloadFont(M.fonteNegrito);
    }
    CloseWindow();
    return 0;
}
