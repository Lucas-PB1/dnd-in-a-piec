extends TesteBase
## Armas mágicas +1, +2 e +3: bônus no ataque e no dano, sem Corrosão, nome, cor, save e saque.


func _initialize() -> void:
	var adaga := load("res://data/armas/adaga.tres") as Arma
	var ficha := Ficha.new(load("res://data/classe_guerreiro.tres") as ClasseRPG, {&"forca": 15, &"destreza": 14, &"constituicao": 14, &"inteligencia": 10, &"sabedoria": 10, &"carisma": 10}, "Teste")
	var magica := adaga.com_bonus_magico(2)
	_checar(magica.nome == "Adaga +2" and magica.bonus_magico == 2, "o nome ganha o bônus e o bônus fica na arma")
	_checar(adaga.bonus_magico == 0 and adaga.nome == "Adaga", "a arma original não muda")
	_checar(not magica.corroivel, "arma mágica não sofre Corrosão")
	_checar(magica.cor_do_brilho() == Arma.CORES_MAGICAS[2] and adaga.cor_do_brilho() == Color.WHITE, "cada nível tem a sua cor; a comum não brilha")
	_checar(ficha.bonus_ataque(magica) == ficha.bonus_ataque(adaga) + 2, "+2 soma 2 no ataque")
	_checar(ficha.dado_dano(magica).bonus == ficha.dado_dano(adaga).bonus + 2, "+2 soma 2 no dano")
	_checar(ficha.dado_dano(magica, false, true).bonus == mini(ficha.bonus_dano(magica), 0) + 2, "no ataque extra o bônus mágico ainda soma")
	_checar(adaga.com_bonus_magico(0).nome == "Adaga", "bônus 0 devolve só a cópia")
	_checar(Arma.separar_nome_magico("Espada Curta +3") == ["Espada Curta", 3] and Arma.separar_nome_magico("Adaga") == ["Adaga", 0], "o nome mágico se separa em base e bônus")
	_testar_save(magica)
	_testar_saque()
	_terminar("armas mágicas +1/+2/+3")


func _testar_save(magica: Arma) -> void:
	Salvamento.caminho = "user://save_teste_magica.json"
	var inventario := Inventario.new()
	inventario.adicionar(magica)
	var ficha := Ficha.new(load("res://data/classe_guerreiro.tres") as ClasseRPG, {&"forca": 15, &"destreza": 14, &"constituicao": 14, &"inteligencia": 10, &"sabedoria": 10, &"carisma": 10}, "Teste")
	var dados := Salvamento.para_dicionario(ficha, inventario, 1)
	var novo := Inventario.new()
	Salvamento.restaurar_inventario(dados, novo)
	var volta := novo.itens[0] as Arma if novo.itens.size() == 1 else null
	_checar(volta != null and volta.nome == "Adaga +2" and volta.bonus_magico == 2, "a arma mágica volta do save com o bônus")
	Salvamento.apagar()


func _testar_saque() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var por_bonus := [0, 0, 0, 0]
	for i in 600:
		var arma := Saque.arma(20, rng) as Arma
		if arma != null:
			por_bonus[arma.bonus_magico] += 1
	_checar(por_bonus[0] > por_bonus[1] and por_bonus[1] > por_bonus[2], "no saque, o comum vem mais que o +1 e o +1 mais que o +2")
	_checar(por_bonus[1] + por_bonus[2] + por_bonus[3] > 0, "o saque às vezes traz arma mágica")
