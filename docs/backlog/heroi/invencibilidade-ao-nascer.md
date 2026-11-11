---
title: 1 s de invencibilidade ao nascer
size: P
priority: 16
area: heroi
---

# 1 s de invencibilidade ao nascer

## Falta
- Ao spawnar / entrar na fase / “Tentar de novo”, o herói fica **1 s invulnerável** (mesmo mecanismo de `DefesaComponent.invulneravel` pós-acerto).
- Evita morte instantânea se nascer em cima de golpe ou lava.

## Pronto quando
- Nascer ou reaparecer com 1 s sem levar dano; teste cobre o caso.
