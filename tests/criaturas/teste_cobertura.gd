extends TesteBase
## Cobertura contra ataques à distância: a regra pura (`Abrigo`) e o Hobgoblin num mundo com um penhasco: quando o
## herói atira de cima, ele corre para o pé do penhasco (fora da linha de tiro), espera e volta; e não atira
## contra a parede.
## godot --headless --debug --path . --script res://tests/criaturas/teste_cobertura.gd

const CENA_HOBGOBLIN := "res://features/humanoides/hobgoblin_guerreiro.tscn"
const CHAO_Y := 300.0
const PLATAFORMA_Y := 220.0
const BORDA_X := 150.0
## Peito do herói na plataforma (de onde sai o tiro).
const ORIGEM := Vector2(40.0, 184.0)
const QUADROS_MAXIMOS := 300


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regra()
	await _testar_corre_para_o_abrigo()
	await _testar_fica_se_ja_protegido()
	await _testar_nao_atira_na_parede()
	print("PASSOU: todos os testes da cobertura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_regra() -> void:
	var protegido: Array[bool] = [false, false, true, true]
	var andavel: Array[bool] = [true, true, true, true]
	_checar(Abrigo.passos_ate_abrigo(protegido, andavel) == 2, "o 1º ponto protegido é o abrigo (índice 2)")
	andavel[1] = false
	_checar(Abrigo.passos_ate_abrigo(protegido, andavel) == -1, "um obstáculo no caminho impede de chegar ao abrigo")
	_checar(Abrigo.escolher_lado(3, 5, 1) == -1 and Abrigo.escolher_lado(5, 3, -1) == 1, "vai para o abrigo mais perto")
	_checar(Abrigo.escolher_lado(-1, 4, -1) == 1 and Abrigo.escolher_lado(-1, -1, 1) == 0, "um lado só, ou nenhum")
	_checar(Abrigo.escolher_lado(2, 2, -1) == -1, "empate: o lado oposto ao atirador")


func _montar(goblin_x: float, com_flechas: bool) -> Array:
	var mundo := Node2D.new()
	root.add_child(mundo)
	for bloco in [Vector3(-200, BORDA_X, PLATAFORMA_Y), Vector3(BORDA_X, 900, CHAO_Y)]:
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
	alvo.global_position = Vector2(ORIGEM.x, PLATAFORMA_Y)
	var ficha: CriaturaRPG = (load("res://data/hobgoblin_warrior.tres") as CriaturaRPG).duplicate()
	if not com_flechas:
		ficha.disparos = 0
	var goblin: Goblin = load(CENA_HOBGOBLIN).instantiate()
	goblin.criatura = ficha
	mundo.add_child(goblin)
	goblin.global_position = Vector2(goblin_x, CHAO_Y)
	goblin.definir_alvo(alvo)
	return [mundo, goblin]


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _testar_corre_para_o_abrigo() -> void:
	var m := _montar(300.0, false)
	var goblin: Goblin = m[1]
	await _esperar(5)
	goblin.perceber_disparo(ORIGEM)
	var cobriu := false
	for i in QUADROS_MAXIMOS:
		await physics_frame
		if goblin.nome_estado() == &"Cobrindo":
			cobriu = true
			if i > 40:
				break
	_checar(cobriu, "o herói atira de cima: o Hobgoblin entra em Cobrindo")
	_checar(goblin.protegido_do_disparo() and goblin.global_position.x < 300.0, "ele chegou a um ponto fora da linha de tiro (x=%d)" % goblin.global_position.x)
	await _esperar(QUADROS_MAXIMOS)
	_checar(goblin.nome_estado() != &"Cobrindo", "sem novos tiros, sai do abrigo e volta a perseguir (%s)" % goblin.nome_estado())
	m[0].queue_free()
	await physics_frame


func _testar_fica_se_ja_protegido() -> void:
	var m := _montar(BORDA_X + 8.0, false)
	var goblin: Goblin = m[1]
	await _esperar(5)
	var x_antes := goblin.global_position.x
	goblin.perceber_disparo(ORIGEM)
	await _esperar(30)
	_checar(goblin.nome_estado() == &"Cobrindo" and absf(goblin.global_position.x - x_antes) < 6.0,
		"já protegido pelo penhasco: fica onde está, em Cobrindo")
	m[0].queue_free()
	await physics_frame


func _testar_nao_atira_na_parede() -> void:
	var m := _montar(BORDA_X + 8.0, true)
	var protegido: Goblin = m[1]
	await _esperar(5)
	_checar(not protegido.pode_atirar(), "atrás do penhasco o arqueiro não atira na parede")
	var m2 := _montar(420.0, true)
	var exposto: Goblin = m2[1]
	await _esperar(5)
	_checar(exposto.pode_atirar(), "com a linha livre ele atira")
	m[0].queue_free()
	m2[0].queue_free()
	await physics_frame
