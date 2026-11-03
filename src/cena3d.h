// =============================================================================
//  Cena 3D low poly (protótipo)
//
//  O Lua descreve a cena peça por peça e o motor desenha tudo de uma vez, com
//  sombra projetada e iluminação de faces planas.
//
//      motor.cena_camera(px, py, pz, ax, ay, az, fov)
//      motor.cena_luz(i, x, y, z, r, g, b, alcance)     i = 1 a 4
//      motor.peca(forma, x, y, z, ex, ey, ez, giro, cor, inclina_x, inclina_z, brilho)
//          forma: "caixa", "cilindro", "cone" ou "esfera"
//      motor.cena_desenhar()
//      motor.projetar(x, y, z) -> x, y na tela virtual de 960 x 540
//      motor.fps()
// =============================================================================
#pragma once

#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>
#include <vector>

namespace cena3d {

static const int TAM_SOMBRA = 2048;
static const int MAX_LUZES = 4;

enum Forma { CAIXA = 0, CILINDRO, CONE, ESFERA, N_FORMAS };

struct Peca {
    int forma;
    Matrix m;
    Color cor;
    float brilho;
};

struct Luz {
    float pos[3] = {0, 0, 0};
    float cor[3] = {0, 0, 0};
    float alcance = 1;
};

struct Estado {
    bool pronto = false;
    Mesh malhas[N_FORMAS]{};
    Shader sombreador{};
    Shader profundidade{};
    Material matCor{};
    Material matSombra{};
    unsigned int fbo = 0, texSombra = 0, texCorSombra = 0;
    int locLuzVP = -1, locSol = -1, locBrilho = -1, locSombra = -1, locCamera = -1;
    int locLuzPos = -1, locLuzCor = -1, locLuzAlc = -1;
    std::vector<Peca> pecas;
    Luz luzes[MAX_LUZES];
    Vector3 camPos{9, 11, 15}, camAlvo{0, 0, 0};
    float fov = 28.0f;
    bool sombras = true;
    float sombraX = 3.0f, sombraZ = 0.0f, sombraRaio = 24.0f;
};

static Estado E;

static const char* VS_COR = R"(#version 330
in vec3 vertexPosition;
uniform mat4 mvp;
uniform mat4 matModel;
uniform mat4 luzVP;
out vec3 posMundo;
out vec4 posLuz;
void main() {
    vec4 m = matModel * vec4(vertexPosition, 1.0);
    posMundo = m.xyz;
    posLuz = luzVP * m;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
)";

static const char* FS_COR = R"(#version 330
in vec3 posMundo;
in vec4 posLuz;
out vec4 saida;
uniform vec4 colDiffuse;
uniform vec3 solDir;
uniform float brilho;
uniform sampler2D mapaSombra;
uniform vec3 luzPos[4];
uniform vec3 luzCor[4];
uniform float luzAlc[4];

float sombra(vec3 n) {
    vec3 p = posLuz.xyz / posLuz.w * 0.5 + 0.5;
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z > 1.0) return 1.0;
    float vies = max(0.0022 * (1.0 - dot(n, solDir)), 0.0007);
    vec2 passo = 1.0 / vec2(textureSize(mapaSombra, 0));
    float luz = 0.0;
    for (int x = -1; x <= 1; x++)
        for (int y = -1; y <= 1; y++)
            luz += (p.z - vies > texture(mapaSombra, p.xy + vec2(x, y) * passo * 1.3).r) ? 0.0 : 1.0;
    return luz / 9.0;
}

void main() {
    // normal da face: é o que dá o visual facetado do low poly
    vec3 n = normalize(cross(dFdx(posMundo), dFdy(posMundo)));

    vec3 base = colDiffuse.rgb;
    vec3 ceu = vec3(0.50, 0.46, 0.50);
    vec3 chao = vec3(0.27, 0.19, 0.16);
    vec3 luz = mix(chao, ceu, n.y * 0.5 + 0.5);

    float difuso = max(dot(n, solDir), 0.0);
    luz += vec3(1.05, 0.90, 0.72) * difuso * sombra(n);

    for (int i = 0; i < 4; i++) {
        if (luzAlc[i] <= 0.0) continue;
        vec3 d = luzPos[i] - posMundo;
        float dist = length(d);
        float a = clamp(1.0 - dist / luzAlc[i], 0.0, 1.0);
        luz += luzCor[i] * a * a * (0.35 + 0.65 * max(dot(n, d / max(dist, 0.001)), 0.0));
    }

    vec3 c = base * luz + base * brilho;
    c = c / (1.0 + c * 0.18);    // segura os claros sem estourar
    saida = vec4(pow(c, vec3(0.92)), 1.0);
}
)";

