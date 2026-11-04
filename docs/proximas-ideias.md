# Próximas ideias: registro detalhado

Registro da conversa de 3 de novembro de 2026, da mensagem "eu vou querer algumas mudanças em relação ao mercadinho" até este documento.

**Situação: nada disto foi produzido. A produção só começa quando o dono do jogo mandar.**

## Como ler

Cada item separa de quem veio a ideia, porque isso muda o quanto ela pode ser alterada:

- **O dono pediu:** é o que ele quer. Não mude sem perguntar. As frases entre aspas são dele, com pequenos ajustes para a leitura.
- **O dono aprovou:** veio do Claude, e o dono disse que gostou ("Sim, gostei das ideias") ou aceitou claramente.
- **Sugestão do Claude:** detalhe proposto dentro de um pacote de ideias que o dono disse ter gostado, sem comentar o ponto específico. Pode ser seguido, mas vale mostrar a ele.
- **A decidir:** ainda não há resposta.

Os números marcados como sugestão são pontos de partida, não pedidos.

---

## 1. Visão geral e o que orienta tudo

**O dono pediu:**

- **Sensação de progresso:** "uma ideia de jogo no qual você sinta que está chegando no final, só que abre uma nova aba, e daí você começa a ter novas coisas no jogo, e vai introduzindo, e que seja satisfatório".
- **Escopo:** o jogo "está tomando uma forma muito interessante", mas "ganhando um escopo muito maior" do que ele imaginava. As coisas precisam ficar mais controladas.
- **Final do jogo:** "por enquanto vamos deixar o fim do jogo com a derrota do Lorde Demônio". Ele quer acrescentar mais coisas no futuro.
- **Só cliques:** "Tudo clicando, sem movimentação, sem nada." O jogador não controla personagens.
- **Identidade:** ao pedir um fazendeiro por fazenda, ele disse que "assim nós conseguimos ter mais identidade no jogo". Isso serve de critério para decisões parecidas.
- **Agente de bugs:** em mensagem anterior, ele pediu que esse agente só trabalhe quando ele pedir.

---

## 2. Plataforma: priorizar o PC e pausar o APK

**O dono pediu:**

- **Motivo:** o jogo "foi feito para o PC", e com o escopo maior ficou inviável manter a opção do celular.
- **Primeiro pedido:** retirar o APK nas próximas modificações.
- **Pedido final, que substitui o anterior:** não apagar. "Todo o processo que a gente fez para o celular" permanece no GitHub, "porém a gente não prioriza mais ele, prioriza apenas o PC".
- **Motivo de manter:** se no futuro ele quiser testar no celular, "o processo seria menos problemático"; "a única coisa que precisaria era somente atualizar o jogo para caber no celular".

**O dono aprovou** (proposta feita pelo Claude, ainda sem objeção):

- Continuam no GitHub: código do Android, script do APK e chave de teste.
- O último APK continua disponível para baixar.
- A geração do APK deixa de rodar a cada mudança e vira um botão manual no GitHub, acionado quando ele quiser testar.
- O app do celular fica na versão atual e não recebe o que for feito para PC. Isso impede que telas de PC quebrem no celular.

**Ressalva já explicada a ele:** sem testes no celular, algumas coisas ficam para trás. Ao voltar, pode ser preciso ajustar também o motor, não só as telas, para o jogo caber e rodar bem.

**Efeitos previstos:**

- A miniatura 3D da Loja só pede o `.exe` novo, que se atualiza sozinho.
- O limite de bonecos em cena passa a ser medido só no PC.
- Mudanças em C++ não precisam mais garantir compatibilidade com o app instalado. Mesmo assim, evite quebrar a compilação do Android sem necessidade.

---

## 3. Retirar o modo editor

**Histórico da decisão:**

1. O dono primeiro pediu um botão de salvar no editor. O que ele salvasse viraria o início do jogo: "quando eu deixar um tamanho específico da taverna no modo editor, esse será o tamanho inicial", e uma fazenda posicionada e salva "quando ela fosse liberada, ficaria naquela localização". Ao salvar, tudo iria sozinho para o GitHub, para o Claude ver as alterações.
2. Depois ele mudou de ideia: "literalmente retirar a parte do editor e deixar todas as minhas modificações que eu for fazer agora, deixar tudo pra você". O Claude concordou, e ele pediu para incluir nas ideias.

**Portanto, valem:**

