# Taverna de Aventureiros

Jogo incremental 2D: você gerencia uma taverna que serve heróis, contrata funcionários e cresce até virar o ponto de encontro mais famoso do reino. Tudo se joga com um toque ou um clique.

## Como jogar a versão de teste (Windows)

1. Abra a página **Releases** deste repositório e baixe só o `TavernaDeAventureiros.exe` da **Versão de teste**.
2. Abra o `.exe`. Se o Windows mostrar "O Windows protegeu o computador", clique em **Mais informações** → **Executar assim mesmo** (o jogo ainda não tem assinatura digital).

**Atualização automática:** os scripts e as fontes vão embutidos no próprio `.exe`. Toda vez que abre, o jogo confere aqui no GitHub se existe uma versão nova; se existir, baixa, se substitui e reinicia sozinho. A versão atual aparece no canto inferior esquerdo do salão. Sem internet, o jogo abre normalmente na versão que já tem.

A cada mudança enviada para o GitHub, uma nova versão de teste é gerada automaticamente.

## Como o projeto é organizado

| Pasta | O que tem |
| --- | --- |
| `src/` | Motor em C++ (raylib): janela, desenho, toque/clique, fontes, salvar |
| `scripts/` | O jogo em Lua: `jogo.lua` (regras), `arvore.lua` (habilidades), `mundo.lua` (3D), `telas.lua` e `ui.lua` (interface) |
| `tests/` | `rodar.sh` (testes e robô que joga até o final) e `capturar.sh` (imagens de cada tela) |
| `.claude/agents/` | Agentes do projeto: layout, pesquisa visual e guardião de bugs |
| `scripts/config.lua` | Todos os números do balanceamento (preços, tempos, bônus) |
| `assets/` | Fontes (Poppins, licença OFL) e, no futuro, imagens e sons |
| `docs/GDD.md` | Documento de design do jogo (GDD) |

O motor chama estas funções do `scripts/main.lua`: `iniciar()`, `atualizar(dt)`, `desenhar()`, `tocar(x, y)` e `ao_sair()`. O jogo é desenhado numa tela virtual deitada (16:9) de 960 × 540, que o motor escala para a tela. No computador ele abre em tela cheia; F11 ou Alt+Enter alternam com o modo janela, e Alt+F4 fecha o jogo.

**Editando com o jogo aberto (modo de desenvolvimento):** um `.exe` compilado no próprio computador, sem pacote embutido, usa as pastas `scripts` e `assets` ao lado dele. Ao salvar qualquer arquivo `.lua` dentro da pasta `scripts`, o jogo recarrega na hora, mantendo o progresso. F5 também recarrega. Se houver um erro no script, ele aparece na tela em vez de fechar o jogo.

O progresso fica salvo em `%APPDATA%\TavernaDeAventureiros\progresso_v2.sav`. Apague esse arquivo para recomeçar do zero.

## Compilar no próprio computador (opcional)

Precisa de CMake e de um compilador C++ (Visual Studio no Windows):

```
cmake -S . -B build
cmake --build build --config Release
```

A raylib e a Lua são baixadas automaticamente pelo CMake.
