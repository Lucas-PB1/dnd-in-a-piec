extends TesteBase
## Armaduras e escudos mágicos +1/+2/+3: CA, sem Corrosão, nome, cor, save e loja.


func _initialize() -> void:
	_testar_armadura()
	_testar_escudo()
	_testar_save()
	_testar_loja()
	_terminar("armaduras e escudos mágicos +1/+2/+3")


func _ficha() -> Ficha:
	return Ficha.new(load("res://data/classe_guerreiro.tres") as ClasseRPG, {
		&"forca": 15, &"destreza": 14, &"constituicao": 14,
		&"inteligencia": 10, &"sabedoria": 10, &"carisma": 10,
	}, "Teste")


func _testar_armadura() -> void:
	var cota := load("res://data/armaduras/cota_malha.tres") as Armadura
	var magica := cota.com_bonus_magico(2)
	_checar(magica.nome == "%s +2" % cota.nome and magica.bonus_magico == 2, "o nome ganha o bônus")
	_checar(cota.bonus_magico == 0, "a armadura original não muda")
	_checar(not magica.corroivel, "armadura mágica não sofre Corrosão")
	_checar(magica.cor_do_brilho() == Arma.CORES_MAGICAS[2], "brilho +2")
	var ficha := _ficha()
	_checar(ficha.classe_armadura(magica) == ficha.classe_armadura(cota) + 2, "+2 soma 2 na CA")
	_checar(magica.texto_ca().contains(str(cota.ca_base + 2)), "texto_ca inclui o bônus")
	_checar(cota.com_bonus_magico(0).nome == cota.nome, "bônus 0 devolve só a cópia")


func _testar_escudo() -> void:
	var escudo := load("res://data/armaduras/escudo.tres") as Armadura
	var magico := escudo.com_bonus_magico(1)
	var ficha := _ficha()
	var cota := load("res://data/armaduras/cota_malha.tres") as Armadura
	_checar(ficha.classe_armadura(cota, magico) == ficha.classe_armadura(cota, escudo) + 1,
		"escudo +1 soma 1 na CA")
	_checar(not magico.corroivel and magico.nome.ends_with(" +1"), "escudo mágico sem corrosão")


func _testar_save() -> void:
	Salvamento.caminho = "user://save_teste_armadura_magica.json"
	var inventario := Inventario.new()
	var cota := (load("res://data/armaduras/cota_malha.tres") as Armadura).com_bonus_magico(3)
	inventario.adicionar(cota)
	var dados := Salvamento.para_dicionario(_ficha(), inventario, 1)
	var novo := Inventario.new()
	Salvamento.restaurar_inventario(dados, novo)
	var volta := novo.itens[0] as Armadura if novo.itens.size() == 1 else null
	_checar(volta != null and volta.bonus_magico == 3 and volta.nome.ends_with(" +3"),
		"armadura mágica volta do save")
	Salvamento.apagar()


func _testar_loja() -> void:
	var cota := load("res://data/armaduras/cota_malha.tres") as Armadura
	var magica := cota.com_bonus_magico(1)
	_checar(Loja.preco(magica) == Loja.preco(cota) + Loja.EXTRA_POR_BONUS_MAGICO[1],
		"armadura mágica custa o extra do bônus")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var viu_magica := false
	for i in 80:
		for item in Loja.sortear_estoque(9, rng):
			if item is Armadura and (item as Armadura).bonus_magico > 0:
				viu_magica = true
				break
		if viu_magica:
			break
	_checar(viu_magica, "a loja às vezes vende armadura ou escudo mágico")
