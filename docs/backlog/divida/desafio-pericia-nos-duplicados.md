---
title: DesafioPericia — nós duplicados na fase
size: P
priority: 5
area: divida
---

# DesafioPericia — nós duplicados na fase

## Falta
- No editor, ao abrir a Clareira: aviso “incoming node conflicts with DesafioPericia/Visual|Bloqueio|Area|Aviso…”.
- Causa: `tools/gerar_fase_teste.gd` `_adicionar` marca `owner = fase` em todos os filhos da instância de `desafio_pericia.tscn`; o `pack` grava esses nós de novo em `levels/fase_1.tscn`.
- Corrigir: em instâncias de PackedScene, só o nó raiz recebe `owner`; regenerar a fase 1 (`gerar_fase_teste.gd -- 1`).

## Pronto quando
- Aviso some ao abrir a fase no editor.
- `teste_desafio_pericia` passa.