- Sai o modo editor: F2 e botão nas Configurações.
- Não será feito o botão de salvar no editor nem o envio automático ao GitHub. Nenhuma chave de acesso é necessária.
- O tamanho inicial da taverna e o lugar de cada sala ficam definidos pelo Claude nos arquivos do jogo.

**Continua existindo, porque é parte do jogo:** a Loja, com obras e movimentação de salas e da porta.

**Atenção:** reaproveite o código de arrastar itens do editor (seção 6) antes de apagá-lo. Ajuste também os testes e as capturas que usam o editor, sem enfraquecer o que ainda vale.

**Como o dono vai pedir mudanças de posição** (o Claude propôs, e ele aceitou tirar o editor depois disso):

- Print riscado ou descrição, como "fazenda atrás da taverna, do lado esquerdo".
- Ele também pode montar a arrumação na Loja, durante o jogo, tirar um print, e o Claude deixa aquilo como padrão.
- O Claude confere em imagens do jogo antes de publicar e pode mostrar o resultado na conversa.

**Desvantagem já explicada:** ajuste fino por descrição pode levar duas ou três tentativas.

---

## 4. Mercadinho e mural de missões do lado de fora

**O dono pediu:**

- O mercadinho e a parede de missões ficam "na parte de fora da taverna".
- Segue "a mesma lógica" de liberação de hoje, e "não necessariamente os dois juntos".
- Ao liberar, cria-se "um caminho na parte de fora da taverna, um caminho de pedras". Nele fica o mercadinho, e "do lado do mercadinho ficaria o mural de missões".
- **Motivo:** "está dando muito travamento na parte final do jogo", porque entram "muitos NPCs de uma vez para pegar missões". O objetivo é "facilitar e diminuir esse congestionamento".
- Os aventureiros que pegam missões "ficariam apenas na parte de fora". Os que vendem espólios "também na parte de fora".

**Comportamento esperado:**

- O caminho surge com o primeiro dos dois que for liberado. O outro aparece no lugar dele quando for liberado.
- O mural deixa de ficar na parede interna, e o mercadinho deixa de ficar na ala interna. O que sobrar sem uso na ala leste precisa ser revisto.

**Sugestão do Claude:**

- Aventureiros que só vêm pegar missão nem entram na taverna; o salão fica para quem vai comer e beber.
- Medir os travamentos antes e depois da mudança. Em teste anterior, houve uma travada quando 20 contratados calcularam a rota ao mesmo tempo. Se essa for a causa aqui, mudar o lugar ajuda, mas talvez seja preciso espalhar os cálculos entre os quadros.
- O jogador move o caminho de pedras inteiro, com mural e mercadinho juntos. É mais simples para ele e para as rotas. O dono não se opôs depois de ler a recomendação, que foi registrada como padrão, mas pode mudar.

---

## 5. Estrada e carroça do comerciante

**O dono pediu:**

- "Uma pequena estrada na parte de fora do mapa", onde chega "uma carrocinha" com um NPC.
- Clicando no NPC, aparece "uma lista de coisas que a gente poderia comprar com ele": "mais bebidas, mais carne, mais semente de alguma bebida e semente de alguma fruta, filhotes de vaca".
- Ela passa "constantemente": "uma vez a cada 5 minutos, por aí". Ele primeiro falou em só no começo, depois se corrigiu ("Minto"): ela continua aparecendo, e "conforme você vai evoluindo, ele não vai ser tão mais necessário".

**O dono aprovou** (ao gostar das ideias):

- **Risco a evitar:** se a carroça for a única fonte de comida, quem está sem estoque fica até 5 minutos sem vender.
- A carroça já está na estrada no início do jogo.
- Ela fica cerca de 1 minuto e meio em cada visita.
- A compra de comida e bebida sai do painel atual, senão ninguém usa a carroça.
- Bartolo, o agiota, socorre quem ficar sem nada.
- No fim do jogo, ela continua útil com itens raros e filhotes com desconto.

**Pontos a cuidar:**

- Conferir o que acontece com o nó "Fornecedor fixo", que hoje compra sozinho quando acaba. Ele pode tirar o sentido da carroça, então precisa ser adaptado ou removido. Decida isso ao produzir e avise o dono.
- A carroça não pode travar o começo do jogo, em que o dono quer que se compre comida para revender.

---

## 6. Mover todos os itens

**O dono pediu:** "o próprio jogador conseguisse movimentar os itens da taverna", "literalmente todos os itens", "não somente no modo de editor".

**Sugestão do Claude:**

