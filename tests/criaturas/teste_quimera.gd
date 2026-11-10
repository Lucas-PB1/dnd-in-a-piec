extends TesteBase
## Teste da Quimera (chefe final, fase 10): ficha do livro, Ataques Múltiplos (Cabeçada que derruba, Mordida e Garra), Sopro de
## Fogo (cone por salvaguarda, recarga 5-6, no lugar da Garra) e a luta de verdade: ruge ao perceber o herói, golpeia, sopra e morre.
## godot --headless --debug --path . --script res://tests/criaturas/teste_quimera.gd

const VIDA_DE_TESTE := 9999
const QUADROS_POR_SEGUNDO := 60
## Perto o bastante para os golpes de perto (borda do corpo + 5 pés = 88 px).
const AO_ALCANCE := 70.0
## No cone do Sopro (15 pés = 96 px) mas fora do alcance das garras.
const NO_CONE := 120.0
## Dentro da percepção (120 pés = 768 px) mas longe de qualquer golpe.
const DISTANCIA_DE_PERCEBER := 700.0
const CHAO_Y := 288.0
const FASE_DO_CHEFE := 9
## Invencibilidade do herói depois de um acerto, encurtada no teste (s).
const TEMPO_INVENCIVEL_CURTO := 0.05

var _jogador: Jogador
var _quimera: Quimera


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	await _esperar(10)

	await _testar_fase_do_chefe(cena)
	if _quimera != null:
		_travar_padroes()
		await _testar_rugido()
		await _testar_disparada()
		await _testar_combo()
		await _testar_sopro_sozinho()
		await _testar_recarga()
		await _testar_garra_trocada_pelo_sopro()
		await _testar_bote()
		await _testar_investida()
		await _testar_voo()
		await _testar_furia()
		await _testar_morte(cena)
	cena.queue_free()

	print("PASSOU: todos os testes da Quimera" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/quimera.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 114
		and ficha.deslocamento_pes == 30.0 and ficha.experiencia == 2300 and ficha.iniciativa == 0,
		"Quimera: CA 14, 114 PV (12d10+48), 30 pés, ND 6 (2.300 XP)")
	_checar(ficha.modificador(Atributos.FORCA) == 4 and ficha.modificador(Atributos.CONSTITUICAO) == 4,
		"Força 19 e Constituição 19 (+4)")
	var mordida := ficha.golpe()
	_checar(mordida.nome == "Mordida" and mordida.bonus_ataque == 7 and mordida.tipo_dano == TiposDano.PERFURANTE
		and mordida.dano.texto() == "2d6+4" and mordida.dano_extra != null and mordida.dano_extra.texto() == "2d6",
		"Mordida: +7, 2d6+4 perfurante (4d6+4 com vantagem)")
	var cabecada := ficha.golpe_chifrada(true)
	_checar(cabecada.nome == "Cabeçada" and cabecada.bonus_ataque == 7 and cabecada.tipo_dano == TiposDano.CONTUNDENTE
		and cabecada.dano.texto() == "1d12+4" and cabecada.tem(Proficiencias.EFEITO_DERRUBADA),
		"Cabeçada: +7, 1d12+4 contundente, derruba")
	var garra := ficha.golpe_garra()
	_checar(garra.nome == "Garra" and garra.bonus_ataque == 7 and garra.tipo_dano == TiposDano.CORTANTE and garra.dano.texto() == "1d6+4",
		"Garra: +7, 1d6+4 cortante")
	var sopro := ficha.golpe_linha()
	_checar(sopro.nome == "Sopro de Fogo" and sopro.cd_salvaguarda == 15 and sopro.atributo_salvaguarda == Atributos.DESTREZA
		and sopro.dano.texto() == "7d8" and sopro.tipo_dano == TiposDano.FOGO and ficha.linha_comprimento_pes == 15.0
		and ficha.linha_recarga == 5,
		"Sopro de Fogo: cone de 15 pés, salvaguarda de Destreza CD 15, 7d8 de fogo, recarga 5-6")


