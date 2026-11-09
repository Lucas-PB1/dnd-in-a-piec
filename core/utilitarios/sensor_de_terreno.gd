class_name SensorDeTerreno
extends RefCounted
## Olha o chão à frente de alguém (raios para baixo) e devolve o perfil que `SaltoDnd.planejar` entende.

## Folga acima e abaixo da faixa sondada (px).
const MARGEM_PX := 2.0


## Altura do chão a cada `passo_px`, de `inicio_px` até `quantidade` passos, na direção `direcao` (1 ou -1).
## `pe`: posição dos pés. Cada ponto sonda de `altura_max` acima até `queda_max` abaixo dos pés.
static func perfil(espaco: PhysicsDirectSpaceState2D, pe: Vector2, direcao: float, inicio_px: float, passo_px: float,
		quantidade: int, altura_max: float, queda_max: float, mascara: int) -> Array[float]:
	var saida: Array[float] = []
	for i in quantidade:
		var x := pe.x + direcao * (inicio_px + i * passo_px)
		saida.append(_altura_do_chao(espaco, Vector2(x, pe.y), altura_max, queda_max, mascara))
	return saida


static func _altura_do_chao(espaco: PhysicsDirectSpaceState2D, base: Vector2, altura_max: float, queda_max: float,
		mascara: int) -> float:
	var topo := Vector2(base.x, base.y - altura_max - MARGEM_PX)
	var ponto := PhysicsPointQueryParameters2D.new()
	ponto.position = topo
	ponto.collision_mask = mascara
	if not espaco.intersect_point(ponto, 1).is_empty():
		return SaltoDnd.MURO
	var raio := PhysicsRayQueryParameters2D.create(topo, Vector2(base.x, base.y + queda_max + MARGEM_PX), mascara)
	var acerto := espaco.intersect_ray(raio)
	if acerto.is_empty():
		return SaltoDnd.SEM_CHAO
	return base.y - (acerto["position"] as Vector2).y


## True se nada do mundo (`mascara`) atrapalha a linha entre os dois pontos: é o que um tiro precisa para chegar.
static func linha_livre(espaco: PhysicsDirectSpaceState2D, de: Vector2, ate: Vector2, mascara: int) -> bool:
	return espaco.intersect_ray(PhysicsRayQueryParameters2D.create(de, ate, mascara)).is_empty()
