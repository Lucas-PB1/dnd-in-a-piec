extends EstadoQuimera
## Mergulho: cai sobre o herói corrigindo a pontaria; ao tocar o chão a tela treme, a cabeçada (derruba) acerta o que está
## embaixo e ela fica um instante no pouso antes de voltar a perseguir.

## Tempo parada no pouso (s).
const TEMPO_DO_POUSO := 0.5
## Se nunca chegar ao chão (algo deu errado), desiste depois deste tempo (s).
const TEMPO_MAXIMO := 3.0

var _tempo: float = 0.0
var _pousou: bool = false
var _pouso: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	_pouso = 0.0
	_pousou = false
	quimera.voando = true
	quimera.mostrar_quadro(&"pular", Quimera.QUADRO_QUEDA)


func sair() -> void:
	quimera.terminar_voo()
	quimera.desligar_golpe()


func processar_fisica(delta: float) -> void:
	if _pousou:
		quimera.parar()
		_pouso += delta
		if _pouso >= TEMPO_DO_POUSO:
			trocar_para.emit(&"Perseguindo")
		return
	_tempo += delta
	quimera.mergulhar()
	if quimera.is_on_floor():
		_pousou = true
		quimera.aterrissar_do_mergulho()
	elif _tempo >= TEMPO_MAXIMO:
		trocar_para.emit(&"Perseguindo")
