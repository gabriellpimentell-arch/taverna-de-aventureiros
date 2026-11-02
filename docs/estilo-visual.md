# Estilo visual

Proposta para a taverna low poly, feita só com `caixa`, `cilindro`, `cone` e `esfera`, sem modelos nem texturas externas. As referências serviram de inspiração. Paleta e receitas são autorais e ainda não foram testadas em jogo.

**Direção:** diorama quente e aconchegante, poucas cores por área, e a história contada pela cor: de madeira escura e velas até pedra clara, azul e ouro da guilda.

## O que ajustar primeiro

A base é a última versão de `scripts/prototipo3d.lua` (a do commit atual).

- **Tudo tem o mesmo marrom.** O piso `#7a5433` e o banquinho `#7c4d29` quase se confundem. Escureça o piso e clareie os tampos.
- **As áreas não têm identidade.** Dê a cada uma sua cor de destaque (tabela abaixo).
- **Os cartazes estão retos.** Em `(i - 2) * 0.0` o ângulo é sempre zero, e `giro` nem serviria: ele gira no eixo vertical. Em parede do fundo, use `inclina_z`.

## Paleta

| Uso | Cores |
|---|---|
| Piso (duas tábuas) | `#6b4a30` `#62442b` |
| Corredor gasto (`RUA_Z`) | `#7d5a3a` |
| Paredes e vigas | `#4f3522` `#2d1c11` |
| Madeira: escura, média, tampo | `#4a2c17` `#7b4a26` `#b07a47` |
| Pedra: escura, média, clara (guilda) | `#4e4a48` `#6e6a64` `#a8a294` |
| Pergaminho e pano claro | `#f0e4c8` |
| Ferro | `#2f2c2c` |
| Luz quente | `#ffd26a` `#ffc04a` `#ff7a24` |

| Área | Destaque |
|---|---|
| Salão | tapete `#8f3a32`, vela `#ffd26a` |
| Balcão | âmbar `#e8a33d`, espuma `#fff4dd` |
| Lareira | fogo `#ff7a24` |
| Quadro de missões | ranks: `#9aa0a6` `#5abf7c` `#6d8fe0` `#a06ad8` `#f2c14e` |
| Mercadinho | toldo `#b5403a` e `#efe2c4` |
| Jardim | verdes `#3f6b34` `#5a8f42` `#86b552`, terra `#5a3d26` |
| Cervejaria | cobre `#b8693a` `#d98f55` |
| Círculo de invocação | violeta `#a06aff`, ciano `#6fe6ff`, fundo `#2a2244` |
| Guilda (fase final) | azul `#2b4a8c`, ouro `#d4a83e` |

Regra: madeira e pedra ocupam a maior parte da cena, e a cor forte fica para os personagens e para o destaque da área. Use só 2 ou 3 tons de cada família.

## Receitas

Coordenadas locais: `(0, 0, 0)` é o centro do objeto no chão e `+z` aponta para a câmera. Os ajudantes seguem os do protótipo, com `b` (brilho) opcional no fim:

```lua
local function caixa(x,y,z,ex,ey,ez,c,giro,b) peca("caixa",x,y+ey/2,z,ex,ey,ez,giro or 0,c,0,0,b or 0) end
local function cilindro(x,y,z,d,a,c,b) peca("cilindro",x,y,z,d,a,d,0,c,0,0,b or 0) end
local function cone(x,y,z,d,a,c,b) peca("cone",x,y,z,d,a,d,0,c,0,0,b or 0) end
local function esfera(x,y,z,d,c,ey,b) peca("esfera",x,y,z,d,ey or d,d,0,c,0,0,b or 0) end
```

A base de `caixa`, `cilindro` e `cone` fica em `y`. A `esfera` tem o centro em `y`. Nomes como `PEDRA` e `TAMPO` são da paleta.

### 1. Lareira (na parede esquerda, frente em +x)
```lua
caixa(.45,0,0, .9,2.5,2.2, PEDRA)             -- corpo
caixa(.35,2.5,0, .7,1.7,1.4, PEDRA_ESC)       -- chaminé
caixa(.92,.5,-.8, .06,.25,.4, PEDRA_CLARA)    -- repita 5 ou 6 pedras soltas pela frente
caixa(.8,0,0, .24,1.2,1.3, "#201a18")         -- boca
caixa(.6,1.45,0, 1,.16,2.5, MADEIRA_ESC)      -- consola
peca("cilindro",1,.1,-.4, .16,.8,.16, 0,"#5b3a22",math.pi/2)  -- lenha deitada (faça 2)
cone(1,.15,-.15, .46,.6*f,"#ff7a24",1.2); cone(1,.15,.2, .4,.5/f,"#ff9a30",1.2)
cone(1.05,.15,0, .36,.8*f,"#ffc04a",1.3)      -- f oscila com o tempo
```

