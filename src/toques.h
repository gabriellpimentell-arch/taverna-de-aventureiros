// Traduz os dedos na tela em toques do jogo. Só o Android usa; não depende de nada
// do sistema, para poder ser testado no computador (tests/toques_teste.cpp).
//
//  - O toque espera um instante antes de valer: se um segundo dedo chegar, era pinça
//    e nenhum botão é apertado por engano.
//  - Toque rápido entre dois quadros não se perde: chegam "tocar" e "soltar" juntos.
//  - Durante a pinça, nada de arrastar; ela só termina quando todos os dedos saem.
#pragma once

#include <vector>

namespace toques {

enum Tipo { TOCAR, SOLTAR, CANCELAR };
struct Evento {
    Tipo tipo;
    float x, y;
};

static const double ESPERA_SEGUNDOS = 0.07;

class Rastreador {
public:
    void descer(float x, float y, double t) {
        if (estado == ATIVO) fila.push_back({CANCELAR, x, y});  // o sistema perdeu o "soltar" anterior
        estado = ESPERA;
        x0 = x;
        y0 = y;
        t0 = t;
    }
    void outroDedo() {
        if (estado == ATIVO) fila.push_back({CANCELAR, x0, y0});
        if (estado != PARADO) estado = PINCA;
    }
    // o último dedo saiu
    void subir(float x, float y) {
        if (estado == ESPERA) fila.push_back({TOCAR, x0, y0});
        if (estado == ESPERA || estado == ATIVO) fila.push_back({SOLTAR, x, y});
        estado = PARADO;
    }
    // o sistema tirou os dedos do jogo: notificação, troca de app, tela apagada
    void cancelar() {
        if (estado == ATIVO) fila.push_back({CANCELAR, x0, y0});
        estado = PARADO;
    }
    // Chamar uma vez por quadro: devolve o que aconteceu desde o quadro anterior.
    std::vector<Evento> quadro(double t) {
        if (estado == ESPERA && t - t0 >= ESPERA_SEGUNDOS) {
            fila.push_back({TOCAR, x0, y0});
            estado = ATIVO;
        }
        std::vector<Evento> saida;
        saida.swap(fila);
        return saida;
    }
    bool baixo() const { return estado == ATIVO; }

private:
    enum Estado { PARADO, ESPERA, ATIVO, PINCA };
    Estado estado = PARADO;
    float x0 = 0, y0 = 0;
    double t0 = 0;
    std::vector<Evento> fila;
};

}  // namespace toques
