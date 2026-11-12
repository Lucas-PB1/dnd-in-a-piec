extends TesteBase
## Capacidade compartilhada de Táticas de Matilha (`MatilhaDeCriatura`).
## Regra pura e mundo: também `teste_minions_novos`.
## godot --headless --debug --path . --script res://tests/criaturas/teste_matilha_de_criatura.gd


func _initialize() -> void:
	_testar_ficha()
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_vale_com_aliado()
	print("PASSOU: todos os testes da matilha de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var sem := CriaturaRPG.new()
	_checar(not MatilhaDeCriatura.tem_matilha(sem), "sem traço")
	var hob: CriaturaRPG = load("res://data/hobgoblin_warrior.tres")
	_checar(MatilhaDeCriatura.tem_matilha(hob) and MatilhaDeCriatura.new(hob).tem(), "Hobgoblin tem matilha")
	var minion: CriaturaRPG = load("res://data/goblin_minion.tres")
	_checar(not MatilhaDeCriatura.tem_matilha(minion), "Minion sem matilha")


func _testar_vale_com_aliado() -> void:
	var mundo := Node2D.new()
	root.add_child(mundo)
	var alvo := Node2D.new()
	mundo.add_child(alvo)
	alvo.global_position = Vector2(100, 0)
	var ficha: CriaturaRPG = (load("res://data/kobold_warrior.tres") as CriaturaRPG).duplicate()
	var atacante: Goblin = load("res://features/humanoides/kobold_guerreiro.tscn").instantiate()
	atacante.criatura = ficha
	mundo.add_child(atacante)
	atacante.add_to_group(&"monstros")
	atacante.global_position = Vector2(0, 0)
	atacante.definir_alvo(alvo)
	var matilha := MatilhaDeCriatura.new(ficha)
	_checar(not matilha.vale(alvo, mundo.get_tree(), atacante), "sozinho: sem matilha")
	## Aliado de outra feature (Ooze) no grupo: a capacidade não depende de ser Goblin.
	var aliado: GrayOoze = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	mundo.add_child(aliado)
	aliado.add_to_group(&"monstros")
	aliado.global_position = Vector2(120, 0)
	aliado.definir_alvo(alvo)
	await physics_frame
	_checar(matilha.vale(alvo, mundo.get_tree(), atacante), "Ooze a 20 px do alvo: matilha vale")
	mundo.queue_free()
	await physics_frame
