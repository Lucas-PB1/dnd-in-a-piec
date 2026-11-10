extends TesteBase
## Capacidade compartilhada de tática (`TaticaDeCriatura`): timers e decisões.
## Integração no mundo: `teste_cobertura`, `teste_flanqueio`, `teste_estrategia`.
## godot --headless --debug --path . --script res://tests/criaturas/teste_tatica_de_criatura.gd


func _initialize() -> void:
	_testar_preferencia_e_timers()
	_testar_flanqueio_puro()
	_testar_afastar_ferido()
	print("PASSOU: todos os testes da tática de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_preferencia_e_timers() -> void:
	var ficha: CriaturaRPG = load("res://data/hobgoblin_warrior.tres")
	var tatica := TaticaDeCriatura.new(ficha)
	_checar(tatica.prefere_distancia, "Hobgoblin: prefere distância")
	_checar(tatica.tempo_sem_disparo() == INF, "sem tiro ainda")
	tatica.perceber_disparo(Vector2(10, 0))
	_checar(is_equal_approx(tatica.tempo_sem_disparo(), 0.0), "tiro zera o timer")
	tatica.passar_tempo(1.5)
	_checar(is_equal_approx(tatica.tempo_sem_disparo(), 1.5), "passar_tempo avança")
	var ooze: CriaturaRPG = load("res://data/gray_ooze.tres")
	_checar(not TaticaDeCriatura.new(ooze).prefere_distancia, "Ooze: não prefere distância")


func _testar_flanqueio_puro() -> void:
	var ficha := CriaturaRPG.new()
	var tatica := TaticaDeCriatura.new(ficha)
	var engajados: Array[float] = [90.0]
	_checar(tatica.quer_flanquear(100.0, 50.0, 50.0, false, true, 10, 10, 32.0, 10.0, engajados),
		"aliado no mesmo lado engajado: flanqueia")
	_checar(tatica.x_do_flanco() > 100.0, "flanco fica do lado oposto")
	_checar(not tatica.quer_flanquear(100.0, 50.0, 50.0, false, true, 10, 10, 32.0, 10.0, engajados),
		"intervalo de flanco impede de repetir na hora")


func _testar_afastar_ferido() -> void:
	var ficha := CriaturaRPG.new()
	var tatica := TaticaDeCriatura.new(ficha)
	_checar(tatica.quer_afastar(true, 3, 10, 1, true, false, false, false), "ferido com aliado: afasta")
	_checar(tatica.motivo_afastar() == TaticaDeCriatura.MOTIVO_FERIDO, "motivo ferido")
	_checar(not tatica.quer_afastar(true, 3, 10, 1, true, false, false, false), "só uma vez por vida")
