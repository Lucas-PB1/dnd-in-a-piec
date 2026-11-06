extends EstadoGoblin
## Golpe de adaga: só acerta enquanto o braço está esticado (quadros 2 e 3 da animação de 3
## quadros a 10 fps). Com Fuga Ágil, Desengaja logo depois.

## Quando o golpe começa e para de acertar (s desde o início do ataque).
const INICIO_ACERTO := 0.1
const FIM_ACERTO := 0.3

var _tempo: float = 0.0
var _ligado: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	goblin.iniciar_ataque()


func sair() -> void:
	goblin.desligar_golpe()


func processar_fisica(delta: float) -> void:
	_tempo += delta
	var na_janela := _tempo >= INICIO_ACERTO and _tempo < FIM_ACERTO
	if na_janela and not _ligado:
		goblin.ligar_golpe()
		_ligado = true
	elif not na_janela and _ligado:
		goblin.desligar_golpe()
		_ligado = false
	if goblin.animacao_terminou():
		trocar_para.emit(&"Desengajando" if goblin.tem_fuga_agil() else &"Perseguindo")
