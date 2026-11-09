class_name RecargasPorRodada
extends RefCounted
## Os efeitos de talento que valem uma vez por rodada (1,5 s): depois de gastar um, ele espera uma rodada.
## Regra pura: quem usa chama `passar(delta)` a cada quadro.

var _restante: Dictionary[StringName, float] = {}


## O efeito foi gasto agora: começa a espera de uma rodada.
func gastar(efeito: StringName) -> void:
	_restante[efeito] = EscalaDnd.RODADA_SEGUNDOS


func em_recarga(efeito: StringName) -> bool:
	return _restante.get(efeito, 0.0) > 0.0


func passar(delta: float) -> void:
	for efeito in _restante:
		_restante[efeito] = maxf(_restante[efeito] - delta, 0.0)