## A fase 10 (índice 9) nasce com a Quimera no marcador: conta na cota, a missão pede o chefe, a HUD mostra a barra.
func _testar_fase_do_chefe(cena: Main) -> void:
	cena._entrar_fase(Main.CENAS_FASE[FASE_DO_CHEFE])
	await _esperar(5)
	var chefes := cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS).filter(func(m: Node) -> bool: return m is Quimera)
	_checar(chefes.size() == 1, "a fase do covil nasce com uma Quimera")
	if chefes.is_empty():
		return
	_quimera = chefes[0]
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	var missao := cena.get_node("Hud").find_child("Missao", true, false) as Label
	_checar(cena._ids_da_cota.has(_quimera.get_instance_id()), "o chefe conta na cota da porta")
	_checar("Quimera" in missao.text, "a missão pede para derrotar a Quimera (%s)" % missao.text)
	_checar(barra.visible, "a HUD mostra a barra de vida do chefe")
	for monstro in cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS):
		if monstro != _quimera:
			monstro.queue_free()  # só o chefe conta nesta luta
	await _esperar(3)


## Ao perceber o herói, ruge (estado Rugindo) e parte para cima.
func _testar_rugido() -> void:
	_quimera.set("_sopro_pronto", false)
	var estados: Dictionary = {}
	for i in QUADROS_POR_SEGUNDO * 6:
		await physics_frame
		_colocar_heroi_a(DISTANCIA_DE_PERCEBER)
		estados[_quimera.nome_estado()] = true
		if &"Perseguindo" in estados and &"Rugindo" in estados:
			break
	_checar(&"Rugindo" in estados, "ao perceber o herói, a Quimera ruge")
	_checar(&"Perseguindo" in estados, "e depois parte para cima do herói")


## Com o herói longe ela corre na Disparada (o dobro da velocidade), a passada acompanha o chão e, perto, ela freia sem travar.
func _testar_disparada() -> void:
	_quimera.set("_sopro_pronto", false)
	var andar := EscalaDnd.deslocamento_para_velocidade(_quimera.criatura.deslocamento_pes)
	var mais_rapida := 0.0
	var ritmo := 0.0
	for i in QUADROS_POR_SEGUNDO * 2:
		await physics_frame
		_colocar_heroi_a(DISTANCIA_DE_PERCEBER)
		mais_rapida = maxf(mais_rapida, absf(_quimera.velocity.x))
		ritmo = maxf(ritmo, (_quimera.get_node("Sprite") as AnimatedSprite2D).speed_scale)
	_checar(is_equal_approx(mais_rapida, andar * EscalaDnd.MULTIPLICADOR_DISPARADA),
		"longe, ela corre na Disparada (%.0f px/s, andar é %.0f)" % [mais_rapida, andar])
	_checar(ritmo > 1.5, "a passada acelera com a corrida (ritmo %.2f)" % ritmo)
	_colocar_heroi_a(AO_ALCANCE)
	await _esperar(QUADROS_POR_SEGUNDO)
	_checar(absf(_quimera.velocity.x) < andar, "perto, ela já não corre")


## De perto: Cabeçada (derruba o herói), Mordida (com vantagem no herói caído) e Garra, as três no mesmo ataque.
func _testar_combo() -> void:
	(_jogador.get_node("Defesa") as DefesaComponent).classe_armadura = 1
	# Sem a invencibilidade de 1 s depois de cada acerto, os três golpes do combo (0,4 s no total) caem todos no herói.
	_jogador.stats.tempo_invencibilidade = TEMPO_INVENCIVEL_CURTO
	_quimera.set("_sopro_pronto", false)
	var nomes: Dictionary = {}
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: nomes[r.golpe.nome] = true)
	var estados: Dictionary = {}
	var caiu := false
	for i in QUADROS_POR_SEGUNDO * 30:
		await physics_frame
		_colocar_heroi_a(AO_ALCANCE)
		estados[_quimera.nome_estado()] = true
		caiu = caiu or _jogador.nome_estado() == &"Caido"
		if "Cabeçada" in nomes and "Mordida" in nomes and "Garra" in nomes:
			break
	_checar(&"Atacando" in estados, "ao alcance, a Quimera ataca")
	_checar("Cabeçada" in nomes and "Mordida" in nomes and "Garra" in nomes,
		"os Ataques Múltiplos: Cabeçada, Mordida e Garra (%s)" % ", ".join(nomes.keys()))
	_checar(caiu, "a Cabeçada derruba o herói")


