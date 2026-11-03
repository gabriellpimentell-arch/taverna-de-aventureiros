# Histórico de bugs e testes

Memória do projeto para quem for testar o jogo. Leia antes de começar, para não investigar de novo o que já foi resolvido, e atualize ao terminar.

## Como testar

| O que | Comando | Quando |
| --- | --- | --- |
| Testes rápidos (regras, todos os botões, saves estragados, colisões, editor) | `LUA_BIN=lua5.4 tests/rodar.sh 5 rapido` | Toda mudança |
| Jogo inteiro pelo robô, até derrotar o Lorde Demônio | `lua5.4 tests/robo_so.lua . 40` (cerca de 6 min) | Mudou regra ou balanceamento |
| Jogo real, com uma imagem de cada tela | `JOGO_BIN=<executável> tests/capturar.sh <pasta>` | Mudou tela ou cena |

O GitHub repete os testes rápidos antes de cada publicação no `main`. Se falharem, a versão não é publicada.

Só rode o que a mudança pode ter afetado. Os testes em `tests/testes.lua` já cobrem os bugs abaixo: não é preciso investigá-los de novo à mão, basta os testes passarem.

## Regras

- Todo bug corrigido ganha um teste que falharia sem a correção.
- Nunca apague nem enfraqueça um teste para fazê-lo passar.
- As sementes mudam a cada rodada, então uma falha rara pode ser real: repita antes de descartar.

## Falhas ainda em aberto

- **Bonecos se encostando:** "bonecos quase nunca se sobrepõem" falha às vezes (69 casos em 3000 passos, limite de 60). Causa não encontrada.
- **Por dentro da mesa:** "ninguém anda por dentro de mesa" falhou uma vez (41 casos) e não voltou em 120 sementes. Causa não encontrada. `iniciar` ressemeia pelo relógio, então a semente não reproduz a falha.
- **Layout que fecha o caminho:** com a porta tapada ou móveis fechando o corredor, as pessoas atravessam os móveis. É proposital, para o jogo não travar, e o editor avisa.
- **Editor:** balcão e estantes de venda não acompanham a parede do fundo quando ela recua.
- **Notícia:** fechar o jogo com a tela de novidade aberta faz aquela novidade não voltar.
- **Desempenho em salão enorme:** com +40 m, uma rota leva 19 ms e uma busca sem caminho, 350 ms.
- **Balanceamento:** o robô leva cerca de 31 h e o ouro por segundo dele cai no fim.

## Já corrigidos (com teste)

### Formatação e saves
- 100 mi aparecia como "1 mi", 120 mil como "12 mil" e 999.999 como "1000 mil".
- Número infinito ou inválido invalidava o save inteiro; saves com tipos errados travavam o jogo.
- Arquivo adulterado com laço infinito travava a leitura.
- Se o início do jogo falhasse, fechar gravava um save vazio por cima do progresso.
- Party incompleta ou com id inválido prendia os membros.

### Ganho offline
- Coletar inflava o ouro por segundo e multiplicava o ganho seguinte.
- Sair com a janela de ganho aberta perdia o ouro.
- Missões ficavam com tempo negativo.

### Interface
- Botões de investir e promover não respondiam com a lista rolável.
- Arrastar comprava em vez de só rolar; janela aberta deixava arrastar e rolar a tela de trás.
- Botão cortado tapava "Contratar", e nó cortado da árvore recebia toque.
- Tela final: o mundo seguia rodando atrás, e um toque ainda servia cliente.
- O botão das Configurações abria o editor na tela final.

### Regras
- A missão SSS nunca liberava, porque os membros da party estavam sempre em missão.
- "Formar a party final" falhava com invocado em outra party.
- Comprar mesa depois do balcão trocava o lugar de quem estava sentado.
- Mercadinho ficava fora da ala em save sem o nó correspondente.
- Recomeçar mantinha a contagem de histórias.
- Invocados piscavam, porque o visual era sorteado a cada quadro.

### Rotas e colisões
- Quem era empurrado seguia reto por dentro da mesa; agora a rota é refeita.
- O banco direito da mesa 8 não tinha caminho, e todos cruzavam as mesas 7 e 8.
- Com mesa ou balcão girados, o garçom parava dentro do móvel.
- Garçons em casa ficavam presos ao lado de quem estava sentado no balcão.
- Bancos das mesas 7 e 8 a 0,2 m um do outro causavam o maior congestionamento.

### Editor e posições
- Um clique sem arrastar movia o objeto e gastava um desfazer.
- Soltar fora da janela deixava o arrasto preso.
- Valores absurdos jogavam objetos para fora do mundo.
- Só abrir e fechar o editor fixava as posições oficiais no arquivo local.
- Filhos não giravam nem subiam com o pai, e arrastar filho de pai girado errava o ponto.
- Ids antigos (`garrafas`, `barris_*`) perdiam a posição; encolher o salão deixava objetos fora.
- Com +40 m em todos os lados, o limite de visão cortava o salão.

### Notícias e menestrel
- Notícia, faixa e medidor eram zerados a cada 12 missões; a notícia sobrevivia a apagar o progresso.
- O menestrel cantava no meio do caminho em salão enorme e perdia a história ao aplicar o layout.
- O robô ficava pausado para sempre na primeira notícia.

## Como manter

Ao terminar uma rodada: acrescente aqui o que foi corrigido, mova para "Já corrigidos" o que saiu de "em aberto" e registre as falhas novas sem causa conhecida.
