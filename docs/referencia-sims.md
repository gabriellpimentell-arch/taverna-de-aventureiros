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
## Fontes
1. [Carl's Sims 4 Guide: Building Basics](https://www.carls-sims-4-guide.com/tutorials/building/houses.php)
2. [The Sims Wiki: Build mode (The Sims 4)](https://www.thesimswiki.com/wiki/Build_mode_(The_Sims_4))
3. [EA: FreePlay Build Mode FAQ (restrito a um grupo de jogadores em ago/2026)](https://www.ea.com/en/games/the-sims/the-sims-freeplay/news/build-mode-and-home-store-refresh-faq)
4. [SimsCommunity: Build/Buy Hotkey Guide](https://simscommunity.info/2022/01/24/the-sims-4-build-buy-hotkey-guide/)
5. [Twinfinite: mover móveis em The Sims Mobile](https://twinfinite.net/?p=337137)
6. [Twinfinite: girar móveis em The Sims Mobile](https://twinfinite.net/?p=290899)
7. [The Girl Who Games: FreePlay, redimensionar e apagar cômodos](https://thegirlwhogames.blog/2014/07/05/the-sims-freeplay-building-deleting-and-resizing-rooms/)
