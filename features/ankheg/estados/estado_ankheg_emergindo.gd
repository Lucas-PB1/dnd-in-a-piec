extends EstadoAnkheg
## Sai do chão: a terra treme e a marca vermelha avisa o ponto (o herói ainda pode sair de cima); então o Ankheg salta da
## terra e cai exatamente ali, passando direto para a mordida da emboscada.

## Quanto a terra avisa antes de o Ankheg saltar (s).
const AVISO_DA_TERRA := 0.6
## Só depois deste tempo no ar vale conferir se já pousou (o primeiro quadro ainda "toca" o chão), e o limite de segurança (s).
const TEMPO_MINIMO_NO_AR := 0.15
const TEMPO_MAXIMO_NO_AR := 2.0

var _tempo: float = 0.0
var _x: float = 0.0
var _saltou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_x = ankheg.global_position.x
	_saltou = false
	ankheg.parar()


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if not _saltou:
		ankheg.avisar_terra(minf(_tempo / AVISO_DA_TERRA, 1.0))
		if _tempo >= AVISO_DA_TERRA:
			ankheg.emergir_em(_x)
			_saltou = true
			_tempo = 0.0
		return
	var pousou := _tempo >= TEMPO_MINIMO_NO_AR and ankheg.is_on_floor()
	if pousou or _tempo >= TEMPO_MAXIMO_NO_AR:
		ankheg.aterrissar()
		trocar_para.emit(&"Mordendo")