static const char* VS_PROF = R"(#version 330
in vec3 vertexPosition;
uniform mat4 mvp;
void main() { gl_Position = mvp * vec4(vertexPosition, 1.0); }
)";

static const char* FS_PROF = R"(#version 330
out vec4 saida;
void main() { saida = vec4(1.0); }
)";

// No celular (OpenGL ES 3) muda só o cabeçalho dos sombreadores
static std::string adaptar(const char* fonte) {
    std::string s = fonte;
#if defined(__ANDROID__) || defined(TAVERNA_ES3)
    const std::string de = "#version 330";
    size_t p = s.find(de);
    if (p != std::string::npos) s.replace(p, de.size(), "#version 300 es\nprecision highp float;\nprecision highp sampler2D;");
#endif
    return s;
}

static Vector3 solDirecao() { return Vector3Normalize(Vector3{-0.55f, 1.0f, 0.62f}); }

static void preparar() {
    if (E.pronto) return;
    E.pronto = true;

    E.malhas[CAIXA] = GenMeshCube(1, 1, 1);
    E.malhas[CILINDRO] = GenMeshCylinder(0.5f, 1, 9);
    E.malhas[CONE] = GenMeshCone(0.5f, 1, 9);
    E.malhas[ESFERA] = GenMeshSphere(0.5f, 6, 9);

    E.sombreador = LoadShaderFromMemory(adaptar(VS_COR).c_str(), adaptar(FS_COR).c_str());
    E.sombreador.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocation(E.sombreador, "matModel");
    E.locLuzVP = GetShaderLocation(E.sombreador, "luzVP");
    E.locSol = GetShaderLocation(E.sombreador, "solDir");
    E.locBrilho = GetShaderLocation(E.sombreador, "brilho");
    E.locSombra = GetShaderLocation(E.sombreador, "mapaSombra");
    E.locLuzPos = GetShaderLocation(E.sombreador, "luzPos");
    E.locLuzCor = GetShaderLocation(E.sombreador, "luzCor");
    E.locLuzAlc = GetShaderLocation(E.sombreador, "luzAlc");
    E.profundidade = LoadShaderFromMemory(adaptar(VS_PROF).c_str(), adaptar(FS_PROF).c_str());

    E.matCor = LoadMaterialDefault();
    E.matCor.shader = E.sombreador;
    E.matSombra = LoadMaterialDefault();
    E.matSombra.shader = E.profundidade;

    E.fbo = rlLoadFramebuffer();
    rlEnableFramebuffer(E.fbo);
    E.texCorSombra = rlLoadTexture(nullptr, TAM_SOMBRA, TAM_SOMBRA, RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8, 1);
    E.texSombra = rlLoadTextureDepth(TAM_SOMBRA, TAM_SOMBRA, false);
    rlFramebufferAttach(E.fbo, E.texCorSombra, RL_ATTACHMENT_COLOR_CHANNEL0, RL_ATTACHMENT_TEXTURE2D, 0);
    rlFramebufferAttach(E.fbo, E.texSombra, RL_ATTACHMENT_DEPTH, RL_ATTACHMENT_TEXTURE2D, 0);
    if (!rlFramebufferComplete(E.fbo)) TraceLog(LOG_WARNING, "CENA3D: mapa de sombra incompleto");
    rlDisableFramebuffer();
}

static Matrix matrizVista() { return MatrixLookAt(E.camPos, E.camAlvo, Vector3{0, 1, 0}); }

static Matrix matrizProjecao(float largura, float altura) {
    // a câmera recua com o tamanho da taverna: o limite de visão precisa recuar junto
    float d = Vector3Distance(E.camPos, E.camAlvo);
    return MatrixPerspective(E.fov * DEG2RAD, largura / altura, 0.5, std::max(200.0f, d * 3.0f));
}

