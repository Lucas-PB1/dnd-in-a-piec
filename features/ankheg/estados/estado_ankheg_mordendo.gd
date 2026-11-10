extends EstadoAnkheg
## Mordida: primeiro o aviso; depois só acerta na janela da ficha da cena. Na emboscada (depois do salto do chão) não há
## aviso: a animação de pouso é o bote, e a mordida acerta quando as mandíbulas estalam (quadros 2 a 4 do pouso).

## Janela da mordida da emboscada, contada do início do pouso (s).
const INICIO_DO_BOTE := 0.14
const FIM_DO_BOTE := 0.36

var _tempo: float = 0.0
var _ligado: bool = false
var _comecou: bool = false
var _bote: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	_comecou = false
	_bote = ankheg.tempo_aviso() <= 0.0
	iniciar_aviso()


func sair() -> void:
	ankheg.encerrar_aviso()
	ankheg.desligar_golpe()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		ankheg.iniciar_ataque(&"pousar" if _bote else &"mordida")
		return
	_tempo += delta
	var inicio := INICIO_DO_BOTE if _bote else ankheg.inicio_acerto
	var fim := FIM_DO_BOTE if _bote else ankheg.fim_acerto
	var na_janela := _tempo >= inicio and _tempo < fim
	if na_janela and not _ligado:
		ankheg.ligar_golpe()
		_ligado = true
	elif not na_janela and _ligado:
		ankheg.desligar_golpe()
		_ligado = false
	if ankheg.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
