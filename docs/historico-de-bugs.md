# Histórico de bugs e testes

Memória do projeto para quem for testar o jogo. Leia antes de começar, para não investigar de novo o que já foi resolvido, e atualize ao terminar.

**Decisão do dono:** os agentes de bugs só atuam quando ele pedir, porque são demorados. No trabalho normal, rode apenas os testes rápidos.

O branch `dupla-agentes` guarda a primeira rodada da dupla, interrompida e com 2 testes falhando (rotas com mesas giradas ou sobre a porta). Reaproveite-o quando pedirem essa correção.

## Como testar

| O que | Comando | Quando |
| --- | --- | --- |
| Testes rápidos (regras, todos os botões, saves estragados, colisões, editor, Android sem aparelho) | `LUA_BIN=lua5.4 tests/rodar.sh 5 rapido` | Toda mudança |
| Jogo inteiro pelo robô, até derrotar o Lorde Demônio | `lua5.4 tests/robo_so.lua . 40` (cerca de 6 min) | Mudou regra ou balanceamento |
| Jogo real, com uma imagem de cada tela | `JOGO_BIN=<executável> tests/capturar.sh <pasta>` | Mudou tela ou cena |

Os dois agentes de bugs dividem o jogo ao meio, na compra do Recrutador:

| Agente | Parte | Comando |
| --- | --- | --- |
| `guardiao-bugs` | Do início até o Recrutador: taverna, missões, mercadinho e produção | `tests/parte.sh 1` |
| `guardiao-final` | Do Recrutador até o final: contratados, parties, heróis, invocação e Lorde Demônio | `tests/parte.sh 2` |

Eles trabalham ao mesmo tempo. Quando o `guardiao-bugs` corrige um bug, roda `tests/reiniciar_parte2.sh`: o `guardiao-final` recomeça da metade, porque o ponto de partida dele mudou.

O GitHub repete os testes rápidos antes de cada publicação no `main`. Se falharem, a versão não é publicada.

Só rode o que a mudança pode ter afetado. Os testes em `tests/testes.lua` já cobrem os bugs abaixo: não é preciso investigá-los de novo à mão, basta os testes passarem.

## Regras

- Todo bug corrigido ganha um teste que falharia sem a correção.
- Nunca apague nem enfraqueça um teste para fazê-lo passar.
- As sementes mudam a cada rodada, então uma falha rara pode ser real: repita antes de descartar.

## Falhas ainda em aberto

- **Bonecos se encostando:** "bonecos quase nunca se sobrepõem" falha às vezes (69 casos em 3000 passos, limite de 60). Causa não encontrada.
- **Por dentro da mesa:** "ninguém anda por dentro de mesa" falhou uma vez (41 casos) e não voltou em 120 sementes. Causa não encontrada. `iniciar` ressemeia pelo relógio, então a semente não reproduz a falha.
- **Pessoa empurrada para dentro da mesa:** com o passo de 0,25 s do robô, um empurrão entre bonecos pode saltar até 0,9 m e cair no fundo de uma mesa. Quem cai lá agora sai pelo ponto livre até 1,8 m, cruzando o móvel; a causa do salto segue aberta. Não foi medido com o passo menor do jogo real.
- **Vacas em fazenda mínima:** com a fazenda encolhida a 3 x 3 m, as 8 vacas ficam paradas e sobrepostas. Não trava; o editor permite esse tamanho.
- **Salão mínimo com 8 mesas:** não cabe; as pessoas atravessam móveis (874 casos de sem caminho em 150 s), como em "Layout que fecha o caminho".
- **Layout que fecha o caminho:** com a porta tapada ou móveis fechando o corredor, as pessoas atravessam os móveis. É proposital, para o jogo não travar, e o editor avisa.
- **Salão encolhido fecha o caminho:** com tudo comprado, recuar a frente 1 m deixa 18 dos 20 lugares sem rota (a segunda fileira encosta na primeira e o bardo fecha a saída da porta); -3 m na direita ou na esquerda deixa 4, e -2 m no fundo, 2. No mínimo (8 x 7 m) as mesas ficam empilhadas, porque 6 mesas não cabem. O editor avisa ao sair, e as pessoas atravessam os móveis. Precisa de decisão: mínimo maior ou rearrumar as mesas sozinho.
- **Itens novos só no salão e na ala leste:** o limite não deixa levá-los para a cozinha, o jardim, o pomar ou a fazenda. Os móveis originais soltos têm o mesmo limite.
- **Áreas externas sobre o salão:** jardim, pomar e fazenda podem ser arrastados para cima do salão. A porta pode ir para o meio do salão. Item levado para uma sala ainda não comprada fica solto até ela abrir.
- **Cozinheiro e móveis:** ele anda em linha reta entre fogão e mesa de preparo. Não sai da cozinha, mas atravessa o que o jogador puser no meio.
- **Giro do balcão:** a folga até a parede considera o balcão sem giro; girado a 90 graus, ele pode encostar na parede.
- **Editor:** balcão e estantes de venda não acompanham a parede do fundo quando ela recua.
- **Notícia:** fechar o jogo com a tela de novidade aberta faz aquela novidade não voltar.
- **Desempenho em salão enorme:** com +40 m, uma rota leva 19 ms e uma busca sem caminho, 350 ms. Com o save completo, 20 contratados que partem no mesmo quadro travaram 840 ms uma vez (2 núcleos ocupados). Tamanho normal: pico de 96 ms; desenho sempre abaixo de 9 ms em Lua.
- **Balanceamento:** o robô leva cerca de 31 h e o ouro por segundo dele cai no fim.

