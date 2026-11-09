class_name JanelaDeDefesa
extends RefCounted
## Duelista Defensivo: uma janela de 0,75 s com +proficiência na CA contra golpes corpo a corpo, e 1 s de espera
## depois. Regra pura: `passar` avisa quando a janela fecha e quando a defesa volta a ficar pronta.

const DURACAO := 0.75
const RECARGA := 1.0
## O que aconteceu neste quadro.
enum Evento { NADA, FECHOU, PRONTA }

var _tempo: float = 0.0
var _recarga: float = 0.0


func ativa() -> bool:
	return _tempo > 0.0


func pronta() -> bool:
	return _tempo <= 0.0 and _recarga <= 0.0


## Abre a janela. false se já está aberta ou esperando.
func abrir() -> bool:
	if not pronta():
		return false
	_tempo = DURACAO
	return true


func cancelar() -> void:
	_tempo = 0.0
	_recarga = 0.0


func passar(delta: float) -> Evento:
	if _tempo > 0.0:
		_tempo -= delta
		if _tempo <= 0.0:
			_recarga = RECARGA
			return Evento.FECHOU
	elif _recarga > 0.0:
		_recarga -= delta
		if _recarga <= 0.0:
			return Evento.PRONTA
	return Evento.NADA
