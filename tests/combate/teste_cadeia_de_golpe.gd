extends TesteBase
## Cadeia do corpo a corpo: quantos golpes a ação vale e quando o 2º J pede a outra mão.


func _initialize() -> void:
	var ficha := _ficha()
	_checar(CadeiaDeGolpe.golpes_na_acao(ficha, false) == 1, "nível 1: um golpe")
	_checar(CadeiaDeGolpe.golpes_na_acao(ficha, true) == 2, "Surto no nível 1 dobra para dois")
	ficha.nivel = Ficha.NIVEL_ATAQUE_EXTRA
	_checar(CadeiaDeGolpe.golpes_na_acao(ficha, false) == 2, "Ataque Extra: dois golpes")
	_checar(CadeiaDeGolpe.golpes_na_acao(ficha, true) == 4, "Surto com Ataque Extra: quatro")
	_checar(CadeiaDeGolpe.golpes_na_acao(null, false) == 1, "sem ficha: um golpe")
	var curta: Arma = load("res://data/armas/espada_curta.tres")
	var adaga: Arma = load("res://data/armas/adaga.tres")
	var arco: Arma = load("res://data/armas/arco_curto.tres")
	_checar(not CadeiaDeGolpe.pede_duas_armas(curta, adaga, ficha, false), "sem ação bônus e sem Corte Duplo, não pede extra")
	_checar(CadeiaDeGolpe.pede_duas_armas(curta, adaga, ficha, true), "ação bônus livre pede o extra das duas leves")
	_checar(not CadeiaDeGolpe.pede_duas_armas(arco, adaga, ficha, true), "arma de disparo não pede extra de mão")
	ficha.armas_dominadas.append(adaga.nome)
	_checar(CadeiaDeGolpe.tem_corte_duplo(ficha, curta, adaga), "dominar a adaga liga o Corte Duplo")
	_checar(CadeiaDeGolpe.pede_duas_armas(curta, adaga, ficha, false), "Corte Duplo pede extra sem ação bônus")
	_terminar("cadeia de golpe")


func _ficha() -> Ficha:
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	return Ficha.new(classe, classe.atributos_sugeridos, "Teste")