### 2. Janela acesa (na parede do fundo)
```lua
caixa(0,1.5,.04, 1.2,1.5,.08, VIGA)           -- moldura
caixa(0,1.62,.09, .96,1.26,.04, "#ffc96b",0,1.3)  -- vidro
caixa(0,1.62,.12, .07,1.26,.03, VIGA)         -- travessa vertical
caixa(0,2.2,.12, .96,.07,.03, VIGA)           -- travessa horizontal
caixa(0,1.42,.12, 1.4,.1,.24, MADEIRA_MED)    -- peitoril
```

### 3. Balcão (clientes em +z)
```lua
caixa(0,0,0, 5.2,1.05,.72, MADEIRA_MED)
caixa(0,0,.02, 5.3,.14,.76, MADEIRA_ESC)      -- rodapé
for x=-2,2 do caixa(x,.24,.37, .72,.62,.04, MADEIRA_ESC) end  -- painéis
caixa(0,1.05,.05, 5.5,.12,.95, TAMPO)
cilindro(1.9,1.17,-.1, .5,.6, MADEIRA_MED); caixa(1.9,1.4,.17, .06,.06,.16, FERRO)  -- barrilete com torneira
cilindro(x,1.17,.22, .16,.2,"#e8a33d"); cilindro(x,1.37,.22, .18,.05,"#fff4dd")     -- caneca
```

### 4. Quadro de missões (na parede do fundo)
```lua
caixa(0,1.3,.05, 2.6,1.7,.1, MADEIRA_ESC)     -- moldura
caixa(0,1.4,.11, 2.3,1.5,.03, "#a87e4f")      -- cortiça
caixa(0,3,.14, 2.9,.12,.3, MADEIRA_ESC)       -- telhadinho
-- cartazes {x,y,rz}: {-.8,1.85,.06} {-.1,1.75,-.05} {.7,1.9,.08} {-.55,2.45,-.07} {.2,2.45,.04} {.85,2.5,-.06}
peca("caixa",x,y,.14, .46,.58,.02, 0,"#f0e4c8",0,rz)
peca("caixa",x,y+.2,.155, .46,.1,.02, 0,COR_DO_RANK,0,rz)  -- faixa em vez de texto
```

### 5. Mesa posta (tampo em y = 0,82)
```lua
cilindro(0,0,0, .26,.72, MADEIRA_ESC); cilindro(0,0,0, .8,.07, MADEIRA_ESC)
cilindro(0,.70,0, 1.75,.12, TAMPO)
cilindro(0,.82,0, .1,.18,"#efe2c4"); esfera(0,1.06,0, .09,"#ffd26a",nil,1.6)  -- vela
cilindro(-.35,.82,.1, .36,.03,"#d8cdb8"); esfera(-.35,.92,.1, .2,"#b5713a")   -- prato com comida
cilindro(.35,.82,-.1, .16,.2,"#e8a33d"); cilindro(.35,1.02,-.1, .18,.05,"#fff4dd")  -- caneca
```
Mostre prato e caneca só quando houver cliente servido: a mesa passa a informar o estado do jogo.

### 6. Pilha de carga (para encher cantos)
```lua
caixa(0,0,0, .7,.6,.7, MADEIRA_MED); caixa(0,.6,0, .74,.06,.74, TAMPO)        -- caixote
caixa(-.28,0,.36, .1,.6,.03, MADEIRA_ESC); caixa(.28,0,.36, .1,.6,.03, MADEIRA_ESC)
esfera(.75,.26,.1, .6,"#c9b58b",.52); esfera(.75,.54,.1, .18,"#a8946c")        -- saco
peca("cilindro",-.2,.38,.9, .76,1,.76, 0,MADEIRA_MED,0,math.pi/2)              -- barril deitado
peca("cilindro",-.4,.38,.9, .82,.08,.82, 0,FERRO,0,math.pi/2)                  -- aro (faça 2)
```

