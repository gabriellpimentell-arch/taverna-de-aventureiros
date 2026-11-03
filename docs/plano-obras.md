# Plano: obras, loja, andares e começo endividado

Pedido do dono. Referência de construção: `docs/referencia-sims.md`, seção "Fase 2".

## Decisões
- **Salas são blocos**: taverna, cozinha, cervejaria, invocação, jardim, pomar e fazenda têm posição salva e vão para qualquer lado da taverna, inclusive atrás. A taverna é a referência e também pode ser deslocada.
- **Encaixe**: nada sobrepõe nada no mesmo andar. Internas encostam na taverna ou em outra interna, com ao menos 2 m de parede comum. Áreas externas ficam sempre fora, em qualquer lado, e só no térreo.
- **Portas automáticas**: a porta nasce no maior trecho de parede comum; a porteira da área externa aponta para a taverna. A porta da rua pode ser movida ao longo das paredes livres e foge sozinha se uma sala a cobrir.
- **Mover sala é grátis**; aumentar custa ouro; diminuir devolve 50% do que foi pago por aquele metro. Abaixo do tamanho original não há devolução.
- **Obras sem pausar**: a aba Loja abre um painel lateral e o jogo segue. Fantasma verde ou vermelho com o motivo escrito; cobra ao soltar.
- **Loja**: comprar na árvore libera o item; ele fica "para colocar" até o jogador escolher o lugar. Decoração é paga em ouro na própria Loja. `J.auto_colocar` (usado em saves antigos e testes) coloca sozinho no lugar padrão.
- **Andares**: térreo, segundo andar e subsolo, liberados na árvore. Botões na borda esquerda; só o andar ativo é desenhado, em y = 0. Cada andar extra tem um hall do tamanho da taverna, com escada, onde as salas encostam.
- **Segundo andar**: Quartos e Sala do chefe da guilda. Cervejaria, cozinha e invocação podem ir para cima ou para baixo.
- **Equipe**: o gerente fica atrás do balcão e serve sozinho no começo. Com garçom, ele põe o pedido no balcão e o garçom leva. O moço de cozinha traz da cozinha para o gerente. Ao abrir as missões o gerente vira chefe da guilda e sobe; o balcão passa a funcionar sozinho com a equipe.
- **Economia**: começa endividado; pega empréstimo com o agiota; compra mantimentos e revende. Produção: cozinha (pão), cervejaria, jardim (trigo e lúpulo), pomar (frutas), fazenda (carne).
