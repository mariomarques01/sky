# Arquitetura

A cena em `worlds/world_01/level_01/` contém os terrenos, os vãos da ponte, os triggers, o inimigo, as ruínas e a câmera. Cada prop GLB é uma PackedScene independente. A composição de Background fica atrás do plano de movimento e dispensa física. O mundo aplica materiais compartilhados e instala os efeitos ambientais na inicialização.

`player/player.tscn` compõe CharacterBody3D, colisão, máquina de estados, saúde, dash e visual com esqueleto. O controlador amostra ações por tick físico, aplica aceleração, gravidade, tolerância de borda e fila de salto, resolve o movimento com move_and_slide e seleciona o estado. A velocidade em Z é zero e o corpo retorna ao plano central. O estado emite entered quando muda. Dash controla duração, recarga e disponibilidade aérea. Health controla a janela de imunidade. As propriedades exportadas desses nós ajustam o comportamento no Inspector.

O AnimationTree do visual usa uma AnimationNodeStateMachine com Walking e Running e transições de 140 ms. Os demais estados usam a pose disponível com tempo congelado, inclinação de dash, intermitência por dano ou redução de escala na morte. Respawn restaura escala, velocidade e vida. A câmera suaviza posição e antecipação e recebe o sinal impact para deslocamento transitório.

Cada coletável é uma Area3D com bloqueio de coleta dupla. O GameManager contabiliza por tipo e emite changed ou finished. O HUD escuta esses sinais. O patrulheiro usa limites e um RayCast3D apontado para o piso. A diferença entre os pés do jogador e o centro do inimigo, junto à velocidade vertical, caracteriza o impacto por cima.

Quatro autoloads concentram o estado da partida, persistência ConfigFile, síntese e reprodução de sons e reinício de cena. O checkpoint dura uma tentativa da fase. Reiniciar restaura inimigos, coletas e vida. A interface e o menu usam processamento durante pausa, com liberação das ações de toque ao abrir o menu.

### Animação do explorador

O controlador passa a pose, velocidades e o tempo restante de pouso ao Visual.
A deformação, o rastro e o arco de morte afetam apenas a apresentação.
Em player/player.tscn, abra Visual/AnimationTree e troque Walking no nó
Idle, Jump, Fall, Land, Dash, Hurt ou Death pelo clipe dedicado da biblioteca
do Explorer. Walking marca uma pose procedural provisória. Landing usa Land.
A árvore avança no passo de física apenas para clipes dedicados. Walk e Run
continuam sincronizados com a distância e os golpes e acrobacias conservam suas poses.
