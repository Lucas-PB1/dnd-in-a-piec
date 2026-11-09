extends TesteBase
## Second Wind, troca de tecla e criatura trazida para a arena.
## godot --headless --path . --script res://tests/teste_segundo_folego.gd

const ARQUIVO_TESTE := "user://teste_comandos.cfg"
const QUADROS_ACAO_BONUS := 100

var _principal: Main
var _jogador: Jogador


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_cura()
	_principal = load("res://levels/main.tscn").instantiate()
	_principal.mostrar_inicio = false
	_principal.semente_armadilhas = 1
	root.add_child(_principal)
	_jogador = _principal.get_node("Jogador")
	await _esperar(10)

	await _testar_folego()
	_testar_teclas()
	await _testar_criatura()

	if _falhas == 0:
		print("PASSOU: fôlego, comandos e criatura")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_cura() -> void:
	var dado := Dado.de_texto(ClasseRPG.DADO_SEGUNDO_FOLEGO)
	_checar(dado != null and dado.minimo() == 2 and dado.maximo() == 11, "cura do livro vai de 2 a 11")
	var classe := load("res://data/classe_guerreiro.tres") as ClasseRPG
	_checar(classe.usos_segundo_folego == 2, "guerreiro tem 2 usos por luta")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		var cura := classe.cura_do_folego(rng)
		if cura < dado.minimo() or cura > dado.maximo():
			_checar(false, "rolagem %d fora de 2 a 11" % cura)
			return
	_checar(true, "30 rolagens ficaram entre 2 e 11")
	var menor_nivel_2 := 12
	var maior_nivel_2 := 2
	for i in 30:
		var cura_nivel_2 := classe.cura_do_folego(rng, 2)
		menor_nivel_2 = mini(menor_nivel_2, cura_nivel_2)
		maior_nivel_2 = maxi(maior_nivel_2, cura_nivel_2)
	_checar(menor_nivel_2 >= 3 and maior_nivel_2 <= 12, "Second Wind no nível 2 cura 1d10+2")

	var vida := HealthComponent.new()
	vida.configurar(10)
	vida.receber_dano(4)
	_checar(vida.curar(3) == 3 and vida.vida_atual == 9, "cura sobe a vida")
	_checar(vida.curar(50) == 1 and vida.vida_atual == 10, "cura não passa do máximo")
	_checar(vida.curar(5) == 0, "vida cheia não sobe")
	vida.receber_dano(10)
	_checar(vida.esta_morto() and vida.curar(4) == 0, "morto não cura")
	vida.free()


func _testar_folego() -> void:
	var hud: Label = _principal.get_node("Hud/Coluna/Folego")
	_checar(_jogador.usos_folego() == 2, "começa com 2 usos")
	_checar(hud.text == "Fôlego 2/2", "HUD mostra Fôlego 2/2")
	var cheia := _jogador.vida_atual()

	await _apertar_folego()
	_checar(_jogador.usos_folego() == 1, "vida cheia gasta o uso mesmo assim")
	_checar(_jogador.vida_atual() == cheia, "vida cheia não sobe")
	_checar(not _jogador.acao_bonus_livre(), "fôlego gasta a ação bônus")
	_checar(hud.text == "Fôlego 1/2", "HUD desce para 1/2")

	await _apertar_folego()
	_checar(_jogador.usos_folego() == 1, "sem ação bônus o segundo aperto não gasta")

	await _esperar(QUADROS_ACAO_BONUS)
	var vida: HealthComponent = _jogador.get_node("Vida")
	var faltando := 10
	vida.receber_dano(faltando)
	var antes := _jogador.vida_atual()
	await _apertar_folego()
	var ganho := _jogador.vida_atual() - antes
	_checar(ganho >= 2 and ganho <= faltando, "segundo uso cura de 2 até o que falta (deu %d)" % ganho)
	_checar(_jogador.vida_atual() <= _jogador.vida_maxima(), "não passou do máximo")
	_checar(_jogador.usos_folego() == 0, "os dois usos acabaram")

	await _esperar(QUADROS_ACAO_BONUS)
	var parado := _jogador.vida_atual()
	await _apertar_folego()
	_checar(_jogador.usos_folego() == 0 and _jogador.vida_atual() == parado, "terceiro uso não cura")

	_jogador.reviver()
	await _esperar(5)
	_checar(_jogador.usos_folego() == 2 and _jogador.acao_bonus_livre(), "reviver devolve os 2 usos e a ação bônus")
	_checar(_jogador.vida_atual() == _jogador.vida_maxima(), "reviver enche a vida")
	_checar(hud.text == "Fôlego 2/2", "HUD volta para 2/2")


