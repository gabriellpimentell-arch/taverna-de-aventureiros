# Próximas mudanças da Taverna de Aventureiros

Este documento descreve como o jogo deve ficar depois das próximas entregas. O dono autorizou a produção contínua, sem pedir aprovação entre as partes.

## Situação em 5 de novembro de 2026

| Parte | Situação | Onde está |
| --- | --- | --- |
| Pesquisa da árvore | Pronta | `docs/referencia-arvore-mecanica.md` e `docs/referencia-arvore-tela.md` |
| 1. Base | Pronta | Publicada |
| 2. Produção | Pronta | Publicada |
| 3. Árvores e receitas | Falta o rebalanceamento | Ramo `parte-1`, sem publicar |
| 4. Vida na taverna | Não começou | Hoje há só o nó Quartos |
| 5. Estrutura | Não começou | Hoje a área de avaliação é só um nó não comprável |
| Conferência final | Não começou | Robô, imagens, GDD e resumo |

**Medido no ramo `parte-1`:** testes rápidos com 0 falhas em uma rodada. O robô termina um jogo novo em 10,5 horas de jogo; o alvo é de 20 a 25 horas. Em `tests/robo.lua`, há um ajuste sem commit, feito durante esse rebalanceamento.

## A direção do jogo

A Taverna é um jogo incremental de cliques: o jogador nunca controla personagens, só toca nas coisas e toma decisões. O prazer central deve ser a sensação de que tudo está quase terminado, até que algo novo se abre e o jogo ganha outra camada. Cada novidade precisa parecer uma recompensa, e não mais uma obrigação.

O jogo cresceu além do previsto, então o escopo precisa de controle. Por isso, as mudanças vêm em cinco partes, cada uma publicada para teste antes da próxima. O fim continua sendo a derrota do Lorde Demônio. Conteúdo depois disso fica para outro momento.

Regras que valem para tudo:

- Ninguém morre. Falhar custa tempo ou dinheiro, nunca um personagem.
- O PC é a plataforma prioritária.
- O agente de bugs só trabalha quando o dono pedir.
- Quando houver dúvida, escolhe-se o que dá mais identidade ao jogo: cada ambiente e cada personagem deve ter uma função clara e própria.

---

## Parte 1: a base

### Só para PC, com o celular guardado

Manter o jogo cabendo e rodando bem no celular limita cada ideia nova, então o desenvolvimento passa a mirar só o PC. O trabalho do celular não é apagado, porque ele deve facilitar uma volta futura.

- O código do Android, o script que gera o APK e a chave de teste continuam no repositório.
- O último APK continua disponível para baixar.
- A geração do APK sai da publicação automática e vira uma ação manual no GitHub.
- O app já instalado fica congelado na versão atual, sem baixar atualizações feitas para PC.

Ao voltar para o celular, o processo já existe, mas será preciso adaptar as telas e possivelmente o motor. Mudanças no motor não precisam garantir compatibilidade com o celular, mas não se deve quebrar a compilação sem necessidade.

### Fim do modo editor

O modo editor (tecla F2 e botão nas Configurações) sai do jogo. Ele existia só para ajustar o layout e hoje atrapalha, porque permite obras de graça. Não haverá botão para salvar edições nem envio automático ao GitHub.

O tamanho inicial da taverna e o lugar onde cada sala nasce ficam definidos nos arquivos do jogo pelo Claude. Para mudar uma posição, o dono descreve o que quer, manda um print riscado ou monta a arrumação na Loja e envia um print. O Claude confere o resultado em imagens do jogo antes de publicar. Ajustes finos podem levar algumas tentativas.

A Loja, com obras e movimentação de salas, continua, porque faz parte do jogo. O código de arrastar itens do editor deve ser reaproveitado para a Loja antes de ser apagado. Testes e capturas que usam o editor precisam ser ajustados, mantendo a verificação de tudo o que continuar existindo.

### Mercadinho e mural de missões do lado de fora

Hoje, o fim do jogo trava porque muitos aventureiros entram ao mesmo tempo para pegar missões. A solução é tirar essa movimentação do salão.

