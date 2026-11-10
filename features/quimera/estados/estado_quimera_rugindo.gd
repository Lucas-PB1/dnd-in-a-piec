extends EstadoQuimera
## O rugido de entrada: a tela treme e, quando a animação acaba, ela parte para cima do herói.


func entrar() -> void:
	quimera.rugir()


func processar_fisica(_delta: float) -> void:
	quimera.parar()
	if quimera.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
