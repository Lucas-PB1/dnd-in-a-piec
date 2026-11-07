extends EstadoGoblin
## Ronda: anda devagar até um extremo (a patrulha da ficha, a partir de onde começou) e volta
## a Parado, que depois manda para o outro lado. Percebeu o alvo, persegue.

var _destino: float = 0.0


func entrar() -> void:
	_destino = goblin.proximo_extremo_patrulha()
	goblin.tocar(&"correr")


func processar_fisica(_delta: float) -> void:
	if goblin.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
		return
	if goblin.andar_ate(_destino):
		trocar_para.emit(&"Parado")