Quando o jogador liberar o mercadinho ou as missões, o que vier primeiro, surge um caminho de pedras do lado de fora da taverna. O mercadinho fica nesse caminho, com o mural de missões ao lado dele. Os dois continuam sendo liberados de forma independente, e o segundo aparece no lugar dele quando for comprado.

- Quem vem pegar missão ou vender espólios fica só do lado de fora e nem entra na taverna.
- O salão fica para quem vem comer e beber.
- O jogador pode mover o caminho de pedras inteiro, levando o mural e o mercadinho juntos.
- O mural sai da parede interna, e o mercadinho sai da ala leste. O que restar sem uso nessa ala precisa ser revisto.

Os travamentos devem ser medidos antes e depois. Se boa parte vier de muitos personagens calculando a rota ao mesmo tempo, esses cálculos também precisam ser espalhados entre os quadros.

### Mover todos os itens

Pela Loja e com o jogo rodando, o jogador pode mover qualquer item da taverna, sem exceção e de graça. Isso inclui o que veio da árvore de habilidades. Excluir continua valendo só para decoração, para ninguém perder algo que comprou.

### Mestre de Obras

Bem no começo da árvore principal, há um nó barato chamado Mestre de Obras. Antes dele, o tamanho da taverna e dos ambientes é fixo. Depois dele, o jogador pode aumentar e diminuir tudo, porque mais clientes e funcionários logo vão pedir mais espaço.

Mover salas continua de graça. Aumentar custa ouro por metro, e diminuir devolve metade do que foi pago por aquele metro.

### Loja sem limite e com imagens

A árvore passa a liberar funções, e a Loja passa a vender as unidades. Hoje os níveis da árvore limitam, por exemplo, os garçons a quatro, o que não dá conta do fim do jogo.

Funciona assim: o jogador libera "Garçom" uma vez na árvore. A partir daí, o garçom aparece na Loja e pode ser comprado quantas vezes o jogador quiser, ficando mais caro a cada unidade. O mesmo vale para mesas, quartos, animais, plantações, árvores frutíferas e o resto do que é colocado no mapa.

Para esse crescimento não trazer os travamentos de volta:

- O preço sobe rápido.
- Há um limite técnico alto, definido depois de medir o desempenho no PC.
- Passado certo número, comprar mais um garçom pode apenas deixar os outros mais rápidos, sem colocar mais um boneco em cena.
- Os quartos ficam limitados pelo espaço, o que dá um motivo para ampliar a taverna.

Saves com níveis já comprados precisam continuar funcionando, com uma migração que preserve o que o jogador já tem.

Todo item da Loja mostra imagem e nome, porque só o texto não é intuitivo. O ideal é uma miniatura do próprio modelo 3D, para o item parecer igual ao que aparece no jogo. Isso exige mudar o motor, mas basta o `.exe` novo, que se atualiza sozinho.

### Regra geral das áreas

Toda área nova segue o mesmo caminho: um nó da árvore principal a libera, ela vai para a Loja, e o jogador escolhe na Loja onde colocá-la, junto à taverna. Nenhuma aparece sozinha no mapa.

Isso vale para quartos, sala da guilda, área de avaliação, mercadinho, mural de missões, as três fazendas, cozinha, cervejaria e sala de invocação.

O mercadinho e o mural seguem a regra e ficam ligados ao caminho de pedras: colocar o primeiro deles define o lugar do caminho, e o segundo fica ao lado.

### Saves independentes

Hoje, tamanhos e decoração valem para todos os saves, então um jogo novo herda o que foi construído em outro. Isso deve ser corrigido nesta parte: cada save guarda sua própria construção.

---

## Parte 2: produção

### Estrada e carroça do comerciante

Uma pequena estrada passa fora do mapa. Uma carroça com um comerciante chega a cada 5 minutos, mais ou menos, durante o jogo inteiro. Ao tocar nele, abre-se uma lista de compras:

- bebidas e carne;
- sementes de bebida e de fruta;
- filhotes de vaca, porco e galinha.

No começo do jogo, ela é a principal fonte de mantimentos. Conforme o jogador produz o próprio estoque, ela fica menos necessária, mas continua útil no fim do jogo, com itens raros e filhotes com desconto.

A carroça não pode travar o começo do jogo:

