# Relatório de validação

## Áudio e resposta ao impacto

O autoload de áudio usa oito vozes de efeitos e um player dedicado à música. A faixa original de Jardins Celestiais começa com uma introdução de 4,8 segundos e repete o trecho até 24 segundos. Os arquivos WAV podem ser regenerados com `procedural/bake_audio.py`.

O teste de partida verifica o pool, os buses, a reprodução simultânea e a configuração do loop. Dois stomps medem a pausa de três ciclos de física a 60 Hz e comparam o ápice com o botão de pulo solto e segurado. O teste também verifica a emissão de poeira no pouso e na derrapagem.

## Revisão dos saltos e das caixas

A Travessia das Ilhas tem vãos de até 2,11 unidades entre bordas, incluindo os extremos da plataforma móvel. A rota elevada ainda permite usar o Dash. No início da fase, a plataforma que cai foi afastada do poste de escalada, e a plataforma orbital tem um curso menor perto dela. O teste sai do poste com um salto e confirma que a contagem da queda começa após a aterrissagem.

Os testes verificam o contato por cima, a emissão e a remoção dos estilhaços, a coleta das recompensas e a derrota das patrulhas. A primeira caixa surpresa fica em terreno livre. Uma sentinela guarda a caixa de cristal e duas patrulhas ficam nos lados da caixa do coração.

## Prado Florido

A continuação acrescenta cerca de 35 unidades de percurso horizontal entre o templo e o novo ponto de conclusão. Os três módulos de chão têm colisões sobrepostas nas junções, e as rampas ligam os dois terraços ao caminho principal.

- `tests/expansion.tscn` percorre o templo e o prado com as ações do jogador. Verifica o impacto lateral, a quebra das quatro caixas por cima, moeda, cristal, coração, a subida opcional, o checkpoint, o respawn e a nova conclusão.
- Caixas abertas continuam abertas após um respawn e voltam numa nova partida. As regras de gravação dos tesouros únicos continuam cobertas pelo teste.
- As cenas `route` e `playthrough` passaram no Godot 4.7.2, assim como a exportação com o preset Web. A composição foi inspecionada no Chromium com WebGL 2. O desempenho em celulares físicos não foi medido.

## Expansão dos Jardins Celestiais antes do Prado Florido

Validada no Godot 4.7.2 com as cenas `tests/route.tscn`, `tests/playthrough.tscn` e `tests/expansion.tscn` a 60 Hz. Cada cena usa uma pasta de dados temporária no workflow do GitHub Pages.

- O percurso original chega ao arco com a coleta azul e continua na mesma cena. Os testes de regressão cobrem movimentação, salto duplo, Dash, dano, pausa, ponte original e multitouch.
- O teste da expansão usa as ações do jogador entre os pontos de partida das duas rotas. Na travessia principal, o maior vão entre bordas é de 2,41 unidades incluindo os extremos da plataforma móvel. O salto simples a 6,6 unidades/s cobre cerca de 4,3 unidades com elevação de 0,62. Os saltos também foram percorridos com a aceleração real, partindo das áreas de pouso.
- A rota opcional inclui sete pousos, uso do Dash no vão após a plataforma móvel, recuperação de um ponto de vida, abertura do baú e retorno à ponte. Foram validados a passagem nas ruínas, o alcance vertical da câmera, a conclusão no templo e a recuperação após quedas.
- O teste recarrega a gravação do disco e reinstancia a fase para confirmar que o cristal raro, o cristal épico e o baú não reaparecem. A conclusão continua disponível em uma nova partida.
- O preset Web produziu HTML, WASM e PCK e abriu no Chromium com WebGL 2 em modo Compatibility. Foram inspecionados os setores em viewport horizontal e verificado o toque simultâneo de movimento e salto no Chromium emulado. O desempenho e a latência do toque em aparelhos físicos não foram medidos.

## Validação do mapa original

Os resultados abaixo registram a versão anterior à expansão.

Ambiente Linux x86_64, Godot 4.7.2.stable. A cena principal foi executada em modo headless e renderizada no backend Forward Mobile com Vulkan 1.4.305 e Mesa llvmpipe. As imagens em inicio.png, ponte.png e arco.png são capturas do viewport. A janela de captura mede 960 × 540, com área lógica base de 1920 × 1080.

## Reprodução

Execute na raiz com Godot 4.7.2 disponível no PATH.

```sh
godot --headless --editor --import
godot --headless tests/playthrough.tscn
godot --headless tests/route.tscn
godot tests/captures.tscn
```

O teste de percurso usa as ações normais desde o spawn até o arco. Terminou com três vidas, cinco cristais dourados, três moedas e um cristal azul. O teste de mecânicas reposiciona o personagem em situações específicas para isolar cada comportamento. Os testes gravam preferências e recordes na pasta de dados local da aplicação. No Linux, definir XDG_DATA_HOME para uma pasta temporária isola esses dados.

| Verificação executada | Resultado observado |
|---|---|
| Importação e carregamento | Cópia em diretório separado, cache reconstruído, cena principal carregada |
| Integridade do protagonista | SHA-256 do GLB do projeto idêntico ao do anexo |
| Locomoção | Spawn no chão, aceleração até corrida, salto, salto duplo e velocidade de dash aéreo |
| Multitouch | Dois eventos ScreenTouch enviados ao viewport, ações de direita e salto ativas simultaneamente e liberadas ao levantar os dedos |
| Ponte | Atravessada com movimento lateral contínuo. Um ressalto na junção final foi corrigido e o percurso repetido |
| Coletáveis | Area3D incrementou o contador e o cristal azul concluiu a fase |
| Checkpoint | Cruzamento registrou a segunda ilha. Queda no abismo levou o jogador de volta com vida restaurada |
| Inimigo | Dano lateral, janela de imunidade e derrota por impacto com recompensa |
| Menu e gráficos | Pausa e retomada do SceneTree, troca e gravação do perfil |
| Controles | InputMap lido pela engine para teclas físicas, direcional, analógico, botões de ação e Start |
| Apresentação | Capturas horizontais da partida, ponte e ruínas. O personagem ocupa aproximadamente um quinto da altura na partida |

O teste contínuo e as 17 verificações do teste de mecânicas passaram. A execução em tempo real terminou sem erro de script ou runtime. Em execução acelerada com --fixed-fps, o driver Dummy pode emitir um aviso de liberação de AudioStreamPlaybackWAV ao encerrar imediatamente após um efeito. A execução em tempo real foi usada para o resultado final.

Faltam medições em GPUs móveis, testes com gamepad e tela sensível ao toque físicos, pacotes assinados e validação das áreas seguras nos dois sistemas. A renderização por software permite inspecionar composição e shaders, mas não fornece um benchmark de telefone.
