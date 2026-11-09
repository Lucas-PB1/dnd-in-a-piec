extends EstadoAnkheg
## Borrifo Ácido: aviso, a cabeça se ergue e o jato sai na janela da cena; quem está na linha rola Destreza (CD 12).

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
	ankheg.desligar_borrifo()


func processar_fisica(delta: float) -> void:
	ankheg.parar()
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		ankheg.iniciar_ataque(&"cuspe")
		return
	_tempo += delta
	var na_janela := _tempo >= ankheg.inicio_borrifo and _tempo < ankheg.fim_borrifo
	if na_janela and not _ligado:
		ankheg.ligar_borrifo()
		_ligado = true
	elif not na_janela and _ligado:
		ankheg.desligar_borrifo()
		_ligado = false
	if ankheg.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
