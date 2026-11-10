extends TesteBase
## Capacidade compartilhada de arremesso (`ArremessoDeCriatura`).
## O spawn no mundo fica nos testes do Goblin.
## godot --headless --debug --path . --script res://tests/criaturas/teste_arremesso_de_criatura.gd


func _initialize() -> void:
	_testar_municao_e_alcance()
	_testar_consumir()
	print("PASSOU: todos os testes do arremesso de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_municao_e_alcance() -> void:
	var sem := CriaturaRPG.new()
	sem.arremessos = 0
	_checar(not ArremessoDeCriatura.tem_arremesso(sem), "arremessos 0: sem arremesso")
	var ficha := CriaturaRPG.new()
	ficha.arremessos = 3
	ficha.arremesso_longo_pes = 60.0
	_checar(ArremessoDeCriatura.tem_arremesso(ficha), "arremessos 3: tem")
	var arremesso := ArremessoDeCriatura.new(ficha)
	_checar(arremesso.restantes() == 3 and arremesso.tem_arma(), "começa com 3")
	_checar(arremesso.no_alcance_longo(EscalaDnd.pes_para_pixels(60.0)), "no limite longo")
	_checar(not arremesso.no_alcance_longo(EscalaDnd.pes_para_pixels(61.0)), "além do longo")


func _testar_consumir() -> void:
	var ficha := CriaturaRPG.new()
	ficha.arremessos = 1
	var arremesso := ArremessoDeCriatura.new(ficha)
	_checar(arremesso.consumir() and not arremesso.tem_arma(), "gasta a única")
	_checar(not arremesso.consumir(), "sem arma: não consome")
