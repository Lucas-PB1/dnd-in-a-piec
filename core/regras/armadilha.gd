class_name Armadilha
extends RefCounted
## Sorteio puro de quem ocupa os pontos de armadilha de uma fase.
## A mesma semente devolve os mesmos pontos e tipos. O jogo usa outra semente a cada entrada.


## Embaralha os pontos, fica com `quantidade` e dá um tipo permitido a cada um.
static func sortear(pontos: Array[Vector2], quantidade: int, tipos: Array[StringName], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if pontos.is_empty() or tipos.is_empty() or quantidade <= 0:
		return resultado
	var ordem: Array[Vector2] = pontos.duplicate()
	_embaralhar(ordem, rng)
	var ocupados := mini(quantidade, ordem.size())
	for i in ocupados:
		resultado.append({
			"posicao": ordem[i],
			"tipo": tipos[rng.randi_range(0, tipos.size() - 1)],
		})
	return resultado


static func _embaralhar(itens: Array[Vector2], rng: RandomNumberGenerator) -> void:
	for i in range(itens.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado: Vector2 = itens[i]
		itens[i] = itens[j]
		itens[j] = guardado
