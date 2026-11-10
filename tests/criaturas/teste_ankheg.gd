extends TesteBase
## Teste do Ankheg (chefe da fase 3): ficha do livro, golpe de salvaguarda (Borrifo Ácido), herói agarrado (escapa a cada
## rodada), e a luta de verdade: anda, morde, borrifa, cava e emerge, e morre.
## godot --headless --debug --path . --script res://tests/criaturas/teste_ankheg.gd

const CENA := "res://features/ankheg/ankheg.tscn"
const VIDA_DE_TESTE := 9999
const POSICAO := Vector2(900, 288)
## Perto o bastante para morder (a borda do corpo + 5 pés) e dentro da linha do Borrifo (30 pés = 192 px).
const AO_ALCANCE := 60.0
const NA_LINHA := 120.0
## Trecho plano do começo da fase, onde o teste do Borrifo em área põe o Ankheg e a vítima.
const POSICAO_DO_BORRIFO_X := 150.0
## Longe o bastante para o Ankheg querer cavar.
const LONGE := 260.0
const QUADROS_POR_SEGUNDO := 60

var _jogador: Jogador
var _ankheg: Ankheg


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	_testar_salvaguarda()
	_testar_agarrao_puro()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	cena.tirar_criaturas()
	_ankheg = load(CENA).instantiate()
	cena.add_child(_ankheg)
	_ankheg.global_position = POSICAO
	_ankheg.definir_alvo(_jogador)
	await _esperar(10)

	await _testar_agarrao_do_heroi()
	await _testar_mordida_e_borrifo()
	await _testar_escavacao()
	await _testar_sem_terra_nao_cava()
	await _testar_borrifo_atinge_aliados(cena)
	await _testar_morte()
	await _testar_fase_do_chefe(cena)
	cena.queue_free()

	print("PASSOU: todos os testes do Ankheg" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/ankheg.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 45
		and ficha.deslocamento_pes == 30.0 and ficha.escavacao_pes == 10.0 and ficha.experiencia == 450,
		"Ankheg: CA 14, 45 PV (6d10+12), 30 pés, escava 10 pés, ND 2 (450 XP)")
	var mordida := ficha.golpe()
	_checar(mordida.nome == "Mordida" and mordida.bonus_ataque == 5 and mordida.tipo_dano == TiposDano.CORTANTE
		and mordida.dano.media() == 10 and ficha.dano_medio(mordida) == 13.0 and mordida.tem(Proficiencias.EFEITO_AGARRAR),
		"Mordida: +5, 10 (2d6+3) cortante + 3 (1d6) ácido e agarra")
	var borrifo := ficha.golpe_linha()
	_checar(borrifo.cd_salvaguarda == 12 and borrifo.atributo_salvaguarda == Atributos.DESTREZA
		and borrifo.tipo_dano == TiposDano.ACIDO and borrifo.dano.texto() == "4d6"
		and ficha.linha_comprimento_pes == 30.0 and ficha.linha_largura_pes == 5.0 and ficha.linha_recarga == 6,
		"Borrifo Ácido: Destreza CD 12, 4d6 ácido, linha de 30 x 5 pés, recarga 6")


## Salvaguarda no lugar de ataque: falhou, dano inteiro; passou, metade.
func _testar_salvaguarda() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var impossivel := Golpe.new("Teste", 0, Dado.new(4, 6), TiposDano.ACIDO)
	impossivel.cd_salvaguarda = 99
	var falhou := Combate.resolver_salvaguarda(impossivel, 0, rng)
	_checar(not falhou.salvou and falhou.acertou and falhou.dano >= 4, "salvaguarda impossível: dano inteiro (%d)" % falhou.dano)
	var facil := Golpe.new("Teste", 0, Dado.new(4, 6), TiposDano.ACIDO)
	facil.cd_salvaguarda = 5
	var passou := Combate.resolver_salvaguarda(facil, 100, rng)
	_checar(passou.salvou and passou.dano <= 12, "salvaguarda fácil: metade do dano (%d)" % passou.dano)
	var resistente := Combate.resolver_salvaguarda(impossivel, 0, rng, [TiposDano.ACIDO] as Array[StringName])
	_checar(resistente.resistido and resistente.dano <= 12, "resistência ao ácido também reduz o dano do Borrifo")


