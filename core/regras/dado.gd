class_name Dado
extends RefCounted
## Dados no formato de D&D: "1d6", "2d8+1", "3d8+9", "1d4-1". Regra pura: não usa nós nem Input.

var quantidade: int
var faces: int
## Valor fixo somado depois dos dados (o "+1" de "2d8+1").
var bonus: int


func _init(qtd: int = 1, num_faces: int = 6, valor_fixo: int = 0) -> void:
	quantidade = qtd
	faces = num_faces
	bonus = valor_fixo


## Lê uma notação como "1d6" ou "2d8+1". Devolve null se ela for inválida.
static func de_texto(notacao: String) -> Dado:
	var restante := notacao.to_lower().replace(" ", "")
	var valor_fixo := 0
	for sinal in ["+", "-"]:
		var pos := restante.find(sinal)
		if pos > 0:
			var resto := restante.substr(pos + 1)
			if not resto.is_valid_int():
				return null
			valor_fixo = int(resto) * (1 if sinal == "+" else -1)
			restante = restante.left(pos)
			break
	var partes := restante.split("d")
	if partes.size() != 2 or not partes[0].is_valid_int() or not partes[1].is_valid_int():
		return null
	var qtd := int(partes[0])
	var num_faces := int(partes[1])
	if qtd < 1 or num_faces < 1:  # "1d1" vale: dano fixo de 1 (ex.: soco desarmado)
		return null
	return Dado.new(qtd, num_faces, valor_fixo)


## Rola e soma (dados + bônus). Com `critico`, rola os dados em dobro (o bônus não dobra).
## Passe um `rng` com semente para resultados repetíveis.
func rolar(rng: RandomNumberGenerator, critico: bool = false) -> int:
	var vezes := quantidade * (2 if critico else 1)
	var total := bonus
	for i in vezes:
		total += rng.randi_range(1, faces)
	return total


func minimo() -> int:
	return quantidade + bonus


func maximo() -> int:
	return quantidade * faces + bonus


## Média arredondada para baixo (como a vida "22 (3d8+9)" nas fichas de D&D).
func media() -> int:
	return floori(quantidade * (faces + 1) / 2.0) + bonus


## Um novo Dado com os mesmos dados e `extra` somado ao bônus.
func com_bonus(extra: int) -> Dado:
	return Dado.new(quantidade, faces, bonus + extra)


func texto() -> String:
	var base := "%dd%d" % [quantidade, faces]
	if bonus > 0:
		return "%s+%d" % [base, bonus]
	if bonus < 0:
		return "%s%d" % [base, bonus]
	return base
