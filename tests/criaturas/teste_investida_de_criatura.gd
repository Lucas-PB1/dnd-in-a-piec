extends TesteBase
## Capacidade compartilhada de investida/chifrada (`InvestidaDeCriatura`).
## Integração no mundo: `teste_minotauro` e `teste_quimera`.
## godot --headless --debug --path . --script res://tests/criaturas/teste_investida_de_criatura.gd


func _initialize() -> void:
	_testar_ficha_e_carreira()
	_testar_recarga()
	_testar_quer_investir()
	print("PASSOU: todos os testes da investida de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha_e_carreira() -> void:
	var sem := CriaturaRPG.new()
	_checar(not InvestidaDeCriatura.tem_chifrada(sem), "sem dano: sem chifrada")
	var mino: CriaturaRPG = load("res://data/minotauro.tres")
	_checar(InvestidaDeCriatura.tem_chifrada(mino), "Minotauro tem chifrada")
	var investida := InvestidaDeCriatura.new(mino)
	_checar(investida.pronta() and is_equal_approx(investida.carreira_px(), EscalaDnd.pes_para_pixels(10.0)),
		"pronta e carreira 10 pés")
	_checar(not investida.carreira_completa(EscalaDnd.pes_para_pixels(9.0)), "ainda sem carreira")
	_checar(investida.carreira_completa(EscalaDnd.pes_para_pixels(10.0)), "carreira completa")
	var com := investida.golpe(true)
	_checar(com.tem(Proficiencias.EFEITO_DERRUBADA), "com carreira: derruba")
	var quimera: CriaturaRPG = load("res://data/quimera.tres")
	_checar(InvestidaDeCriatura.tem_chifrada(quimera), "Quimera tem cabeçada")


func _testar_recarga() -> void:
	var ficha := CriaturaRPG.new()
	ficha.chifrada_dano = "1d6"
	ficha.chifrada_recarga = 0
	var sem_recarga := InvestidaDeCriatura.new(ficha)
	sem_recarga.consumir()
	_checar(sem_recarga.pronta(), "recarga 0: consumir não gasta")
	ficha.chifrada_recarga = 7
	var lenta := InvestidaDeCriatura.new(ficha)
	lenta.consumir()
	_checar(not lenta.pronta(), "recarga 7: gasta")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	lenta.passar_tempo(EscalaDnd.RODADA_SEGUNDOS, rng)
	_checar(not lenta.pronta(), "1d6 nunca passa de 6: recarga 7 não volta")


func _testar_quer_investir() -> void:
	var ficha: CriaturaRPG = (load("res://data/minotauro.tres") as CriaturaRPG).duplicate()
	var investida := InvestidaDeCriatura.new(ficha)
	var minima := investida.distancia_minima_px(30.0)
	_checar(investida.quer_investir(minima, 30.0, 320.0, 0.0, 64.0, true, true), "na janela mínima")
	_checar(not investida.quer_investir(minima - 1.0, 30.0, 320.0, 0.0, 64.0, true, true), "perto demais")
	_checar(not investida.quer_investir(minima, 30.0, 320.0, 100.0, 64.0, true, true), "altura diferente")
	investida.consumir()
	_checar(not investida.quer_investir(minima, 30.0, 320.0, 0.0, 64.0, true, true), "sem chifrada pronta")
