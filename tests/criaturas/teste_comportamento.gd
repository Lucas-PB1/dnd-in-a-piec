extends TesteBase
## Comportamento dos monstros: o aviso (brilho e pausa) antes do golpe, e a patrulha de quem
## perdeu o alvo. godot --headless --debug --path . --script res://tests/criaturas/teste_comportamento.gd

const CENA_GOBLIN := "res://features/humanoides/goblin.tscn"
const CENA_OOZE := "res://features/gray_ooze/gray_ooze.tscn"
const POSICAO := Vector2(900, 288)
const VIDA_DE_TESTE := 999
## Fora da visão de 60 pés (384 px) e ao alcance da adaga/do Pseudópode.
const LONGE_DA_VISAO := 600.0
const PERTO_PARA_REVELAR := 300.0
const AO_ALCANCE := 30.0
const QUADRO := 1.0 / 60.0
## Quadros para uma patrulha completa (pausa de 1,5 s + 96 px a meia velocidade + folga).
const QUADROS_PATRULHA := 720
## A patrulha é de 15 pés (96 px); aceita um pouco além por causa do tempo de parar.
const MARGEM_PATRULHA := 24.0

var _jogador: Jogador
var _cena: Main


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_fichas()
	_cena = load("res://levels/main.tscn").instantiate()
	_cena.mostrar_inicio = false
	root.add_child(_cena)
	_jogador = _cena.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	(_jogador.get_node("Defesa") as DefesaComponent).invulneravel = true
	_cena.tirar_criaturas()
	await _testar_aviso_do_goblin()
	await _testar_aviso_do_ooze()
	await _testar_patrulha()
	await _testar_tremor_e_sombra()
	_cena.queue_free()

	if _falhas == 0:
		print("PASSOU: todos os testes do comportamento")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_fichas() -> void:
	var minion: CriaturaRPG = load("res://data/goblin_minion.tres")
	var warrior: CriaturaRPG = load("res://data/goblin_warrior.tres")
	var ooze: CriaturaRPG = load("res://data/gray_ooze.tres")
	_checar(minion.aviso_ataque > 0.0 and warrior.aviso_ataque > 0.0 and ooze.aviso_ataque > 0.0, "os três monstros avisam antes do golpe")
	_checar(minion.patrulha_pes == 15.0 and warrior.patrulha_pes == 15.0 and ooze.patrulha_pes == 0.0,
		"goblins patrulham 15 pés; o Ooze espera parado")


func _testar_aviso_do_goblin() -> void:
	var goblin: Goblin = await _criar(CENA_GOBLIN)
	goblin.definir_percepcao_passiva(100)  # sem emboscada: o aviso vale
	var aviso := goblin.criatura.aviso_ataque
	var brilhou := false
	var tempo := 0.0
	var primeiro_acerto := -1.0
	var golpe := goblin.get_node("Golpe") as HitboxComponent
	_colocar_heroi_a(goblin, AO_ALCANCE)
	for i in 240:
		await physics_frame
		_colocar_heroi_a(goblin, AO_ALCANCE)
		if goblin.nome_estado() != &"Atacando":
			continue
		tempo += QUADRO
		brilhou = brilhou or goblin.get_node("Sprite").modulate == goblin.cor_aviso
		if golpe.esta_ligada() and primeiro_acerto < 0.0:
			primeiro_acerto = tempo
	_checar(brilhou, "o goblin brilha antes de golpear")
	_checar(primeiro_acerto >= aviso, "o golpe só acerta depois do aviso de %.2f s (acertou em %.2f s)" % [aviso, primeiro_acerto])
	_checar(goblin.get_node("Sprite").modulate != goblin.cor_aviso or goblin.nome_estado() == &"Atacando",
		"o brilho some quando o golpe sai")
	goblin.free()