### 7. Barraca do mercadinho
```lua
-- postes: atrás (z = -.65) altura 2.7, na frente (z = .7) altura 2.3, em x = ±2.1, seção .18
caixa(0,0,.4, 4.2,.95,.8, MADEIRA_MED); caixa(0,.95,.4, 4.4,.1,.95, TAMPO)
for i=0,5 do local x,c = -1.95+i*.78, i%2==0 and "#b5403a" or "#efe2c4"
  peca("caixa",x,2.6,0, .8,.1,2, 0,c,.3)      -- toldo inclinado para a frente
  caixa(x,2.1,.95, .8,.18,.05, c)             -- barrado
end
```
Mantenha a espada, o escudo, as poções e a arca sobre o balcão. Uma prateleira no fundo ficaria escondida atrás do barrado.

### 8. Canteiro do jardim (3 × 1,4)
```lua
caixa(0,0,0, 2.9,.22,1.3, "#5a3d26")          -- terra
caixa(0,0,-.7, 3,.3,.12, MADEIRA_MED); caixa(0,0,.7, 3,.3,.12, MADEIRA_MED)
caixa(-1.5,0,0, .12,.3,1.52, MADEIRA_MED); caixa(1.5,0,0, .12,.3,1.52, MADEIRA_MED)
-- 5 plantas por fileira, de x = -1.1 a 1.1:
cilindro(x,.22,-.4, .06,.5,"#5a8f42"); esfera(x,.8,-.4, .24,"#86b552")  -- fundo: lúpulo, alto
esfera(x,.34,0, .34,"#3f6b34",.26)                                      -- meio: couve
cone(x,.22,.4, .18,.26,"#e08a3c")                                       -- frente: cenoura, baixa
```
Altura crescente de frente para trás. Para mostrar crescimento, multiplique os tamanhos por uma escala de 0 a 1.

### 9. Árvore e cerca (só no fundo ou à esquerda)
```lua
cilindro(0,0,0, .4,1.2,"#5b3a22")
esfera(0,1.7,0, 1.6,"#5a8f42",1.3); esfera(-.45,1.35,.25, 1,"#3f6b34",.8); esfera(.35,2.15,-.1, .9,"#86b552",.8)
caixa(x,0,0, .12,.7,.12, MADEIRA_MED)         -- moirão a cada 1 m
caixa(xm,.2,0, 1,.08,.05, TAMPO); caixa(xm,.5,0, 1,.08,.05, TAMPO)  -- travessas
```

### 10. Tina de cobre da cervejaria
```lua
cilindro(0,0,0, 1.5,.16, FERRO); cilindro(0,.16,0, 1.3,1.1,"#b8693a")
cilindro(0,.35,0, 1.34,.07, FERRO); cilindro(0,.95,0, 1.34,.07, FERRO)   -- aros
esfera(0,1.26,0, 1.3,"#d98f55",.7); cilindro(0,1.6,0, .22,.5,"#b8693a")  -- domo e gargalo
caixa(.6,2.05,0, 1.3,.14,.14,"#b8693a"); cilindro(1.25,.7,0, .14,1.45,"#b8693a")  -- cano
caixa(0,.02,.62, .4,.2,.1,"#ffb347",0,1.3)    -- fogo embaixo
-- e um barril de altura .68 em x = 1.25, recebendo o cano
```

### 11. Círculo de invocação (cerca de 4,6 de diâmetro)
```lua
cilindro(0,0,0, 4.6,.12, PEDRA_ESC)
cilindro(0,.12,0, 4,.03,"#a06aff",1.2)        -- anel: disco aceso...
cilindro(0,.15,0, 3.7,.03,"#2a2244")          -- ...coberto por um disco escuro
for k=0,5 do local a = k*math.pi/3 + t*.3     -- hexagrama girando devagar
  caixa(.81*math.cos(a),.18,.81*math.sin(a), .08,.02,2.8,"#6fe6ff",-a,1.3)
end
-- 4 pilares em raio 2,1, diagonais:
caixa(x,.12,z, .36,.3,.36, PEDRA)
cone(x,.85,z, .3,.5,"#6fe6ff",1.3); peca("cone",x,.85,z, .3,.4,.3, 0,"#6fe6ff",math.pi,0,1.3)  -- cristal
```
Na invocação, suba 6 raios finos em volta do centro. Evite um cilindro cheio: o motor não tem transparência e ele esconderia o herói.

### 12. Estandarte da guilda (na parede do fundo)
```lua
caixa(0,3.2,.1, 1.3,.07,.07, FERRO)
caixa(0,1.5,.1, .9,1.7,.04,"#2b4a8c")                       -- pano
peca("caixa",0,1.5,.1, .64,.64,.04, 0,"#2b4a8c",0,math.pi/4)  -- ponta
caixa(0,3,.13, .9,.1,.03,"#d4a83e")                         -- barra dourada
peca("cilindro",0,2.4,.12, .5,.03,.5, 0,"#d4a83e",math.pi/2)  -- emblema
```

