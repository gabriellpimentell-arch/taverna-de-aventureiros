# Referência: apresentação da tela da árvore

Foco: como a árvore aparece e se navega; as regras de revelação ficam com o outro agente. Tudo é desenhável com o que `tela_arvore` já usa: círculo, anel, linha, retângulo, texto e recorte.

**Evidência:** a busca achou pouca análise séria de UI. [F] é o que a fonte afirma; [R] é recomendação minha, sem fonte direta, com tempos e tamanhos como ponto de partida. Não confirmei como Nodebuster e Cookie Clicker revelam nós, então não servem de modelo aqui.

## O que as fontes mostram
- [F] Esconder divide opiniões. No Factorio, a "névoa" visa descoberta e menos sobrecarga; quem responde quer planejar ou exige que o objetivo atual continue visível.
- [F] Um autor de árvore enorme esconde nós distantes (a dois nós do que já foi liberado) para não sobrecarregar novatos.
- [F] Árvores que crescem para fora obrigam a aproximar e afastar sem parar, e o jogador perde a noção do que comprou. A navegação é a principal crítica à árvore de Nodebuster.
- [F] Brilho forte atrapalha a leitura do nó (Roblox DevForum). Em Nodebuster, tremor e flashes causam cansaço.
- [F] Cor sozinha falha: amarelo e verde-limão se confundem. Pedidos: escurecer o que está no máximo e variar borda ou forma.
- [F] Mod de UX do Dyson Sphere Program: zoom e posição por página, salvos por partida; arrastar no vazio mantém a seleção e clicar no vazio desfaz; o nó escolhido se distingue dos pré-requisitos, dos desbloqueios seguintes e do resto; nível no próprio nó.
- [F] Cuqueclicker: alcançável com cor, inalcançável em cinza, o resto em névoa. A câmera desliza até o foco, mas no arraste obedece direto e fica onde o jogador deixou.
- [F] Em Path of Exile 2, jogadores reclamam de "emaranhado" de linhas e nós tão próximos que parecem um só.

## O que a tela já tem
Já existem `???`, cadeado, anel dourado pulsante, enquadramento automático e prioridade de rótulos. Problemas para a nova ideia:
- O enquadramento salta sem animação; depois de arrastar ou usar a roda (`manual`), para de atuar e o nó novo pode nascer fora da tela.
- A roda aproxima em torno do centro da árvore, não do cursor (`telas.lua:1200`).
- O painel de detalhe (672,64, 276x280) pode cobrir o nó escolhido, e o do bloqueado mostra "Custo depois", o que estraga a surpresa.
- Os nós não têm ícone, só nível no centro: silhueta exigiria desenhar ícones.

## Recomendações [R]
### 1. Estados do nó
| Estado | Aparência |
| --- | --- |
| Escondido | não desenhado |
| Pista | círculo pequeno e escuro com `?`, sem nome, custo ou cadeado |
| Disponível, sem ouro | fundo apagado, anel fino na cor do ramo, nome e custo |
| Comprável | anel dourado grosso; **é o único estado que pulsa** |
| Comprado, com níveis restantes | cor do ramo e `2/5` |
| Máximo | cor do ramo um pouco escurecida e `OK` |

Use `?` como padrão, por ser barato e consistente; silhueta só em nós-marco, como uma sala nova.

### 2. Sugerir sem mostrar
- Nó comprado com continuação ganha um **toco de linha** que some aos poucos. Sem toco, o ramo acabou.
- O painel de uma pista diz só "Algo novo surge aqui", sem custo.
- Ideia de identidade: fundo escuro em que a **luz de vela cresce** a cada compra, com círculos translúcidos e sem brilho sobre os nós.

### 3. Sequência ao comprar (total abaixo de 1 s)
Som e anel que expande no nó (0 ms); linha cresce até o filho (100 a 350 ms); filho surge de escala 0 a 1,1 e assenta em 1 (150 ms); nome aparece (150 ms). Vários filhos entram com 80 ms de intervalo. Clicar ou comprar de novo encerra a animação. Revelação não vista toca ao reabrir a tela.

### 4. Câmera
- Nós novos cabem na tela: **a câmera não se move**. Não cabem e o jogador não mexeu: desliza 300 a 400 ms e só então os nós nascem.
- Se ele mexeu, não tome o controle: **seta na borda** com ponto dourado, que leva à novidade ao ser clicada.
- Roda aproxima em torno do cursor; o painel desloca a árvore se cobrir o nó; `Espaço` centraliza; `Esc` fecha o painel.
- **Árvores de ambiente (5 a 8 nós) cabem inteiras:** sem zoom nem arrasto enquanto couberem. Só a principal precisa de navegação.

### 5. Linhas
Comprada: cor do ramo, grossa. Até disponível: média, clara. Até pista: fina e tracejada. Ao selecionar, realce o caminho até a raiz e esmaeça o resto. Mantenha um espaçamento mínimo entre nós.

### 6. Faixa de ambientes
- 44 px no topo da área da árvore: Principal à esquerda e um ícone por ambiente liberado (até 7, cerca de 56 px cada). Ajuste o enquadramento e `bate`.
- O ícone surge só ao liberar o ambiente, sem casas vazias. É desenhado em código, na cor da sala, com nome no hover.
- Teclas 1 a 7 trocam de árvore, com corte ou deslize de 150 ms. Cada árvore guarda zoom, posição e seleção no save [F, DSP].
- Clicar na sala abre a aba já naquele ambiente; `Esc` volta ao mapa na mesma câmera. Revisar conflito com o que esse clique faz hoje.

### 7. Indicar novidade
- **Ponto dourado** no ícone e na aba: compra nova desde a última visita. Assim não fica sempre aceso quando sobra ouro no fim do jogo.
- **"Novo" pequeno:** nó ou ambiente revelado e não visto; some ao ser visto. Sem contador numérico.

## O que evitar
Brilho forte, tremor, flash; pulsar em vários estados; tirar a câmera do jogador; animação que atrase compras em sequência; esconder a meta do capítulo.

## Fontes
- [Factorio: fog of war em tecnologias](https://forums.factorio.com/viewtopic.php?p=667601)
- [Roblox DevForum: árvores grandes](https://devforum.roblox.com/t/skill-tree-design-for-big-skill-trees/3586195)
- [r/incremental_games: daltonismo e nós compráveis](https://reddit.sentinel-team.org/posts/1ss0uzt/snapshots/2026-04-23T08%3A29%3A11.337454Z)
- [r/incremental_games: árvore grande ou upgrades fixos](https://reddit.sentinel-team.org/posts/1qoix5a/snapshots/2026-01-28T01%3A31%3A55.791486Z)
- [Nodebuster: resumo de avaliações](https://vaporlens.app/app/3107330/nodebuster.md)
- [DSP Tech Tree UX Overhaul](https://thunderstore.io/c/dyson-sphere-program/p/Nekogod/DSPTechTreeUXOverhaul/)
- [Cuqueclicker: código da árvore](https://docs.rs/cuqueclicker/1.2.0/src/cuqueclicker_lib/ui/tree.rs.html)
- [Path of Exile: visual da árvore passiva](https://www.pathofexile.com/forum/view-thread/3631742)
