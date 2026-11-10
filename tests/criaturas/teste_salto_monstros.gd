extends TesteBase
## Salto dos monstros: a regra pura (Força do livro, degrau, vão, queda) e o Hobgoblin saltando de verdade num
## mundo de blocos (subir um degrau, atravessar um buraco, descer atrás do alvo).
## godot --headless --debug --path . --script res://tests/teste_salto_monstros.gd

const CENA_HOBGOBLIN := "res://features/goblin/hobgoblin_guerreiro.tscn"
const LADRILHO := 32.0
const CHAO_Y := 300.0
const QUADROS_MAXIMOS := 360


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_capacidade()
	_testar_plano()
	await _testar_degrau()
	await _testar_vao()
	await _testar_descida()
	await _testar_muro_alto()
	await _testar_degrau_dos_outros()
	print("PASSOU: todos os testes do salto dos monstros" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_capacidade() -> void:
	_checar(is_equal_approx(SaltoDnd.distancia_px(15), 96.0), "salto em distância = Força em pés (15 pés = 96 px)")
	_checar(is_equal_approx(SaltoDnd.altura_px(15), EscalaDnd.pes_para_pixels(8.0)),
		"altura = 3 pés + mod. de Força (+2) + alcance dos braços (3 pés)")
	_checar(SaltoDnd.altura_px(8) >= LADRILHO and SaltoDnd.altura_px(7) < LADRILHO,
		"Força 8 (Goblin) sobe 1 ladrilho; Força 7 (Kobold) não")


func _testar_plano() -> void:
	var alto := SaltoDnd.altura_px(15)
	var longe := SaltoDnd.distancia_px(15)
	var sem := SaltoDnd.SEM_CHAO
	_checar(SaltoDnd.planejar([0.0, 0.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "chão plano: não salta")
	_checar(SaltoDnd.planejar([32.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.SUBIR, "degrau de 1 ladrilho: sobe")
	_checar(SaltoDnd.planejar([64.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "degrau alto demais: não sobe")
	_checar(SaltoDnd.planejar([SaltoDnd.MURO] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "muro ou teto baixo: não salta")
	var vao := SaltoDnd.planejar([sem, sem, 0.0] as Array[float], 8.0, 14.0, alto, longe, false)
	_checar(vao.tipo == SaltoDnd.Tipo.VAO and is_equal_approx(vao.distancia_px, 30.0), "buraco com chão do outro lado: salta o vão")
	var largo: Array[float] = []
	for i in 14:
		largo.append(sem)
	largo.append(0.0)
	_checar(SaltoDnd.planejar(largo, 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "vão maior que o salto em distância: não salta")
	_checar(SaltoDnd.planejar([sem, sem] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "buraco sem outro lado: não salta")
	_checar(SaltoDnd.planejar([-64.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "queda grande sem alvo embaixo: fica")
	_checar(SaltoDnd.planejar([-64.0] as Array[float], 8.0, 14.0, alto, longe, true).tipo == SaltoDnd.Tipo.DESCER, "queda grande com alvo embaixo: desce")
	_checar(SaltoDnd.planejar([-200.0] as Array[float], 8.0, 14.0, alto, longe, true).tipo == SaltoDnd.Tipo.NENHUM, "queda acima do limite seguro: não desce")


## Mundo de teste: blocos de chão (x inicial, x final, topo) e um alvo; devolve o Hobgoblin sem flechas.
func _montar_mundo(blocos: Array[Vector3], alvo_em: Vector2, goblin_em: Vector2) -> Array:
	var mundo := Node2D.new()
	root.add_child(mundo)
	for bloco in blocos:
		var corpo := StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(bloco.y - bloco.x, 400.0)
		forma.shape = retangulo
		corpo.add_child(forma)
		corpo.position = Vector2((bloco.x + bloco.y) / 2.0, bloco.z + 200.0)
		corpo.collision_layer = 1
		mundo.add_child(corpo)
	var alvo := Node2D.new()
	mundo.add_child(alvo)
	alvo.global_position = alvo_em
	var ficha: CriaturaRPG = (load("res://data/hobgoblin_warrior.tres") as CriaturaRPG).duplicate()
	ficha.disparos = 0
	var goblin: Goblin = load(CENA_HOBGOBLIN).instantiate()
	goblin.criatura = ficha
	mundo.add_child(goblin)
	goblin.global_position = goblin_em
	goblin.definir_alvo(alvo)
	return [mundo, goblin]


func _esperar_ate(condicao: Callable) -> bool:
	for i in QUADROS_MAXIMOS:
		await physics_frame
		if condicao.call():
			return true
	return false


func _testar_degrau() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y), Vector3(300, 700, CHAO_Y - LADRILHO)] as Array[Vector3],
		Vector2(480, CHAO_Y - LADRILHO), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 340.0)
	_checar(passou and absf(goblin.global_position.y - (CHAO_Y - LADRILHO)) < 4.0, "Hobgoblin sobe o degrau de 1 ladrilho atrás do alvo")
	m[0].queue_free()
	await physics_frame


func _testar_vao() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y), Vector3(350, 800, CHAO_Y)] as Array[Vector3],
		Vector2(520, CHAO_Y), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 400.0)
	_checar(passou and goblin.is_on_floor(), "Hobgoblin salta um buraco de 50 px (1,5 ladrilho) e continua")
	m[0].queue_free()
	await physics_frame


func _testar_descida() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y - 2 * LADRILHO), Vector3(300, 800, CHAO_Y)] as Array[Vector3],
		Vector2(520, CHAO_Y), Vector2(200, CHAO_Y - 2 * LADRILHO))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 400.0)
	_checar(passou and absf(goblin.global_position.y - CHAO_Y) < 4.0, "Hobgoblin desce 2 ladrilhos atrás de um alvo embaixo")
	m[0].queue_free()
	await physics_frame


func _testar_muro_alto() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y), Vector3(300, 700, CHAO_Y - 4 * LADRILHO)] as Array[Vector3],
		Vector2(480, CHAO_Y - 4 * LADRILHO), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 330.0)
	_checar(not passou, "muro de 4 ladrilhos: o Hobgoblin não consegue e fica no pé dele")
	m[0].queue_free()
	await physics_frame