## Evolução até virar guilda

| Fase | O que muda |
|---|---|
| Taverna | Madeira escura, velas, uma lareira, poucos objetos |
| Movimentada | Tapete, janelas acesas, pilhas de carga, quadro cheio |
| Guilda | Pedra clara nas paredes, estandartes azul e ouro, quadro maior, círculo violeta |

Troque cores e acrescente peças sem mudar o layout. Assim o jogador reconhece a própria taverna em cada fase.

## Luz

Valores conferidos em `src/cena3d.h`: são **4 luzes por cena**, e o sol e a luz ambiente são fixos no shader.

| Vaga | Uso | Cor (r, g, b) e alcance |
|---|---|---|
| 1 | Lareira, sempre com oscilação | 2.1, 1.0, .36; 7.5 |
| 2 | Salão e balcão, luz central | 1.15, .8, .42; 8 |
| 3 | Área em foco (mercadinho ou cervejaria) | .95, .66, .36; 6.5 |
| 4 | Círculo; antes dele, reforço do balcão | .7, .35, 1.2; 6 |

- **Hierarquia:** o sol define a direção, o ambiente preenche, e cada luz de ponto só destaca um lugar. O ponto mais claro da cena deve ficar onde está a ação principal.
- **Mais luzes de mentira:** com só 4 vagas, use peças com `brilho` (velas, janelas) e, no piso, um disco um pouco mais claro de `.02` de altura como mancha de luz.
- **Brilho:** use de 1,2 a 1,6 em cor clara e saturada. Ele multiplica a cor da peça, então cor escura não acende. De 1 para cima, a peça não projeta sombra.
- **Sombra da parede esquerda:** o sol vem da esquerda e a parede de 4,2 m escurece cerca de 2,3 m do piso. A lareira funciona bem ali. A porta precisa de um lampião.
- **Contraste do círculo:** coloque-o longe da lareira. O violeta rende mais contra um ambiente quente.

## Leitura pela câmera

Na câmera atual a escala é de cerca de 45 px por metro em 960×540, e o ângulo é de cerca de 38° (35 px por metro com o recuo).

- **Espessura mínima:** `.08` (cerca de 3 px). Abaixo disso o detalhe some ou pisca.
- **Altura esconde:** um objeto esconde cerca de 1,3 vez a própria altura do que está atrás dele. Coisas altas ficam na parede do fundo ou da esquerda, e coisas na frente ficam abaixo de 1,6 m.
- **O topo manda:** a câmera vê mais os topos, então o tampo claro faz mais efeito que a frente detalhada.

## O que evitar

- Faixas e peças coplanares: sobreponha ao menos `.02` para não piscar.
- Muitas variações de cor e planta: pouca variedade bem escolhida rende mais.
- Sombra muito escura junto de luz muito clara.
- Rostos, texto em 3D e detalhes finos, que não se leem nessa escala.
- Enfeite acrescentado sem função: cada peça extra deve identificar a área ou mostrar um estado do jogo.
- Pôr um objeto no corredor `RUA_Z`, que é por onde todos andam.

## Fontes

Li o texto das páginas, não as imagens, e nenhuma trazia paleta em hexadecimal: as cores acima são escolhas minhas.

- [80 Level: diorama 3D só com cores](https://80.lv/articles/how-to-create-a-3d-diorama-with-just-colors): paleta contida, sombras claras, ponto mais claro no foco, plantas em três alturas.
- [Creative Bloq: luz principal, preenchimento e contorno](https://www.creativebloq.com/3d/how-to-use-key-fill-and-rim-lighting-in-3d-art): papel de cada luz.
- [Eurobricks: MOC Avendor Adventurers Guild](https://www.eurobricks.com/forum/forums/topic/198696-moc-avendor-adventurers-guild): mistura de taverna e guilda, balcão como centro, pergaminhos de missão.
- [CraftPix: Guild Hall em vista de cima](https://craftpix.net/?p=97724): inventário de guilda (quadro de avisos, suportes de armas, pentagramas, bandeiras).
- [Superhive: Medieval Market & Tavern Props](https://superhivemarket.com/products/medieval-market--tavern-props-pack): inventário de objetos (caixote, sacos, banca, lanterna).
- [TurboSquid: Low Poly Witch Room](https://www.turbosquid.com/3d-models/low-poly-witch-room-stylized-fantasy-magic-interior-2644308): magia em cor fria e brilhante contra luz quente de vela.
