class_name ItemAleatorio
extends RefCounted
## Sorteia uma arma ou armadura do arsenal do jogo (Artesão: um item novo a cada fase). Regra pura.

const PASTAS: Array[String] = ["res://data/armas", "res://data/armaduras"]


## Uma cópia nova de um item sorteado entre todas as armas e armaduras. null se não houver nenhum.
static func sortear(rng: RandomNumberGenerator) -> Item:
	var todos: Array[Item] = []
	for pasta in PASTAS:
		for recurso in Recursos.da_pasta(pasta):
			todos.append(recurso as Item)
	if todos.is_empty():
		return null
	return todos[rng.randi_range(0, todos.size() - 1)].duplicate() as Item
