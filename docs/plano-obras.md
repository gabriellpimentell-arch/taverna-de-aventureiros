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

## Parte 2: estrada e carroça (decisões sem o dono)
- **Estrada**: faixa fora do mapa, sempre à frente da construção mais avançada do térreo; a câmera recua um pouco para ela caber. Nada se coloca nela.
- **Carroça**: fica 90 s e volta 300 s depois da chegada anterior, já parada no início (save antigo também). O relógio é salvo e não anda com o jogo fechado. A lista não pausa o jogo e fecha quando ela parte.
- **Fornecedor fixo**: adaptado, não removido. Encomenda sozinho pelo dobro do preço da carroça; o nó subiu de 40 para 400 de ouro, para a carroça valer a pena no começo.
- **Bartolo**: sem nada para vender, socorre se faltar ouro com a carroça aqui ou, com ela longe, mesmo com ouro: traz 5 de comida, 5 de bebida e 40 de ouro, e cobra na dívida.
- **Filhotes**: 80% do preço da Loja; a partir do rank B, 50%. Um de cada por visita. A Loja continua vendendo pelo preço cheio.
- **Raros (a partir do rank B)**: especiarias e hidromel, um pacote de cada por visita. 20 pedidos rendem o dobro; custam 0,5 pedido por uso.

## Parte 2: três fazendas (decisões sem o dono)
- **Ids internos ficam**: `jardim`, `pomar` e `fazenda`, além de `vaca`. Só os nomes na tela mudaram, porque saves e layout antigos dependem deles.
- **Estoques**: `e.estoques` tem trigo, lúpulo, frutas, carne de vaca, carne de porco e ovos, com teto próprio cada. O estoque único antigo vira metade trigo e metade lúpulo, sem perder unidade.
- **Colheita**: um só relógio para as três fazendas (20 s, com Irrigação). Canteiros dão metade trigo, metade lúpulo. As árvores frutíferas deixaram de aumentar a colheita das plantas: agora dão frutas. Vaca dá 1 carne, porco 1,5 carne, galinha 1 ovo.
- **Como a produção alimenta os pedidos**: com a cozinha aberta, comida sai do maior estoque entre trigo, frutas, carnes e ovos. Com a cervejaria, bebida sai do maior entre lúpulo e frutas. Antes da despensa, usa-se a comprada. Sem cozinheiro, o prato da casa só poupa a despensa; com ele, rende mais, como antes.
- **Saves sem despensa** (bem antigos): continuam servindo de graça, e o estoque só é gasto quando rende mais. A carroça esconde bebidas e carne para eles.
- **Sementes**: guardadas, cada uma dobra um canteiro de lúpulo ou uma árvore em uma colheita. Sem semente a colheita segue normal: nada trava.
- **Porco e galinha na Loja**: nó da Fazenda de animais libera; 500 mil e 150 mil, com renda e pedidos menores que a vaca. Em cena: 12 porcos e 16 galinhas, como os 20 de vaca; passou disso, rendem sem boneco.
- **Painel à esquerda (carroça, despensa, dívida)**: só nas abas Taverna, Loja e Árvore, porque cobria o título das outras.

## Parte 2: três fazendeiros e fim da parte (decisões sem o dono)
- **Fazendeiros**: um nó libera cada um (das plantações, das árvores e dos animais) e a Loja vende. Um boneco por fazenda, que só anda nela. Do 2º ao 6º nível, a compra só treina o mesmo: +25% por nível, e só naquela fazenda.
- **Migração**: níveis do Fazendeiro antigo viram unidades na Loja, com o mesmo efeito. Conferido com os três saves prontos da versão anterior: nenhum nó ou unidade perdidos, e o estoque somou igual (899 e 500).
- **Saves prontos**: Metade e Completo agora nascem com a despensa e a carroça, como um jogo novo. Quem já tinha cópia antiga em uma vaga de teste segue migrando normalmente.
- **Ritmo**: o robô de jogo novo termina em 14,7 h, contra 17,7 h antes da Parte 2. Porcos e galinhas somam pedidos e renda, e o prato da casa rende mais cedo. Ficou assim porque a Parte 3 rebalanceia a economia.
- **Para o dono rever depois de jogar**: preços da carroça e das sementes; a carroça só anda com o jogo aberto; o desconto de filhotes em um por visita; a estrada encurta um pouco o zoom da taverna.

## Parte 3: árvores dos ambientes (decisões sem o dono)
- **Abertura**: comprar o nó na principal libera a sala na Loja; colocar a sala abre a árvore, com um aviso e o selo "Novo" na faixa. A aba não muda sozinha, para não interromper a Loja.
- **Faixa**: fixa em x = 256, à direita do painel da dívida. Ponto dourado = há compra naquela árvore. Câmera e seleção por árvore valem só enquanto o jogo está aberto: não vão para o save.
- **Toque na sala**: abre ao soltar, sem arrastar, e só se o toque não pegou balão nem carroça. Conta só o piso da sala no andar ativo.
- **Saíram da principal**: Moço de cozinha, Cozinheiro, Pratos especiais (cozinha); Receita da casa (cervejaria); Mais canteiros, Adubo, Fazendeiro, Irrigação (sementes); Fazendeiro das árvores (frutíferas); Fazendeiro dos animais (animais); Ritual (invocação). Os ids não mudaram, então o comprado continua valendo.
- **Animais**: a fazenda traz 1 vaca; Galinheiro, Chiqueiro e Curral liberam a venda, nesta ordem. Save com a fazenda já ganha os três.
- **Relógios**: cada fazenda tem o próprio (`ciclo`, `ciclo_pomar`, `ciclo_fazenda`). Irrigação agora só acelera as plantas; quem já a tinha perde esse efeito nas outras duas fazendas.
- **Frutíferas**: li "tempo de colheita" como colheita mais rápida, como o documento supõe.

## Parte 3: receitas (decisões sem o dono)
- **Lugar**: a tela fica na aba Árvore, em um ícone "Receitas" logo depois de Cozinha, para não criar outra aba na barra. A Produção tem um atalho.
- **Regras**: 12 receitas em `C.receitas` (`config.lua`); para ampliar, basta uma linha. Combinar é grátis e não gasta nada. Só aparece o ingrediente que a taverna produz ou tem guardado. Descobrir já põe no cardápio, se houver vaga. O cardápio começa com 2 vagas; o nó Cardápio maior dá mais 3.
- **No pedido**: sai a receita do cardápio de maior bônus que tenha ingrediente, e ela gasta 1 de cada um dos dois. Sem ingrediente, entra a próxima, depois o estoque simples, depois a despensa. O bônus multiplica o do cozinheiro e o da bebida da casa.
- **Nós da cozinha**: Cortes nobres e Receitas de porco liberam 6 receitas; Temperos e Panela grande favorecem as outras. Combinação bloqueada diz o nó que falta, em vez de dizer que não existe.
- **Sem total de receitas**: a lista mostra só o descoberto, como a árvore, sem "3 de 12".
- **Bebida sem cervejaria**: receita de bebida vale só com a cozinha, para quem ordenar as salas de outro jeito.
