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

## Estado do motor (ramo `salas-blocos`)
Pronto em `layout.lua`, `mundo.lua` e `editor.lua`; a Loja usa estas funções sem tocar em desenho:
- `L.pos_sala(id)` -> x, z, andar. `L.mover_sala(id, x, z, andar)` -> ok, motivo. `L.encaixe_valido(id, x, z, andar, l, p)` -> ok, motivo, x e z já encaixados. `L.vaga_sala(id, andar)` -> x, z. `id` também aceita `"taverna"`.
- `L.pos_porta()` -> lado, t. `L.mover_porta(lado, t)` -> ok, motivo. `L.porta_livre(lado, t)`. `L.porta_mais_perto(x, z)` -> lado, t. Lados: oeste, fundo, leste, frente.
- `L.andar_ativo`, `L.mudar_andar(n)`, `L.andar_existe(n)`, `L.andares()`, `L.andar_de(id)`, `L.no_andar_ativo(id)`. `L.portas(andar)`, `L.lado_porteira(id)`, `L.trechos_baixos(id, lado)`, `L.parede_baixa(id, lado, c)`, `L.estado_blocos()`, `L.definir_blocos(t)`.
- Depois de mover com o jogo rodando: `L.salvar()`. O jogo percebe a mudança por `L.versao` e chama `J.aplicar_obra()` sozinho, sem expulsar ninguém.
- Loja pronta em `loja.lua` (tela) e `jogo.lua` (regras): `J.para_colocar`, `J.por_item`, `J.por_sala`, `J.comprar_decoracao`, `J.orcar_obra`, `J.obra`. Salvo em `e.colocados` e `e.obras`. Sem `e.colocados` (save antigo) ou com `J.auto_colocar` (testes, robô) tudo é colocado sozinho. Preços em `config.lua`.
