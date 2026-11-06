extends EstadoGoblin
## Arremessa uma adaga: o braço estica (a mesma animação do golpe) e a adaga sai no meio dele.

## Quando a adaga sai da mão (s desde o início).
const MOMENTO_SOLTURA := 0.15

var _tempo: float = 0.0
var _soltou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_soltou = false
	goblin.iniciar_ataque()


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if _tempo >= MOMENTO_SOLTURA and not _soltou:
		goblin.arremessar_adaga()
		_soltou = true
	if goblin.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
