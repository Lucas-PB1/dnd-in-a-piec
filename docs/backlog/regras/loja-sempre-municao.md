---
title: Loja — sempre pelo menos 1 munição
size: P
priority: 11
area: regras
---

# Loja — sempre pelo menos 1 munição

## Falta
- Em `Loja.sortear_estoque`, o estoque de 7 itens deve incluir **sempre ≥ 1** item de `data/municoes/`.
- Pode sair na mesma fatia de código que `loja-renovar-estoque` se for conveniente.

## Pronto quando
- Nenhuma visita à loja sai sem pelo menos um tipo de munição; coberto por teste.
