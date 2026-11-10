extends TesteBase
## Teste do Gray Ooze no jogo: percebe, persegue, ataca uma vez por rodada, machuca o herói,
## leva dano e morre. godot --headless --debug --path . --script res://tests/criaturas/teste_gray_ooze.gd

## Mais que isso de distância e o Ooze não percebe (Visão às Cegas 60 pés = 384 px).
const LONGE := 500.0
const PERTO := 200.0
const AO_ALCANCE := 40.0
const VIDA_DE_TESTE := 999
## Acertos com dano na espada para conferir a Corrosão.
const ACERTOS_CORROSAO := 2

var _jogador: Jogador
var _ooze: GrayOoze


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_ooze_sozinho()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	cena.semente_armadilhas = 1
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	cena.tirar_criaturas()
	_ooze = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	_ooze.add_to_group(&"monstros")
	cena.add_child(_ooze)
	_ooze.global_position = Vector2(720, 288)
	_ooze.definir_alvo(_jogador)
	await _esperar(10)

	await _testar_percepcao_e_perseguicao()
	await _testar_ataques_contra_o_heroi()
	await _testar_corrosao_da_espada()
	await _testar_morte_do_ooze()
	await _testar_voce_caiu(cena)
	cena.queue_free()
	await _testar_porta()

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
	# Só neste teste: muita vida, para o herói não cair (cair pausa o jogo com "Você caiu!").
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	var vida_inicial := _jogador.vida_atual()
	_colocar_heroi_a(AO_ALCANCE)
	var viu_dano_no_heroi := false
	for i in 300:  # 5 s
		await physics_frame
		_jogador.posicionar_no_inicio(Vector2(_ooze.global_position.x - AO_ALCANCE, _jogador.global_position.y))
		viu_dano_no_heroi = viu_dano_no_heroi or _jogador.nome_estado() == &"LevandoDano"
	_checar(not resultados.is_empty(), "ao alcance, o Ooze ataca o herói com o Pseudópode")
	var esperado_max := ceili(5.0 / EscalaDnd.intervalo_ataque(_ooze.criatura.iniciativa)) + 1
	_checar(resultados.size() <= esperado_max, "ritmo da iniciativa -2: no máximo 1 ataque a cada 1,2 s (%d em 5 s)" % resultados.size())
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


## Forma Corrosiva: cada golpe da espada que causa dano no Ooze dá -1 no ataque da espada.
## Usa um Ooze à parte (longe) para não matar o da fase.
func _testar_corrosao_da_espada() -> void:
	var alvo: GrayOoze = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	alvo.position = Vector2(5000, 0)
	root.add_child(alvo)
	await _esperar(2)
	var espada := _jogador.inventario.itens[0] as Arma
	_jogador.inventario.equipar(espada)
	var danos := [0]
	(alvo.get_node("Defesa") as DefesaComponent).golpe_resolvido.connect(
		func(r: Combate.Resultado, _o: Vector2) -> void:
			if r.dano > 0:
				danos[0] += 1)
	var hurtbox: HurtboxComponent = alvo.get_node("Hurtbox")
	for i in 20:  # repete até ter acertos com dano suficientes (errar é possível)
		if danos[0] >= ACERTOS_CORROSAO:
			break
		hurtbox.receber_golpe(_jogador.criar_golpe(), alvo.global_position + Vector2.LEFT)
	_checar(danos[0] == ACERTOS_CORROSAO and _jogador.inventario.penalidade(espada) == ACERTOS_CORROSAO,
		"cada acerto com dano corrói a espada em -1 (%d acertos -> -%d)" % [danos[0], _jogador.inventario.penalidade(espada)])
	var golpe := _jogador.criar_golpe()
	_checar(golpe.bonus_ataque == _jogador.ficha.bonus_ataque(espada) - danos[0], "o ataque da espada cai com o desgaste")
	var antes := _jogador.inventario.penalidade(espada)
	var soco := Golpe.new("Soco", 100, Dado.new(1, 1, 3))  # não é arma: não sofre Corrosão
	hurtbox.receber_golpe(soco, alvo.global_position + Vector2.LEFT)
	_checar(_jogador.inventario.penalidade(espada) == antes, "soco (não corroível) não desgasta nada")
	alvo.queue_free()
	await _esperar(1)


## Herói com vida zerada: "Você caiu!" pausa; "Tentar de novo" revive e traz o Ooze de volta.
func _testar_voce_caiu(cena: Node) -> void:
	_jogador.configurar_ficha(_jogador.ficha)  # volta à vida normal da ficha
	var golpe_fatal := Golpe.new("Fatal", 100, Dado.new(1, 1, 99), TiposDano.ACIDO)
	var hurtbox: HurtboxComponent = _jogador.get_node("Hurtbox")
	for i in 5:
		if _jogador.vida_atual() == 0:
			break
		(_jogador.get_node("Defesa") as DefesaComponent).invulneravel = false
		hurtbox.receber_golpe(golpe_fatal, _jogador.global_position + Vector2.RIGHT)
	await create_timer(Jogador.DURACAO_MORTE + 0.3).timeout  # a animação de morte toca antes da tela
	var tela: TelaDerrota = null
	for filho in cena.get_node("Interface").get_children():
		if filho is TelaDerrota:
			tela = filho
	_checar(tela != null and paused, "vida zerou: aparece 'Você caiu!' e o jogo pausa")
	if tela == null:
		return
	tela.tentar_de_novo_escolhido.emit()
	await process_frame
	await physics_frame
	var monstros := get_nodes_in_group(&"monstros")
	_checar(not paused and _jogador.vida_atual() == _jogador.vida_maxima(), "Tentar de novo: despausa com a vida cheia")
	_checar(monstros.size() == 1, "Tentar de novo recria a cota da fase, sem o Ooze colocado no teste")


## Com a cota viva a porta não muda de fase. Cumprida, abre a seguinte.
func _testar_porta() -> void:
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	cena.semente_armadilhas = 1
	root.add_child(cena)
	var jogador: Jogador = cena.get_node("Jogador")
	var fase: Fase = cena.get_node("Fase")
	await _esperar(5)
	_checar(get_nodes_in_group(&"monstros").size() == fase.quantidade,
		"a clareira nasce a cota dela")
	jogador.global_position = fase.posicao_porta()
	await _esperar(5)
	_checar((cena.get_node("Fase") as Fase).indice == 1, "com a cota viva, a porta não troca de fase")
	for monstro in get_nodes_in_group(&"monstros"):
		(monstro.get_node("Vida") as HealthComponent).receber_dano(999)
	for i in 180:
		await physics_frame
		if get_nodes_in_group(&"monstros").is_empty():
			break
	await _esperar(5)
	_checar((cena.get_node("Fase") as Fase).indice == 2, "cota cumprida em cima da porta: abre a fase 2")
	cena.queue_free()


func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_ooze.global_position.x - distancia, _jogador.global_position.y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
