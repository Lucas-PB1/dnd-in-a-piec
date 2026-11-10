class_name FugaAgilDeCriatura
extends RefCounted
## Capacidade de Fuga Ágil da ficha (`fuga_agil`): Desengajar depois do melee.
## Calcula velocidade e duração do recuo; o movimento e o estado ficam na feature.

## Distância padrão do recuo (pés), se a feature não passar outra.
const RECUO_PADRAO_PES := 15.0

var _criatura: CriaturaRPG
## Quanto se afasta ao Desengajar (pés), em Disparada.
var recuo_pes: float = RECUO_PADRAO_PES


func _init(criatura: CriaturaRPG, recuo_pes_export: float = RECUO_PADRAO_PES) -> void:
	_criatura = criatura
	recuo_pes = recuo_pes_export


static func tem_fuga_agil(criatura: CriaturaRPG) -> bool:
	return criatura.fuga_agil


func tem() -> bool:
	return tem_fuga_agil(_criatura)


## Velocidade do recuo (px/s): deslocamento efetivo em Disparada.
func velocidade_px(deslocamento_efetivo_pes: float) -> float:
	return EscalaDnd.deslocamento_para_velocidade(deslocamento_efetivo_pes) * EscalaDnd.MULTIPLICADOR_DISPARADA


## Duração do recuo (s) na velocidade de Disparada.
func tempo_de_fuga(deslocamento_efetivo_pes: float) -> float:
	var velocidade := velocidade_px(deslocamento_efetivo_pes)
	return EscalaDnd.pes_para_pixels(recuo_pes) / velocidade if velocidade > 0.0 else 0.0
