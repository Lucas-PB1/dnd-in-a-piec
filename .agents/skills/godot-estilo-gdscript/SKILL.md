---
name: godot-estilo-gdscript
description: Estilo de GDScript do projeto - tipagem estática, class_name, snake_case/PascalCase, comentários em português, funções curtas, sem números mágicos, DRY com regra de três, autoload só com justificativa e nada de abstração por precaução. Use SEMPRE que escrever ou alterar qualquer arquivo .gd.
---

# Estilo de GDScript

## Tipagem e nomes
- **Tipagem estática sempre:** `var vida: int = 3`, `func receber_dano(qtd: int) -> void:`; `:=` quando o tipo é óbvio.
- `class_name` em scripts que outros usam por tipo (componentes, estados, Resources, classes puras). Scripts de uso único não precisam.
- `snake_case` em arquivos, funções e variáveis; `PascalCase` em classes e nós; `CONSTANTE` em `const`; `_privado` com sublinhado.
- Nomes em português que dizem a intenção. Funções são verbos; booleanos são perguntas (`esta_correndo()`).

## Funções e números
- Funções curtas (alvo: até ~25 linhas), uma coisa por função, retorno antecipado em vez de `if` aninhado.
- **Sem números mágicos:** valor ajustável → `@export` (com `##` dizendo efeito e unidade) ou campo do Resource de dados; valor fixo da regra → `const` com nome.
- `@onready var x: Tipo = $No` para nós.

## Comentários
- Em português. Explique o **porquê**, não o óbvio. `##` em cima de exports, sinais e funções públicas.
- Código morto é apagado (o git guarda).

## DRY e simplicidade
- **Regra de três:** a mesma lógica pela 3ª vez → extraia (classe pura, componente ou Resource). Na 2ª, só anote.
- **Nada de abstração "por precaução":** só crie camada, classe ou componente com necessidade real e **presente**.

## Autoload
- Só para o que é realmente global (event bus, save, áudio).
- **Antes de criar um autoload, explique ao usuário o motivo e espere o ok.**

## Antes de entregar
- Rode `tests/rodar_testes.ps1`: testes passando, jogo sem erros **e sem avisos**.
- Faça a checagem contra as skills usadas (ver AGENTS.md).
