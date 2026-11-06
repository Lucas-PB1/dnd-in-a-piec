---
name: godot-componentes-e-dados
description: Composição com nós-componentes (HealthComponent, HitboxComponent, MovementComponent...), valores de balanceamento em Resources .tres e regras complexas em classes RefCounted testáveis. Use ao criar entidades (jogador, inimigos, objetos), ao definir números de jogo e ao escrever regras de combate, inventário ou progressão.
---

# Componentes e dados

## Composição em vez de herança
- Entidades são montadas com **nós-componentes**, cada um com um trabalho só:
  `HealthComponent` (vida, dano, morte), `HitboxComponent` (causa dano), `HurtboxComponent` (recebe dano), `MovementComponent`, `FlashComponent` (pisca ao levar dano) etc.
- Componente genérico (usado por 2+ features) fica em `core/componentes/`; específico fica na feature.
- Componente expõe funções e **sinais**; não conhece a entidade concreta (não faz `as Jogador`).
- Herança só para variações reais do **mesmo** objeto (cena herdada), nunca para compartilhar código entre coisas diferentes.

## Dados em Resources
- Valores de balanceamento (vida, dano, velocidade, altura do pulo, tempos) ficam em **Resources customizados** (`class_name StatsJogador extends Resource` com `@export`), salvos em `data/*.tres`.
- O script **só lê** o Resource (`@export var stats: StatsJogador`). Não altera o `.tres` em tempo de jogo; estado que muda (vida atual) fica no componente.
- Um `.tres` por configuração (ex.: `data/jogador_padrao.tres`, `data/inimigo_andarilho.tres`).

## Regras em classes puras
- Regras com lógica de verdade (cálculo de dano, inventário, progressão, detecção de toque duplo) vão em `class_name X extends RefCounted`, **sem nós e sem `Input`**: recebem dados, devolvem resultado.
- O nó só traduz: lê input/física, chama a regra, aplica o resultado.
- Toda classe pura tem teste em `tests/` rodando headless.

## Não exagere
- Só crie componente/Resource/classe quando houver uso **agora**. Um número usado num lugar só pode ficar no Resource da entidade; não crie um Resource por número.
