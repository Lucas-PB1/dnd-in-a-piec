extends TesteBase
## Flanqueio (só manobra, sem vantagem): o lado do alvo e dois Hobgoblins no mundo: um já segura o herói e o outro,
## do mesmo lado, dá a volta e termina do lado oposto.
## godot --headless --debug --path . --script res://tests/teste_flanqueio.gd

const CENA_HOBGOBLIN := "res://features/goblin/hobgoblin_guerreiro.tscn"
const CHAO_Y := 300.0
const ALVO_X := 400.0
const QUADROS_MAXIMOS := 240


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regra()
	await _testar_da_a_volta()
	print("PASSOU: todos os testes do flanqueio" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_regra() -> void:
	_checar(Flanqueio.lado(100.0, 50.0) == -1 and Flanqueio.lado(100.0, 150.0) == 1, "lado esquerdo e direito do alvo")


func _montar() -> Array:
	var mundo := Node2D.new()
	root.add_child(mundo)
	var corpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(1600.0, 400.0)
	forma.shape = retangulo
	corpo.add_child(forma)
	corpo.position = Vector2(400.0, CHAO_Y + 200.0)
	corpo.collision_layer = 1
	mundo.add_child(corpo)
	var alvo := Node2D.new()
	mundo.add_child(alvo)
	alvo.global_position = Vector2(ALVO_X, CHAO_Y)
	var ficha: CriaturaRPG = (load("res://data/hobgoblin_warrior.tres") as CriaturaRPG).duplicate()
	ficha.disparos = 0
	var monstros: Array[Goblin] = []
	for x in [ALVO_X - 20.0, ALVO_X - 150.0]:
		var goblin: Goblin = load(CENA_HOBGOBLIN).instantiate()
		goblin.criatura = ficha
		mundo.add_child(goblin)
		goblin.add_to_group(&"monstros")
		goblin.global_position = Vector2(x, CHAO_Y)
		goblin.definir_alvo(alvo)
		monstros.append(goblin)
	return [mundo, monstros]


func _testar_da_a_volta() -> void:
	var m := _montar()
	var monstros: Array[Goblin] = m[1]
	var flanqueador := monstros[1]
	var flanqueou := false
	for i in QUADROS_MAXIMOS:
		await physics_frame
		flanqueou = flanqueou or flanqueador.nome_estado() == &"Flanqueando"
	_checar(flanqueou, "um aliado segura o herói pela esquerda: o outro entra em Flanqueando")
	_checar(flanqueador.global_position.x > ALVO_X, "ele terminou do outro lado do herói (x=%d)" % flanqueador.global_position.x)
	m[0].queue_free()
	await physics_frame