- Ela já está na estrada quando o jogo começa.
- Fica cerca de um minuto e meio a cada visita.
- Quem ficar sem nada recebe socorro de Bartolo, o agiota.
- A compra de comida e bebida sai do painel de hoje, para a carroça ter sentido.
- O nó Fornecedor fixo, que compra sozinho, precisa ser adaptado ou removido.

### Três fazendas, três animais e três fazendeiros

As áreas de produção passam a ter funções claras:

| Fazenda | Substitui | O que produz | Quem cuida |
| --- | --- | --- | --- |
| Fazenda de sementes | Jardim | Trigo, lúpulo e outras plantas | Fazendeiro das plantações |
| Fazenda de árvores frutíferas | Jardim de frutas | Frutas | Fazendeiro das árvores |
| Fazenda de animais | Fazenda | Carne de vaca, carne de porco e ovos | Fazendeiro dos animais |

Só haverá três animais: vaca, porco e galinha. Cada um produz algo diferente, o que alimenta as receitas da Parte 3. Cada fazendeiro trabalha só na sua fazenda, para cada área ter identidade própria.

---

## Parte 3: árvores por ambiente e receitas

### Nova forma da árvore: revelar aos poucos

Hoje a árvore já mostra todas as ramificações, e isso tira a surpresa. Ela passa a revelar o caminho conforme o jogador avança: no começo, quase tudo está apagado ou escondido, e comprar um nó faz surgir as ramificações seguintes.

Exemplos da sequência:

- Liberar a sala da guilda faz aparecer o ramo com a área de avaliação.
- Liberar a primeira fazenda faz aparecer a fazenda de árvores frutíferas, e liberar essa faz aparecer a fazenda de animais.

**Pesquisa obrigatória antes de produzir:** ao iniciar esta parte, usar dois agentes de pesquisa para estudar minuciosamente as árvores de habilidades de jogos incrementais. A pesquisa ainda não foi feita. Os dois devem:

- Entender primeiro a ideia acima, de revelar novas ramificações só depois de liberar um nó.
- Analisar como esses jogos escondem e revelam nós, mostram o progresso e criam vontade de ver o que vem depois.
- Dividir o trabalho para não repetir os mesmos jogos, por exemplo um focado nos jogos e outro em como a tela da árvore é apresentada.
- Entregar recomendações práticas para a Taverna, incluindo a árvore principal e as árvores por ambiente.

O formato final da árvore só é decidido depois dessa pesquisa, que é feita antes da Parte 1, porque a árvore muda já nela. O dono dispensou a aprovação do resultado.

### Uma árvore para cada ambiente

A árvore principal libera ambientes e funções. Cada ambiente liberado ganha uma árvore própria, o que transforma cada abertura em um novo conjunto de metas: cozinha, cervejaria, as três fazendas e a invocação.

- Para a barra de baixo não lotar, há uma só aba Árvore, com ícones dos ambientes no topo.
- Tocar na sala no mapa também abre a árvore dela.
- Cada árvore começa com 5 a 8 nós.
- A árvore das frutíferas é simples: mais produção e colheita mais rápida.
- A árvore da cozinha libera receitas, como as de porco.

Isso muda a economia inteira, então o jogo precisa ser rebalanceado. O robô de testes deve confirmar que o jogo continua terminável do início ao fim.

### Receitas na cozinha

A tela da cozinha tem dois espaços para ingredientes. Ao combinar dois ingredientes, o jogador descobre uma receita, se ela existir: trigo com ovo, por exemplo, vira torta. O jogo começa com umas 10 receitas, e o jogador escolhe quais entram no cardápio. Cada receita faz o pedido render mais e gasta os ingredientes dela.

A primeira versão fica simples, mas deve permitir acrescentar receitas e regras depois sem refazer o sistema.

### Invocação e sumos sacerdotes

Abrir a invocação cria a árvore dela. Um nó dessa árvore, a Ordem dos Sumos Sacerdotes, libera a contratação dos sacerdotes, que passam a ser pré-requisito para invocar heróis.

1. O jogador contrata 4 sacerdotes, um a um, cada um mais caro que o anterior.
2. Cada sacerdote vai para um dos 4 pilares do círculo, e o pilar acende.
3. Com os 4 pilares acesos, o círculo se ativa e a invocação de heróis é liberada.

