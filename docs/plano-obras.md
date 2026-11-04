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
Pronto em `layout.lua` e `mundo.lua`; a Loja usa estas funções sem tocar em desenho:
- `L.pos_sala(id)` -> x, z, andar. `L.mover_sala(id, x, z, andar)` -> ok, motivo. `L.encaixe_valido(id, x, z, andar, l, p)` -> ok, motivo, x e z já encaixados. `L.vaga_sala(id, andar)` -> x, z. `id` também aceita `"taverna"`.
- `L.pos_porta()` -> lado, t. `L.mover_porta(lado, t)` -> ok, motivo. `L.porta_livre(lado, t)`. `L.porta_mais_perto(x, z)` -> lado, t. Lados: oeste, fundo, leste, frente.
- `L.andar_ativo`, `L.mudar_andar(n)`, `L.andar_existe(n)`, `L.andares()`, `L.andar_de(id)`, `L.no_andar_ativo(id)`. `L.portas(andar)`, `L.lado_porteira(id)`, `L.trechos_baixos(id, lado)`, `L.parede_baixa(id, lado, c)`, `L.estado_blocos()`, `L.definir_blocos(t)`.
- Depois de mover com o jogo rodando: `L.salvar()`. O jogo percebe a mudança por `L.versao` e chama `J.aplicar_obra()` sozinho, sem expulsar ninguém.
- Loja pronta em `loja.lua` (tela) e `jogo.lua` (regras): `J.para_colocar`, `J.por_item`, `J.por_sala`, `J.comprar_decoracao`, `J.orcar_obra`, `J.obra`. Salvo em `e.colocados`, `e.obras` e `e.layout`. Sem `e.colocados` (save antigo) ou com `J.auto_colocar` (testes, robô) tudo é colocado sozinho. Preços em `config.lua`.

## Parte 1: decisões tomadas sem o dono (revise se quiser)
- **Caminho de pedras**: bloco externo fixo de 12 x 6 m, sem alça de tamanho. Mercadinho à esquerda, mural à direita; quem chega anda em linha reta pela faixa, sem rota nem colisão (`J.visitantes`, no máximo 40; passou disso, só o ouro entra).
- **Volta de missão**: ninguém entra mais para comemorar. A comemoração vira `J.festas`: o próximo cliente vale como festa, e a próxima chegada vem na metade do tempo. O robô terminou em 25,2 h contra 24,8 h antes.
- **Ala leste**: abre só com o nó dela (o nó do mercadinho deixou de abri-la). Ficou com as mesas 7 e 8, uma atrás da outra, e o caixote no canto.
- **Mover itens**: terceira aba da Loja, Mover. Tocar no mercadinho, nas estantes ou no mural leva o caminho inteiro. Se o item fechar a passagem até um lugar, ele volta atrás. Girar e subir saíram junto com o editor. Excluir só para decoração comprada, sem devolver ouro.
- **Construção por save**: mora em `e.layout`. Save sem esse campo copia o arquivo de layout antigo uma vez; o arquivo nunca é reescrito. Jogo novo, tela inicial e save pronto recém-copiado nascem de `layout_padrao.lua`.
- **Travamento**: medir com `lua tests/medir.lua . save 120` e `lua tests/medir.lua . robo 60`. Rotas: até 3 buscas por quadro; quem passa disso espera o próximo. Vacas: uma por quadro escolhe destino, com 4 tentativas.

## Parte 1: árvore, Mestre de Obras e Loja sem limite (decisões sem o dono)
- **Revelação**: sai sempre das compras, sem nada salvo. Nó aparece com todos os pré-requisitos comprados. Cada nó disponível mostra um "?" do primeiro filho; os outros viram toco de linha. Nó com um pré-requisito comprado e outro não também é "?".
- **Raízes**: Cardápio, Mesas e Placa. Nenhum nó tem mais de 3 filhos diretos. 
- **Ordem**: mesa > garçom > cozinha > cervejaria > fazenda de sementes > mural > mercadinho; sementes > frutíferas > animais; segundo andar > quartos e sala da guilda (que também exige o mural) > área de avaliação.
- **Área de avaliação**: já existe como nó `em_breve`, um "?" que não se compra, com o lugar reservado depois da sala da guilda. A Parte 5 só tira a marca.
- **Preços mudados na árvore**: segundo andar 12 mil > 1 mil (agora vem antes dos quartos); decoração 90 mil > 2,5 mil e ricos 8 mil > 4 mil (evitam salto de preço); pratos especiais e sua meta longa saem da cervejaria, junto com nós próximos. Noite de festa exige o mural. Cervejaria virou nó único + "Receita da casa" (os níveis antigos).
- **Parte 3**: `A.ARVORES` lista as árvores; a tela só lê `T.arv.arvore`. Abas por ambiente são novas entradas nessa tabela.
- **Mestre de Obras**: 35 de ouro, filho de Mesas. Save antigo com qualquer compra ganha o nó: já fazia obras.
- **Loja sem limite**: preço e efeito em `C.loja` (`config.lua`). Quarto, frutífera e animal: o primeiro vem com o nó, como antes. Multiplicadores: mesa e garçom 2,2; quarto e vaca 2,8; canteiro e árvore 2,6.
- **Limite de garçons: 40 em cena**, medido com `lua tests/medir.lua . garcons N 30 30` (motor falso: regras e Lua do desenho, sem a placa de vídeo):

| Garçons | Média | p99 | Pior quadro | Ouro/s |
| --- | --- | --- | --- | --- |
| 20 | 4,1 ms | 9,5 ms | 32 ms | 7,2 mi |
| 40 | 4,4 ms | 10,8 ms | 39 ms | 14,3 mi |
| 80 | 5,1 ms | 10,4 ms | 43 ms | 7,6 mi |

  A 80 eles se atrapalham e a renda cai: 40 é o pico. Os poucos quadros acima de 16,7 ms são iguais nos três casos. Acima de 40, cada compra tira 5% da espera e soma 2% de velocidade (até o dobro), sem boneco novo.
- **Outros limites**: mesas 40 objetos, mas o espaço trava antes (o salão original cabe 9 com a ala; ampliar abre mais); quartos = área da sala / 3,5 m²; árvores e vacas 20 em cena, canteiros o que couber na fazenda; passou disso a compra rende sem objeto novo. Mesa não vai atrás do balcão, e a ala leste é só das mesas 7 e 8.
- **Miniaturas**: `motor.miniatura_gravar` renderiza o modelo uma vez, sem sombras, em uma textura de 128 px; a Loja só a redesenha. As áreas usam o móvel que as identifica. Compila igual para Android, mas não foi testado lá.
- **Ritmo**: o robô termina em 17,7 h, contra 25,1 h antes destas etapas: unidades sem teto de níveis aceleram o fim do jogo. A Parte 3 rebalanceia a economia, então o preço ficou como está.
