# Android e iOS

O projeto usa o renderizador Mobile, área lógica 1920 × 1080, orientação horizontal e expansão para outras proporções. A interface converte a área segura do dispositivo em coordenadas do viewport. Cada dedo pode manter uma ação independente e deslizar para outra. O jogo usa uma luz direcional. As ilhas distantes possuem malhas menores, sem colisões, e a importação de cenas gera LODs quando a geometria permite.

| Perfil | Escala interna | Sombra direcional | Custo ambiental |
|---|---:|---|---|
| Baixo | 65% | Desligada | Água simples, sem névoa de partículas da queda, sem motas e camada adicional de nuvens |
| Médio | 82% | Até 18 unidades | Água completa e camadas de nuvens |
| Alto | 100% | Até 35 unidades | Detalhe ambiental completo |

As flores são distribuídas em quatro MultiMeshes com alcance de visibilidade de 33 unidades. A ponte separa as colisões do balanço visual. O personagem preserva a malha original e as texturas usam compressão de VRAM e mipmaps. O frustum culling da engine opera sobre as instâncias. O cenário aberto oferece pouca oclusão estável. O pequeno número de coletas únicas permite liberar o efeito de cada coleta ao terminar.

Os presets de exportação incluem Android ARM64 e iOS. Para gerar um pacote, instale os templates correspondentes à versão do Godot. Android requer SDK/JDK configurados. A distribuição iOS requer macOS, Xcode, equipe de desenvolvimento e assinatura. A medição de 60 FPS requer aparelhos físicos e deve incluir aquecimento, resolução nativa, memória de texturas e o custo de overdraw das nuvens.
