extends EstadoOoze
## Pseudópode: primeiro o aviso (para, olha e brilha); depois o golpe só acerta na janela em
## que o braço de gosma está esticado (quadros 2 e 3 da animação de 5 quadros a 10 fps).

## Quando o Pseudópode começa e para de acertar (s desde o início do ataque).
const INICIO_ACERTO := 0.2
const FIM_ACERTO := 0.35

var _tempo: float = 0.0
var _ligado: bool = false
var _comecou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	_comecou = false
	iniciar_aviso()


func sair() -> void:
	ooze.encerrar_aviso()
	ooze.desligar_pseudopode()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		ooze.iniciar_ataque()
		return
	_tempo += delta
	var na_janela := _tempo >= INICIO_ACERTO and _tempo < FIM_ACERTO
	if na_janela and not _ligado:
		ooze.ligar_pseudopode()
		_ligado = true
	elif not na_janela and _ligado:
		ooze.desligar_pseudopode()
		_ligado = false
	if ooze.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
