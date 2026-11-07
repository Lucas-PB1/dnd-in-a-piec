extends EstadoGoblin
## Parado, esperando perceber um alvo (Visão no Escuro). Quem patrulha (ficha) espera um
## instante e vai até o outro extremo da ronda.

## Quanto fica parado antes de seguir a patrulha (s).
const PAUSA_ANTES_DE_PATRULHAR := 1.5

var _espera: float = 0.0


func entrar() -> void:
	_espera = 0.0
	goblin.parar()
	goblin.tocar(&"parado")


func processar_fisica(delta: float) -> void:
	if goblin.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
		return
	if not goblin.quer_patrulhar():
		return
	_espera += delta
	if _espera >= PAUSA_ANTES_DE_PATRULHAR:
		trocar_para.emit(&"Patrulhando")
