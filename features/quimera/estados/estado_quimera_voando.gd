extends EstadoQuimera
## Voo: depois do aviso decola, sobe e sobrevoa o herói; quando está em cima (ou o tempo de sobrevoo acaba) passa ao mergulho.


var _tempo: float = 0.0
var _no_ar: bool = false


func entrar() -> void:
	_tempo = 0.0
	_no_ar = false
	iniciar_aviso()


func sair() -> void:
	quimera.encerrar_aviso()
	quimera.terminar_voo()  # o Mergulhando liga o voo de novo ao entrar


func processar_fisica(delta: float) -> void:
	if not _no_ar:
		quimera.parar()
		if avisando(delta):
			return
		_no_ar = true
		quimera.comecar_voo()
		return
	_tempo += delta
	quimera.voar_para_alvo()
	if quimera.sobre_o_alvo() or _tempo >= quimera.tempo_maximo_de_voo:
		trocar_para.emit(&"Mergulhando")
