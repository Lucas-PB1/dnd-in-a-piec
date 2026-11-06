class_name Dado
extends RefCounted
## Dados no formato de D&D: "1d6", "2d8", "4d6". Regra pura: não usa nós nem Input.

var quantidade: int
var faces: int


func _init(qtd: int = 1, num_faces: int = 6) -> void:
	quantidade = qtd
	faces = num_faces


## Lê uma notação como "1d6". Devolve null se ela for inválida.
static func de_texto(notacao: String) -> Dado:
	var partes := notacao.to_lower().strip_edges().split("d")
	if partes.size() != 2 or not partes[0].is_valid_int() or not partes[1].is_valid_int():
		return null
	var qtd := int(partes[0])
	var num_faces := int(partes[1])
	if qtd < 1 or num_faces < 2:
		return null
	return Dado.new(qtd, num_faces)


## Rola todos os dados e soma. Passe um `rng` com semente para resultados repetíveis.
func rolar(rng: RandomNumberGenerator) -> int:
	var total := 0
	for i in quantidade:
		total += rng.randi_range(1, faces)
	return total


func minimo() -> int:
	return quantidade


func maximo() -> int:
	return quantidade * faces


func texto() -> String:
	return "%dd%d" % [quantidade, faces]
