class_name PontosMao
extends Resource
## Onde está a mão da frente do herói em cada quadro de cada animação, e o ângulo em que
## ele segura a arma em cada animação. Gerado por tools/marcar_pontos_mao.gd (dá para
## corrigir à mão no Inspector). Pontos em pixels, relativos aos PÉS, com o herói olhando
## para a DIREITA.

## Ângulo de descanso usado quando a animação não está em `angulos` (graus; + = ponta para baixo).
const ANGULO_PADRAO := 60.0

## animação -> um ponto por quadro.
@export var pontos: Dictionary[StringName, PackedVector2Array] = {}
## animação -> ângulo de descanso da arma (graus).
@export var angulos: Dictionary[StringName, float] = {}


## Ponto da mão no `quadro` da `animacao`, ou Vector2.ZERO se não houver.
func ponto(animacao: StringName, quadro: int) -> Vector2:
	var lista: PackedVector2Array = pontos.get(animacao, PackedVector2Array())
	if lista.is_empty():
		return Vector2.ZERO
	return lista[clampi(quadro, 0, lista.size() - 1)]


func angulo(animacao: StringName) -> float:
	return angulos.get(animacao, ANGULO_PADRAO)
