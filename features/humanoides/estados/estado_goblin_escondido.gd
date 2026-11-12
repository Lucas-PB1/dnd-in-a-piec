extends EstadoGoblin
## Escondido até o teste secreto. Percebido: persegue. Não percebido: espera o corpo a corpo
## e ataca de surpresa. Sem alvo, fica invisível e parado.


func entrar() -> void:
	goblin.esconder()
	goblin.parar()
	goblin.tocar(&"parado")


func sair() -> void:
	goblin.revelar()


func processar_fisica(_delta: float) -> void:
	if not goblin.tem_furtividade():
		trocar_para.emit(&"Parado")
		return
	if not goblin.alvo_percebido():
		return
	if not goblin.teste_secreto_feito():
		goblin.rolar_furtividade()
	_decidir()


func _decidir() -> void:
	if goblin.foi_percebido():
		trocar_para.emit(&"Perseguindo")
	elif goblin.alvo_ao_alcance():
		goblin.marcar_emboscada()
		trocar_para.emit(&"Atacando")
