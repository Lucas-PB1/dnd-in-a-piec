extends TesteBase
## Capacidade compartilhada de furtividade (`FurtividadeDeCriatura`).
## Esconder/revelar e estado Escondido: `teste_goblin`.
## godot --headless --debug --path . --script res://tests/criaturas/teste_furtividade_de_criatura.gd


func _initialize() -> void:
	_testar_ficha()
	_testar_rolagem_e_emboscada()
	print("PASSOU: todos os testes da furtividade de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var sem := CriaturaRPG.new()
	_checar(not FurtividadeDeCriatura.tem_furtividade(sem), "sem traço")
	var minion: CriaturaRPG = load("res://data/goblin_minion.tres")
	_checar(FurtividadeDeCriatura.tem_furtividade(minion) and minion.bonus_furtividade == 6, "Minion +6")
	var warrior: CriaturaRPG = load("res://data/goblin_warrior.tres")
	_checar(warrior.esconde_de_novo and FurtividadeDeCriatura.new(warrior).esconde_de_novo(),
		"Warrior esconde de novo")
	_checar(not FurtividadeDeCriatura.new(minion).esconde_de_novo(), "Minion não esconde de novo")


func _testar_rolagem_e_emboscada() -> void:
	var ficha: CriaturaRPG = (load("res://data/goblin_minion.tres") as CriaturaRPG).duplicate()
	var furt := FurtividadeDeCriatura.new(ficha)
	furt.percepcao_passiva = 99
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	furt.rolar(rng)
	_checar(furt.teste_secreto_feito() and furt.foi_percebido(), "passiva alta: percebido")
	furt.reiniciar()
	furt.percepcao_passiva = 0
	furt.rolar(rng)
	_checar(furt.teste_secreto_feito() and not furt.foi_percebido(), "passiva 0: não percebido")
	_checar(is_equal_approx(furt.aviso_do_ataque(0.5), 0.5), "sem emboscada: aviso normal")
	furt.marcar_emboscada()
	_checar(furt.tem_emboscada() and is_equal_approx(furt.aviso_do_ataque(0.5), 0.0), "emboscada: sem aviso")
	_checar(furt.consumir_emboscada() and not furt.tem_emboscada(), "consome emboscada")
	_checar(not furt.consumir_emboscada(), "já consumida")
