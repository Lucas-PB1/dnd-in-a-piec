extends SceneTree
## Teste do Gray Ooze no jogo: percebe, persegue, ataca uma vez por rodada, machuca o herói,
## leva dano e morre. godot --headless --debug --path . --script res://tests/teste_gray_ooze.gd

## Mais que isso de distância e o Ooze não percebe (Visão às Cegas 60 pés = 384 px).
const LONGE := 500.0
const PERTO := 200.0
const AO_ALCANCE := 40.0

var _falhas := 0
var _jogador: Jogador
var _ooze: GrayOoze


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_ooze_sozinho()
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	_ooze = cena.get_node("GrayOoze")
	await _esperar(10)

	await _testar_percepcao_e_perseguicao()
	await _testar_ataques_contra_o_heroi()
	await _testar_morte_do_ooze()
	cena.queue_free()

	if _falhas == 0:
		print("PASSOU: todos os testes do Gray Ooze")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## A cena do Ooze roda sozinha (como no F6): sem alvo, fica parado.
func _testar_ooze_sozinho() -> void:
	var ooze: GrayOoze = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	root.add_child(ooze)
	await _esperar(10)
	_checar(ooze.nome_estado() == &"Parado" and ooze.vida_atual() == 22, "Ooze sozinho: parado, 22 PV")
	ooze.queue_free()
	await _esperar(1)


func _testar_percepcao_e_perseguicao() -> void:
	_colocar_heroi_a(LONGE)
	await _esperar(20)
	_checar(_ooze.nome_estado() == &"Parado", "herói longe (fora dos 60 pés): Ooze fica parado")
	_colocar_heroi_a(PERTO)
	var x_antes := _ooze.global_position.x
	await _esperar(60)
	_checar(_ooze.nome_estado() == &"Perseguindo", "herói a menos de 60 pés: Ooze persegue")
	var andou := x_antes - _ooze.global_position.x
	_checar(andou > 30.0 and andou < 55.0, "anda devagar na direção do herói (~43 px/s; andou %.0f px em 1 s)" % andou)


func _testar_ataques_contra_o_heroi() -> void:
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r))
	var vida_inicial := _jogador.vida_atual()
	_colocar_heroi_a(AO_ALCANCE)
	var viu_dano_no_heroi := false
	for i in 300:  # 5 s
		await physics_frame
		_jogador.posicionar_no_inicio(Vector2(_ooze.global_position.x - AO_ALCANCE, _jogador.global_position.y))
		viu_dano_no_heroi = viu_dano_no_heroi or _jogador.nome_estado() == &"LevandoDano"
	_checar(not resultados.is_empty(), "ao alcance, o Ooze ataca o herói com o Pseudópode")
	var esperado_max := ceili(5.0 / EscalaDnd.RODADA_SEGUNDOS) + 1
	_checar(resultados.size() <= esperado_max, "no máximo um ataque por rodada (%d em 5 s)" % resultados.size())
	var acertos := resultados.filter(func(r: Combate.Resultado) -> bool: return r.acertou)
	var coerentes := resultados.all(func(r: Combate.Resultado) -> bool:
		return r.acertou == (r.d20 == 20 or (r.d20 != 1 and r.d20 + 3 >= _jogador.ficha.classe_armadura())))
	_checar(coerentes, "Pseudópode: d20 + 3 contra a CA %d do herói" % _jogador.ficha.classe_armadura())
	if not acertos.is_empty():
		_checar(viu_dano_no_heroi, "acerto empurra o herói (estado LevandoDano)")
		var dano_ok := acertos.all(func(r: Combate.Resultado) -> bool: return r.dano >= 3 and r.dano <= 33)
		_checar(dano_ok, "dano do Pseudópode entre 3 e 33 (2d8+1, crítico 4d8+1)")
	_checar(_jogador.vida_atual() <= vida_inicial, "a vida do herói não sobe ao apanhar")
	_colocar_heroi_a(LONGE)
	await _esperar(30)


func _testar_morte_do_ooze() -> void:
	var morreu := [false]
	_ooze.morreu.connect(func() -> void: morreu[0] = true)
	var hurtbox: HurtboxComponent = _ooze.get_node("Hurtbox")
	var golpe_forte := Golpe.new("Teste", 100, Dado.new(1, 1, 50))
	for i in 5:
		hurtbox.receber_golpe(golpe_forte, _ooze.global_position + Vector2.LEFT)
		if _ooze.vida_atual() == 0:
			break
	_checar(_ooze.vida_atual() == 0 and _ooze.nome_estado() == &"Morrendo", "vida zerada: Ooze derrete (Morrendo)")
	for i in 120:
		if morreu[0]:
			break
		await physics_frame
	_checar(morreu[0], "depois da animação, o Ooze avisa que morreu e some")


func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_ooze.global_position.x - distancia, _jogador.global_position.y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
