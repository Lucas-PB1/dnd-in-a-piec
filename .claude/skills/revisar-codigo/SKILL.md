---
name: revisar-codigo
description: Revisa os scripts GDScript e cenas do projeto (ou só os arquivos mudados) contra as regras de Clean Code, SOLID e DRY da skill codigo-limpo-godot e propõe melhorias. Use quando o usuário pedir revisão, refatoração, "deixar o código limpo", ou antes de fechar uma fatia.
---

# Revisar código (Clean Code, SOLID, DRY)

1. **Carregue as regras:** leia `.claude/skills/codigo-limpo-godot/SKILL.md`.
2. **Escolha o alvo:**
   - Sem argumento: arquivos mudados desde o último commit (`git diff --name-only HEAD` + `git status --short`), só `.gd` e `.tscn`.
   - Com argumento (`tudo`, uma pasta ou um arquivo): esse alvo.
3. **Leia cada arquivo inteiro** e anote, por arquivo:
   - Clean Code: nomes ruins, funções longas ou com várias responsabilidades, números mágicos, falta de tipagem, comentários óbvios ou código morto.
   - SOLID: script fazendo mais de um trabalho, `get_parent()` encadeado ou caminho fixo para nós de fora, filho chamando o pai em vez de sinal, `match`/`if` gigante que cresce a cada tipo novo.
   - DRY: a mesma lógica ou os mesmos números em 3+ lugares (procure com Grep no projeto todo).
   - Excesso de engenharia: abstração que só tem um uso e não simplifica nada.
4. **Relatório ao usuário, em português, curto:**
   - Uma tabela `Arquivo | Problema | Regra | Sugestão`, do mais importante para o menos.
   - No máximo 8 itens; agrupe os parecidos.
   - Diga o que está **bom** também (1 a 3 linhas).
5. **Não aplique mudanças sem o "ok"** do usuário, a menos que ele já tenha pedido para corrigir.
6. Ao aplicar: uma mudança por vez, rode os testes de `tests/` e o jogo headless depois de cada grupo, e confira que não surgiram erros nem avisos.
