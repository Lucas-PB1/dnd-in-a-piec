extends EstadoMinotauro
## Chifrada: aviso (agacha e brilha), corrida em linha reta e o bote. Com 10 pés de corrida antes do acerto, soma o dano e
## derruba o herói. Barrado por um bloco marcado, quebra e segue; barrado por parede ou queda, ou sem acertar, fica cansado.

enum Etapa { AVISO, CORRENDO, RECUPERANDO }

## Tempo de recuperação (s) depois de acertar e depois de quebrar um bloco; o de errar é `tempo_cansaco` do Minotauro.
const RECUPERACAO_ACERTO := 0.5
const RECUPERACAO_BLOCO := 0.5
## Quadro da animação da Chifrada em que o bote termina de golpear.
const QUADRO_DO_BOTE := 4
## Depois de quebrar um bloco, ignora a "parede" por este tempo (s): a colisão do bloco some no fim do quadro e o aviso de
## parede do quadro anterior ainda vale.
const GRACA_APOS_BLOCO := 0.15

var _etapa: Etapa = Etapa.AVISO
var _corrida: float = 0.0
var _carreira_completa: bool = false
var _quebrou_bloco: bool = false
var _espera: float = 0.0
var _graca: float = 0.0


func entrar() -> void:
	_etapa = Etapa.AVISO
	_corrida = 0.0
	_carreira_completa = false
	_quebrou_bloco = false
	_graca = 0.0
	iniciar_aviso(&"preparar")


func sair() -> void:
	minotauro.encerrar_aviso()
	minotauro.desligar_chifres()


func processar_fisica(delta: float) -> void:
	match _etapa:
		Etapa.AVISO:
			_avisar(delta)
		Etapa.CORRENDO:
			_correr(delta)
		Etapa.RECUPERANDO:
			_recuperar(delta)


func _avisar(delta: float) -> void:
	minotauro.parar()
	if avisando(delta):
		return
	minotauro.iniciar_investida()
	_etapa = Etapa.CORRENDO


func _correr(delta: float) -> void:
	minotauro.correr_na_investida()
	_corrida += absf(minotauro.velocity.x) * delta
	_graca -= delta
	if not _carreira_completa and minotauro.carreira_completa(_corrida):
		_carreira_completa = true
		minotauro.completar_carreira()
	if minotauro.chifrada_acertou():
		minotauro.abalar_com_a_chifrada()
		_recuperar_depois(RECUPERACAO_ACERTO, true)
	elif _graca <= 0.0 and minotauro.investida_barrada():
		_ao_ser_barrado()
	elif _corrida >= minotauro.distancia_investida:
		_recuperar_depois(minotauro.tempo_cansaco, false)


## Se o que barra é um bloco marcado, quebra e segue em frente; parede ou queda encerram a investida.
func _ao_ser_barrado() -> void:
	if minotauro.quebrar_a_frente() > 0:
		_quebrou_bloco = true
		_graca = GRACA_APOS_BLOCO
		return
	_recuperar_depois(RECUPERACAO_BLOCO if _quebrou_bloco else minotauro.tempo_cansaco, false)


func _recuperar_depois(tempo: float, bote: bool) -> void:
	minotauro.desligar_chifres()
	minotauro.parar()
	if bote:
		minotauro.iniciar_ataque(&"chifrada", QUADRO_DO_BOTE)
	else:
		minotauro.tocar(&"parado")
	_espera = tempo
	_etapa = Etapa.RECUPERANDO


func _recuperar(delta: float) -> void:
	minotauro.parar()
	_espera -= delta
	if _espera <= 0.0:
		trocar_para.emit(&"Perseguindo")
