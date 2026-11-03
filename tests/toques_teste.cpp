// Toques no celular: pinça, toque rápido e dedos perdidos. Compilado por tests/rodar.sh.
#include "../src/toques.h"

#include <cstdio>
#include <string>

using namespace toques;
static int falhas = 0;

static std::string nomes(const std::vector<Evento>& v) {
    std::string s;
    for (const Evento& e : v) s += e.tipo == TOCAR ? "T" : e.tipo == SOLTAR ? "S" : "C";
    return s;
}
static void ok(const char* nome, const std::string& obtido, const std::string& esperado) {
    if (obtido != esperado) {
        printf("FALHOU %s: obteve '%s', esperava '%s'\n", nome, obtido.c_str(), esperado.c_str());
        falhas++;
    }
}

int main() {
    {
        Rastreador r;  // toque e soltura entre dois quadros
        r.descer(10, 20, 1.0);
        r.subir(11, 21);
        auto e = r.quadro(1.01);
        ok("toque rapido chega inteiro", nomes(e), "TS");
        ok("toque usa o ponto onde desceu", e[0].x == 10 && e[0].y == 20 ? "sim" : "nao", "sim");
        ok("nada sobra", nomes(r.quadro(1.02)), "");
    }
    {
        Rastreador r;  // pinça: nenhum botão apertado, nada ao soltar
        r.descer(10, 20, 1.0);
        ok("espera o segundo dedo", nomes(r.quadro(1.03)), "");
        r.outroDedo();
        ok("pinca nao toca", nomes(r.quadro(1.5)), "");
        ok("pinca nao arrasta", r.baixo() ? "sim" : "nao", "nao");
        r.subir(5, 5);
        ok("pinca nao solta", nomes(r.quadro(1.6)), "");
    }
    {
        Rastreador r;  // arrastando e chega o segundo dedo: cancela
        r.descer(10, 20, 1.0);
        ok("toque longo vale", nomes(r.quadro(1.1)), "T");
        ok("arrasta", r.baixo() ? "sim" : "nao", "sim");
        r.outroDedo();
        ok("segundo dedo cancela", nomes(r.quadro(1.2)), "C");
        r.subir(1, 1);
        ok("sem soltar depois de cancelar", nomes(r.quadro(1.3)), "");
    }
    {
        Rastreador r;  // jogo minimizado com o dedo na tela
        r.descer(1, 1, 1.0);
        r.quadro(1.1);
        r.cancelar();
        ok("cancelar avisa o jogo", nomes(r.quadro(1.2)), "C");
        ok("nao fica preso", r.baixo() ? "sim" : "nao", "nao");
        r.descer(1, 1, 2.0);
        r.cancelar();
        ok("cancelar antes de valer nao toca", nomes(r.quadro(3.0)), "");
    }
    {
        Rastreador r;  // o sistema perdeu o "soltar"
        r.descer(1, 1, 1.0);
        r.quadro(1.1);
        r.descer(2, 2, 2.0);
        ok("dedo novo fecha o toque perdido", nomes(r.quadro(2.1)), "CT");
    }
    if (falhas == 0) printf("toques: ok\n");
    return falhas == 0 ? 0 : 1;
}
