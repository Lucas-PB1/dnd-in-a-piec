extends TesteBase
## Skeleton (Monster Manual 2024, conferido no Códice): ficha, vulnerabilidade a contundente (dano dobra), imunidade a veneno,
## cena rodando sozinha, morte com a animação `morrer` e presença na Main (sorteio, bestiário, acompanhantes do Wight).
## godot --headless --debug --path . --script res://tests/criaturas/teste_skeleton.gd

const CENA := "res://features/goblin/skeleton_guerreiro.tscn"
const GOLPE_CERTEIRO := 100
const DANO_FIXO := 4
const TEMPO_DE_MORRER := 5.0
const QUADROS_POR_SEGUNDO := 60


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	await _testar_defesas()
	await _testar_morte()
	_testar_main()
	print("PASSOU: todos os testes do Skeleton" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/skeleton.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 13 and ficha.iniciativa == 3
		and ficha.deslocamento_pes == 30.0 and ficha.experiencia == 50, "Skeleton: CA 14, 13 PV (2d8+4), iniciativa +3, 30 pés, 50 XP")
	_checar(ficha.modificador(Atributos.DESTREZA) == 3 and ficha.modificador(Atributos.CONSTITUICAO) == 2, "Destreza 16 (+3) e Constituição 15 (+2)")
	var espada := ficha.golpe()
	_checar(espada.nome == "Espada Curta" and espada.bonus_ataque == 5 and espada.dano.texto() == "1d6+3"
		and espada.tipo_dano == TiposDano.PERFURANTE, "Espada Curta: +5, 1d6+3 perfurante")
	_checar(ficha.disparo_nome == "Arco Curto" and ficha.disparo_normal_pes == 80.0 and ficha.disparo_longo_pes == 320.0
		and ficha.disparo_dano == "1d6+3", "Arco Curto: +5, 80/320 pés, 1d6+3")
	_checar(&"contundente" in ficha.vulnerabilidades and &"veneno" in ficha.imunidades_dano
		and &"envenenado" in ficha.imunidades_condicoes, "vulnerável a contundente, imune a veneno e a Envenenado")


## Dano fixo de 4: contundente dobra (8), perfurante fica (4), veneno some (0).
func _testar_defesas() -> void:
	var esqueleto: Goblin = await _nascer()
	var defesa: DefesaComponent = esqueleto.get_node("Defesa")
	var vida: HealthComponent = esqueleto.get_node("Vida")
	_checar(esqueleto.nome_estado() == &"Parado" and vida.vida_atual == 13, "Skeleton sozinho: parado, 13 PV")
	var danos: Dictionary = {}
	for tipo: StringName in [TiposDano.CONTUNDENTE, TiposDano.PERFURANTE, TiposDano.VENENO]:
		var antes := vida.vida_atual
		vida.vida_atual = vida.vida_maxima
		var golpe := Golpe.new("Teste", GOLPE_CERTEIRO, Dado.new(0, 6, DANO_FIXO), tipo)
		defesa._ao_receber_golpe(golpe, Vector2.ZERO)
		danos[tipo] = vida.vida_maxima - vida.vida_atual
		vida.vida_atual = antes
	_checar(danos[TiposDano.CONTUNDENTE] == DANO_FIXO * 2, "dano contundente dobra (%d)" % danos[TiposDano.CONTUNDENTE])
	_checar(danos[TiposDano.PERFURANTE] == DANO_FIXO, "dano perfurante normal (%d)" % danos[TiposDano.PERFURANTE])
	_checar(danos[TiposDano.VENENO] == 0, "veneno não faz nada (%d)" % danos[TiposDano.VENENO])
	esqueleto.queue_free()
	await _esperar(2)


## Ao morrer toca `morrer` até o fim e só então some.
func _testar_morte() -> void:
	var esqueleto: Goblin = await _nascer()
	var morreu := [false]
	esqueleto.morreu.connect(func() -> void: morreu[0] = true)
	(esqueleto.get_node("Vida") as HealthComponent).receber_dano(99)
	await _esperar(5)
	var sprite: AnimatedSprite2D = esqueleto.get_node("Sprite")
	_checar(esqueleto.nome_estado() == &"Morrendo" and sprite.animation == &"morrer", "ao morrer toca a animação `morrer`")
	_checar(not morreu[0], "ainda não sumiu enquanto a animação toca")
	await _esperar(int(QUADROS_POR_SEGUNDO * TEMPO_DE_MORRER))
	_checar(morreu[0], "depois da animação some e emite morreu")


func _testar_main() -> void:
	_checar(Main.CENAS_DOS_TIPOS.has(&"skeleton"), "a Main sabe sortear o tipo skeleton")
	var cripta: Node = load("res://levels/fase_9.tscn").instantiate()
	_checar(&"skeleton" in cripta.acompanhantes_do_chefe, "os acompanhantes do Wight são Skeletons")
	cripta.free()
	var nomes: Array[String] = []
	for entrada in Main.ENTRADAS_BESTIARIO:
		nomes.append(entrada.criatura.nome)
	_checar("Skeleton" in nomes, "o Skeleton tem página no bestiário")


func _nascer() -> Goblin:
	var goblin: Goblin = load(CENA).instantiate()
	root.add_child(goblin)
	await _esperar(3)
	return goblin


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
