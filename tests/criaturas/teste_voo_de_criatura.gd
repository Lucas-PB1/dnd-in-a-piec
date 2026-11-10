extends TesteBase
## Capacidade compartilhada de voo (`VooDeCriatura`).
## Integração: `teste_quimera` (padrão Voando / Mergulhando).
## godot --headless --debug --path . --script res://tests/criaturas/teste_voo_de_criatura.gd


func _initialize() -> void:
	_testar_ficha_e_velocidade()
	_testar_sobre_o_alvo()
	print("PASSOU: todos os testes do voo de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha_e_velocidade() -> void:
	var sem := CriaturaRPG.new()
	_checar(not VooDeCriatura.tem_voo(sem), "sem voo_pes")
	var quimera: CriaturaRPG = load("res://data/quimera.tres")
	_checar(VooDeCriatura.tem_voo(quimera) and is_equal_approx(quimera.voo_pes, 60.0), "Quimera voa 60 pés")
	var voo := VooDeCriatura.new(quimera, 150.0)
	_checar(voo.tem() and is_equal_approx(voo.velocidade_px(), EscalaDnd.deslocamento_para_velocidade(60.0)),
		"velocidade = 60 pés/rodada")
	_checar(is_equal_approx(voo.velocidade_horizontal_desejada(100.0), voo.velocidade_px()), "longe: voa para a direita")
	_checar(is_equal_approx(voo.velocidade_horizontal_desejada(10.0), 0.0), "em cima: vx 0")
	_checar(is_equal_approx(voo.altura_alvo_y(300.0), 150.0), "altura alvo y")


func _testar_sobre_o_alvo() -> void:
	var ficha: CriaturaRPG = (load("res://data/quimera.tres") as CriaturaRPG).duplicate()
	var voo := VooDeCriatura.new(ficha, 150.0)
	var alvo := Vector2(400, 300)
	_checar(not voo.sobre_o_alvo(Vector2(200, 300), alvo), "longe na horizontal")
	_checar(not voo.sobre_o_alvo(Vector2(400, 280), alvo), "ainda baixo")
	_checar(voo.sobre_o_alvo(Vector2(400, 300 - 150.0 * VooDeCriatura.FRACAO_ALTURA_MINIMA), alvo),
		"em cima e na altura mínima")