func _testar_agarrao_puro() -> void:
	var agarrao := AgarraoDoHeroi.new()
	var rng := RandomNumberGenerator.new()
	_checar(not agarrao.esta_agarrado() and not agarrao.passar(10.0), "livre: não conta tempo")
	agarrao.agarrar(42, 13)
	_checar(agarrao.esta_agarrado() and not agarrao.pode_antecipar() and not agarrao.passar(0.5),
		"agarrado: ainda não é hora de tentar escapar")
	_checar(agarrao.passar(EscalaDnd.RODADA_SEGUNDOS), "ao fim da rodada é hora de tentar")
	_checar(agarrao.tentar_escapar(100, rng) and not agarrao.esta_agarrado(), "bônus enorme: escapa e fica livre")
	agarrao.agarrar(42, 99)
	_checar(not agarrao.tentar_escapar(0, rng) and agarrao.esta_agarrado(), "CD impossível: continua agarrado")


## O golpe com Agarrar prende o herói: ele não anda nem pula, e a cada rodada tenta escapar.
func _testar_agarrao_do_heroi() -> void:
	_ankheg.global_position = Vector2(POSICAO.x + 2000.0, POSICAO.y)  # longe: só o golpe de teste conta
	_ankheg.set_physics_process(false)  # parado: só o golpe de teste conta, sem mordida nem Borrifo de verdade
	for i in 300:  # se o Ankheg já mordeu, espera passar a invencibilidade do herói
		if not _jogador.esta_invencivel():
			break
		await physics_frame
	var golpe := Golpe.new("Mordida", 100, Dado.new(1, 4), TiposDano.CORTANTE)
	golpe.efeitos.append(EfeitosDeTalento.Agarrar.new(30))  # CD 30: não escapa sozinho
	golpe.autor_id = _ankheg.get_instance_id()
	(_jogador.get_node("Hurtbox") as HurtboxComponent).receber_golpe(golpe, _ankheg.global_position)
	_checar(_jogador.esta_agarrado(), "a mordida que agarra prende o herói")
	var x := _jogador.global_position.x
	Input.action_press(&"mover_direita")
	await _esperar(30)
	Input.action_release(&"mover_direita")
	_checar(is_equal_approx(_jogador.global_position.x, x), "agarrado, o herói não anda")
	_jogador._agarrao.agarrar(_ankheg.get_instance_id(), 1)  # CD 1: escapa na primeira tentativa
	await _esperar(int(EscalaDnd.RODADA_SEGUNDOS * QUADROS_POR_SEGUNDO) + 10)
	_checar(not _jogador.esta_agarrado(), "a cada rodada tenta escapar e, passando, se solta")
	_ankheg.set_physics_process(true)
	_ankheg.global_position = POSICAO


func _testar_mordida_e_borrifo() -> void:
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r))
	var estados: Dictionary = {}
	for i in QUADROS_POR_SEGUNDO * 12:
		await physics_frame
		_colocar_heroi_a(AO_ALCANCE if i % 600 < 300 else NA_LINHA)
		_jogador._agarrao.soltar()
		estados[_ankheg.nome_estado()] = true
	_checar(&"Mordendo" in estados, "ao alcance, morde")
	_checar(&"Borrifando" in estados, "com o Borrifo pronto e o herói na linha, borrifa ácido")
	_checar(resultados.any(func(r: Combate.Resultado) -> bool: return r.golpe.nome == "Mordida"), "a mordida chega ao herói")
	_checar(resultados.any(func(r: Combate.Resultado) -> bool: return r.golpe.nome == "Borrifo Ácido" and r.dano > 0),
		"o Borrifo Ácido fere o herói que está na linha")
	_checar(not _ankheg.borrifo_pronto() or &"Borrifando" in estados, "o Borrifo gasta a recarga")


