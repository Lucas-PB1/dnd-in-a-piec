extends TesteBase
## Capacidade compartilhada de Fuga Ágil (`FugaAgilDeCriatura`).
## Desengajar no mundo: `teste_goblin` / `teste_goblin_guerreiro`.
## godot --headless --debug --path . --script res://tests/criaturas/teste_fuga_agil_de_criatura.gd


func _initialize() -> void:
	_testar_ficha_e_tempo()
	print("PASSOU: todos os testes da fuga ágil de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha_e_tempo() -> void:
	var sem := CriaturaRPG.new()
	_checar(not FugaAgilDeCriatura.tem_fuga_agil(sem), "sem traço")
	var minion: CriaturaRPG = load("res://data/goblin_minion.tres")
	_checar(FugaAgilDeCriatura.tem_fuga_agil(minion), "Minion tem Fuga Ágil")
	var fuga := FugaAgilDeCriatura.new(minion, 15.0)
	_checar(fuga.tem() and is_equal_approx(fuga.recuo_pes, 15.0), "recuo 15 pés")
	var deslocamento := minion.deslocamento_pes
	var velocidade := fuga.velocidade_px(deslocamento)
	_checar(velocidade > 0.0, "velocidade de Disparada > 0")
	var esperado := EscalaDnd.pes_para_pixels(15.0) / velocidade
	_checar(is_equal_approx(fuga.tempo_de_fuga(deslocamento), esperado), "tempo = distância / velocidade")
	_checar(is_equal_approx(fuga.tempo_de_fuga(0.0), 0.0), "sem deslocamento: tempo 0")
