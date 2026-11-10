extends TesteBase
## Teste das regras puras de D&D: Dado, Atributos, CompraDePontos e Ficha.
## godot --headless --debug --path . --script res://tests/regras/teste_regras_dnd.gd

const ROLAGENS := 300

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 1234
	_testar_dado()
	_testar_modificador()
	_testar_compra_de_pontos()
	_testar_ficha()
	_testar_pericias()
	_testar_armadilhas()
	_testar_fases()
	if _falhas == 0:
		print("PASSOU: todos os testes das regras de D&D")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_dado() -> void:
	var d6 := Dado.de_texto("1d6")
	_checar(d6 != null and d6.quantidade == 1 and d6.faces == 6, "lê '1d6'")
	_checar(Dado.de_texto("4D6") != null, "aceita 'D' maiúsculo")
	_checar(Dado.de_texto("d6") == null and Dado.de_texto("1x6") == null and Dado.de_texto("0d6") == null,
		"recusa textos inválidos")
	var vistos := {}
	var dentro := true
	for i in ROLAGENS:
		var r := d6.rolar(_rng)
		dentro = dentro and r >= 1 and r <= 6
		vistos[r] = true
	_checar(dentro and vistos.size() == 6, "1d6 dá de 1 a 6 e sai todos os valores")
	var dois_d8 := Dado.new(2, 8)
	_checar(dois_d8.minimo() == 2 and dois_d8.maximo() == 16 and dois_d8.texto() == "2d8", "2d8: mínimo, máximo e texto")


func _testar_modificador() -> void:
	var esperado := {3: -4, 7: -2, 8: -1, 9: -1, 10: 0, 11: 0, 12: 1, 13: 1, 14: 2, 15: 2, 18: 4, 20: 5}
	var certo := true
	for valor in esperado:
		certo = certo and Atributos.modificador(valor) == esperado[valor]
	_checar(certo, "modificador = (valor - 10) / 2 arredondado para baixo (tabela do livro)")
	_checar(Atributos.texto_modificador(15) == "+2" and Atributos.texto_modificador(8) == "-1"
		and Atributos.texto_modificador(10) == "+0", "texto do modificador com sinal")


func _testar_compra_de_pontos() -> void:
	var compra := CompraDePontos.new()
	_checar(compra.pontos_restantes() == 27, "começa com 27 pontos e tudo em 8")
	_checar(not compra.pode_diminuir(Atributos.FORCA), "não desce abaixo de 8")
	for i in 7:
		compra.aumentar(Atributos.FORCA)
	_checar(compra.valores[Atributos.FORCA] == 15 and compra.pontos_restantes() == 18, "subir de 8 a 15 custa 9")
	_checar(not compra.aumentar(Atributos.FORCA), "não passa de 15")
	_checar(compra.custo_para_aumentar(Atributos.DESTREZA) == 1, "8 -> 9 custa 1")
	for atributo in [Atributos.DESTREZA, Atributos.CONSTITUICAO]:
		for i in 7:
			compra.aumentar(atributo)
	_checar(compra.pontos_restantes() == 0, "três atributos em 15 gastam os 27")
	_checar(not compra.aumentar(Atributos.CARISMA), "sem pontos, não sobe mais nada")
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var sugestao := CompraDePontos.new()
	_checar(sugestao.aplicar(guerreiro.atributos_sugeridos) and sugestao.pontos_restantes() == 0,
		"sugestão do Guerreiro gasta exatamente 27")
	_checar(not sugestao.aplicar({Atributos.FORCA: 16}), "recusa valor acima de 15")
	_testar_builds_do_guerreiro(guerreiro)


func _testar_ficha() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var espada: Arma = load("res://data/armas/espada_curta.tres")
	var forte := Ficha.new(guerreiro, {Atributos.FORCA: 15, Atributos.DESTREZA: 10, Atributos.CONSTITUICAO: 14})
	_checar(forte.vida_maxima() == 12, "Guerreiro CON 14: vida = 10 + 2 = 12")
	var fragil := Ficha.new(guerreiro, {Atributos.CONSTITUICAO: 8})
	_checar(fragil.vida_maxima() == 9, "Guerreiro CON 8: vida = 10 - 1 = 9")
	_checar(forte.bonus_dano(espada) == 2 and forte.texto_dano(espada) == "1d6+2", "espada curta usa FOR quando é maior")
	var agil := Ficha.new(guerreiro, {Atributos.FORCA: 8, Atributos.DESTREZA: 15})
	_checar(agil.bonus_dano(espada) == 2, "acuidade: espada curta usa DES quando é maior")
	var sem_acuidade := espada.duplicate() as Arma
	sem_acuidade.acuidade = false
	_checar(agil.bonus_dano(sem_acuidade) == -1 and agil.texto_dano(sem_acuidade) == "1d6-1",
		"arma sem acuidade usa só FOR")
	var dentro := true
	for i in ROLAGENS:
		var dano := forte.rolar_dano(espada, _rng)
		dentro = dentro and dano >= 3 and dano <= 8
	_checar(dentro, "dano 1d6+2 fica entre 3 e 8")
	var fraco := Ficha.new(guerreiro, {Atributos.FORCA: 3, Atributos.DESTREZA: 3})
	var minimo_ok := true
	for i in ROLAGENS:
		minimo_ok = minimo_ok and fraco.rolar_dano(espada, _rng) >= Ficha.DANO_MINIMO
	_checar(minimo_ok, "dano nunca fica abaixo de 1")


