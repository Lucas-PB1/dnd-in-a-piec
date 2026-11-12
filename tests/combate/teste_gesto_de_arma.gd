extends TesteBase
## Regra pura do gesto: disparo, arremesso, carga e munição, sem o herói na cena.


func _initialize() -> void:
	var adaga: Arma = load("res://data/armas/adaga.tres")
	var arco: Arma = load("res://data/armas/arco_curto.tres")
	_checar(GestoDeArma.e_arremesso(adaga) and not GestoDeArma.e_disparo(adaga), "adaga é arremesso")
	_checar(GestoDeArma.e_disparo(arco) and not GestoDeArma.e_arremesso(arco), "arco é disparo")
	_checar(not GestoDeArma.sai_no_gesto(null), "mão vazia não tem gesto")
	var ficha := _ficha()
	_checar(is_equal_approx(GestoDeArma.teto(false, ficha), 1.0), "arremesso enche até 1")
	_checar(is_equal_approx(GestoDeArma.teto(true, ficha), ficha.teto_da_carga()), "disparo usa o teto da ficha")
	_checar(is_equal_approx(GestoDeArma.tempo_ate_o_teto(false, ficha), Ficha.TEMPO_CARGA_DISPARO), "arremesso usa o tempo cheio")
	_checar(is_equal_approx(GestoDeArma.tempo_ate_o_teto(true, ficha), ficha.tempo_ate_teto_da_carga()), "disparo segue a Destreza")
	var mochila := Inventario.new()
	_checar(not GestoDeArma.tem_municao(mochila, arco), "sem flecha não há munição")
	mochila.adicionar(load("res://data/municoes/flecha.tres"))
	_checar(GestoDeArma.tem_municao(mochila, arco), "com flecha há munição")
	_checar(not GestoDeArma.ignora_inimigo_perto(ficha, arco), "sem talento, inimigo perto conta")
	ficha.talentos.append(Ficha.TALENTO_ATIRADOR_DE_ELITE)
	_checar(GestoDeArma.ignora_inimigo_perto(ficha, arco), "Atirador de Elite ignora o perto")
	_terminar("gesto de arma")


func _ficha() -> Ficha:
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	return Ficha.new(classe, classe.atributos_sugeridos, "Teste")
