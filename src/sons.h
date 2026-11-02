// =============================================================================
//  Sons gerados por código: efeitos curtos e uma musiquinha de taverna em laço.
//  Se o computador não tiver saída de áudio, tudo simplesmente fica em silêncio.
// =============================================================================
#pragma once

#include "raylib.h"

#include <cmath>
#include <cstdlib>
#include <map>
#include <string>
#include <vector>

namespace sons {

static const int TAXA = 22050;
static bool g_pronto = false;
static float g_vEfeitos = 0.7f, g_vMusica = 0.4f;
static std::map<std::string, Sound> g_efeitos;
static Sound g_musica{};

static Sound criar(const std::vector<short>& a) {
    Wave w{};
    w.frameCount = (unsigned int)a.size();
    w.sampleRate = TAXA;
    w.sampleSize = 16;
    w.channels = 1;
    w.data = (void*)a.data();
    return LoadSoundFromWave(w);
}

// nota com ataque curto e queda, somando harmônicos: lembra corda dedilhada
static void nota(std::vector<short>& a, double inicio, double dur, double freq, double vol) {
    size_t i0 = (size_t)(inicio * TAXA), n = (size_t)(dur * TAXA);
    if (a.size() < i0 + n) a.resize(i0 + n, 0);
    for (size_t i = 0; i < n; i++) {
        double t = (double)i / TAXA;
        double env = std::min(t * 200.0, 1.0) * std::exp(-t * 3.2 / dur);
        double v = std::sin(2 * PI * freq * t) + 0.45 * std::sin(4 * PI * freq * t) + 0.2 * std::sin(6 * PI * freq * t);
        int s = a[i0 + i] + (int)(v * env * vol * 9000.0);
        a[i0 + i] = (short)std::max(-32000, std::min(32000, s));
    }
}

static double midi(int m) { return 440.0 * std::pow(2.0, (m - 69) / 12.0); }

static Sound efeito(std::initializer_list<std::pair<int, double>> notas, double passo, double dur, double vol) {
    std::vector<short> a;
    double t = 0;
    for (auto& n : notas) {
        nota(a, t, dur, midi(n.first), vol * n.second);
        t += passo;
    }
    return criar(a);
}

static void gerarMusica() {
    // valsa em lá menor, 16 compassos
    static const int acordes[8][3] = {{57, 60, 64}, {53, 57, 60}, {48, 52, 55}, {55, 59, 62},
                                      {57, 60, 64}, {53, 57, 60}, {52, 56, 59}, {57, 60, 64}};
    static const int melodia[48] = {76, 0, 72, 69, 0, 72, 77, 0, 76, 72, 0, 69, 79, 0, 76, 72, 0, 76, 74, 0, 71, 67, 0, 71,
                                    76, 0, 79, 81, 0, 79, 77, 0, 76, 74, 0, 72, 71, 0, 74, 76, 0, 74, 69, 0, 0, 69, 0, 0};
    const double compasso = 1.35, passo = compasso / 3;
    std::vector<short> a;
    for (int rep = 0; rep < 2; rep++) {
        for (int c = 0; c < 8; c++) {
            double t0 = (rep * 8 + c) * 2 * compasso;
            for (int b = 0; b < 2; b++) {
                double t = t0 + b * compasso;
                nota(a, t, 1.1, midi(acordes[c][0] - 12), 0.42);
                nota(a, t + passo, 0.7, midi(acordes[c][1]), 0.2);
                nota(a, t + passo, 0.7, midi(acordes[c][2]), 0.2);
                nota(a, t + 2 * passo, 0.7, midi(acordes[c][1]), 0.2);
                nota(a, t + 2 * passo, 0.7, midi(acordes[c][2]), 0.2);
            }
            for (int i = 0; i < 6; i++) {
                int m = melodia[c * 6 + i];
                if (m && rep == 1) nota(a, t0 + i * passo, 0.8, midi(m + 12), 0.2);
                if (m && rep == 0) nota(a, t0 + i * passo, 0.8, midi(m), 0.3);
            }
        }
    }
    g_musica = criar(a);
}

static void iniciar() {
    InitAudioDevice();
    if (!IsAudioDeviceReady()) return;
    g_pronto = true;
    g_efeitos["moeda"] = efeito({{88, 0.6}, {93, 0.8}}, 0.05, 0.14, 0.9);
    g_efeitos["clique"] = efeito({{72, 0.5}}, 0.0, 0.06, 0.8);
    g_efeitos["compra"] = efeito({{72, 0.7}, {76, 0.7}, {79, 0.8}, {84, 1.0}}, 0.06, 0.2, 0.9);
    g_efeitos["erro"] = efeito({{50, 1.0}, {47, 1.0}}, 0.08, 0.14, 0.9);
    g_efeitos["missao"] = efeito({{67, 0.8}, {72, 0.8}, {76, 1.0}}, 0.1, 0.3, 0.8);
    g_efeitos["briga"] = efeito({{45, 1.0}, {44, 1.0}, {45, 1.0}, {41, 1.0}}, 0.06, 0.1, 1.0);
    g_efeitos["invocar"] = efeito({{60, 0.6}, {67, 0.7}, {72, 0.8}, {79, 0.9}, {84, 1.0}, {91, 1.0}}, 0.12, 0.6, 0.8);
    gerarMusica();
}

static void volumes(float efeitos, float musica) {
    g_vEfeitos = efeitos;
    g_vMusica = musica;
    if (g_pronto) SetSoundVolume(g_musica, musica);
}

static void tocar(const std::string& nome) {
    if (!g_pronto) return;
    auto it = g_efeitos.find(nome);
    if (it == g_efeitos.end()) return;
    SetSoundVolume(it->second, g_vEfeitos);
    PlaySound(it->second);
}

static void atualizar() {
    if (g_pronto && g_vMusica > 0.001f && !IsSoundPlaying(g_musica)) {
        SetSoundVolume(g_musica, g_vMusica);
        PlaySound(g_musica);
    }
    if (g_pronto && g_vMusica <= 0.001f && IsSoundPlaying(g_musica)) StopSound(g_musica);
}

static void encerrar() {
    if (!g_pronto) return;
    for (auto& e : g_efeitos) UnloadSound(e.second);
    UnloadSound(g_musica);
    CloseAudioDevice();
}

}  // namespace sons
