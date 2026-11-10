extends TesteBase
## Descanso curto (fase sem chefe) vs longo (chefe / morte).
## godot --headless --debug --path . --script res://tests/heroi/teste_descanso.gd

const CENA_MAIN := "res://levels/main.tscn"


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regras_no_heroi()
	await _testar_fase_e_morte()
	_terminar("descansos curto e longo")


func _testar_regras_no_heroi() -> void:
	var heroi: Jogador = load("res://features/jogador/jogador.tscn").instantiate()
	root.add_child(heroi)
	await process_frame
	var vida: HealthComponent = heroi.get_node("Vida")
	vida.receber_dano(5)
	vida.reduzir_maximo(3)
	heroi.usar_folego()
	var pv_ferido := heroi.vida_atual()
	var max_ferido := heroi.vida_maxima()
	_checar(heroi.usos_folego() < heroi.usos_folego_total(), "gastou Fôlego antes do curto")

	heroi.descansar_curto()
	_checar(heroi.usos_folego() == heroi.usos_folego_total(), "curto devolve Fôlego")
	_checar(heroi.acao_bonus_livre(), "curto libera ação bônus")
	_checar(heroi.vida_atual() == pv_ferido, "curto não enche PV")
	_checar(heroi.vida_maxima() == max_ferido and vida.maximo_drenado == 3, "curto não tira drenar")

	heroi.descansar_longo()
	_checar(heroi.vida_atual() == heroi.vida_maxima() and vida.maximo_drenado == 0,
		"longo enche PV e restaura o máximo")
	heroi.queue_free()
	await process_frame


func _testar_fase_e_morte() -> void:
	var main: Node = load(CENA_MAIN).instantiate()
	root.add_child(main)
	await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	main._entrar_fase(load("res://levels/fase_1.tscn"), true)
	await physics_frame
	jogador.get_node("Vida").receber_dano(4)
	jogador.usar_folego()
	main._surto_usado = true

	main._entrar_fase(load("res://levels/fase_2.tscn"), false)
	await physics_frame
	_checar(not main._surto_usado and jogador.usos_folego() == jogador.usos_folego_total(),
		"sair de fase sem chefe = curto: Surto e Fôlego voltam")
	_checar(jogador.vida_atual() < jogador.vida_maxima(), "curto na porta não enche PV")

	jogador.get_node("Vida").receber_dano(2)
	main._entrar_fase(load("res://levels/fase_4.tscn"), true)
	await physics_frame
	_checar(jogador.vida_atual() == jogador.vida_maxima(), "sair de chefe = longo: PV cheio")

	main._surto_usado = true
	jogador.get_node("Vida").receber_dano(8)
	var tela: TelaDerrota = load("res://ui/derrota/tela_derrota.tscn").instantiate()
	main.get_node("Interface").add_child(tela)
	main._tentar_de_novo(tela)
	await physics_frame
	_checar(not main._surto_usado and jogador.vida_atual() == jogador.vida_maxima(),
		"morrer = longo: Surto e PV de volta")
	main.queue_free()
	await process_frame