## Com o herói no cone, fora do alcance das garras, e o Sopro pronto: sopra; o fogo queima (salvaguarda de Destreza).
func _testar_sopro_sozinho() -> void:
	_quimera.set("_sopro_pronto", true)
	var vida: HealthComponent = _jogador.get_node("Vida")
	var antes := vida.vida_atual
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	var sopro := {"visto": false, "salvou": false}
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void:
		if r.golpe.nome == "Sopro de Fogo":
			sopro["visto"] = true
			sopro["salvou"] = r.salvou)
	var estados: Dictionary = {}
	for i in QUADROS_POR_SEGUNDO * 12:
		await physics_frame
		_colocar_heroi_a(NO_CONE)
		estados[_quimera.nome_estado()] = true
		if sopro["visto"]:
			break
	_checar(&"Soprando" in estados and sopro["visto"], "com o herói no cone, a Quimera usa o Sopro de Fogo")
	_checar(vida.vida_atual < antes, "o fogo queima o herói (%d de vida)" % (antes - vida.vida_atual))
	_checar(not _quimera.sopro_pronto(), "o Sopro gasta a recarga")


## Recarga 5-6: depois de um tempo, o Sopro volta.
func _testar_recarga() -> void:
	_jogador.posicionar_no_inicio(Vector2(_quimera.global_position.x - DISTANCIA_DE_PERCEBER, CHAO_Y))
	var voltou := false
	for i in QUADROS_POR_SEGUNDO * 60:
		await physics_frame
		if _quimera.sopro_pronto():
			voltou = true
			break
	_checar(voltou, "o Sopro de Fogo recarrega com o tempo (recarga 5-6)")


## Com o Sopro pronto no meio do combo de perto, ele toma o lugar da Garra.
func _testar_garra_trocada_pelo_sopro() -> void:
	(_jogador.get_node("Defesa") as DefesaComponent).classe_armadura = 1
	_jogador.stats.tempo_invencibilidade = TEMPO_INVENCIVEL_CURTO
	await _esperar(QUADROS_POR_SEGUNDO)  # a invencibilidade do Sopro anterior acaba
	_quimera.set("_sopro_pronto", true)
	(_quimera.get_node("MaquinaEstados") as MaquinaEstados).trocar(&"Perseguindo")
	var nomes: Dictionary = {}
	var vistos: Dictionary = {}
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: nomes[r.golpe.nome] = true)
	for i in QUADROS_POR_SEGUNDO * 20:
		await physics_frame
		vistos[_quimera.nome_estado()] = true
		_colocar_heroi_a(AO_ALCANCE)
		if "Sopro de Fogo" in nomes and "Mordida" in nomes:
			break
	_checar("Sopro de Fogo" in nomes and not ("Garra" in nomes) and "Mordida" in nomes,
		"o Sopro toma o lugar da Garra no combo (%s; estados %s)" % [", ".join(nomes.keys()), ", ".join(vistos.keys())])



## Força um padrão (troca de estado) com o herói a `distancia` e devolve os golpes que acertaram e os estados por onde passou.
func _rodar_padrao(estado: StringName, distancia: float, ate: Callable) -> Dictionary:
	var golpes: Dictionary = {}
	var estados: Dictionary = {}
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	var ouvinte := func(r: Combate.Resultado, _o: Vector2) -> void: golpes[r.golpe.nome] = true
	defesa.golpe_resolvido.connect(ouvinte)
	await _esperar(QUADROS_POR_SEGUNDO * 2)  # a invencibilidade do herói do padrão anterior acaba
	_quimera.set("_sopro_pronto", false)
	_colocar_heroi_a(distancia)
	await _esperar(2)
	(_quimera.get_node("MaquinaEstados") as MaquinaEstados).trocar(estado)
	for i in QUADROS_POR_SEGUNDO * 6:
		await physics_frame
		_quimera.set("_sopro_pronto", false)
		estados[_quimera.nome_estado()] = true
		if ate.call(golpes, estados):
			break
	defesa.golpe_resolvido.disconnect(ouvinte)
	return {"golpes": golpes, "estados": estados}


