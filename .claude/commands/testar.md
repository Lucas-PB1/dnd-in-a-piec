---
description: Roda todos os testes e o jogo headless (erros e avisos) e resume o resultado em português.
argument-hint: "[nome do teste, opcional: ex. goblin]"
---
Rode os testes do projeto e resuma.

1. Sem argumento: rode tudo (importa, roda o jogo 3 s procurando erros e avisos, roda todo `tests/**/teste_*.gd`):
   `powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tests\rodar_testes.ps1`
   Com argumento `$ARGUMENTS`: ache o arquivo sob `tests/` (ex.: `goblin` → `tests/criaturas/teste_goblin.gd`) e rode
   `& $env:GODOT_EDITOR_PATH --headless --debug --path C:\Jogos\rpg --script res://tests/<pasta>/teste_$ARGUMENTS.gd`
2. Responda em português, curto:
   - Resultado geral (TUDO OK ou FALHOU).
   - Cada `ERRO`, `ERROR` ou `WARNING`, com o arquivo e a linha quando houver. **Aviso também reprova.**
   - Para cada falha, a causa mais provável e onde olhar (não corrija sem o ok, a menos que o usuário tenha pedido).
3. Se um teste travar (ferramenta com erro rodada com `--debug` fica no depurador), pare o processo e avise.