- Mover é sempre de graça, inclusive o que vem da árvore.
- Excluir continua valendo só para decoração, para ninguém perder o que comprou.
- Isso acontece na Loja, com o jogo rodando.

---

## 7. Mestre de Obras: liberar o ajuste de tamanho

**O dono pediu:**

- Na árvore de habilidades, "uma opção de liberar limite de tamanho". Ao liberar, "você conseguisse ajustar o tamanho da taverna e de todos os ambientes".
- Primeiro ele pensou em metade do jogo, depois se corrigiu: "Pode ser bem no começo, porque quanto mais garçons e clientes você coloca no jogo, mais complicado vai ser". Assim, "no comecinho do jogo, você já pode ter a opção".
- Ele deixou o nome com o Claude: "você escolhe o nome mais adequado".

**O dono aprovou:** o nome **Mestre de Obras**, um NPC contratado que libera as reformas. Custa pouco e vem logo no começo.

**Consequência:** antes desse nó, o tamanho é fixo. Mover salas continua grátis, e as obras seguem o preço já existente: aumentar custa ouro, e diminuir devolve 50% do que foi pago por aquele metro.

---

## 8. Loja sem limite e com imagens

### Comprar na Loja, não na árvore

**O dono pediu:**

- "4 garçons não está sendo o suficiente para comportar a quantidade de NPCs que tem no fim do jogo".
- Retirar a ideia de comprar cada garçom seguido na árvore.
- Na árvore principal fica, por exemplo, "liberar garçom". Depois, o garçom "vai direto para a loja", e "você pode ir adicionando quanto você quiser".
- "Quanto mais você vai adicionando garçons, mais caro vai ficar. Mas somente na loja", porque na árvore "você está limitando um pouco a quantidade", e assim "fica um pouquinho mais saudável economicamente".
- "A mesma coisa em relação aos quartos. E algumas, tipo, vaca, os animais, as plantações." E depois: "A mesma coisa se aplica para o restante das coisas."

**O dono aprovou:**

- O preço sobe rápido a cada unidade.
- **Ressalva:** mais bonecos podem aumentar os travamentos, justamente o que ele quer resolver. Usar um limite técnico alto, definido depois de medir o desempenho no PC.
- Opção: passado certo número, um novo garçom só deixa os outros mais rápidos, sem colocar mais um boneco em cena.
- Os quartos ficam limitados pelo espaço, o que dá um motivo para construir.

**Pontos a cuidar:**

- Reveja cada nó com vários níveis que coloca coisas no mapa: garçom, mesa, canteiro, árvore do pomar, vacas e quartos. Cada um vira um nó de liberação único na árvore, com a compra na Loja.
- Mantenha funcionando os saves com esses nós já comprados, inclusive os três saves de teste, com uma migração que preserve o que o jogador já tem.

### Imagem dos itens

**O dono pediu:**

- "Na parte da loja, eu gostaria que tivesse a aparência dos itens que você está adicionando." Se é um garçom, aparece "a imagem do garçom, e não só o nome", porque "só o nome está um pouquinho difícil de assimilar" e "não é intuitivo".
- "Eu quero que tenha sempre os nomes e a imagem do que eu estou comprando."

**O dono aprovou:** o ideal é uma miniatura feita do próprio modelo 3D, para o item da Loja ser igual ao do jogo. Exige mudar o motor e só atualiza o `.exe`.

---

## 9. Três fazendas e três fazendeiros

**O dono pediu:**

- Separar em "fazenda de sementes, fazenda de árvores frutíferas" e "fazenda de vacas não, né? De animais".
- "Um fazendeiro para cada fazenda": um só para as plantações, outro só para as árvores frutíferas, outro só para os animais.
- Além da vaca, "um porco, uma galinha. Normalmente só esses três mesmo".

**O dono aprovou:**

| Fazenda | Antes | Produz | Quem cuida |
| --- | --- | --- | --- |
| Sementes | Jardim | Trigo, lúpulo e outras plantas | Fazendeiro das plantações |
| Árvores frutíferas | Jardim de frutas | Frutas | Fazendeiro das árvores |
| Animais | Fazenda | Vaca: carne de vaca. Porco: carne de porco. Galinha: ovos | Fazendeiro dos animais |

É mais um trabalho de renomear e separar o que cada uma produz. Cada animal produz uma coisa diferente.

---

## 10. Uma árvore de habilidades para cada ambiente

**O dono pediu:**

