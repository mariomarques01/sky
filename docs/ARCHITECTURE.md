# Arquitetura

A cena em `worlds/world_01/level_01/` contém os terrenos, os vãos da ponte, os triggers, o inimigo, as ruínas e a câmera. Cada prop GLB é uma PackedScene independente. A composição de Background fica atrás do plano de movimento e dispensa física. O mundo aplica materiais compartilhados e instala os efeitos ambientais na inicialização.

`player/player.tscn` compõe CharacterBody3D, colisão, máquina de estados, saúde, dash e visual com esqueleto. O controlador amostra ações por tick físico, aplica aceleração, gravidade, tolerância de borda e fila de salto, resolve o movimento com move_and_slide e seleciona o estado. A velocidade em Z é zero e o corpo retorna ao plano central. O estado emite entered quando muda. Dash controla duração, recarga e disponibilidade aérea. Health controla a janela de imunidade. As propriedades exportadas desses nós ajustam o comportamento no Inspector.

A câmera suaviza posição e antecipação e recebe o sinal `impact` para deslocamento transitório.

Cada coletável é uma Area3D com bloqueio de coleta dupla. O GameManager contabiliza por tipo e emite changed ou finished. O HUD escuta esses sinais. O patrulheiro usa limites e um RayCast3D apontado para o piso. A diferença entre os pés do jogador e o centro do inimigo, junto à velocidade vertical, caracteriza o impacto por cima.

Quatro autoloads concentram o estado da partida, persistência ConfigFile, reprodução de áudio e reinício de cena. O checkpoint dura uma tentativa da fase. Reiniciar restaura inimigos, coletas e vida. A interface e o menu usam processamento durante pausa, com liberação das ações de toque ao abrir o menu.

### Áudio e impacto

`Audio` distribui efeitos por SFX e UI, com oito vozes prontas e expansão do
pool quando todas estão ocupadas. A Web registra os samples na inicialização
para tirar o custo da primeira reprodução dos frames de jogo. As caixas tocam
o som quando recebem o golpe e liberam os estilhaços ao fim da compressão.
O perfil Baixo usa nove fragmentos de madeira em vez de dezoito.

A música usa dois players no bus Música. O Guardião troca o loop da fase
pelo tema da luta e restaura o loop da fase na derrota, com fades cruzados
de 0,5 s. A conclusão para a música e toca o jingle de vitória no bus SFX.
Os WAVs são sintetizados por `procedural/bake_audio.py`.

`Game.hit_stop(0.05)` aplica a pausa de stomp, ground pound e acertos no Guardião.
Um único temporizador ignora a escala do tempo e continua com o menu pausado.
Impactos sobrepostos estendem o prazo até o maior tempo restante. O fim da pausa
ou o reinício da fase restaura a escala anterior.

### Animação do explorador

O controlador passa a pose, as velocidades e o tempo restante de pouso ao Visual.
O AnimationTree em `player/player.tscn` tem um nó para cada clipe da tabela.
Ao importar ou substituir o clipe com esse nome na biblioteca padrão do
AnimationPlayer do Explorer, o nó passa a usá-lo automaticamente. Para escolher
um clipe de outra biblioteca, selecione-o no campo **Animation** do nó da árvore.

| Nó e nome exato do clipe | Duração recomendada | Reprodução |
| --- | --- | --- |
| `Idle` | 3,20 s | Loop |
| `Jump` | 0,25 s | Uma vez, mantém a última pose |
| `Fall` | 0,60 s | Loop |
| `Land` | 0,08 s | Uma vez |
| `Dash` | 0,16 s | Uma vez |
| `Hurt` | 0,23 s | Uma vez |
| `Death` | 0,35 s | Uma vez |

As durações são de referência. A física controla a troca de estado e pode
interromper o clipe. `Landing` seleciona `Land`. Anime o esqueleto no lugar,
com os mesmos nomes de ossos. O deslocamento fica com o controlador.

`Walking` é o marcador de fallback. Um clipe ausente também mantém a pose
procedural, com respiração no Idle. O Bunny atual tem uma única malha sem
blend shapes ou ossos de pálpebras. O piscar depende de um rig facial futuro.
A árvore avança em passos de física e as poses têm blend de até 140 ms.
Walk e Run seguem sincronizados com a distância. Squash/stretch, rastro do dash,
intermitência de dano e deslocamento do arco de morte ficam na camada visual.
A cambalhota procedural de morte cede lugar ao clipe `Death` quando disponível.

### HUD e toque

O direcional, Pulo e Ação capturam dedos independentes. Ação emite touch_attack para o combo no chão ou chute aéreo. O gesto para cima na área livre usa dive para o mergulho em velocidade. Um gesto horizontal iniciado
na área livre da metade inferior aciona dash e preserva o segundo toque de salto.
O HUD guarda tamanho, opacidade e lado na seção `toque` de Save. A área segura
contém o menu e o controle virtual. O mínimo físico usa o DPI informado pelo sistema.
Game emite `collected(kind)` e `checkpoint_activated` para os avisos do HUD.
A conclusão apresenta o relógio de jogo da fase (pausas excluídas), as moedas da
partida e o recorde persistente de cristais dourados.

### Arena de inimigos

Abra `worlds/test_enemies/Arena.tscn` com F6. Espinhos, voador e guardião
especializam o deslocamento e o contato da patrulha do cogumelo. Cogumelos e
espinhos se comprimem durante a pausa de 150 ms antes da virada. O voador
antecipa os extremos horizontais do voo senoidal com a mesma compressão.
O contato desses três inimigos causa dano após 150 ms de sobreposição contínua.
Golpes válidos ainda podem derrotá-los durante a antecipação. Ao fim da
animação de derrota, cada inimigo libera oito partículas de CPU de vida curta.
O impacto vertical também atinge espinhos próximos pelo sinal `ground_pound`.
O Casco de Pedra pertence a `slam_target` e recebe `take_ground_pound(player)`
só quando o jogador aterrissa com impacto vertical no raio de 1,45. Outros
alvos do grupo preservam a chamada `take_movement_hit`. O barril usa um
RigidBody3D restrito ao plano e uma Area3D para distinguir soco de dano.

O Guardião patrulha com três pontos de vida. Com dois, alterna antecipação,
salto e recuperação. Com um, troca o salto por uma investida. Cada salto ou
investida começa com 0,4 s de flash e pausa. O HUD recebe `health_changed`
e exibe a barra enquanto a luta está ativa. O rig de câmera enquadra a arena
durante a luta e aproxima o visual do Guardião na derrota.

A morte do jogador restaura vida, posição, ataque e materiais do Guardião
no mesmo nó. Ela também libera câmera, HUD e música para o retorno ao
checkpoint. A distância de ativação na trilha mantém o checkpoint fora do
alcance da luta. Na vitória, a animação e as partículas antecedem a criação
de `GuardianCrystal`. A câmera volta a seguir o jogador. Coletar o cristal
conclui a fase e dispara o jingle.

O canhão captura na entrada e lança com Pulo ou Ação. O cipó fornece uma
âncora móvel ao grupo `climb_pole`: segure cima para agarrar e Pulo para soltar.

A fase principal instancia `LookoutTrail.tscn` depois do mirante. A trilha
inclui o Casco de Pedra e tem um checkpoint após o vão. A última ilha contém
a arena do Guardião e sua recompensa.
