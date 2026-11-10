<!-- Gerado de .claude/commands/proxima-fatia.md por tools/gerar_regras_cursor.ps1. Edite a fonte, nÃ£o este arquivo. -->
# Propõe a próxima fatia do jogo com 3 opções, a partir de docs/backlog/, sem começar nada.

Proponha a próxima fatia de trabalho. **Não escreva código nesta etapa.**

1. Leia `docs/backlog/README.md` e os `.md` do backlog em `docs/backlog/**/` (YAML: `title`, `size`, `priority`, `area`; pasta = `area`). Ignore `_modelo.md`. Leia o fim de `docs/CHANGELOG.md`.
2. Se houver mudanças sem commit (`git status --short`), diga isso primeiro: o ideal é fechar a fatia anterior (`/fechar-fatia`) antes.
3. Escolha **3 opções** que façam sentido agora (menor `priority` primeiro como recomendada), cada uma com:
   - o que o jogador vai ver de diferente;
   - tamanho (P/M/G) e arquivos/pastas (use `docs/reference/arquitetura.md` e `docs/how-to/receitas.md`);
   - o que precisa decidir ou instalar antes (créditos do SpriteCook, download de arte, ferramentas).
4. Pergunte qual seguir (com as 3 opções como escolha). Só comece depois do "ok".
