extends TesteBase
## 1 s de invencibilidade ao nascer / reviver / entrar na fase.
## godot --headless --debug --path . --script res://tests/heroi/teste_invencibilidade_ao_nascer.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 8:
		await process_frame
	main.tirar_criaturas()
	var jogador: Jogador = main.get_node("Jogador")
	var defesa: DefesaComponent = jogador.get_node("Defesa")
	_checar(jogador.esta_invencivel() and defesa.invulneravel,
		"ao começar a fase o herói nasce invencível")

	await create_timer(jogador.stats.tempo_invencibilidade + 0.15).timeout
	_checar(not jogador.esta_invencivel() and not defesa.invulneravel,
		"a invencibilidade do nascimento acaba em 1 s")

	var vida_antes := jogador.vida_atual()
	defesa.invulneravel = false
	var golpe := Golpe.new("Teste", 100, Dado.new(1, 1, 4), TiposDano.CONTUNDENTE)
	(jogador.get_node("Hurtbox") as HurtboxComponent).receber_golpe(
		golpe, jogador.global_position + Vector2.RIGHT * 20.0)
	await process_frame
	_checar(jogador.vida_atual() < vida_antes, "sem invencibilidade o golpe acerta")

	jogador.reviver()
	await process_frame
	_checar(jogador.esta_invencivel() and defesa.invulneravel,
		"Tentar de novo / reviver também dá 1 s de invencibilidade")
	var vida_cheia := jogador.vida_atual()
	(jogador.get_node("Hurtbox") as HurtboxComponent).receber_golpe(
		golpe, jogador.global_position + Vector2.RIGHT * 20.0)
	await process_frame
	_checar(jogador.vida_atual() == vida_cheia, "durante a proteção o golpe não tira vida")

	main._entrar_fase(load("res://levels/fase_2.tscn"), false)
	await process_frame
	_checar(jogador.esta_invencivel() and defesa.invulneravel,
		"entrar numa fase nova também protege 1 s")

	main.queue_free()
	await process_frame
	_terminar("invencibilidade ao nascer")