func _testar_pericias() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	_checar(guerreiro.quantidade_pericias == 2 and guerreiro.pericias_escolhiveis.size() == 9,
		"Guerreiro escolhe 2 de 9 perícias")
	_checar(Pericia.PERCEPCAO in guerreiro.pericias_sugeridas and Pericia.ATLETISMO in guerreiro.pericias_sugeridas,
		"sugestão: Percepção e Atletismo")
	var ficha := Ficha.new(guerreiro, guerreiro.atributos_sugeridos)
	_checar(ficha.percepcao_passiva() == Pericia.PASSIVA_BASE + 1, "SAB 12 sem perícia: passiva 11")
	ficha.pericias = [Pericia.PERCEPCAO, Pericia.ATLETISMO]
	_checar(ficha.percepcao_passiva() == Pericia.PASSIVA_BASE + 1 + Ficha.BONUS_PROFICIENCIA,
		"com Percepção: passiva 13")
	_checar(ficha.bonus_pericia(Pericia.ATLETISMO) == 2 + Ficha.BONUS_PROFICIENCIA,
		"Atletismo com FOR 15: +4")
	_checar(Pericia.furtividade_passa(13, 13) and not Pericia.furtividade_passa(12, 13),
		"Furtividade igual à passiva continua escondido; abaixo, percebe")


func _testar_armadilhas() -> void:
	var pontos: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0), Vector2(200, 0)]
	var tipos: Array[StringName] = [&"ooze", &"minion"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var primeira := Armadilha.sortear(pontos, 2, tipos, rng)
	rng.seed = 1
	var de_novo := Armadilha.sortear(pontos, 2, tipos, rng)
	_checar(primeira.size() == 2 and _sorteios_iguais(primeira, de_novo), "a mesma semente repete pontos e tipos")
	var mudou := false
	for semente in range(2, 40):
		rng.seed = semente
		if not _sorteios_iguais(primeira, Armadilha.sortear(pontos, 2, tipos, rng)):
			mudou = true
			break
	_checar(mudou, "outra semente muda alguém")
	var dentro := true
	for escolha in primeira:
		dentro = dentro and escolha.posicao in pontos and escolha.tipo in tipos
	_checar(dentro, "só sai ponto e tipo que a fase ofereceu")


func _sorteios_iguais(um: Array[Dictionary], outro: Array[Dictionary]) -> bool:
	if um.size() != outro.size():
		return false
	for i in um.size():
		if um[i].posicao != outro[i].posicao or um[i].tipo != outro[i].tipo:
			return false
	return true


func _testar_fases() -> void:
	var quantidades: Array[int] = [1, 2, 3, 3, 4, 4, 4, 5, 2, 3]
	for i in quantidades.size():
		var fase: Fase = load("res://levels/fase_%d.tscn" % [i + 1]).instantiate()
		root.add_child(fase)
		var pode_warrior := &"warrior" in fase.tipos_permitidos
		_checar(fase.quantidade == quantidades[i] and fase.pontos_armadilha().size() > fase.quantidade,
			"fase %d ocupa %d e sobra ponto de armadilha" % [i + 1, fase.quantidade])
		_checar(pode_warrior == (i >= 3), "Warrior só entra no sorteio a partir da ruína")
		_checar(fase.indice == i + 1 and fase.ultima == (i == 9), "a última fase é o covil")
		fase.free()


## As três distribuições prontas do Guerreiro: armadura média, pesada e leve.
func _testar_builds_do_guerreiro(guerreiro: ClasseRPG) -> void:
	_checar(guerreiro.builds_sugeridos.size() == 3, "o Guerreiro tem 3 distribuições prontas")
	var esperados := {
		"Armadura média": [15, 14, 14, 10, 10, 8],
		"Armadura pesada": [15, 10, 14, 10, 14, 8],
		"Armadura leve": [10, 15, 14, 10, 14, 8],
	}
	for build in guerreiro.builds_sugeridos:
		var compra := CompraDePontos.new()
		_checar(compra.aplicar(build.atributos) and compra.pontos_restantes() >= 0, "%s cabe nos 27 pontos (sobram %d)" % [build.nome, compra.pontos_restantes()])
		var valores: Array = []
		for atributo in Atributos.TODOS:
			valores.append(build.atributos[atributo])
		_checar(valores == esperados.get(build.nome), "%s: FOR, DES, CON, INT, SAB, CAR como combinado" % build.nome)