- "Após cada liberação de ambiente tivesse sua própria árvore de habilidades", para "criar um incentivo maior para o jogador". Ele também pediu a opinião do Claude, que foi favorável.
- Exemplo: liberada a cozinha, a árvore dela libera "uma receita de porco". "Cada ambiente seria uma árvore de habilidades única."
- Árvore exclusiva "tanto pra cozinha, pra cervejaria, pras fazendas, pra os jardins também".
- A árvore das frutíferas "não seria tão complexa", porque "é só plantar a árvore e fazer ela crescer". Ela seria "tipo, aumentar a produção, aumentar o tempo de colheita". **Provavelmente ele quis dizer colheita mais rápida**, o que convém confirmar ao produzir.
- A árvore principal continua existindo.

**O dono aprovou:**

- A árvore principal libera os ambientes e as funções.
- Para não lotar a barra de baixo, há uma só aba Árvore, com ícones dos ambientes no topo.
- Tocar na sala no mapa também abre a árvore dela.
- Cada árvore tem de 5 a 8 nós no começo.
- A invocação também tem árvore, com os sumos sacerdotes (seção 10.1).

**Ponto a cuidar:** é preciso rebalancear a economia inteira. Rode o robô do início ao fim para confirmar que o jogo continua terminável.

---

## 10.1. Árvore da invocação e sumos sacerdotes

**O dono pediu:**

- Ao abrir a invocação, cria-se "uma nova árvore de habilidades", igual às dos outros ambientes (seção 10).
- Dentro dela, há "a opção de desbloquear sumos sacerdotes".
- São necessários **4 sacerdotes**, "porque como tem 4 pilares". Primeiro ele falou em 5 e se corrigiu.
- Os 4 são "um pré-requisito para desbloquear a invocação de herói".
- Ele deixou com o Claude a melhor forma de introduzir: contratar um mago e evoluí-lo até virar sacerdote, ou desbloquear direto na árvore.

**Sugestão do Claude, ainda sem resposta do dono:** desbloquear na árvore, sem evoluir um mago.

1. Um nó da árvore da invocação, por exemplo "Ordem dos Sumos Sacerdotes", libera os sacerdotes.
2. O jogador contrata os 4 um a um, cada um mais caro que o anterior.
3. Cada sacerdote vai para um pilar, e o pilar acende.
4. Com os 4 pilares acesos, o círculo se ativa e a invocação de heróis é liberada.

**Motivos:**

- Evoluir um mago tiraria um contratado das missões e da party, e o jogador poderia ficar sem nenhum mago disponível.
- Quatro pilares acendendo mostram o progresso na tela, sem precisar de outro sistema de evolução.
- Assim, o escopo fica menor. A ideia de ordenar um contratado pode entrar depois, no refinamento.

**Ponto a cuidar:** o robô de testes precisa contratar os 4 antes de invocar, para o jogo continuar terminável.

---

## 11. Receitas na cozinha

**O dono pediu:**

- "A cozinha, eu quero que desse para combinar alimentos diferentes para criar receitas novas."
- Ele sabe que é "um tanto quanto complexo e difícil", mas quer "introduzir agora e depois ir refinando com o tempo".

**O dono aprovou:**

- A tela da cozinha tem dois espaços para ingredientes.
- Combinar dois ingredientes descobre uma receita, se ela existir. Exemplo: trigo + ovo = torta.
- Começa com umas 10 receitas.
- O jogador escolhe quais ficam no cardápio.
- Cada receita faz o pedido render mais e gasta os ingredientes dela.
- Fica feito de um jeito que dê para refinar sem refazer tudo.

---

## 12. Escada, quartos e NPCs dormindo

**O dono pediu:**

- Aumentar o tamanho da escada.
- Hoje "no segundo andar está um quarto com muitas camas". Ele quer "quartos individuais, ou individual ou com duas camas".
- "Que desse para adicionar conforme a evolução do jogo", dentro do limite que couber, pensando no final.
- "Na parte de cima da taverna."
- "Agora os NPCs subissem as escadas e fossem dormir nas camas. Alguns NPCs." Ele não sabia exatamente como fazer e pediu ajuda.
- Pela seção 8, os quartos também são comprados na Loja.

**O dono aprovou:**

- Um aventureiro que volta de missão fica cansado e, se houver cama livre, sobe e dorme por um tempo.
- A renda dos quartos passa a depender dos quartos ocupados, em vez de cair sozinha.
- A evolução é: individual, depois duplo, depois quarto de herói.
- Quem dorme sai do salão, o que alivia a lotação.
- Há um limite de hóspedes, para a escada não virar novo gargalo.

