class_name CompraDePontos
extends RefCounted
## Compra de pontos do D&D 5e: 27 pontos, cada atributo de 8 a 15. Regra pura.

const PONTOS_TOTAIS := 27
const VALOR_MINIMO := 8
const VALOR_MAXIMO := 15
## Custo acumulado para chegar em cada valor (tabela do Livro do Jogador).
const CUSTO_TOTAL := {8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9}

## Valor atual de cada atributo (todos começam em 8).
var valores: Dictionary[StringName, int] = {}


func _init() -> void:
	for atributo in Atributos.TODOS:
		valores[atributo] = VALOR_MINIMO


func pontos_gastos() -> int:
	var total := 0
	for atributo in valores:
		total += CUSTO_TOTAL[valores[atributo]]
	return total


func pontos_restantes() -> int:
	return PONTOS_TOTAIS - pontos_gastos()


## Quanto custa subir `atributo` em 1 (ou -1 se já está no máximo).
func custo_para_aumentar(atributo: StringName) -> int:
	var valor := valores[atributo]
	if valor >= VALOR_MAXIMO:
		return -1
	return CUSTO_TOTAL[valor + 1] - CUSTO_TOTAL[valor]


func pode_aumentar(atributo: StringName) -> bool:
	var custo := custo_para_aumentar(atributo)
	return custo >= 0 and custo <= pontos_restantes()


func pode_diminuir(atributo: StringName) -> bool:
	return valores[atributo] > VALOR_MINIMO


func aumentar(atributo: StringName) -> bool:
	if not pode_aumentar(atributo):
		return false
	valores[atributo] += 1
	return true


func diminuir(atributo: StringName) -> bool:
	if not pode_diminuir(atributo):
		return false
	valores[atributo] -= 1
	return true


## Aplica um conjunto pronto (ex.: sugestão da classe). Retorna false (e não muda nada)
## se algum valor estiver fora de 8..15 ou se o total passar de 27 pontos.
func aplicar(novos: Dictionary) -> bool:
	var teste := CompraDePontos.new()
	for atributo in Atributos.TODOS:
		var valor: int = novos.get(atributo, VALOR_MINIMO)
		if valor < VALOR_MINIMO or valor > VALOR_MAXIMO:
			return false
		teste.valores[atributo] = valor
	if teste.pontos_restantes() < 0:
		return false
	valores = teste.valores
	return true
