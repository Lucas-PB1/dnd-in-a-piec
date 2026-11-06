class_name PontosMao
extends Resource
## Onde estão as mãos do herói em cada quadro de cada animação (a da frente segura a arma,
## a de trás o escudo), o ângulo em que ele segura a arma e os pontos do corpo onde vão as
## peças da armadura (ombro da frente, cintura, topo da cabeça). Gerado por
## tools/marcar_pontos_mao.gd (dá para corrigir à mão no Inspector). Pontos em pixels,
## relativos aos PÉS, com o herói olhando para a DIREITA.

## Ângulo de descanso usado quando a animação não está em `angulos` (graus; + = ponta para baixo).
const ANGULO_PADRAO := 60.0

## animação -> ponto da mão da FRENTE, um por quadro.
@export var pontos: Dictionary[StringName, PackedVector2Array] = {}
## animação -> ponto da mão de TRÁS, um por quadro.
@export var pontos_de_tras: Dictionary[StringName, PackedVector2Array] = {}
## animação -> ângulo de descanso da arma (graus).
@export var angulos: Dictionary[StringName, float] = {}
## animação -> ombro da frente (ombreira), cintura (saiote, na linha do cinto) e topo da
## cabeça (elmo; x = meio da cabeça), um por quadro.
@export var ombros: Dictionary[StringName, PackedVector2Array] = {}
@export var cinturas: Dictionary[StringName, PackedVector2Array] = {}
@export var cabecas: Dictionary[StringName, PackedVector2Array] = {}


## Ponto da mão da frente no `quadro` da `animacao`, ou Vector2.ZERO se não houver.
func ponto(animacao: StringName, quadro: int) -> Vector2:
	return _ponto_em(pontos, animacao, quadro)


func ponto_de_tras(animacao: StringName, quadro: int) -> Vector2:
	return _ponto_em(pontos_de_tras, animacao, quadro)


func ombro(animacao: StringName, quadro: int) -> Vector2:
	return _ponto_em(ombros, animacao, quadro)


func cintura(animacao: StringName, quadro: int) -> Vector2:
	return _ponto_em(cinturas, animacao, quadro)


func cabeca(animacao: StringName, quadro: int) -> Vector2:
	return _ponto_em(cabecas, animacao, quadro)


func angulo(animacao: StringName) -> float:
	return angulos.get(animacao, ANGULO_PADRAO)


func _ponto_em(tabela: Dictionary, animacao: StringName, quadro: int) -> Vector2:
	var lista: PackedVector2Array = tabela.get(animacao, PackedVector2Array())
	if lista.is_empty():
		return Vector2.ZERO
	return lista[clampi(quadro, 0, lista.size() - 1)]
