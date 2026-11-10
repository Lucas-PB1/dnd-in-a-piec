extends EstadoQuimera
## Sopro de Fogo: a cabeça de dragão da cauda sobe e solta o cone; quem está nele rola Destreza (CD 15). Vindo do combo, entra
## sem novo aviso (o Sopro toma o lugar da Garra).

var _tempo: float = 0.0
var _comecou: bool = false
var _ligado: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	_comecou = quimera.combo_em_andamento
	quimera.combo_em_andamento = false
	if _comecou:
		quimera.iniciar_sopro()
	else:
		iniciar_aviso()


func sair() -> void:
	quimera.encerrar_aviso()
	quimera.desligar_sopro()


func processar_fisica(delta: float) -> void:
	quimera.parar()
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		quimera.iniciar_sopro()
		return
	_tempo += delta
	var na_janela := _tempo >= quimera.inicio_sopro and _tempo < quimera.fim_sopro
	if na_janela and not _ligado:
		quimera.ligar_sopro()
		_ligado = true
	elif not na_janela and _ligado:
		quimera.desligar_sopro()
		_ligado = false
	if quimera.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
