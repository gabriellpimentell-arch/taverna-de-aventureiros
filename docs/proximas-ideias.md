# Próximas ideias

Ideias combinadas com o dono do jogo em 3 de novembro de 2026. **Nada disto foi produzido ainda.** A produção só começa quando ele autorizar.

## Decisões já tomadas

- **Plataforma:** a prioridade passa a ser só o PC. Tudo do jogo continua sendo por cliques, sem controlar personagens.
- **APK:** fica pausado, não apagado. Código, script e chave de teste continuam no GitHub, e o último APK continua disponível. A geração deixa de ser automática e vira um botão manual. O app do celular para de receber novidades. Ao voltar, pode ser preciso ajustar telas e motor.
- **Editor:** sai do jogo (F2, botão nas Configurações e a ideia de salvar e enviar ao GitHub). Mudanças de layout ficam com o Claude, pedidas por texto ou print riscado e conferidas em imagens antes de publicar.
- **Final do jogo:** por enquanto continua sendo a derrota do Lorde Demônio.
- **Direção do jogo:** quando o jogador sentir que está chegando ao fim, abre-se algo novo. O escopo cresceu além do esperado e precisa ser controlado.

## Parte 1: base

### Pausar o APK e retirar o editor
Como descrito nas decisões acima. Reaproveitar o código de arrastar itens do editor antes de apagá-lo. Definir nos arquivos do jogo o tamanho inicial da taverna e o lugar das salas.

### Mercadinho e missões do lado de fora
- Ao liberar o mercadinho ou as missões, o que vier primeiro, surge um caminho de pedras fora da taverna. Os dois podem ser liberados em momentos diferentes.
- O mercadinho fica nesse caminho, com o mural de missões ao lado.
- Quem pega missão ou vende espólios fica só do lado de fora. Quem vem só para isso nem entra na taverna.
- O jogador move o caminho inteiro, com os dois juntos.
- **Motivo:** muitos NPCs entrando de uma vez travam o fim do jogo. Medir os travamentos antes e depois. Se a causa for o cálculo de rotas ao mesmo tempo, espalhar esses cálculos entre os quadros.

### Mover itens
O jogador move literalmente todos os itens pela Loja, de graça. Excluir continua valendo só para decoração.

### Mestre de Obras
Nó barato, bem no começo da árvore, que libera ajustar o tamanho da taverna e de todos os ambientes. Antes dele, o tamanho é fixo. O nome é uma sugestão.

### Loja com imagens e sem limite
- A árvore só libera a função, por exemplo o garçom. Depois disso, compra-se quantos quiser na Loja, e cada um fica mais caro.
- Vale para garçons, quartos, animais, plantações e o resto. Quatro garçons não dão conta do fim do jogo.
- Todo item mostra imagem e nome. O ideal é uma miniatura feita do próprio modelo 3D.
- **Ressalva:** mais bonecos podem aumentar os travamentos. Usar preço que sobe rápido e um limite técnico alto, medido no PC. Passado certo número, um novo garçom pode só deixar os outros mais rápidos.

## Parte 2: produção

### Estrada e carroça
- Uma pequena estrada passa fora do mapa, e uma carroça com um NPC chega a cada 5 minutos, mais ou menos, durante o jogo todo.
- Clicar no NPC abre a lista de compras: bebidas, carne, sementes de bebida e de fruta, e filhotes de animais.
- Ela perde importância conforme o jogador produz mais.
- **Proteções sugeridas:** já estar na estrada no início do jogo; ficar cerca de 1 minuto e meio a cada visita; Bartolo socorrer quem ficar sem nada.
- **Sugestões:** tirar a compra de comida e bebida do painel atual; oferecer itens raros e filhotes com desconto no fim do jogo.

### Três fazendas e três fazendeiros
| Fazenda | Produz | Quem cuida |
| --- | --- | --- |
| Sementes | Trigo, lúpulo e outras plantas | Um fazendeiro só para ela |
| Árvores frutíferas | Frutas | Um fazendeiro só para ela |
| Animais | Vaca, porco e galinha (carne de vaca, carne de porco e ovos) | Um fazendeiro só para ela |

## Parte 3: árvores por ambiente e receitas

### Uma árvore para cada ambiente
- A árvore principal libera os ambientes e as funções.
- Cozinha, cervejaria, cada fazenda e a invocação ganham árvore própria, com 5 a 8 nós no começo.
- A árvore das frutíferas é simples: mais produção e colheita mais rápida. A da cozinha libera receitas, como a de porco.
- **Sugestão de tela:** uma só aba Árvore, com ícones dos ambientes no topo. Tocar na sala no mapa também abre a árvore dela.
- Exige rebalancear a economia inteira.

### Receitas na cozinha
Começar simples e refinar com o tempo.
- A tela da cozinha tem dois espaços para ingredientes.
- Combinar dois ingredientes descobre uma receita, se ela existir, como trigo + ovo = torta.
- Começar com cerca de 10 receitas. O jogador escolhe quais ficam no cardápio.
- Cada receita faz o pedido render mais e gasta os ingredientes dela.

## Parte 4: vida na taverna

### Escada, quartos e NPCs dormindo
- A escada fica maior.
- O quartão com muitas camas vira quartos individuais ou duplos, liberados conforme o jogo evolui e comprados na Loja. O limite é o espaço.
- Alguns NPCs sobem a escada e dormem nas camas.
- **Sugestão:** o aventureiro volta cansado da missão e, se houver cama livre, sobe e dorme por um tempo. A renda dos quartos passa a depender da ocupação. Quem dorme alivia o salão. Um limite de hóspedes evita que a escada vire gargalo.

## Parte 5: estrutura

### Capítulos
| Capítulo | Objetivo | O que abre no final |
| --- | --- | --- |
| 1. A taverna | Pagar a dívida e produzir a própria comida | Missões e o caminho de pedras |
| 2. A guilda | Mural, mercadinho, quartos e contratados | Área de avaliação |
| 3. Os heróis | Promoções, party e invocação | Lorde Demônio |
| 4. Futuro | Deixado para depois | A definir |

As abas do capítulo seguinte ficam escondidas até a virada.

### Área de avaliação
- Fica fora da taverna. O aventureiro luta contra alguém de rank maior e, se ganhar, é promovido.
- O jogador escolhe um contratado e paga uma taxa. O duelo é automático, dura cerca de 15 segundos, e a chance de vitória aparece antes.
- Se perder, ninguém morre: só espera um tempo para tentar de novo.
- Vira o único caminho de promoção.

## Em aberto

- **Invocação:** o dono começou a falar de uma opção para a invocação do herói e mudou de assunto. Se ele não disser outra coisa, vale a árvore exclusiva.
- **Decisões assumidas pelo Claude, que o dono pode mudar:** a avaliação como único caminho de promoção; o caminho de pedras movido inteiro; a divisão nessas cinco partes, com publicação para teste ao fim de cada uma.
