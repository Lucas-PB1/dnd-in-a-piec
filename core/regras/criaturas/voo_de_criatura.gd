class_name VooDeCriatura
extends RefCounted
## Capacidade de voo da ficha (`voo_pes`). Velocidade e “sobre o alvo”;
## subir / mergulhar / animação ficam na feature.

## Quanto sobre o alvo (px) conta como “em cima” na horizontal.
const MARGEM_SOBRE_ALVO_PX := 40.0
## Fração da altura de voo já ganha antes de poder mergulhar.
const FRACAO_ALTURA_MINIMA := 0.7

var _criatura: CriaturaRPG
## Altura (px) sobre o alvo em que sobrevoa.
var altura_px: float = 150.0


func _init(criatura: CriaturaRPG, altura_sobre_alvo_px: float = 150.0) -> void:
	_criatura = criatura
	altura_px = altura_sobre_alvo_px


static func tem_voo(criatura: CriaturaRPG) -> bool:
	return criatura.voo_pes > 0.0


func tem() -> bool:
	return tem_voo(_criatura)


## Velocidade de voo (px/s) a partir da ficha.
func velocidade_px() -> float:
	return EscalaDnd.deslocamento_para_velocidade(_criatura.voo_pes)


## Velocidade horizontal desejada ao voar até o alvo (0 se já em cima).
func velocidade_horizontal_desejada(dx: float) -> float:
	if absf(dx) <= MARGEM_SOBRE_ALVO_PX:
		return 0.0
	return signf(dx) * velocidade_px()


## Y em que deve pairar sobre o alvo.
func altura_alvo_y(alvo_y: float) -> float:
	return alvo_y - altura_px


## Em cima do herói e já na altura de voo (hora de mergulhar).
func sobre_o_alvo(posicao: Vector2, alvo: Vector2) -> bool:
	return absf(alvo.x - posicao.x) <= MARGEM_SOBRE_ALVO_PX \
		and posicao.y <= alvo.y - altura_px * FRACAO_ALTURA_MINIMA
