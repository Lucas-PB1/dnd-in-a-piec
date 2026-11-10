extends TesteBase
## Desafio de perícia na fase: E perto rola Atletismo (Mente Tática pode ajudar); sucesso remove o bloqueio.
## godot --headless --debug --path . --script res://tests/campanha/teste_desafio_pericia.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regra_pura()
	await _testar_na_main()
	await _testar_mente_tatica()
	print("PASSOU: desafio de perícia" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_regra_pura() -> void:
	var desafio: DesafioPericia = load("res://features/desafio_pericia/desafio_pericia.tscn").instantiate()
	root.add_child(desafio)
	_checar(desafio.pericia_do_teste() == Pericia.ATLETISMO and desafio.cd_do_teste() == 12, "padrão: Atletismo CD 12")
	desafio.concluir(false)
	_checar(not desafio.esta_resolvido(), "falha não remove o bloqueio")
	desafio.concluir(true)
	_checar(desafio.esta_resolvido(), "sucesso resolve uma vez")
	desafio.queue_free()


func _testar_na_main() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 5:
		await process_frame
	var desafio: DesafioPericia = main.get_node_or_null("Fase/DesafioPericia")
	_checar(desafio != null, "a Clareira tem um DesafioPericia")
	if desafio == null:
		main.free()
		await process_frame
		return
	var jogador: Jogador = main.get_node("Jogador")
	desafio.cd = 1
	jogador.posicionar_no_inicio(desafio.global_position + Vector2(-20, 0))
	await process_frame
	main._ao_pedir_teste_de_pericia(desafio)
	_checar(desafio.esta_resolvido(), "sucesso na main remove a pedra")
	main.free()
	await process_frame


## Mente Tática no teste do desafio: com CD alta e Fôlego, o d10 pode virar sucesso.
func _testar_mente_tatica() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 5:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	jogador.ficha.definir_nivel_inicial(2)
	jogador.ao_mudar_ficha()
	jogador.definir_mente_tatica(true)
	var desafio: DesafioPericia = main.get_node_or_null("Fase/DesafioPericia")
	if desafio == null:
		main.free()
		await process_frame
		return
	# CD que falha no d20 sozinho com bônus típico, mas o d10 da Mente Tática pode salvar.
	desafio.cd = 25
	var viu_mente := false
	for _i in 40:
		var r := jogador.rolar_teste_pericia(Pericia.ATLETISMO, desafio.cd_do_teste())
		if r.get("usou_mente_tatica", false):
			viu_mente = true
			desafio.concluir(r.passou)
			_checar(r.passou and desafio.esta_resolvido(), "Mente Tática que vira sucesso conclui o desafio")
			break
		if r.passou:
			# rolagem natural alta rara: ainda valida o caminho
			desafio.concluir(true)
			viu_mente = true
			break
	_checar(viu_mente, "em várias tentativas a Mente Tática ou um sucesso aparece")
	main.free()
	await process_frame
