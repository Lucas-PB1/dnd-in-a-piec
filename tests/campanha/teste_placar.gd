extends TesteBase
## Placar: abates, tempo de fase/run, recordes locais e linha na HUD.
## godot --headless --debug --path . --script res://tests/campanha/teste_placar.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regra()
	await _testar_na_main()
	print("PASSOU: placar kills e timer" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_regra() -> void:
	var placar := Placar.new()
	placar.caminho = "user://placar_teste.cfg"
	DirAccess.remove_absolute(placar.caminho)
	placar.iniciar_run()
	placar.iniciar_fase(1)
	_checar(placar.texto_hud() == "Abates 0 · Fase 0:00 · Run 0:00", "HUD começa zerada")
	placar.avancar(65.0)
	placar.registrar_morte()
	placar.registrar_morte()
	_checar(placar.kills_fase == 2 and placar.kills_run == 2, "abates somam na fase e na run")
	_checar(placar.texto_hud() == "Abates 2 · Fase 1:05 · Run 1:05", "tempos formatados mm:ss")
	_checar(placar.fechar_fase(true, false), "primeiro tempo da fase é recorde")
	_checar(is_equal_approx(placar.melhor_da_fase(1), 65.0), "recorde da fase 1 gravado")
	placar.iniciar_fase(1)
	placar.avancar(70.0)
	_checar(not placar.fechar_fase(true, false), "tempo pior não substitui o recorde")
	placar.iniciar_fase(1)
	placar.avancar(50.0)
	_checar(placar.fechar_fase(true, false) and is_equal_approx(placar.melhor_da_fase(1), 50.0),
		"tempo melhor atualiza o recorde")
	placar.iniciar_run()
	placar.iniciar_fase(2)
	placar.avancar(10.0)
	placar.registrar_morte()
	placar.fechar_fase(true, true)
	_checar(is_equal_approx(placar.melhor_run_s, 10.0), "run completa grava melhor run")
	var outro := Placar.new()
	outro.caminho = placar.caminho
	outro.carregar()
	_checar(is_equal_approx(outro.melhor_da_fase(1), 50.0) and is_equal_approx(outro.melhor_run_s, 10.0),
		"recordes voltam do arquivo")
	_checar("Abates: 1 nesta fase" in placar.texto_resumo(), "resumo cita abates")
	DirAccess.remove_absolute(placar.caminho)


func _testar_na_main() -> void:
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	await physics_frame
	await physics_frame
	var rotulo := cena.get_node("Hud").find_child("Placar", true, false) as Label
	_checar(rotulo != null and rotulo.visible and "Abates" in rotulo.text, "HUD mostra o placar na fase 1")
	var antes := cena._placar.kills_fase
	cena._placar.registrar_morte()
	cena._mostrar_placar()
	_checar(cena._placar.kills_fase == antes + 1 and str(cena._placar.kills_fase) in rotulo.text,
		"abate atualiza a linha do placar")
	cena._ids_da_cota.clear()
	var tempo_antes := cena._placar.tempo_fase_s
	await _esperar(3)
	_checar(is_equal_approx(cena._placar.tempo_fase_s, tempo_antes),
		"sem inimigos da cota o timer não anda")
	cena.free()
	await process_frame


func _esperar(quadros: int) -> void:
	for i in quadros:
		await process_frame
