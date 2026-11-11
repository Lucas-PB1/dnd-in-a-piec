extends TesteBase
## Deslocamento vem da ficha (livro): Ooze 10, Zumbi 20, maioria 30, Minotauro 40; voo/escavação à parte.
## godot --headless --debug --path . --script res://tests/criaturas/teste_deslocamento_criaturas.gd

const FICHAS_PES: Dictionary = {
	"res://data/gray_ooze.tres": 10.0,
	"res://data/zombie.tres": 20.0,
	"res://data/goblin_minion.tres": 30.0,
	"res://data/goblin_warrior.tres": 30.0,
	"res://data/kobold_warrior.tres": 30.0,
	"res://data/hobgoblin_warrior.tres": 30.0,
	"res://data/bugbear_warrior.tres": 30.0,
	"res://data/skeleton.tres": 30.0,
	"res://data/ankheg.tres": 30.0,
	"res://data/wight.tres": 30.0,
	"res://data/quimera.tres": 30.0,
	"res://data/minotauro.tres": 40.0,
}


func _initialize() -> void:
	_testar_fichas()
	_testar_velocidade_e_passada()
	_terminar("deslocamento por ficha")


func _testar_fichas() -> void:
	for caminho in FICHAS_PES:
		var ficha := load(caminho) as CriaturaRPG
		var esperado: float = FICHAS_PES[caminho]
		_checar(
			ficha != null and is_equal_approx(ficha.deslocamento_pes, esperado),
			"%s anda %.0f pés" % [caminho.get_file(), esperado]
		)
	var ankheg := load("res://data/ankheg.tres") as CriaturaRPG
	_checar(is_equal_approx(ankheg.escavacao_pes, 10.0), "Ankheg escava 10 pés")
	var quimera := load("res://data/quimera.tres") as CriaturaRPG
	_checar(is_equal_approx(quimera.voo_pes, 60.0), "Quimera voa 60 pés")


func _testar_velocidade_e_passada() -> void:
	var condicoes := CondicoesComponent.new()
	var lenta := load("res://data/gray_ooze.tres") as CriaturaRPG
	var media := load("res://data/goblin_minion.tres") as CriaturaRPG
	var rapida := load("res://data/minotauro.tres") as CriaturaRPG
	var v_ooze := MontagemDeCriatura.velocidade_andar(lenta, condicoes)
	var v_goblin := MontagemDeCriatura.velocidade_andar(media, condicoes)
	var v_mino := MontagemDeCriatura.velocidade_andar(rapida, condicoes)
	_checar(v_ooze < v_goblin and v_goblin < v_mino, "Ooze < Goblin < Minotauro em px/s")
	_checar(is_equal_approx(v_ooze * 3.0, v_goblin), "10 pés é 1/3 de 30 pés")
	_checar(
		is_equal_approx(MontagemDeCriatura.ritmo_da_passada(v_goblin, v_goblin, &"andar"), 1.0),
		"passada 1 na velocidade da ficha"
	)
	_checar(
		MontagemDeCriatura.ritmo_da_passada(v_goblin * 2.0, v_goblin, &"andar") > 1.5,
		"Disparada acelera a passada"
	)
	_checar(
		is_equal_approx(MontagemDeCriatura.ritmo_da_passada(v_goblin, v_goblin, &"atacar"), 1.0),
		"fora de andar a passada não muda"
	)
	condicoes.free()