- **Android, só dá para ver no aparelho:** nenhum dos itens de Android foi rodado em celular. Conferir: abrir, tocar, pinça, minimizar e voltar (sombras e fontes), botão voltar, Sair e abrir de novo, copiar no editor, desempenho (sombra de 2048 e uma chamada de desenho por peça).
- **Android, sem tratamento:** janela que muda de tamanho com o jogo aberto (dobráveis; a raylib ignora), contexto OpenGL perdido pelo sistema, aparelho sem configuração MSAA 4x. A barra de navegação fica visível, porque esconder muda o tamanho da janela.
- **`MOTOR_ANDROID`:** ao mudar o motor, aumente o número em `src/main.cpp` e em `build.yml`; `tests/android.lua` confere. Como as correções acima estão no motor, quem já tiver um APK precisa instalar o novo (ainda não houve APK publicado).

- **Teste instável sem causa conhecida:** cerca de 1 em 50 rodadas parou em `não comprou <nó>` (`libera` em `tests/testes.lua`, linhas diferentes). A mesma semente passa depois; ocorreu com outro agente editando scripts ao mesmo tempo, o que pode ser a causa.

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

### Segunda metade, com cozinha, pomar e fazenda
- Desfazer a party durante a batalha final deixava a luta seguir sem party. Agora é recusado, com aviso.
- Número acima de 1e21 virava centenas de dígitos na tela. Agora usa notação científica.
- Os canteiros, comprados na árvore, podiam ser excluídos, contra o GDD.
- Quem caía no fundo de uma mesa fazia `tests/parte.sh 2` falhar quase sempre em "pessoa sem caminho", e sem saída real fazia até 16 buscas caras seguidas; agora são no máximo 4.
- Testes novos: paredes de 4,2 m nos três saves prontos; layout com excluídos e itens novos abrindo save antigo, metade, completo e novo.

### Rotas e colisões
- Quem era empurrado seguia reto por dentro da mesa; agora a rota é refeita.
- O banco direito da mesa 8 não tinha caminho, e todos cruzavam as mesas 7 e 8.
- Com mesa ou balcão girados, o garçom parava dentro do móvel.
- Garçons em casa ficavam presos ao lado de quem estava sentado no balcão.
- O caixote da ala leste fechava a passagem atrás da barraca, e quem vendia ali ficava sem caminho.
- Quem era empurrado para dentro de um móvel ficava sem caminho; agora sai pelo ponto livre mais próximo.
- Bancos das mesas 7 e 8 a 0,2 m um do outro causavam o maior congestionamento.

