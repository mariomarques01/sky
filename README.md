# Skybound — Ilhas Perdidas

## Jogar

Abra `project.godot` no Godot 4.7.2, aguarde a importação e pressione **F6** na cena World_01_Level_01 ou **F5** a partir de qualquer cena. A primeira importação extrai os materiais do explorador e prepara os recursos locais. O jogo funciona offline.

Atravesse a primeira ponte, passe pelo cogumelo e suba os terraços. Depois do arco, siga os cristais dourados pelas ilhas e ruínas até a Ponte Celestial, ou explore as ilhas elevadas em busca de tesouros. Saia do Templo Celestial pela direita para atravessar o Prado Florido. Aterrisse sobre as caixas com estrela para revelar as recompensas. A fase termina no mirante, após o novo checkpoint. As chamas azuis marcam os checkpoints. A queda devolve o explorador ao último checkpoint ativado nesta partida. Os tesouros únicos, o recorde de cristais dourados, a conclusão e o perfil gráfico ficam em `user://skybound.cfg`.

| Ação | Teclado | Gamepad | Touch |
|---|---|---|---|
| Mover e acelerar | A/D ou ←/→ | Analógico esquerdo ou direcional | Direcional virtual |
| Saltar | Espaço ou W | Botão inferior | ↑ |
| Salto duplo aéreo | Solte e pressione salto no ar | Segundo toque no botão inferior | Segundo toque em ↑ |
| Agachar ou deslizar durante a corrida | S ou ↓ | Direcional para baixo | Para baixo no direcional |
| Soco, chute aéreo ou mergulho | J | Botão superior | Botão Ação |
| Subir em poste | ↑ | Direcional para cima | Para cima no direcional |
| Dash | X ou Shift | Botão esquerdo | Deslize horizontalmente na metade inferior, fora dos botões |
| Pausa | Esc | Start | Ⅱ |
| Exibir ou ocultar controles virtuais no computador | T | | |

Soltar o salto cedo reduz a altura. Um salto sobre o cogumelo rende uma moeda. O menu de pausa permite reiniciar e alternar os perfis Baixo, Médio e Alto, ajustar tamanho e opacidade dos controles e inverter o lado do direcional. As preferências ficam salvas para a próxima partida.

Aperte salto logo após pousar em movimento para encadear o segundo salto. Corra e repita após o segundo pouso para o salto triplo. Agache e salte para saltar longe em movimento ou dar um mortal para trás parado. Inverta a direção durante a corrida e salte enquanto derrapa para o mortal lateral. Salte novamente ao tocar de frente uma parede no ar para quicar nela.

Pressione agachar no ar para preparar um impacto vertical. O botão de ataque no ar dá um chute em baixa velocidade ou um mergulho quando você está rápido. O mergulho termina em deslizada ao tocar o chão. Saltar nessa deslizada dá uma cambalhota. No chão, use o mesmo botão para encadear dois socos e um chute, ou mergulhe durante a corrida. Segure na direção de uma borda ao cair para agarrá-la e salte para subir. À esquerda do início há uma área com caixa quebrável, poste, trampolim, plataforma que cai, plataforma orbital e vento.

## Projeto

A cena abre com a geometria do cenário já posicionada e editável. O GLB do personagem, os módulos de ambiente e o retrato estão incluídos. Python serve apenas para reconstruir as malhas procedurais quando necessário.

- [Arquitetura](docs/ARCHITECTURE.md)
- [Direção artística e capturas](docs/ART_DIRECTION.md)
- [Inventário de assets](docs/ASSET_INVENTORY.md)
- [Configuração mobile](docs/MOBILE_OPTIMIZATION.md)
- [Testes e reprodução](docs/TEST_REPORT.md)
- [Pendências de produção](docs/PENDING_TASKS.md)

## Jogar no navegador

Abra [Skybound no GitHub Pages](https://mariomarques01.github.io/sky/) em um navegador com WebGL 2. Os controles virtuais aparecem ao abrir o jogo na Web. O navegador libera o áudio após o primeiro toque ou tecla. No iPhone, abra o jogo no Safari e use **Compartilhar → Adicionar à Tela de Início**. No Android, use **Instalar app** no menu do navegador. Abra pelo ícone para jogar usando toda a área disponível, em pé ou na horizontal.

Após o primeiro download, o jogo pode abrir offline. Com internet, ele verifica atualizações ao voltar para a tela, ao reconectar e a cada minuto. Quando o download da versão nova termina, o jogo recarrega automaticamente.

O workflow de Pages exporta a cena principal com o Godot 4.7.2 a cada push para main. Para reproduzir a publicação localmente, instale os templates dessa versão e execute os comandos abaixo. Acesse http://localhost:8000.

```sh
godot --headless --editor --import
mkdir -p build/web
godot --headless --export-release Web build/web/index.html
python3 web/package_pwa.py build/web "$(git rev-parse HEAD)"
python3 -m http.server 8000 --directory build/web
```
