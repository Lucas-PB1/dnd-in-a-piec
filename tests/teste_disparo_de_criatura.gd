extends TesteBase
## Capacidade compartilhada de disparo e Sensibilidade à Luz Solar (`DisparoDeCriatura`).
## O spawn da flecha no mundo fica nos testes do Goblin Warrior / Wight.
## godot --headless --debug --path . --script res://tests/teste_disparo_de_criatura.gd


func _initialize() -> void:
	_testar_sol()
	_testar_municao_e_alcance()
	_testar_consumir_flecha()
	print("PASSOU: todos os testes do disparo de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_sol() -> void:
	var sensivel := CriaturaRPG.new()
	sensivel.sensivel_ao_sol = true
	_checar(DisparoDeCriatura.desvantagem_por_sol(sensivel, true), "sensível ao sol + dia = desvantagem")
	_checar(not DisparoDeCriatura.desvantagem_por_sol(sensivel, false), "sensível ao sol sem sol = sem desvantagem")
	var comum := CriaturaRPG.new()
	comum.sensivel_ao_sol = false
	_checar(not DisparoDeCriatura.desvantagem_por_sol(comum, true), "sem o traço: sol não importa")
	var disparo := DisparoDeCriatura.new(comum)
	disparo.luz_do_sol = true
	_checar(not disparo.desvantagem_solar(), "ficha sem o traço: desvantagem_solar falsa")
	var com_sol := DisparoDeCriatura.new(sensivel)
	com_sol.luz_do_sol = true
	_checar(com_sol.desvantagem_solar(), "com o traço e luz: desvantagem_solar")


func _testar_municao_e_alcance() -> void:
	var ficha := CriaturaRPG.new()
	ficha.disparos = 0
	_checar(not DisparoDeCriatura.tem_disparo(ficha), "disparos 0: sem disparo")
	ficha.disparos = -1
	ficha.disparo_longo_pes = 80.0
	_checar(DisparoDeCriatura.tem_disparo(ficha), "disparos -1: tem disparo (não acaba)")
	var infinito := DisparoDeCriatura.new(ficha)
	_checar(infinito.tem_flecha() and infinito.flechas_restantes() < 0, "munição infinita")
	_checar(infinito.no_alcance_longo(EscalaDnd.pes_para_pixels(80.0)), "no limite longo")
	_checar(not infinito.no_alcance_longo(EscalaDnd.pes_para_pixels(81.0)), "além do longo")
	ficha.disparos = 2
	var finito := DisparoDeCriatura.new(ficha)
	_checar(finito.flechas_restantes() == 2, "começa com 2 flechas")


func _testar_consumir_flecha() -> void:
	var finita := CriaturaRPG.new()
	finita.disparos = 1
	var disparo := DisparoDeCriatura.new(finita)
	_checar(disparo.consumir_flecha() and not disparo.tem_flecha(), "gasta a única flecha")
	_checar(not disparo.consumir_flecha(), "sem flecha: não consome")
	var infinita := CriaturaRPG.new()
	infinita.disparos = -1
	var sem_fim := DisparoDeCriatura.new(infinita)
	_checar(sem_fim.consumir_flecha() and sem_fim.tem_flecha() and sem_fim.flechas_restantes() < 0,
		"infinita: consome e continua tendo")
