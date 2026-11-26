# Skybound — Ilhas Perdidas

## Jogar

Abra `project.godot` no Godot 4.7.2, aguarde a importação e pressione **F6** na cena World_01_Level_01 ou **F5** a partir de qualquer cena. A primeira importação extrai os materiais do explorador e prepara os recursos locais. O jogo funciona offline.

Atravesse a primeira ponte, passe pelo cogumelo e suba os terraços. Depois do arco, siga os cristais dourados pelas ilhas e ruínas até a Ponte Celestial, ou explore as ilhas elevadas em busca de tesouros. Saia do Templo Celestial pela direita para atravessar o Prado Florido. Aterrisse sobre as caixas com estrela para revelar as recompensas. A fase termina no mirante, após o novo checkpoint. As chamas azuis marcam os checkpoints. A queda devolve o explorador ao último checkpoint ativado nesta partida. Os tesouros únicos, o recorde de cristais dourados, a conclusão e o perfil gráfico ficam em `user://skybound.cfg`.

| Ação | Teclado | Gamepad | Touch |
|---|---|---|---|
| Mover e acelerar | A/D ou ←/→ | Analógico esquerdo ou direcional | Setas da esquerda |
| Saltar | Espaço ou W | Botão inferior | ↑ |
| Salto duplo | Solte e pressione salto no ar | Segundo toque no botão inferior | Segundo toque em ↑ |
| Dash | X ou Shift | Botão esquerdo | ϟ |
| Pausa | Esc | Start | Ⅱ |
| Exibir ou ocultar controles virtuais no computador | T | | |

Soltar o salto cedo reduz a altura. Um salto sobre o cogumelo rende uma moeda. O menu de pausa permite reiniciar e alternar os perfis Baixo, Médio e Alto.

## Projeto

A cena abre com a geometria do cenário já posicionada e editável. O GLB do personagem, os módulos de ambiente e o retrato estão incluídos. Python serve apenas para reconstruir as malhas procedurais quando necessário.

- [Arquitetura](docs/ARCHITECTURE.md)
- [Direção artística e capturas](docs/ART_DIRECTION.md)
- [Inventário de assets](docs/ASSET_INVENTORY.md)
- [Configuração mobile](docs/MOBILE_OPTIMIZATION.md)
- [Testes e reprodução](docs/TEST_REPORT.md)
- [Pendências de produção](docs/PENDING_TASKS.md)

## Jogar no navegador

Abra [Skybound no GitHub Pages](https://mariomarques01.github.io/sky/) em um navegador com WebGL 2. No celular, vire a tela para a horizontal. O primeiro acesso baixa o jogo.

O workflow de Pages exporta a cena principal com o Godot 4.7.2 a cada push para main. Para reproduzir a publicação localmente, instale os templates dessa versão e execute os comandos abaixo. Acesse http://localhost:8000.

```sh
godot --headless --editor --import
mkdir -p build/web
godot --headless --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```
