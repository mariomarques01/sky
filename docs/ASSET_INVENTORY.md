# Inventário

O repositório remoto consultado não anunciou refs Git. O workspace inicial continha as três referências JPEG e o GLB anexado. A primeira imagem orientou a composição, a segunda orientou a modularidade e a terceira forneceu o recorte circular do HUD.

| Item auditado | Conteúdo |
|---|---|
| Personagem | Meshy_AI_The_Brave_Bunny_Explorer_20261109_animated_mixamo_All_animation.glb importado como `assets/models/Bunny.glb` com pesos de skinning revisados nas mãos, no quadril e nas pernas |
| Geometria | Mesh_0, uma primitiva indexada, 71.393 vértices e 127.420 triângulos |
| Material | Material_0 com três imagens JPEG embutidas de 2048 × 2048, extraídas pelo importador Godot |
| Esqueleto | SmartRigArmature, 32 juntas com skinning |
| Dimensões locais | Aproximadamente 0,683 × 1,700 × 0,566 unidades. Base em Y=0, eixo vertical +Y. O visual gira em torno de Y para alinhar a frente ao deslocamento lateral |
| Animações presentes | Walking e Running |
| Sons | Efeitos, jingle e trilhas originais sintetizados em WAV com `procedural/bake_audio.py` |

`procedural/bake.py` recria os módulos com a seed 1739, usando somente a biblioteca padrão do Python. Execute `python3 procedural/bake.py` na raiz e reimporte. Cada GLB resultante reúne as superfícies do módulo em uma malha e pode ser instanciado em outra fase.

Meadow e Horizon fornecem ilhas, rocha, cobertura e trepadeiras. Bridge contém tábuas, postes, amarrações e cordas. Maple, Blossoms e Rosette fornecem árvore, flores e folhas dobradas. Pillar, Arch e Pennant compõem as ruínas. Crate, Barrel e Sign compõem a partida. Sunstone, Coin e Aether usam silhuetas próprias. Sporeling combina chapéu, pintas, olhos e pés. A queda e as nuvens usam QuadMesh com shaders específicos. Os sólidos físicos simples ficam invisíveis.
