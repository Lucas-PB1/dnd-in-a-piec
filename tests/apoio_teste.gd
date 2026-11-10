class_name TesteBase
extends SceneTree
## Base de todos os testes (`extends TesteBase`): conta as falhas e imprime "ok" ou "ERRO" por verificação, que é
## o formato que `rodar_testes.ps1` procura (este arquivo não começa com "teste_" de propósito: o runner roda todo teste_*.gd).
## Sempre termine com `_terminar("resumo")` (imprime PASSOU/FALHOU). Nunca só `quit(_falhas)`: o runner exige a linha PASSOU.

var _falhas: int = 0


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		print("  ERRO - ", descricao)
		_falhas += 1


## Imprime PASSOU ou FALHOU e encerra com código 0/1. Use no fim de todo teste.
func _terminar(resumo: String) -> void:
	if _falhas == 0:
		print("PASSOU: ", resumo)
	else:
		print("FALHOU: %d teste(s) — %s" % [_falhas, resumo])
	quit(1 if _falhas > 0 else 0)
