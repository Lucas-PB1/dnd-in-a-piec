extends EstadoOoze
## Foi acertado: treme (animação de dano) e volta a perseguir quando ela acaba.


func entrar() -> void:
	ooze.parar()
	ooze.desligar_pseudopode()
	ooze.tocar(&"dano")


func processar_fisica(_delta: float) -> void:
	if ooze.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