---

## 13. Capítulos

**O dono pediu:** a sensação descrita na seção 1, sem uma divisão definida.

**O dono aprovou** (proposta do Claude):

| Capítulo | Objetivo | O que abre no final |
| --- | --- | --- |
| 1. A taverna | Pagar a dívida e produzir a própria comida | Missões e o caminho de pedras |
| 2. A guilda | Mural, mercadinho, quartos e contratados | Área de avaliação |
| 3. Os heróis | Promoções, party e invocação | Lorde Demônio |
| 4. Futuro | Deixado para depois | A definir |

- Cada capítulo tem seu objetivo e um momento de virada.
- As abas do seguinte ficam escondidas até a virada.
- O capítulo 4 não entra agora, para o escopo não crescer.

---

## 14. Área de avaliação dos heróis

**O dono pediu** (ideia ainda em formação, "tô pensando"):

- "Introduzir uma área que fica na parte de fora, novamente da taverna, na qual teria treinamento dos heróis. Seria uma área de avaliação."
- "O aventureiro ia lá, brigava com um aventureiro de rank maior; caso ele ganhasse, ele era promovido para um rank maior."
- Ele disse que não sabia bem como introduzir isso.

**O dono aprovou** (ao gostar das ideias):

- O jogador escolhe um contratado e paga uma taxa.
- Um duelo acontece na arena, em uns 15 segundos, sem o jogador controlar nada.
- A chance de vitória depende do poder do contratado contra o do examinador, e aparece antes da luta.
- Se perder, ninguém morre: ele só espera um tempo para tentar de novo. Isso mantém a regra de não ter risco de morte.
- Dá um uso claro ao dinheiro investido em armas e armaduras.
- É o único caminho de promoção, para não existirem duas formas de fazer a mesma coisa. Registrado como padrão, e o dono pode mudar.

---

## 15. Ordem de produção

O dono disse "gostei das ideias" sobre esta divisão. Cada parte é publicada para ele testar antes da próxima, para um problema não ficar escondido no meio de tudo.

**Parte 1: base**
1. Pausar o APK e priorizar o PC (seção 2).
2. Retirar o editor (seção 3).
3. Mercadinho e mural do lado de fora (seção 4).
4. Mover todos os itens (seção 6).
5. Mestre de Obras (seção 7).
6. Loja sem limite e com imagens (seção 8).

**Parte 2: produção**
7. Estrada e carroça (seção 5).
8. Três fazendas, porco, galinha e três fazendeiros (seção 9).

**Parte 3: árvores e receitas**
9. Árvore por ambiente e sumos sacerdotes (seções 10 e 10.1).
10. Receitas (seção 11).

**Parte 4: vida na taverna**
11. Escada, quartos e NPCs dormindo (seção 12).

**Parte 5: estrutura**
12. Capítulos (seção 13).
13. Área de avaliação (seção 14).

**Dependências que explicam a ordem:** o mover itens reaproveita o código do editor. As receitas precisam dos ingredientes das fazendas. Os quartos usam a compra na Loja. A avaliação usa a estrutura de capítulos.

---

## 16. A decidir

1. **Sumos sacerdotes:** falta o dono confirmar a forma sugerida na seção 10.1.
2. **Autorização:** o dono ainda não mandou começar. Na mensagem anterior a esta, ele pediu só este documento.
3. **Preços:** metro de obra, decoração e tudo o que for vendido na Loja ou na carroça. Os atuais são chutes iniciais e devem ser ajustados depois de jogar.
4. **Salas em cadeia e o herdar de saves:** ficaram como limitações da entrega anterior. Uma sala que dá acesso a outra só sai depois que a outra for movida. Tamanhos e decoração ficam salvos para todos os saves, então um jogo novo herda o que foi construído. O Claude disse que o herdar é a primeira coisa que corrigiria. Sem o editor, faz sentido resolver isso junto da Parte 1.

---

## 17. O que não fazer

- Não produzir antes de o dono mandar.
- Não apagar o código do Android nem o processo do APK.
- Não criar botão de salvar no editor nem envio automático ao GitHub. Essa ideia foi substituída.
- Não colocar risco de morte na avaliação.
- Não acionar o agente de bugs sem ele pedir.
- Não mudar o final do jogo agora nem produzir o capítulo 4.
- Não tratar o que está como **Sugestão do Claude** como pedido dele, se ele disser o contrário.
