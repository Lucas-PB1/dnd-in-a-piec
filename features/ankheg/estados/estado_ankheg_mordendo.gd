extends EstadoAnkheg
## Mordida: primeiro o aviso (nenhum se saiu do chão de surpresa); depois só acerta na janela da ficha da cena.

var _tempo: float = 0.0
var _ligado: bool = false
var _comecou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	_comecou = false
	iniciar_aviso()


func sair() -> void:
	ankheg.encerrar_aviso()
	ankheg.desligar_golpe()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		ankheg.iniciar_ataque(&"mordida")
		return
	_tempo += delta
	var na_janela := _tempo >= ankheg.inicio_acerto and _tempo < ankheg.fim_acerto
	if na_janela and not _ligado:
		ankheg.ligar_golpe()
		_ligado = true
	elif not na_janela and _ligado:
		ankheg.desligar_golpe()
		_ligado = false
	if ankheg.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
