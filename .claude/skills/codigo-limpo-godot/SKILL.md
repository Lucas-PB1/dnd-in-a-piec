---
name: codigo-limpo-godot
description: Regras de Clean Code, SOLID e DRY aplicadas a GDScript/Godot 4 neste projeto. Use SEMPRE antes de escrever, mudar ou refatorar qualquer arquivo .gd, .tscn ou recurso do jogo, e ao planejar uma fatia nova.
---

# Código limpo em Godot (Clean Code + SOLID + DRY)

Objetivo: código que o usuário consegue **ler, ajustar e reaproveitar**. Simples primeiro; abstração só quando ela se paga.

## 1. Clean Code

**Nomes**
- Nomes em português que dizem a intenção: `velocidade_corrida`, `_contador_coyote`, `reaparecer()`. Nada de `v`, `tmp`, `dados2`.
- Funções são verbos (`aplicar_gravidade()`), booleanos são perguntas (`esta_correndo()`, `no_chao`).
- `snake_case` para arquivos, funções e variáveis; `PascalCase` para `class_name` e nós; `CONSTANTE_MAIUSCULA` para `const`.
- Prefixo `_` em tudo que é privado do script (variáveis e funções internas).

**Funções pequenas**
- Cada função faz **uma coisa**. Se precisa de um comentário "agora faz X" no meio, isso vira outra função.
- `_physics_process` é um **roteiro** que chama passos com nome: `_aplicar_gravidade(delta)`, `_tentar_pular()`, `_mover_horizontal(delta)`.
- Alvo: até ~25 linhas por função. Retorno antecipado (`if not alvo: return`) em vez de `if` aninhado.

**Sem números mágicos**
- Valor que alguém pode querer ajustar → `@export` com comentário `##` explicando o efeito e a unidade (px, s, px/s).
- Valor fixo da regra → `const` com nome.
- Agrupe exports com `@export_group("...")`.

**Tipagem**
- Sempre tipar: `var vida: int = 3`, `func dano(qtd: int) -> void:`. Use `:=` quando o tipo é óbvio.
- Referências a nós com `@onready var sprite: AnimatedSprite2D = $Sprite`.

**Comentários**
- Comente o **porquê**, não o óbvio. `## doc` em cima de exports, sinais e funções públicas (aparece no editor).
- Código morto é apagado (o git guarda o histórico).

## 2. SOLID, do jeito Godot

| Princípio | Em Godot significa | Exemplo no projeto |
|---|---|---|
| **S**: responsabilidade única | Um script = um trabalho. Física, visual, entrada e UI em scripts separados. | `jogador.gd` move; `animacao_jogador.gd` escolhe a animação. |
| **O**: aberto/fechado | Adicione comportamento com **nós, cenas ou Resources novos**, sem editar um `match` gigante. | Inimigo novo = cena nova que herda/instancia componentes. |
| **L**: substituição de Liskov | Subclasse honra o contrato da base: mesmos sinais, mesmas funções públicas, sem surpresas. | Todo `Inimigo` tem `receber_dano(qtd)` e emite `morreu`. |
| **I**: interfaces enxutas | Contratos pequenos: um sinal ou um método específico (`receber_dano`), use `has_method()` ou grupos. Nada de "deus" com 30 funções públicas. | Projétil só chama `receber_dano` em quem tem. |
| **D**: inversão de dependência | **"Chame para baixo, sinalize para cima."** Pai chama métodos dos filhos; filho avisa o pai por **sinal**. Filho não procura o avô com `get_parent().get_parent()`. Dependências via `@export` ou injeção, não por caminho fixo. | `Jogador` emite `aterrissou`; a animação se conecta. |

Autoload (singleton) só para o que é realmente global (ex.: save, áudio). Não use autoload como atalho para evitar sinais.

## 3. DRY (não se repita) com bom senso

- **Regra de três:** repetiu a mesma lógica pela 3ª vez → extraia. Na 2ª, só anote. Abstração cedo demais é pior que repetição.
- Onde colocar o código compartilhado:
  - **Classe utilitária** (`class_name X extends RefCounted`) para lógica sem nó (ex.: `ToqueDuplo`).
  - **Componente** (cena/nó reutilizável) para comportamento que vários objetos têm (vida, hitbox, piscar ao levar dano).
  - **Resource** (`.tres`) para **dados** compartilhados (stats de inimigo, armas), editáveis no Inspector.
  - **Cena herdada** para variações de um mesmo objeto.
- Os mesmos números em dois lugares → um só lugar (`const` ou `@export`) e o resto lê de lá.
- Ferramentas repetitivas (gerar arte, fase, prints) viram script em `scripts/ferramentas/`.

## 4. Organização de arquivos

- `scripts/` scripts de cena; `scripts/componentes/` componentes reutilizáveis; `scripts/utilitarios/` classes sem nó; `scripts/ferramentas/` linha de comando.
- Uma cena por "coisa" (`jogador.tscn`, `inimigo_x.tscn`), pequena e testável sozinha.

## 5. Checklist antes de entregar

1. Cada função faz uma coisa e tem nome claro?
2. Nenhum número mágico; ajustes estão em `@export` com `##`?
3. Tudo tipado?
4. Cada script tem uma responsabilidade? Algum ficou grande demais (> ~150 linhas)?
5. Comunicação filho→pai por sinal; sem `get_parent()` encadeado?
6. Tem lógica repetida 3x? Extraiu para utilitário/componente/Resource?
7. Abstração nova se paga **agora**? (Se não, desfaça: simples > esperto.)
8. Testes em `tests/` cobrem o comportamento novo e passam headless?
9. O jogo roda sem erros **e sem avisos** no log?
10. `CLAUDE.md` atualizado se uma decisão mudou?

Para revisar um código já escrito com este checklist, use a skill `revisar-codigo`.