func _testar_bote() -> void:
	var r := await _rodar_padrao(&"Bote", 250.0, func(g: Dictionary, _e: Dictionary) -> bool: return g.has("Bote"))
	_checar(r["golpes"].has("Bote"), "o Bote cai em cima do herói (%s)" % ", ".join(r["golpes"].keys()))


func _testar_investida() -> void:
	var r := await _rodar_padrao(&"Investindo", 280.0, func(g: Dictionary, _e: Dictionary) -> bool: return g.has("Cabeçada"))
	_checar(r["golpes"].has("Cabeçada"), "a Investida acerta a Cabeçada (%s; %s; x %.0f)" % [", ".join(r["golpes"].keys()), ", ".join(r["estados"].keys()), _quimera.global_position.x - _jogador.global_position.x])


## Voa (decola, sobe) e mergulha: a Cabeçada do mergulho acerta e ela volta ao chão.
func _testar_voo() -> void:
	var r := await _rodar_padrao(&"Voando", 300.0, func(g: Dictionary, _e: Dictionary) -> bool: return g.has("Mergulho"))
	_checar(&"Voando" in r["estados"] and &"Mergulhando" in r["estados"], "ela voa e mergulha (%s)" % ", ".join(r["estados"].keys()))
	_checar(r["golpes"].has("Mergulho"), "o Mergulho acerta o herói")
	await _esperar(QUADROS_POR_SEGUNDO * 2)
	_checar(not _quimera.voando, "depois do mergulho, ela volta ao chão")


## Abaixo da metade da vida: enfurece e ruge uma vez.
func _testar_furia() -> void:
	(_quimera.get_node("MaquinaEstados") as MaquinaEstados).trocar(&"Perseguindo")
	(_quimera.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	_checar(not _quimera.enfurecida(), "com a vida cheia, ela não está enfurecida")
	var vida: HealthComponent = _quimera.get_node("Vida")
	vida.configurar(100)
	vida.receber_dano(60)
	_checar(_quimera.enfurecida() and _quimera.deve_rugir(), "abaixo da metade da vida, ela enfurece e vai rugir")
	var rugiu := false
	for i in QUADROS_POR_SEGUNDO * 4:
		await physics_frame
		_colocar_heroi_a(DISTANCIA_DE_PERCEBER)
		rugiu = rugiu or _quimera.nome_estado() == &"Rugindo"
	_checar(rugiu and not _quimera.deve_rugir(), "ela ruge ao enfurecer, uma vez só")


func _testar_morte(cena: Main) -> void:
	var morreu := [false]
	var id := _quimera.get_instance_id()
	_quimera.morreu.connect(func() -> void: morreu[0] = true)
	(_quimera.get_node("Vida") as HealthComponent).receber_dano(VIDA_DE_TESTE)
	await _esperar(QUADROS_POR_SEGUNDO * 5)
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	_checar(morreu[0], "ao zerar a vida, a Quimera morre e emite morreu")
	_checar(not barra.visible and not cena._ids_da_cota.has(id), "ao cair, a barra some e a cota abre")


## O herói fica à esquerda da Quimera, na mesma altura.
func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_quimera.global_position.x - distancia, CHAO_Y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


## Impede a escolha automática dos padrões novos (bote, investida e voo): cada teste força o seu e o resto fica previsível.
func _travar_padroes() -> void:
	var recargas: Dictionary = {}
	for padrao: StringName in Quimera.PADROES:
		recargas[padrao] = float(VIDA_DE_TESTE)
	_quimera.set("_recargas_dos_padroes", recargas)