func _testar_aviso_do_ooze() -> void:
	var ooze: GrayOoze = await _criar(CENA_OOZE)
	var aviso := ooze.criatura.aviso_ataque
	var brilhou := false
	var tempo := 0.0
	var primeiro_acerto := -1.0
	var pseudopode := ooze.get_node("Pseudopode") as HitboxComponent
	_colocar_heroi_a(ooze, AO_ALCANCE)
	for i in 300:
		await physics_frame
		_colocar_heroi_a(ooze, AO_ALCANCE)
		if ooze.nome_estado() != &"Atacando":
			continue
		tempo += QUADRO
		brilhou = brilhou or ooze.get_node("Sprite").modulate == ooze.cor_aviso
		if pseudopode.esta_ligada() and primeiro_acerto < 0.0:
			primeiro_acerto = tempo
	_checar(brilhou, "o Ooze brilha antes do Pseudópode")
	_checar(primeiro_acerto >= aviso, "o Pseudópode só acerta depois do aviso (acertou em %.2f s)" % primeiro_acerto)
	ooze.free()


## Revela o goblin, tira o herói da visão e confere a ronda: anda até 15 pés de onde começou.
func _testar_patrulha() -> void:
	var goblin: Goblin = await _criar(CENA_GOBLIN)
	goblin.definir_percepcao_passiva(100)
	_colocar_heroi_a(goblin, PERTO_PARA_REVELAR)
	for i in 30:
		await physics_frame
	_checar(goblin.nome_estado() != &"Escondido", "o goblin foi revelado pelo herói")
	var viu_patrulha := false
	var base := INF
	var mais_longe := 0.0
	for i in QUADROS_PATRULHA:
		await physics_frame
		_colocar_heroi_a(goblin, LONGE_DA_VISAO)
		if goblin.nome_estado() == &"Patrulhando":
			viu_patrulha = true
			base = minf(base, goblin.global_position.x) if base != INF else goblin.global_position.x
		if viu_patrulha:
			mais_longe = maxf(mais_longe, absf(goblin.global_position.x - base))
	_checar(viu_patrulha, "sem ver o herói, o goblin passa a patrulhar")
	var limite := EscalaDnd.pes_para_pixels(goblin.criatura.patrulha_pes) + MARGEM_PATRULHA
	_checar(mais_longe > 40.0 and mais_longe <= 2.0 * limite, "e anda uns %.0f px, dentro da ronda de 15 pés" % mais_longe)
	goblin.free()


## Levar dano treme o sprite e volta ao lugar; a sombra some junto com o goblin escondido.
func _testar_tremor_e_sombra() -> void:
	var goblin: Goblin = await _criar(CENA_GOBLIN)
	var sprite := goblin.get_node("Sprite") as AnimatedSprite2D
	var tremor := goblin.get_node("Tremor") as TremorComponent
	var base := sprite.offset
	var sombra := goblin.get_node("Sombra") as Polygon2D
	_checar(sombra != null and not goblin.esta_escondido() == sombra.visible, "o goblin tem sombra no chão, escondida junto com ele")
	goblin.revelar()
	(goblin.get_node("Vida") as HealthComponent).receber_dano(1)
	goblin.get_node("MaquinaEstados").trocar(&"LevandoDano")
	var mexeu := false
	for i in 6:
		await physics_frame
		await process_frame
		mexeu = mexeu or sprite.offset != base
	_checar(mexeu and tremor.esta_tremendo(), "levar dano treme o sprite")
	for i in 60:
		await physics_frame
		await process_frame
	_checar(not tremor.esta_tremendo() and sprite.offset == base, "e o sprite volta ao lugar depois")
	var ooze: GrayOoze = await _criar(CENA_OOZE)
	_checar(ooze.get_node("Sombra") != null and ooze.get_node("Tremor") != null, "o Ooze também tem sombra e tremor")
	ooze.free()
	goblin.free()


func _criar(caminho: String) -> Node2D:
	var criatura: Node2D = load(caminho).instantiate()
	criatura.add_to_group(&"monstros")
	_cena.add_child(criatura)
	criatura.global_position = POSICAO
	criatura.definir_alvo(_jogador)
	await physics_frame
	return criatura


## Herói à esquerda da criatura, no chão.
func _colocar_heroi_a(criatura: Node2D, distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(criatura.global_position.x - distancia, _jogador.global_position.y))
