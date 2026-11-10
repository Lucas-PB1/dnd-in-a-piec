---
description: Adiciona uma criatura do livro (D&D 2024) seguindo a receita 1 de docs/how-to/receitas.md, com o molde do Goblin.
argument-hint: "<nome da criatura, ex.: Kobold>"
---
Adicione a criatura **$ARGUMENTS** ao jogo.

1. Leia `docs/how-to/receitas.md` (receita 1), `docs/adr/criaturas.md` e `docs/reference/arquitetura.md` (seção Criaturas). Carregue as skills `godot-*`.
2. **Ficha:** peça ao usuário o bloco de estatísticas do livro (print ou texto) se ele não mandou. Não invente números.
3. **Decisões de jogo** (pergunte com 3 opções, a recomendada primeiro): como a criatura luta (ataques, distância, fuga) e qualquer habilidade que não caiba no jogo como está.
4. **Arte:** siga `docs/reference/artes_prontas.md` (CC0/CC-BY, **peça permissão para baixar** dizendo arquivo, fonte e tamanho; crédito em `assets/CREDITOS.md`). SpriteCook só com o custo avisado.
5. Faça a receita 1 inteira: ficha em `data/`, gerador de SpriteFrames em `tools/`, script raiz, estados, cena (roda sozinha no F6), lista do Trazer em `levels/main.gd`, teste `tests/teste_<criatura>.gd` e o teste da lista em `tests/teste_segundo_folego.gd`.
6. **Regra de três:** se já existirem 2 criaturas com código repetido (Ooze e Goblin), proponha extrair a base comum ANTES de copiar de novo.
7. Feche com `/fechar-fatia`.
