# Relatório de validação

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