func _testar_escavacao() -> void:
	_ankheg.global_position = POSICAO
	var estados: Dictionary = {}
	var sumiu := false
	for i in QUADROS_POR_SEGUNDO * 20:
		await physics_frame
		if _ankheg.nome_estado() in [&"Parado", &"Perseguindo"]:
			_colocar_heroi_a(LONGE)
		estados[_ankheg.nome_estado()] = true
		sumiu = sumiu or _ankheg.esta_escondido()
		if &"Emergindo" in estados and _ankheg.nome_estado() == &"Mordendo":
			break
	_checar(sumiu and &"Cavando" in estados, "longe do herói, o Ankheg cava e some")
	_checar(&"Emergindo" in estados and not _ankheg.esta_escondido(), "depois emerge de volta")
	_checar(&"Mordendo" in estados and absf(_ankheg.global_position.x - _jogador.global_position.x) < 120.0,
		"emerge perto do herói, mordendo de surpresa")


## Sem terra no caminho (o herói do outro lado do fim do chão), ele não cava: anda e salta como os goblins.
func _testar_sem_terra_nao_cava() -> void:
	_ankheg.global_position = POSICAO
	await _esperar(30)
	_ankheg.set("_tempo_desde_cavar", 99.0)
	_jogador.posicionar_no_inicio(Vector2(POSICAO.x + 20000.0, _jogador.global_position.y))
	await _esperar(3)
	_checar(not _ankheg.quer_cavar(), "sem chão no caminho, não cava")


## O Borrifo é de área: pega todo mundo na linha, inclusive outras criaturas, mas nunca o próprio Ankheg.
func _testar_borrifo_atinge_aliados(cena: Node) -> void:
	_ankheg.global_position = Vector2(POSICAO_DO_BORRIFO_X, _ankheg.chao_em(POSICAO_DO_BORRIFO_X))
	_ankheg.direcao_olhar = 1
	_ankheg.alvo = null  # parado: só o jato de teste conta
	var vitima: Node2D = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	cena.add_child(vitima)
	vitima.global_position = Vector2(POSICAO_DO_BORRIFO_X + 110.0, _ankheg.chao_em(POSICAO_DO_BORRIFO_X + 110.0))
	var vida_da_vitima := vitima.get_node("Vida") as HealthComponent
	var vida_do_ankheg := _ankheg.get_node("Vida") as HealthComponent
	var antes := vida_da_vitima.vida_atual
	var antes_ankheg := vida_do_ankheg.vida_atual
	await _esperar(5)
	_ankheg.ligar_borrifo()
	await _esperar(10)
	_ankheg.desligar_borrifo()
	_checar(vida_da_vitima.vida_atual < antes, "o Borrifo também fere outra criatura na linha (%d -> %d)" % [antes, vida_da_vitima.vida_atual])
	_checar(vida_do_ankheg.vida_atual == antes_ankheg, "o Borrifo não fere o próprio Ankheg")
	vitima.queue_free()
	_ankheg.alvo = _jogador


func _testar_morte() -> void:
	var morreu := [false]
	_ankheg.morreu.connect(func() -> void: morreu[0] = true)
	(_ankheg.get_node("Vida") as HealthComponent).receber_dano(9999)
	await _esperar(QUADROS_POR_SEGUNDO * 2)
	_checar(morreu[0], "ao zerar a vida, o Ankheg morre e emite morreu")


## A fase 3 nasce com o Ankheg no marcador: ele conta na cota da porta, a missão pede o chefe e a HUD mostra a barra dele.
func _testar_fase_do_chefe(cena: Main) -> void:
	cena._entrar_fase(Main.CENAS_FASE[2])
	await _esperar(5)
	var chefes := cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS).filter(func(m: Node) -> bool: return m is Ankheg)
	_checar(chefes.size() == 1, "a fase 3 nasce com um Ankheg")
	if chefes.is_empty():
		return
	var chefe: Ankheg = chefes[0]
	var id := chefe.get_instance_id()
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	var missao := cena.get_node("Hud").find_child("Missao", true, false) as Label
	_checar(cena._ids_da_cota.has(id), "o chefe conta na cota da porta")
	_checar("derrote o Ankheg" in missao.text, "a missão pede para derrotar o Ankheg")
	_checar(barra.visible, "a HUD mostra a barra de vida do chefe")
	(chefe.get_node("Vida") as HealthComponent).receber_dano(9999)
	await _esperar(QUADROS_POR_SEGUNDO * 2)
	_checar(not barra.visible and not cena._ids_da_cota.has(id), "ao cair, a barra some e a cota abre")


func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_ankheg.global_position.x - distancia, _jogador.global_position.y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
