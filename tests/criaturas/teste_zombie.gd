extends TesteBase
## Zombie (Monster Manual 2024, conferido no Códice): ficha, Fortitude dos Mortos-Vivos (sobra 1 PV na salvaguarda de
## Constituição CD 5 + dano; não vale contra acerto crítico nem dano radiante), cena sozinha, morte e presença na Main.
## godot --headless --debug --path . --script res://tests/criaturas/teste_zombie.gd

const CENA := "res://features/humanoides/zombie_guerreiro.tscn"
const GOLPE_CERTEIRO := 100
const DANO_FIXO := 1
const TENTATIVAS := 300
const BONUS_CONSTITUICAO := 3
const SEMENTE := 7
const TEMPO_DE_MORRER := 4.0
const QUADROS_POR_SEGUNDO := 60


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	_testar_fortitude()
	await _testar_cena()
	_testar_main()
	print("PASSOU: todos os testes do Zombie" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/zombie.tres")
	_checar(ficha.classe_armadura == 8 and ficha.vida_maxima(RandomNumberGenerator.new()) == 15 and ficha.iniciativa == -2
		and ficha.deslocamento_pes == 20.0 and ficha.experiencia == 50, "Zombie: CA 8, 15 PV (2d8+6), iniciativa −2, 20 pés, 50 XP")
	_checar(ficha.modificador(Atributos.FORCA) == 1 and ficha.modificador(Atributos.CONSTITUICAO) == 3, "Força 13 (+1) e Constituição 16 (+3)")
	var pancada := ficha.golpe()
	_checar(pancada.nome == "Pancada" and pancada.bonus_ataque == 3 and pancada.dano.texto() == "1d8+1"
		and pancada.tipo_dano == TiposDano.CONTUNDENTE, "Pancada: +3, 1d8+1 contundente")
	_checar(ficha.fortitude_morto_vivo and &"veneno" in ficha.imunidades_dano and &"envenenado" in ficha.imunidades_condicoes,
		"Fortitude dos Mortos-Vivos, imune a veneno e a Envenenado")


## Dano de 1 contra 1 PV: sem crítico, a salvaguarda quase sempre passa (CD 6 contra +3) e sobra 1 PV; com crítico, nunca.
func _testar_fortitude() -> void:
	var ponto := Node.new()
	root.add_child(ponto)
	var hurtbox := HurtboxComponent.new()
	var vida := HealthComponent.new()
	var defesa := DefesaComponent.new()
	defesa.hurtbox = hurtbox
	defesa.vida = vida
	for no in [hurtbox, vida, defesa]:
		ponto.add_child(no)
	defesa.fortitude_morto_vivo = true
	defesa.bonus_salvaguardas[Atributos.CONSTITUICAO] = BONUS_CONSTITUICAO
	defesa.rng.seed = SEMENTE
	var seguradas := [0]
	var criticos_que_sobraram := [0]
	var criticos := [0]
	defesa.fortitude_usada.connect(func() -> void: seguradas[0] += 1)
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void:
		if r.critico:
			criticos[0] += 1
			if not vida.esta_morto():
				criticos_que_sobraram[0] += 1)
	var mortes := 0
	for i in TENTATIVAS:
		vida.configurar(1)
		defesa._ao_receber_golpe(Golpe.new("Teste", GOLPE_CERTEIRO, Dado.new(0, 6, DANO_FIXO), TiposDano.CONTUNDENTE), Vector2.ZERO)
		if vida.esta_morto():
			mortes += 1
	_checar(seguradas[0] * 2 > TENTATIVAS, "a Fortitude segura o Zombie em 1 PV na maior parte das vezes (%d de %d)" % [seguradas[0], TENTATIVAS])
	_checar(mortes > 0, "mas às vezes a salvaguarda falha e ele morre (%d)" % mortes)
	_checar(criticos[0] > 0 and criticos_que_sobraram[0] == 0, "acerto crítico não é segurado pela Fortitude (%d críticos)" % criticos[0])
	vida.configurar(1)
	seguradas[0] = 0
	for i in TENTATIVAS:
		vida.configurar(1)
		defesa._ao_receber_golpe(Golpe.new("Luz", GOLPE_CERTEIRO, Dado.new(0, 6, DANO_FIXO), TiposDano.RADIANTE), Vector2.ZERO)
	_checar(seguradas[0] == 0, "dano radiante também ignora a Fortitude")
	ponto.queue_free()


func _testar_cena() -> void:
	var zombie: Goblin = load(CENA).instantiate()
	root.add_child(zombie)
	await _esperar(3)
	var vida: HealthComponent = zombie.get_node("Vida")
	_checar(zombie.nome_estado() == &"Parado" and vida.vida_atual == 15, "Zombie sozinho: parado, 15 PV")
	var morreu := [false]
	zombie.morreu.connect(func() -> void: morreu[0] = true)
	(zombie.get_node("Defesa") as DefesaComponent).fortitude_morto_vivo = false
	vida.receber_dano(99)
	await _esperar(5)
	_checar((zombie.get_node("Sprite") as AnimatedSprite2D).animation == &"morrer", "ao morrer toca a animação `morrer`")
	await _esperar(int(QUADROS_POR_SEGUNDO * TEMPO_DE_MORRER))
	_checar(morreu[0], "depois da animação some e emite morreu")


func _testar_main() -> void:
	_checar(Main.CENAS_DOS_TIPOS.has(&"zombie"), "a Main sabe sortear o tipo zombie")
	var cripta: Node = load("res://levels/fase_9.tscn").instantiate()
	_checar(&"zombie" in cripta.tipos_permitidos and &"zombie" in cripta.acompanhantes_do_chefe, "a Cripta sorteia Zombie e o Wight o chama")
	cripta.free()
	var nomes: Array[String] = []
	for entrada in Main.ENTRADAS_BESTIARIO:
		nomes.append(entrada.criatura.nome)
	_checar("Zombie" in nomes, "o Zombie tem página no bestiário")


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
