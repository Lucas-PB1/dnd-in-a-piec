extends EstadoMinotauro
## Glaive Abissal: primeiro o aviso; depois só acerta na janela do golpe (e quebra os blocos marcados à frente).

var _tempo: float = 0.0
var _ligado: bool = false
var _comecou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	_comecou = false
	iniciar_aviso(&"parado")


func sair() -> void:
	minotauro.encerrar_aviso()
	minotauro.desligar_glaive()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		minotauro.iniciar_ataque(&"glaive")
		return
	_tempo += delta
	var na_janela := _tempo >= minotauro.inicio_acerto and _tempo < minotauro.fim_acerto
	if na_janela and not _ligado:
		minotauro.ligar_glaive()
		_ligado = true
	elif not na_janela and _ligado:
		minotauro.desligar_glaive()
		_ligado = false
	if minotauro.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
