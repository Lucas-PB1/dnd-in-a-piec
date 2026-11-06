---
description: Checklist de fim de fatia - testes, docs do tema, histórico, pendências, checagem das skills e proposta de commit.
---
Feche a fatia atual seguindo o checklist. Faça cada passo e diga o resultado de cada um.

1. **Testes:** rode `tests/rodar_testes.ps1`. Tudo tem de passar, sem erros nem avisos. Se falhar, pare e mostre.
2. **Revisão:** confira os arquivos mudados (`git status --short`) contra as skills `godot-*` (use a skill `revisar-codigo` ou o agente `revisor-godot`). Corrija o que for simples; o resto, mostre.
3. **Decisões:** atualize o documento do tema em `docs/decisoes/` com o que foi decidido nesta fatia (e `docs/arquitetura.md` / `docs/receitas.md` se um sistema mudou).
4. **Histórico:** acrescente uma linha no fim de `docs/historico.md` e atualize "Estado atual" no `CLAUDE.md` (só as últimas fatias).
5. **Pendências:** tire de `docs/pendencias.md` o que ficou pronto; acrescente o que apareceu (provisório, dívida, ideia).
6. **Cursor:** se mudou alguma skill ou comando em `.claude/`, rode `tools/gerar_regras_cursor.ps1`.
7. **Créditos:** arte nova de terceiros está em `assets/CREDITOS.md`?
8. **Commit:** proponha a mensagem (português, uma linha de título + o que mudou) e **espere o ok**. Nunca force-push; não inclua arquivos de outra fatia sem avisar.
9. Termine com: (1) o que foi feito, (2) como testar, (3) próxima sugestão (veja `/proxima-fatia`), e a linha `Conforme as skills` ou as violações.
