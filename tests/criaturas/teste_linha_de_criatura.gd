extends TesteBase
## Capacidade compartilhada de salvaguarda em área (`LinhaDeCriatura`).
## Integração no mundo: `teste_ankheg` e `teste_quimera`.
## godot --headless --debug --path . --script res://tests/criaturas/teste_linha_de_criatura.gd


func _initialize() -> void:
	_testar_ficha_e_dimensoes()
	_testar_recarga()
	_testar_alvo_na_area()
	print("PASSOU: todos os testes da linha de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha_e_dimensoes() -> void:
	var sem := CriaturaRPG.new()
	_checar(not LinhaDeCriatura.tem_linha(sem), "sem CD: sem linha")
	var ankheg: CriaturaRPG = load("res://data/ankheg.tres")
	_checar(LinhaDeCriatura.tem_linha(ankheg), "Ankheg tem Borrifo")
	var linha := LinhaDeCriatura.new(ankheg)
	_checar(linha.pronta() and is_equal_approx(linha.comprimento_px(), EscalaDnd.pes_para_pixels(30.0)),
		"pronta e comprimento 30 pés")
	_checar(is_equal_approx(linha.largura_px(), EscalaDnd.pes_para_pixels(5.0)), "largura 5 pés")
	var golpe := linha.golpe()
	_checar(golpe.cd_salvaguarda == 12 and golpe.atributo_salvaguarda == Atributos.DESTREZA
		and golpe.dano.texto() == "4d6" and golpe.tipo_dano == TiposDano.ACIDO,
		"golpe do Borrifo vem da ficha")
	var quimera: CriaturaRPG = load("res://data/quimera.tres")
	_checar(LinhaDeCriatura.tem_linha(quimera), "Quimera tem Sopro")


func _testar_recarga() -> void:
	var ficha := CriaturaRPG.new()
	ficha.linha_cd = 12
	ficha.linha_recarga = 0
	var sem_recarga := LinhaDeCriatura.new(ficha)
	sem_recarga.consumir()
	_checar(sem_recarga.pronta(), "recarga 0: consumir não gasta")
	ficha.linha_recarga = 7
	var lenta := LinhaDeCriatura.new(ficha)
	lenta.consumir()
	_checar(not lenta.pronta(), "recarga 7: gasta")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	lenta.passar_tempo(EscalaDnd.RODADA_SEGUNDOS, rng)
	_checar(not lenta.pronta(), "1d6 nunca passa de 6: recarga 7 não volta")
	ficha.linha_recarga = 1
	var furiosa := LinhaDeCriatura.new(ficha)
	furiosa.consumir()
	furiosa.passar_tempo(EscalaDnd.RODADA_SEGUNDOS * 0.5, rng, 0.5)
	_checar(furiosa.pronta(), "fator 0,5: meia rodada do livro já recarrega")


func _testar_alvo_na_area() -> void:
	var ficha: CriaturaRPG = (load("res://data/ankheg.tres") as CriaturaRPG).duplicate()
	var linha := LinhaDeCriatura.new(ficha)
	var alcance := 36.0 + linha.comprimento_px()
	_checar(linha.alvo_na_area(alcance, 36.0, 0.0, 80.0), "na borda da linha")
	_checar(not linha.alvo_na_area(alcance + 1.0, 36.0, 0.0, 80.0), "além da linha")
	_checar(not linha.alvo_na_area(alcance, 36.0, 81.0, 80.0), "desnível demais")
	linha.consumir()
	_checar(linha.pronta() == false, "depois de consumir não está pronta")
	# alvo_na_area não consulta pronta — a feature combina com pronta().
	_checar(linha.alvo_na_area(alcance, 36.0, 0.0, 80.0), "área continua válida sem pronta")
