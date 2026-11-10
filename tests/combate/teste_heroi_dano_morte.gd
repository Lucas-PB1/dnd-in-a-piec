extends TesteBase
## Dano e morte do herói: ao apanhar toca a animação "dano"; ao morrer toca a "morte" (sem arma na
## mão) e só depois a tela "Você caiu!" abre; reviver volta tudo ao normal.
## godot --headless --debug --path . --script res://tests/combate/teste_heroi_dano_morte.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 6:
		await process_frame
	main.tirar_criaturas()
	var jogador: Jogador = main.get_node("Jogador")
	var sprite: AnimacaoJogador = jogador.get_node("Sprite")
	var frames := sprite.sprite_frames
	_checar(frames.has_animation(&"dano") and frames.get_frame_count(&"dano") == 8, "o herói tem a animação de dano (8 quadros)")
	_checar(frames.has_animation(&"morte") and frames.get_frame_count(&"morte") == 12, "o herói tem a animação de morte (12 quadros)")
	var golpe := Golpe.new("Teste", 100, Dado.new(1, 1, 0), TiposDano.CONTUNDENTE)
	jogador.get_node("Defesa").invulneravel = false
	var hurtbox: HurtboxComponent = jogador.get_node("Hurtbox")
	hurtbox.receber_golpe(golpe, jogador.global_position + Vector2.RIGHT * 20.0)
	# Sob carga paralela o quadro pode atrasar: espera até a animação "dano" ou esgota o tempo curto.
	var viu_dano := false
	for i in 12:
		await physics_frame
		if sprite.animation == &"dano":
			viu_dano = true
			break
	_checar(viu_dano, "ao apanhar, toca a animação de dano (%s)" % sprite.animation)
	await create_timer(0.6).timeout
	_checar(sprite.animation != &"dano" or not sprite.is_playing(), "o dano termina e o herói volta ao normal")
	# Morte
	jogador.get_node("Defesa").invulneravel = false
	var vida: HealthComponent = jogador.get_node("Vida")
	vida.receber_dano(vida.vida_atual)
	await create_timer(0.4).timeout
	_checar(sprite.animation == &"morte", "ao morrer, toca a animação de morte (%s)" % sprite.animation)
	_checar(not (jogador.get_node("Ataque") as Node2D).visible, "a arma some enquanto ele morre")
	_checar(main.get_node("Interface").find_child("TelaDerrota", true, false) == null, "a tela Você caiu ainda não abriu")
	await create_timer(Jogador.DURACAO_MORTE).timeout
	_checar(main.get_node("Interface").find_child("TelaDerrota", true, false) != null and paused, "depois da animação, abre a tela Você caiu")
	jogador.reviver()
	await process_frame
	_checar((jogador.get_node("Ataque") as Node2D).visible and not sprite.morrendo, "reviver traz a arma e a animação normal de volta")
	main.free()
	await process_frame
	_terminar("dano e morte do herói")
