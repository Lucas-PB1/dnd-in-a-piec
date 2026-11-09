class_name TesteBase
extends SceneTree
## Base de todos os testes (`extends TesteBase`): conta as falhas e imprime "ok" ou "ERRO" por verificação, que é
## o formato que `rodar_testes.ps1` procura (este arquivo não começa com "teste_" de propósito: o runner roda todo teste_*.gd). O teste termina com `quit(_falhas)`.

var _falhas: int = 0


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		print("  ERRO - ", descricao)
		_falhas += 1
