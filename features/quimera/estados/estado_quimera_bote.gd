extends EstadoQuimera
## Bote: depois do aviso salta em arco sobre o herói e, na descida, a garra que derruba sai. Ao pisar no chão volta a perseguir.

## Tempo mínimo no ar antes de aceitar o pouso (s): no 1º quadro ainda "está no chão".
const TEMPO_MINIMO := 0.1
## Se algo der errado, volta a perseguir depois deste tempo (s).
const TEMPO_MAXIMO := 2.0
## Ritmo da animação `pular` no bote (o salto dura `tempo_do_bote`).
const RITMO_DO_BOTE := 0.9

var _tempo: float = 0.0
var _no_ar: bool = false
var _garra_ligada: bool = false


func entrar() -> void:
	_tempo = 0.0
	_no_ar = false
	_garra_ligada = false
	iniciar_aviso()


func sair() -> void:
	quimera.encerrar_aviso()
	quimera.desligar_golpe()
	quimera.definir_ritmo(1.0)


func processar_fisica(delta: float) -> void:
	if not _no_ar:
		quimera.parar()
		if avisando(delta):
			return
		_no_ar = true
		quimera.definir_ritmo(RITMO_DO_BOTE)
		quimera.iniciar_bote(quimera.planejar_bote())
		return
	_tempo += delta
	if not _garra_ligada and quimera.velocity.y > 0.0:
		_garra_ligada = true
		quimera.ligar_bote()
	if (quimera.is_on_floor() and _tempo >= TEMPO_MINIMO) or _tempo >= TEMPO_MAXIMO:
		trocar_para.emit(&"Perseguindo")