func _testar_teclas() -> void:
	var antes := _snapshot()
	var tecla_interagir := Comandos.tecla_de(&"interagir")
	Comandos.aplicar_tecla(&"atacar", KEY_U)
	_checar(Comandos.tecla_de(&"atacar") == OS.get_keycode_string(KEY_U), "atacar passou para U")
	Comandos.aplicar_tecla(&"interagir", KEY_U)
	_checar(Comandos.tecla_de(&"atacar") == Comandos.SEM_TECLA, "U saiu da ação que já a usava")
	_checar(Comandos.tecla_de(&"interagir") == OS.get_keycode_string(KEY_U), "U ficou em interagir")
	Comandos.salvar(ARQUIVO_TESTE)
	_restaurar(antes)
	_checar(Comandos.tecla_de(&"interagir") == tecla_interagir, "a memória voltou ao que era antes de gravar")
	Comandos.carregar(ARQUIVO_TESTE)
	_checar(Comandos.tecla_de(&"interagir") == OS.get_keycode_string(KEY_U), "carregar leu U de volta")
	_checar(Comandos.tecla_de(&"atacar") == Comandos.SEM_TECLA, "carregar manteve atacar sem a tecla roubada")
	_restaurar(antes)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_TESTE))

	var tela: TelaComandos = _principal.get_node("Interface/TelaComandos")
	var lista := tela.find_child("ListaCriaturas", true, false) as ItemList
	_checar(not tela.visible, "comandos começa fechado")
	_checar(lista.item_count >= 3 and lista.get_item_text(0) == "Gray Ooze"
		and lista.get_item_text(1) == "Goblin Minion" and lista.get_item_text(2) == "Goblin Warrior",
		"a lista de combate tem o Gray Ooze, o Goblin Minion e o Goblin Warrior")
	tela.abrir()
	_checar(tela.visible and _principal.get_tree().paused, "abrir a tela pausa o jogo")
	tela.fechar()
	_checar(not tela.visible and not _principal.get_tree().paused, "fechar a tela despausa")


func _testar_criatura() -> void:
	var da_cota := _principal.get_tree().get_nodes_in_group(&"monstros")
	var mapa: Node2D = da_cota[0]
	var posicao_mapa := mapa.position.x
	var antes := da_cota.size()
	_principal.trazer_criatura(load("res://features/gray_ooze/gray_ooze.tscn"))
	var novo := _trazido(mapa)
	var distancia := EscalaDnd.pes_para_pixels(Main.DISTANCIA_CRIATURA_PES) * _jogador.direcao_olhar
	_checar(_principal.get_tree().get_nodes_in_group(&"monstros").size() == antes + 1, "trazer aumenta o grupo")
	_checar(novo != null and novo.alvo == _jogador, "o trazido recebe o herói como alvo")
	_checar(novo != null and is_equal_approx(novo.global_position.x, _jogador.global_position.x + distancia),
		"nasce à frente do herói")

	_principal.tirar_criaturas()
	_checar(_principal.get_tree().get_nodes_in_group(&"monstros").is_empty(), "tirar esvazia a arena")

	_principal.trazer_criatura(load("res://features/gray_ooze/gray_ooze.tscn"))
	var vida: HealthComponent = _jogador.get_node("Vida")
	vida.receber_dano(vida.vida_atual)
	await create_timer(Jogador.DURACAO_MORTE + 0.3).timeout  # a animação de morte toca antes da tela
	var derrota := _principal.get_node("Interface").find_child("TelaDerrota", true, false) as TelaDerrota
	_checar(derrota != null, "cair abre a tela Você caiu")
	if derrota == null:
		return
	derrota.get_node("Centro/Painel/Coluna/TentarDeNovo").pressed.emit()
	await process_frame
	var voltaram := _principal.get_tree().get_nodes_in_group(&"monstros")
	var no_lugar := false
	for monstro in voltaram:
		if is_equal_approx((monstro as Node2D).position.x, posicao_mapa):
			no_lugar = true
	_checar(voltaram.size() == antes, "tentar de novo recria a cota da fase, sem o trazido")
	_checar(no_lugar, "com a mesma semente a armadilha volta no mesmo ponto")


func _trazido(mapa: Node) -> GrayOoze:
	for monstro in _principal.get_tree().get_nodes_in_group(&"monstros"):
		if monstro != mapa and monstro is GrayOoze:
			return monstro
	return null


func _snapshot() -> Dictionary:
	var copia := {}
	for acao in Comandos.ACOES:
		var eventos: Array[InputEvent] = []
		for evento in InputMap.action_get_events(acao):
			eventos.append(evento.duplicate())
		copia[acao] = eventos
	return copia


func _restaurar(copia: Dictionary) -> void:
	for acao in copia:
		InputMap.action_erase_events(acao)
		for evento in copia[acao]:
			InputMap.action_add_event(acao, evento)


func _apertar_folego() -> void:
	Input.action_press(&"folego")
	await physics_frame
	Input.action_release(&"folego")
	await physics_frame


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
