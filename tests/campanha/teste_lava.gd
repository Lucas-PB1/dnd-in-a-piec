extends TesteBase
## Lava do Covil: 1d6 de fogo por rodada enquanto o herói está em cima; resistência vale; fase 10 tem poças.
## godot --headless --debug --path . --script res://tests/campanha/teste_lava.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regra_ambiente()
	await _testar_poca()
	await _testar_fase_10()
	print("PASSOU: lava do Covil" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_regra_ambiente() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var golpe := Golpe.new("Lava", 0, Dado.de_texto("1d6"), TiposDano.FOGO)
	var r := Combate.resolver_ambiente(golpe, rng)
	_checar(r.acertou and r.dano >= 1 and r.dano <= 6, "ambiente aplica 1d6 sem ataque")
	rng.seed = 1
	var resistido := Combate.resolver_ambiente(golpe, rng, [TiposDano.FOGO])
	_checar(resistido.resistido and resistido.dano == TiposDano.aplicar_resistencia(r.dano),
		"resistência a fogo reduz a lava pela metade")
	var imune := Combate.resolver_ambiente(golpe, rng, [], [TiposDano.FOGO])
	_checar(imune.dano == 0, "imunidade a fogo zera a lava")


func _testar_poca() -> void:
	var mundo := Node2D.new()
	root.add_child(mundo)
	var lava: Lava = load("res://features/lava/lava.tscn").instantiate()
	lava.configurar(2)
	mundo.add_child(lava)
	lava.position = Vector2(0, 100)
	var heroi := _corpo_com_defesa(20)
	mundo.add_child(heroi)
	heroi.global_position = Vector2(20, 80)
	for i in 5:
		await physics_frame
	var vida: HealthComponent = heroi.get_node("Vida")
	var depois_entrar := vida.vida_atual
	_checar(depois_entrar < 20, "entrar na lava causa dano na hora")
	lava.aplicar_tique()
	_checar(vida.vida_atual < depois_entrar, "ficar na lava causa outro 1d6 na rodada")
	mundo.queue_free()
	await physics_frame


func _testar_fase_10() -> void:
	var fase: Fase = load("res://levels/fase_10.tscn").instantiate()
	root.add_child(fase)
	await process_frame
	var lavas := 0
	for filho in fase.get_children():
		if filho is Lava:
			lavas += 1
	_checar(lavas >= 2, "o Covil tem pelo menos 2 poças de lava")
	fase.queue_free()
	await process_frame


func _corpo_com_defesa(vida_max: int) -> CharacterBody2D:
	var corpo := CharacterBody2D.new()
	corpo.collision_layer = 2
	corpo.collision_mask = 1
	var colisao := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(20, 40)
	colisao.shape = ret
	colisao.position = Vector2(0, -20)
	corpo.add_child(colisao)
	var vida := HealthComponent.new()
	vida.name = "Vida"
	vida.vida_maxima = vida_max
	vida.vida_atual = vida_max
	corpo.add_child(vida)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 8
	corpo.add_child(hurtbox)
	var defesa := DefesaComponent.new()
	defesa.name = "Defesa"
	defesa.hurtbox = hurtbox
	defesa.vida = vida
	corpo.add_child(defesa)
	return corpo