// Desenha a cena na área (x, y, w, h) da tela, em pixels, contando de cima.
static void desenhar(int x, int y, int w, int h, int alturaTela) {
    preparar();
    rlDrawRenderBatchActive();

    Vector3 sol = solDirecao();
    Vector3 centro{E.sombraX, 0.0f, E.sombraZ};
    float raioS = E.sombraRaio;
    Vector3 posSol = Vector3Add(centro, Vector3Scale(sol, raioS * 1.25f));
    Matrix luzVista = MatrixLookAt(posSol, centro, Vector3{0, 1, 0});
    Matrix luzProj = MatrixOrtho(-raioS, raioS, -raioS * 0.84, raioS * 0.84, 1, raioS * 3.4);
    Matrix luzVP = MatrixMultiply(luzVista, luzProj);

    rlEnableDepthTest();
    rlDisableBackfaceCulling();

    // 1) sombra: desenha do ponto de vista do sol
    rlEnableFramebuffer(E.fbo);
    rlViewport(0, 0, TAM_SOMBRA, TAM_SOMBRA);
    rlClearColor(255, 255, 255, 255);
    rlClearScreenBuffers();
    rlSetMatrixProjection(luzProj);
    rlSetMatrixModelview(luzVista);
    if (E.sombras) for (const Peca& p : E.pecas) {
        if (p.brilho >= 1.0f) continue;  // o que emite luz (fogo) não faz sombra
        DrawMesh(E.malhas[p.forma], E.matSombra, p.m);
    }
    rlDisableFramebuffer();

    // 2) cor
    rlViewport(x, alturaTela - y - h, w, h);
    rlSetMatrixProjection(matrizProjecao((float)w, (float)h));
    rlSetMatrixModelview(matrizVista());

    float pos[MAX_LUZES * 3], cor[MAX_LUZES * 3], alc[MAX_LUZES];
    for (int i = 0; i < MAX_LUZES; i++) {
        memcpy(pos + i * 3, E.luzes[i].pos, sizeof(float) * 3);
        memcpy(cor + i * 3, E.luzes[i].cor, sizeof(float) * 3);
        alc[i] = E.luzes[i].alcance;
    }
    int slot = 5;
    rlEnableShader(E.sombreador.id);
    rlSetUniformMatrix(E.locLuzVP, luzVP);
    float s[3] = {sol.x, sol.y, sol.z};
    rlSetUniform(E.locSol, s, RL_SHADER_UNIFORM_VEC3, 1);
    rlSetUniform(E.locLuzPos, pos, RL_SHADER_UNIFORM_VEC3, MAX_LUZES);
    rlSetUniform(E.locLuzCor, cor, RL_SHADER_UNIFORM_VEC3, MAX_LUZES);
    rlSetUniform(E.locLuzAlc, alc, RL_SHADER_UNIFORM_FLOAT, MAX_LUZES);
    rlSetUniform(E.locSombra, &slot, RL_SHADER_UNIFORM_INT, 1);
    rlActiveTextureSlot(slot);
    rlEnableTexture(E.texSombra);
    rlActiveTextureSlot(0);

    for (const Peca& p : E.pecas) {
        E.matCor.maps[MATERIAL_MAP_DIFFUSE].color = p.cor;
        rlEnableShader(E.sombreador.id);
        rlSetUniform(E.locBrilho, &p.brilho, RL_SHADER_UNIFORM_FLOAT, 1);
        DrawMesh(E.malhas[p.forma], E.matCor, p.m);
    }

    rlActiveTextureSlot(slot);
    rlDisableTexture();
    rlActiveTextureSlot(0);
    rlDisableShader();
    rlEnableBackfaceCulling();
    rlDisableDepthTest();
    E.pecas.clear();
}

// Posição 3D -> tela virtual
static bool projetar(Vector3 p, float largura, float altura, float& sx, float& sy) {
    Matrix m = MatrixMultiply(matrizVista(), matrizProjecao(largura, altura));
    float cx = m.m0 * p.x + m.m4 * p.y + m.m8 * p.z + m.m12;
    float cy = m.m1 * p.x + m.m5 * p.y + m.m9 * p.z + m.m13;
    float cw = m.m3 * p.x + m.m7 * p.y + m.m11 * p.z + m.m15;
    if (cw <= 0.0001f) return false;
    sx = (cx / cw + 1.0f) * 0.5f * largura;
    sy = (1.0f - cy / cw) * 0.5f * altura;
    return true;
}

// Tela virtual -> ponto do chão (y = 0)
static bool chao(float sx, float sy, float largura, float altura, Vector3& saida) {
    Matrix inv = MatrixInvert(MatrixMultiply(matrizVista(), matrizProjecao(largura, altura)));
    float nx = sx / largura * 2.0f - 1.0f, ny = 1.0f - sy / altura * 2.0f;
    auto desfaz = [&](float nz) {
        float x = inv.m0 * nx + inv.m4 * ny + inv.m8 * nz + inv.m12;
        float y = inv.m1 * nx + inv.m5 * ny + inv.m9 * nz + inv.m13;
        float z = inv.m2 * nx + inv.m6 * ny + inv.m10 * nz + inv.m14;
        float w = inv.m3 * nx + inv.m7 * ny + inv.m11 * nz + inv.m15;
        return Vector3{x / w, y / w, z / w};
    };
    Vector3 a = desfaz(-1.0f), b = desfaz(1.0f);
    if (std::fabs(b.y - a.y) < 0.0001f) return false;
    float t = -a.y / (b.y - a.y);
    saida = Vector3{a.x + (b.x - a.x) * t, 0.0f, a.z + (b.z - a.z) * t};
    return true;
}

}  // namespace cena3d