### Editor e posições
- Um clique sem arrastar movia o objeto e gastava um desfazer.
- Soltar fora da janela deixava o arrasto preso.
- Valores absurdos jogavam objetos para fora do mundo.
- Só abrir e fechar o editor fixava as posições oficiais no arquivo local.
- Filhos não giravam nem subiam com o pai, e arrastar filho de pai girado errava o ponto.
- Ids antigos (`garrafas`, `barris_*`) perdiam a posição; encolher o salão deixava objetos fora.
- Com +40 m em todos os lados, o limite de visão cortava o salão.

### Editor estilo The Sims
- Mover ou girar uma sala interna (cozinha, cervejaria, círculo) levava fogão, cozinheiro e pilares para fora das paredes, que não andam. Ao voltar a sala, eles voltam ao lugar. Layout salvo assim é corrigido ao carregar.
- Encolher a sala deixava móveis entrando na parede da frente e na sala vizinha.
- "Posição original" num salão encolhido jogava o item para fora da parede.
- Mesas, balcão, palco, bardo, quadro e barraca podiam ser arrastados para fora das paredes, e as pessoas atravessavam a parede para chegar. Mesas 1 a 6 ficam no salão, porque a ala pode não existir.
- Sala interna mais funda que o salão cobria a área externa da frente, com vacas dentro da cozinha. Agora essa área recua.
- Mesa empurrada por salão menor esquecia o lugar depois de desfazer ou recarregar.
- Arquivo de layout estragado: id de item novo que não era texto, itens novos sem limite, e itens da árvore escondidos.
- Vacas 7 e 8 e as flâmulas podiam ser selecionadas sem aparecer na edição.
- Pinça que começava sobre um item trocava a seleção.
- Cozinheiro atravessava a parede quando fogão ou mesa de preparo ficavam colados nela.

### Notícias e menestrel
- Notícia, faixa e medidor eram zerados a cada 12 missões; a notícia sobrevivia a apagar o progresso.
- O menestrel cantava no meio do caminho em salão enorme e perdia a história ao aplicar o layout.
- O robô ficava pausado para sempre na primeira notícia.

### Android (revisão sem aparelho; conferido em `tests/android.lua`, `tests/toques_teste.cpp` e `tests/testes.lua`)
- O APK não abria: faltava `-u ANativeActivity_onCreate` (a opção da raylib só vale para os alvos da pasta dela). O build agora confere o símbolo.
- Fontes próprias nunca carregavam: a raylib redefine `fopen` e não abre caminho absoluto. Agora são lidas pela memória.
- Sair e abrir de novo no mesmo processo: o jogo fechava sozinho (`g_sair`) ou usava Lua e OpenGL já fechados. Agora tudo é zerado.
- Fechar derrubava o app: linha presa à Java (JNI) sem `DetachCurrentThread`.
- Minimizar não salvava, e a música seguia tocando. Agora salva e pausa em `APP_CMD_PAUSE`; ao voltar, conta o tempo parado como tempo fora.
- Pinça apertava o botão sob o primeiro dedo e fazia a tela pular. Toque rápido entre quadros se perdia. Agora passam por `src/toques.h`.
- Gesto de voltar aperta e solta no mesmo quadro e se perdia.
- Baixar a atualização travava o jogo ("o app não responde"); agora baixa em outra linha.
- APK de teste trocava os próprios scripts pelos do `main` ou avisava "APK velho" à toa; internet ruim também contava como APK velho. Só a versão publicada se atualiza, e só o 404 avisa.
- Instalar APK novo mantinha os scripts baixados pelo antigo. Disco cheio na extração destruía a versão que funcionava.
- Textura de sombra usava formato sem tamanho, inválido no ES 3 puro; profundidade da tela passou de 16 para 24 bits (`android/ajustar_raylib.sh`, que falha se a raylib mudar).
- Zoom da pinça dependia da resolução; uma segunda abertura podia criar outra instância (`singleTask`).
- Sombreadores conferidos em contexto ES 3 real (Mesa): compilam e ligam. O motor Linux com `-DTAVERNA_ES3` desenha a cena certa.

## Como manter

Ao terminar uma rodada: acrescente aqui o que foi corrigido, mova para "Já corrigidos" o que saiu de "em aberto" e registre as falhas novas sem causa conhecida.