Os sacerdotes são contratados direto, sem precisar evoluir um mago. Assim, ninguém sai das missões nem da party, e os pilares acendendo mostram o progresso na tela. O robô de testes precisa aprender a contratá-los antes de invocar.

---

## Parte 4: vida na taverna

### Escada, quartos e hóspedes

A escada fica maior. O quarto único com muitas camas, no segundo andar, dá lugar a quartos individuais e duplos, comprados na Loja dentro do espaço disponível. A árvore libera os tipos aos poucos: individual, depois duplo, depois quarto de herói.

Os NPCs passam a usar esses quartos. Um aventureiro que volta de missão fica cansado e, se houver cama livre, sobe a escada e dorme por um tempo. A renda dos quartos passa a depender da ocupação, em vez de cair sozinha.

Quem está dormindo sai do salão, o que também alivia a lotação. Um limite de hóspedes impede que a escada vire um novo gargalo.

---

## Parte 5: estrutura do jogo

### Capítulos

O jogo passa a ter capítulos, cada um com seu objetivo e um momento de virada. As abas do capítulo seguinte ficam escondidas até essa virada.

| Capítulo | Objetivo | O que abre no final |
| --- | --- | --- |
| 1. A taverna | Pagar a dívida e produzir a própria comida | Missões e o caminho de pedras |
| 2. A guilda | Mural, mercadinho, quartos, contratados, sala da guilda e área de avaliação | Heróis e invocação |
| 3. Os heróis | Promoções, party e invocação | Lorde Demônio |

Um quarto capítulo fica para o futuro.

### Área de avaliação

Fora da taverna, há uma arena de treino onde os contratados tentam subir de rank enfrentando um examinador de rank maior. Ela faz parte do capítulo da guilda.

A liberação segue a árvore de habilidades:

1. O jogador compra o nó da sala da guilda na árvore.
2. A sala fica disponível na Loja, e ele escolhe onde colocá-la.
3. A partir daí, a área de avaliação entra entre as próximas habilidades da árvore. Ela não precisa ser o nó logo seguinte, mas depende da sala da guilda.
4. Ao comprar esse nó, a área fica disponível na Loja, e o jogador a coloca do lado de fora.

Hoje, a sala da guilda abre junto com o segundo andar. Ela precisa passar a ter um nó próprio.

Como funciona o uso da área:

1. O jogador escolhe um contratado e paga uma taxa.
2. O jogo mostra a chance de vitória, baseada no poder do contratado contra o do examinador.
3. O duelo roda sozinho, por cerca de 15 segundos.
4. Se ganhar, ele é promovido. Se perder, só espera um tempo para tentar de novo.

A avaliação vira o único caminho de promoção e dá um uso claro ao dinheiro investido em armas e armaduras.

---

## Ordem de produção

| Parte | Conteúdo | Por que nessa ordem |
| --- | --- | --- |
| 1. Base | PC, fim do editor, lado de fora, mover itens, Mestre de Obras, Loja, saves independentes | Resolve o travamento e prepara a Loja, de que as outras partes dependem |
| 2. Produção | Carroça, fazendas, animais, fazendeiros | Cria os ingredientes das receitas |
| 3. Árvores e receitas | Pesquisa com dois agentes, nova forma da árvore, árvores por ambiente, receitas, sumos sacerdotes | Precisa dos ingredientes e rebalanceia a economia |
| 4. Vida na taverna | Escada, quartos, hóspedes | Usa a compra na Loja |
| 5. Estrutura | Capítulos, área de avaliação | Organiza o que já existe, então fica melhor no fim |

---

## Pontos a confirmar

- **Colheita das frutíferas:** o documento considera que a árvore deixa a colheita mais rápida. O dono falou em "aumentar o tempo de colheita", então vale confirmar.
- **Preços:** metro de obra, decoração, itens da Loja e da carroça são pontos de partida, a ajustar depois de jogar.
- **Salas em cadeia:** hoje, uma sala que dá acesso a outra só sai depois que a outra for movida. Isso pode ser melhorado, mas não é prioridade.
