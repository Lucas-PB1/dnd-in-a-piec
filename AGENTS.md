# AGENTS.md

Instruções para agentes de IA neste repositório (jogo original de ação e plataforma 2D lateral em Godot 4.7, GDScript).

**A fonte da verdade é o [CLAUDE.md](CLAUDE.md).** Leia-o inteiro antes de qualquer mudança: visão do jogo, decisões, convenções, como rodar e testar.

Resumo das regras que não podem ser quebradas:
- Responda em português; termine com (1) o que foi feito, (2) como testar, (3) próxima sugestão.
- Uma fatia pequena por vez; não comece a próxima sem o "ok" do usuário.
- `snake_case` em arquivos e funções, `PascalCase` em classes e nós, comentários em português.
- Leia os `SKILL.md` de `.claude/skills/godot-*` relevantes antes de qualquer mudança de código e siga-os. No Cursor elas já estão em `.cursor/rules/` (geradas por `tools/gerar_regras_cursor.ps1`; edite a skill, não o `.mdc`). Ao terminar, diga em 1 linha se está "Conforme as skills" ou quais regras violou e por quê.
- Rode o jogo headless e os testes de `tests/` antes de entregar; corrija erros e avisos.
- Um commit por fatia, em português. Nunca apague arquivos do usuário nem faça force-push.
- Sem addons ou arquitetura nova sem aprovação. SpriteCook gasta créditos: avise antes.
- Arte de terceiros: siga `docs/artes_prontas.md`.
- Se uma decisão mudar, atualize o `CLAUDE.md`.