## Os demais monstros também sobem um degrau de 1 ladrilho atrás do alvo (Gray Ooze, Minotauro e Wight; o Ankheg tem o seu em teste_ankheg).
func _testar_degrau_dos_outros() -> void:
	var cenas := {
		"Gray Ooze": "res://features/gray_ooze/gray_ooze.tscn",
		"Minotauro": "res://features/minotauro/minotauro.tscn", "Wight": "res://features/wight/wight.tscn",
	}
	for nome: String in cenas:
		var mundo := Node2D.new()
		root.add_child(mundo)
		for bloco in [Vector3(0, 300, CHAO_Y), Vector3(300, 800, CHAO_Y - LADRILHO)]:
			var corpo := StaticBody2D.new()
			var forma := CollisionShape2D.new()
			var retangulo := RectangleShape2D.new()
			retangulo.size = Vector2(bloco.y - bloco.x, 400.0)
			forma.shape = retangulo
			corpo.add_child(forma)
			corpo.position = Vector2((bloco.x + bloco.y) / 2.0, bloco.z + 200.0)
			corpo.collision_layer = 1
			mundo.add_child(corpo)
		var alvo := Node2D.new()
		mundo.add_child(alvo)
		alvo.global_position = Vector2(560, CHAO_Y - LADRILHO)
		var monstro: Node2D = load(cenas[nome]).instantiate()
		mundo.add_child(monstro)
		monstro.global_position = Vector2(200, CHAO_Y)
		monstro.call(&"definir_alvo", alvo)
		if "chance_atirar" in monstro:
			monstro.chance_atirar = 0.0  # o Wight atiraria de longe em vez de subir
		var passou := await _esperar_ate(func() -> bool: return monstro.global_position.x > 340.0)
		_checar(passou and absf(monstro.global_position.y - (CHAO_Y - LADRILHO)) < 4.0, "%s sobe o degrau de 1 ladrilho atrás do alvo" % nome)
		mundo.queue_free()
		await physics_frame
