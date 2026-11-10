extends TesteBase
## As regras puras dos talentos do herói (features/jogador/talentos/): recargas, Sorte, dados de vida, veneno,
## janela de defesa e Investida. Sem nós: rodam direto.
## godot --headless --debug --path . --script res://tests/heroi/teste_regras_do_heroi.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_recargas()
	_testar_sorte()
	_testar_dados_de_vida()
	_testar_veneno()
	_testar_janela_de_defesa()
	_testar_investida()
	print("PASSOU: regras puras dos talentos do herói" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _ficha(talentos: Array[StringName]) -> Ficha:
	var ficha := Ficha.new(load("res://data/classe_guerreiro.tres"), {Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 14})
	ficha.definir_nivel_inicial(4)
	ficha.talentos.assign(talentos)
	return ficha


func _testar_recargas() -> void:
	var recargas := RecargasPorRodada.new()
	_checar(not recargas.em_recarga(&"x"), "um efeito nunca gasto não espera")
	recargas.gastar(&"x")
	_checar(recargas.em_recarga(&"x"), "gastar começa a espera")
	recargas.passar(EscalaDnd.RODADA_SEGUNDOS * 0.5)
	_checar(recargas.em_recarga(&"x"), "meia rodada depois ainda espera")
	recargas.passar(EscalaDnd.RODADA_SEGUNDOS)
	_checar(not recargas.em_recarga(&"x"), "passada a rodada, o efeito volta")


func _testar_sorte() -> void:
	var sem := _ficha([])
	var com := _ficha([Ficha.TALENTO_SORTUDO])
	var sorte := SorteDoHeroi.new()
	_checar(SorteDoHeroi.total(sem) == 0 and SorteDoHeroi.total(com) == 2, "a sorte é a proficiência com o talento e zero sem ele")
	sorte.repor(com)
	_checar(not sorte.armar(sem, true) and not sorte.armar(com, false), "sem talento ou com o herói caído não arma")
	_checar(sorte.armar(com, true) and not sorte.armar(com, true), "arma uma vez e não de novo enquanto armada")
	_checar(sorte.gastar() and sorte.pontos == 1 and not sorte.armada, "gastar usa 1 ponto e desarma")
	_checar(not sorte.gastar(), "sem estar armada, nada é gasto")


func _testar_dados_de_vida() -> void:
	var dados := DadosDeVidaDoHeroi.new()
	var ficha := _ficha([Ficha.TALENTO_DURAVEL])
	dados.repor(ficha)
	_checar(dados.restantes == 4, "o Durável de nível 4 tem 4 dados")
	_checar(dados.motivo_de_nao_poder(true, true) == "Vida cheia" and dados.motivo_de_nao_poder(false, false) == "Ação bônus" and dados.motivo_de_nao_poder(false, true) == "", "os motivos de não poder")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var cura := dados.gastar(10, rng)
	_checar(cura >= 1 and cura <= 10 and dados.restantes == 3, "gastar rola o dado e tira 1")
	dados.ao_subir_de_nivel(ficha, 3)
	_checar(dados.restantes == 4, "subir de nível não passa do total")


func _testar_veneno() -> void:
	var veneno := VenenoDoHeroi.new()
	var envenenador := _ficha([Ficha.TALENTO_ENVENENADOR])
	veneno.repor(envenenador)
	var espada: Arma = load("res://data/armas/espada_longa.tres")
	var maca: Arma = load("res://data/armas/maca.tres")
	_checar(veneno.tipo_disponivel(maca, false) == VenenoDoHeroi.POTENTE, "com doses, o potente vale em qualquer arma")
	veneno.aplicar(VenenoDoHeroi.POTENTE)
	_checar(veneno.doses == 1 and veneno.na_arma == VenenoDoHeroi.POTENTE, "aplicar gasta uma dose")
	var golpe := Golpe.new("g", 0, Dado.new(1, 6))
	veneno.aplicar_ao_golpe(golpe, envenenador)
	_checar(golpe.tem(Proficiencias.EFEITO_VENENO) and (golpe.efeito(Proficiencias.EFEITO_VENENO) as EfeitosDeTalento.VenenoPotente).cd == envenenador.cd_veneno(), "o golpe leva o veneno potente e a CD")
	_checar(not veneno.passar(VenenoDoHeroi.DURACAO - 1.0) and veneno.passar(2.0) and veneno.na_arma == &"", "o veneno seca depois de 15 s")
	var sem := VenenoDoHeroi.new()
	sem.repor(_ficha([]))
	_checar(sem.tipo_disponivel(espada, true) == VenenoDoHeroi.BASICO and sem.tipo_disponivel(maca, true) == &"" and sem.tipo_disponivel(espada, false) == &"",
		"sem doses, o básico só serve em arma cortante ou perfurante e com o item")


func _testar_janela_de_defesa() -> void:
	var janela := JanelaDeDefesa.new()
	_checar(janela.pronta() and janela.abrir() and janela.ativa() and not janela.abrir(), "abre uma vez")
	_checar(janela.passar(JanelaDeDefesa.DURACAO + 0.01) == JanelaDeDefesa.Evento.FECHOU and not janela.pronta(), "fecha em 0,75 s e começa a espera")
	_checar(janela.passar(JanelaDeDefesa.RECARGA + 0.01) == JanelaDeDefesa.Evento.PRONTA and janela.pronta(), "em 1 s volta a ficar pronta")
	janela.abrir()
	janela.cancelar()
	_checar(janela.pronta(), "cancelar zera a janela e a espera")


func _testar_investida() -> void:
	var investida := InvestidaDoHeroi.new()
	investida.medir(true, 150.0, 1, 0.3)
	_checar(not investida.carregada(), "300 ms correndo ainda não bastam")
	investida.medir(true, 150.0, 1, 0.3)
	_checar(investida.carregada(), "10 pés em linha reta carregam a investida")
	investida.medir(true, -150.0, 1, 0.1)
	_checar(not investida.carregada() and investida.corrida_px == 0.0, "virar zera a corrida")
	var golpe := Golpe.new("g", 0, Dado.new(1, 6))
	investida.aplicar(golpe)
	_checar(golpe.tem(Proficiencias.EFEITO_INVESTIDA) and not (golpe.efeito(Proficiencias.EFEITO_INVESTIDA) as EfeitosDeTalento.Investida).empurra, "no modo dano soma 1d8")
	investida.alternar()
	var empurra := Golpe.new("h", 0, Dado.new(1, 6))
	investida.aplicar(empurra)
	_checar((empurra.efeito(Proficiencias.EFEITO_INVESTIDA) as EfeitosDeTalento.Investida).empurra, "no modo empurrão empurra 10 pés")
