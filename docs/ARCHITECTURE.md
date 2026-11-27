# Arquitetura

A cena em `worlds/world_01/level_01/` contém os terrenos, os vãos da ponte, os triggers, o inimigo, as ruínas e a câmera. Cada prop GLB é uma PackedScene independente. A composição de Background fica atrás do plano de movimento e dispensa física. O mundo aplica materiais compartilhados e instala os efeitos ambientais na inicialização.

`player/player.tscn` compõe CharacterBody3D, colisão, máquina de estados, saúde, dash e visual com esqueleto. O controlador amostra ações por tick físico, aplica aceleração, gravidade, tolerância de borda e fila de salto, resolve o movimento com move_and_slide e seleciona o estado. A velocidade em Z é zero e o corpo retorna ao plano central. O estado emite entered quando muda. Dash controla duração, recarga e disponibilidade aérea. Health controla a janela de imunidade. As propriedades exportadas desses nós ajustam o comportamento no Inspector.

A câmera suaviza posição e antecipação e recebe o sinal `impact` para deslocamento transitório.

Cada coletável é uma Area3D com bloqueio de coleta dupla. O GameManager contabiliza por tipo e emite changed ou finished. O HUD escuta esses sinais. O patrulheiro usa limites e um RayCast3D apontado para o piso. A diferença entre os pés do jogador e o centro do inimigo, junto à velocidade vertical, caracteriza o impacto por cima.

Quatro autoloads concentram o estado da partida, persistência ConfigFile, síntese e reprodução de sons e reinício de cena. O checkpoint dura uma tentativa da fase. Reiniciar restaura inimigos, coletas e vida. A interface e o menu usam processamento durante pausa, com liberação das ações de toque ao abrir o menu.

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
especializam o deslocamento e o contato da patrulha do cogumelo. O impacto
vertical também atinge espinhos próximos pelo sinal `ground_pound`. O barril
usa um RigidBody3D restrito ao plano e uma Area3D para distinguir soco de dano.
O chefe sinaliza a vida ao HUD ao entrar em combate e após cada acerto.

O canhão captura na entrada e lança com Pulo ou Ação. O cipó fornece uma
âncora móvel ao grupo `climb_pole`: segure cima para agarrar e Pulo para soltar.

A fase principal instancia `LookoutTrail.tscn` depois do mirante. A trilha
reúne os seis elementos, tem um checkpoint após o vão e termina na última ilha.
