# Referência: edição estilo The Sims para a Taverna
Especificação para `scripts/editor.lua` e `scripts/layout.lua`. "Lá" vem das fontes; "Aqui" é proposta de adaptação, ainda não testada. Copiar só princípios: nada de arte, nomes ou textos do jogo.
## Decisões a confirmar com o dono
- Li "itens que não vêm da árvore" como: decoração livre pode ser criada e excluída; item da árvore ou das regras só se move.
- Adicionar e excluir sem custo em ouro nesta versão: decoração sem efeito nas regras.
## Princípio central
- Lá: com a loja aberta, toca-se em qualquer item do lote para mover ou vender, sem botão de modo (FreePlay) [3]. A ferramenta de seleção do PC pega, move e apaga [2].
- Aqui: a cena é o editor. Tocar nela nunca depende da categoria; a lista vira só catálogo de itens novos.
- Causa atual da troca de página: `E.pegar` percorre `itens()`, só a categoria aberta. Passar a percorrer `L.OBJETOS` inteiro.
## Seleção
- Toque ou clique curto seleciona. Arrastar a partir do item seleciona e move no mesmo gesto, sem pressão longa (evitar a espera de The Sims Mobile [5]).
- Acertar pela caixa do objeto, não só pelo centro: hoje o raio é 34 em volta do centro, ruim para o balcão e tapetes.
- Empate: vence o menor ou mais alto (vela antes da mesa, mesa antes do tapete). Tocar de novo no mesmo ponto alterna entre os empilhados.
- Filho (`pai` sem `@`) move sozinho; o pai leva os filhos, como já faz `L.desloc`.
- Toque no vazio tira a seleção. Arrastar o vazio move a câmera só com zoom (`M.arrastar` já ignora sem zoom). Pinça nunca arrasta (`toques.h`).
- Item selecionado: contorno dourado e nome. Pontos dourados só aparecem ao abrir, como dica; somem depois do primeiro toque.
## Barra do item
- Lá: tocar no item mostra uma bolha de giro, e cada toque avança um ângulo [6]. No PC, o giro normal encaixa em 45° e 90° [4].
- Aqui: barra flutuante perto do item, sem cobrir o dedo: Girar 45°, Duplicar, Excluir, Mais (altura, giro fino, posição original). Some durante o arrasto.
- Item protegido: Excluir apagado; ao tocar, explica "Faz parte da árvore: dá para mover, não excluir".
## Alças de parede
- Lá: seleciona-se o cômodo e puxa-se a seta da parede para fora ou para dentro [1]. No celular, paredes redimensionáveis ficam destacadas, com contorno verde ou vermelho e confirmação [7].
- Aqui: com nada selecionado, cada parede mostra uma alça no meio; com um item selecionado, só o item responde. Assim a alça não rouba o toque de móveis junto à parede.
- Alça fica dentro da área útil; passou da borda, encosta na borda. Só uma alça é arrastada por vez. Salão: 4 lados. Jardim, Cervejaria e Círculo: largura e fundo.
- Arrasto: `motor.chao` guarda a distância inicial dedo-parede; o tamanho muda em passos de 1 m, com número ao vivo ("+3 m") e vibração leve a cada passo no celular.
- Congelar o enquadramento da câmera durante o arrasto e reenquadrar ao soltar. Se ele mudar no meio, a parede foge do dedo.
- Sem confirmação por gesto: aplica ao soltar e entra num único Desfazer. Mais rápido que o visto/X de [7], porque o Desfazer existe.
- Diminuir: lá, o que não cabe vai para o inventário [1]. Aqui, móvel volta para dentro; decoração sem lugar também, nunca some.
- Atenção: `L.mudar_tamanho` limita a 0..40, então hoje a sala nunca fica menor que a original. Para diminuir de verdade, definir um mínimo negativo por lado e tratar `L.sala`, `ancora` e o bug conhecido do balcão e das estantes que não acompanham o fundo.
## Catálogo: adicionar e excluir
- Lá: abas por cômodo e por função, busca, filtros e inventário [2][3]; conta-gotas copia o que está na cena [2]; marreta apaga [2]; PC separa vender (Delete) de guardar (Backspace) [4].
- Aqui: botão "+ Item" abre uma gaveta na direita com abas (Móveis, Mesa, Parede, Chão, Jardim) e miniaturas, nunca mais de 2 toques até o item. Fecha sozinha ao arrastar.
- Adicionar: arrastar a miniatura para a cena. Tocar nela põe o item no centro da vista, já selecionado. Nasce no lugar livre mais próximo. Duplicar nasce ao lado. Excluir é imediato, com aviso curto "Excluído. Desfazer".
- Sem inventário nesta versão: excluiu, o item volta ao catálogo sem custo.
- Oficial excluído: marcar `removido = true`, para não voltar sozinho numa atualização; "Posição original" o traz de volta.
- Pontos no código: `aplicar_tabela` descarta id fora de `L.POR_ID`; ela, `guardar` e `L.salvar` só levam x, z, y, g. Itens criados e `removido` exigem uma lista própria (`_extras`) salva, restaurada e no Desfazer.
- Protegidos: mesas (`J.num_mesas`), balcão, mercadinho, jardim, cervejaria, círculo e o que as regras citam por id (`porta`, `quadro`, `palco`, `barril1`-`5`; conferir com grep em `jogo.lua`). Marcar no próprio `ob(...)`.
## Feedback
- Verde ou vermelho durante o arrasto [7]: pegada do item no chão; vermelho se fora da área ou tapando a porta; não bloqueia.
- Soltar em vermelho: volta ao último lugar válido, com aviso do motivo. Passagem fechada só avisa, pois as pessoas atravessam móveis de propósito (`historico-de-bugs.md`).
- Grade só aparece enquanto arrasta. Encaixe de 0,25 m continua; desligado, movimento livre (lá, Alt faz isso e F5 troca a grade [4]).
- Desfazer e Refazer sempre à vista, com contagem. Lá valem só na sessão [2][4]; aqui também: `E.abrir` zera a pilha. Refazer ainda não existe.
## Toque (S24 FE deitado) e mouse
- Tela virtual 960x540: com 2340x1080 em 6,7", 1 unidade é cerca de 0,13 mm (cálculo; conferir no aparelho se a escala preenche a altura).
- Botões de 40-44 têm só 5,3-5,8 mm. Alvo mínimo: 60 (8 mm); alça e barra do item: 68 (9 mm). Alvos a 12 de distância.
- Painéis atuais somam 300 de 960 (31% da tela). Sem seleção, só uma fileira fina; polegares nos cantos inferiores para Desfazer e "+ Item". Nada essencial no meio da borda inferior.
- Mouse: passar por cima destaca item e alça, e muda o cursor. Roda continua zoom. Delete exclui, `,` e `.` giram, Ctrl+Z/Ctrl+Y, Ctrl+D duplica; Alt desliga o encaixe.
## Limites
- Tamanho: até +40 m por lado (hoje); mínimo a definir. Itens criados: começar com 60 e medir FPS no aparelho. Excedeu: "+ Item" explica o limite.
- Cada arrasto inteiro é um Desfazer; manter a pilha de 30 passos. Salvar ao soltar, nunca a cada quadro. Testar save estragado, item removido após atualização e encolher com móvel na faixa que sumiu.
## Evitar
- Pressão longa para mover; botão de modo para mover ou vender; confirmar cada ação; item que some ao encolher; custo ou regras de adjacência entre cômodos, como em [7].
## Fase 2: obras durante o jogo (proposta, ainda não testada)
Onde houver conflito, esta seção vale mais que as acima: agora há custo em ouro e nem tudo acontece em um modo separado. Números são pontos de partida a calibrar.
### Base técnica: o que impede hoje
- `J.editando` pausa o jogo, `J.previa` mostra coisas não compradas, `E.fechar` chama `M.iniciar` (zera a câmera), e `J.aplicar_layout` faz `J.pessoas = {}` (expulsa todo mundo). Obras não podem usar nenhum dos quatro.
- Criar `J.aplicar_obra`: atualiza mesas, porta, quadro e barraca, reconstrói lugares e mapa, mantém `l.dono` quando o lugar continua existindo, recalcula rotas e tira da parede quem ficou preso. É o maior risco desta fase.
- Abrir a aba Obras mostra alças e caminhos para mover salas, com o jogo rodando. Fechar a aba esconde tudo, sem tela de carregamento.
### 1. Puxar parede pagando ouro
- Lá: seta na parede para puxar ou empurrar [1]; móvel junto à parede vai com ela [8]; material é cobrado ou reembolsado [1]; no FreePlay, verde ou vermelho, preço na tela e confirmação [7]. Nas fontes, não confirmei como The Sims 4 mostra o preço durante o arrasto.
- Aqui: durante o arrasto só um fantasma anda (retângulo no chão e parede translúcida); `L.mudar_tamanho` roda ao soltar. Etiqueta junto à alça, sem ficar sob o dedo: "+3 m · 450 ouro" ou "-2 m · +100 ouro".
- Sem ouro: o fantasma para no último metro pago, com "faltam 120", vermelho e sem cobrança. Ouro é conferido de novo ao soltar, pois o jogo segue rodando.
- Preço: por m² de diferença, crescendo com a área total da construção, como as cópias que encarecem em [14]. Exemplo: `preco_m2 = base * (1 + area_total / 100)`.
- Reembolso: 50% do valor pago ao encolher, em ordem inversa da compra (guardar `L.pago_obras`). Encolher abaixo do tamanho original devolve 0. Assim, crescer e encolher nunca dá lucro.
- Desfazer: devolve 100% só nas últimas ações da aba aberta. `guardar` e `E.voltar` precisam registrar a diferença de ouro, nunca restaurar o saldo: o jogo continua ganhando e gastando.
- Objetos no caminho: lá vão para o inventário [1]. Aqui, `L.limitar` empurra para dentro e `d.orig` tenta devolver. Pintar de âmbar, no fantasma, o que vai ser empurrado. Se não couber sem sobrepor, ainda empurra: pessoas atravessam móveis por escolha (`historico-de-bugs.md`).
- Mesa ocupada empurrada: cliente acompanha o lugar. Parede que cruzaria pessoa: quem está ali anda até a célula livre mais próxima.
- Bug conhecido a resolver antes: balcão e estantes não acompanham o fundo ao recuar (`historico-de-bugs.md`).
- A nota "`L.mudar_tamanho` limita a 0..40" acima está velha: já aceita negativo via `minimo(lado)`.
### 2. Mover salas inteiras
- Lá: seleciona-se o cômodo e ele vai inteiro, com móveis, revestimentos, portas e janelas entre cômodos [1]. Cômodo também gira [8][11]. Colocar sobre objetos manda-os para o inventário e ajusta o custo do material [1]. Peça aceita ou recusada: ladrilhos verdes ou vermelhos [13]. Mover coluna cobrada como compra nova é relatado como defeito [9]: mover não deve pedir fundos.
- Aqui: botão Mover na sala selecionada, sem pressão longa. Arrastar leva só o fantasma da sala (contorno e piso), em passos de 1 m; ao soltar em verde, a sala vai com seus filhos e `J.aplicar_obra` roda.
- Dados: `cursor` calcula a fileira e o buraco é fechado sozinho. Trocar por `L.pos_sala[id] = { x, z }` salvo; em save antigo, gravar a posição atual na primeira carga, para nada saltar. `ancora`, `sala_mundo`, `recuo_externo` e `limites_externos` passam a usá-lo. Salão: `L.salao` ganha um deslocamento, somado também aos objetos sem `pai`.
- Vermelho, com motivo na etiqueta: sobrepõe outra sala; não encosta em nada (sem acesso); parede comum menor que 2 m (`LARG_PORTA` 1,4 + folgas de 0,3); fecha a porta de entrada `porta`.
- Soltar em vermelho: volta ao lugar anterior. Mover é grátis (a confirmar com o dono). Decoração solta no destino é empurrada para fora, não some.
- Portas: geradas, não posicionadas. Depois de soltar, cada vizinho ganha uma porta no centro do maior trecho de parede comum; `casca_sala` hoje tem porta fixa à esquerda e precisa receber os vãos por parâmetro; `porta_x` sai.
- Evitar girar salas na primeira versão. `casca_sala` não tem paredes de frente nem direita, porque a câmera é fixa; girar poria parede na frente da cena. Girar continua valendo para móveis. A porta gerada elimina o principal motivo de girar a sala.
- Mapa e rotas (`J.montar_mapa`): depois de mover, testar `J.lugares_sem_rota`; se aparecer lugar sem rota, avisar e permitir Desfazer.
### 3. Catálogo e loja
- Lá: seções por função [2][3]; ladrilhos verdes ou vermelhos, com a compra ao soltar [13]; Shift repete sem reabrir o catálogo [4][13]; itens perdem valor com o tempo [13]. No celular, depósito guarda o que sai e não vende [15].
- Aqui, 960x540: barra lateral direita com 240 de largura (25% da tela). Trilho de 60 com até 6 categorias de 60 de altura, ao lado de 2 colunas de cartões 84x84 com rolagem. Cartão: miniatura, nome curto e preço. Sem ouro: fica à vista, com preço em vermelho. Fechada, sobra um botão de 60x60.
- Duas formas de comprar. Arrastar do cartão para a cena: ao soltar em verde, compra. Tocar no cartão: a barra se recolhe, o fantasma nasce em lugar livre perto do centro e aparece uma barra com Confirmar, Girar e Cancelar. Em tela de toque, tocar sem querer nunca gasta ouro.
- Fantasma: modelo translúcido e pegada verde ou vermelha, levantado 60 unidades acima do dedo para ficar visível. Vermelho nunca cobra.
- Repetir: depois de Confirmar, nasce outro fantasma ao lado e a barra troca para Mais um, Girar e Pronto. No PC, Shift faz o mesmo. Para quando o ouro acaba ou chega em `L.MAX_EXTRAS`, avisando o motivo.
- Devolver: botão Devolver na barra do item, em uma ação e com Desfazer. 100% na mesma aba aberta, 50% depois. Salvar o `pago` em cada extra (`L.adicionar` e `L.texto`), pois o preço de catálogo muda. Sem depreciação diária nem depósito: em um incremental isso só cria trabalho.
- Devolver, repetir e mover nunca atingem os protegidos: `L.removivel` continua valendo. Item da árvore aparece no catálogo só como "Compre na árvore", com atalho para lá.
### 4. Andares e subsolo
- Lá: botões na tela e Page Up/Page Down trocam o andar [11][12]; botões separados mudam a vista das paredes [12]. Escada liga de baixo para cima, exige espaço e abre o vão no piso [10]. Subsolo: até 2 níveis, feito com ferramenta própria ou descendo um nível [10][16].
- Aqui: três botões de 60x60 na borda esquerda, centralizados em altura (+1, Térreo, Subsolo); o atual fica aceso. Teclado: Page Up e Page Down. Limite inicial de -1 a +1. Andar sem acesso aparece como cadeado com o preço.
- Truque da câmera: desenhar sempre o andar ativo em y = 0 e omitir os demais. `motor.chao`, `motor.projetar`, alças e toque seguem iguais, e a câmera nunca se move. Na troca, deslizar 4,5 m e esmaecer em 0,2 s; o andar de baixo pode aparecer só como sombra da pegada.
- Paredes: sem seletor de vistas. A casca já corta frente e direita, e isso serve em todo andar. Fundo e esquerda só baixam (1,2 m) enquanto há arrasto perto delas ou item atrás delas.
- Jogo em outro andar continua: pontinho no botão quando há ouro para coletar, pedido ou alerta. Trocar de andar nunca pausa.
- Escada: item de 2x3 m, comprado no catálogo e colocado de baixo para cima; ocupa a mesma pegada nos dois andares; verde só se couber nos dois. Toque na escada dá atalho para o outro andar. Os `quartos`, que já têm escada desenhada, são o primeiro uso natural.
- Dados: `andar` em sala, objeto e pessoa; `Cam` com um mapa por andar; rota entre andares passa pela escada mais próxima. Pessoa na escada é teleporte com fade na primeira versão.
- Regras: andar de cima precisa estar sobre sala existente. Subsolo livre, com paleta escura e sem janelas (bom para Cervejaria e Invocação, a confirmar). Excluir escada só com o andar vazio.
- Ordem sugerida: entregar 1, 3 e 2 primeiro. O 4 mexe em rotas e desenho: fazer por último, começando com um único andar extra sem clientes.
### Evitar nesta fase
- Pausar o jogo para obras; expulsar clientes; cobrar antes de soltar ou confirmar; reembolso que dê lucro; restaurar saldo no Desfazer; mover ou alterar salas sem mostrar antes o resultado; `J.previa` ligado com o jogo rodando.
## Fontes
1. [Carl's Sims 4 Guide: Building Basics](https://www.carls-sims-4-guide.com/tutorials/building/houses.php)
2. [The Sims Wiki: Build mode (The Sims 4)](https://www.thesimswiki.com/wiki/Build_mode_(The_Sims_4))
3. [EA: FreePlay Build Mode FAQ (restrito a um grupo de jogadores em ago/2026)](https://www.ea.com/en/games/the-sims/the-sims-freeplay/news/build-mode-and-home-store-refresh-faq)
4. [SimsCommunity: Build/Buy Hotkey Guide](https://simscommunity.info/2022/01/24/the-sims-4-build-buy-hotkey-guide/)
5. [Twinfinite: mover móveis em The Sims Mobile](https://twinfinite.net/?p=337137)
6. [Twinfinite: girar móveis em The Sims Mobile](https://twinfinite.net/?p=290899)
7. [The Girl Who Games: FreePlay, redimensionar e apagar cômodos](https://thegirlwhogames.blog/2014/07/05/the-sims-freeplay-building-deleting-and-resizing-rooms/)
8. [Platinum Simmers: The Sims 4, cômodos como objetos](https://www.platinumsimmers.com/articles/the-sims-4-build-mode-frustrations-are-gone)
9. [Fórum EA: mover coluna exige fundos (relato de defeito)](https://forums.ea.com/idea/the-sims-4-bug-reports-en/build-mode-prevents-moving-columns-without-sufficient-funds/13315315)
10. [Carl's Sims 4 Guide: escadas e subsolos](https://carls-sims-4-guide.com/tutorials/building/stairs-basements.php)
11. [Carl's Sims 4 Guide: controles](https://carls-sims-4-guide.com/controls.php)
12. [Fórum EA: alternar vistas de parede](https://forums.ea.com/discussions/the-sims-4-gameplay-en/how-do-i-switch-between-wall-views/8663011)
13. [StrategyWiki: The Sims 2, Buy Mode](https://strategywiki.org/wiki/The_Sims_2/Buy_Mode)
14. [Gamepressure: The Sims Mobile, Build mode](https://www.gamepressure.com/the-sims-mobile/build-mode/z9ac3b)
15. [Gamepressure: The Sims Mobile, Featured and Storage](https://www.gamepressure.com/the-sims-mobile/featured-and-storage/zaac3c)
16. [EA: dicas de subsolo em The Sims 4](https://www.ea.com/en/games/the-sims/the-sims-4/news/basement-tips)
