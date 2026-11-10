class_name SorteDoHeroi
extends RefCounted
## Sortudo: pontos de sorte iguais à proficiência, que voltam a cada fase. Um botão arma a sorte; a próxima
## rolagem do herói (ataque ou teste) gasta um ponto e usa o melhor de dois d20. Regra pura.

var pontos: int = 0
var armada: bool = false


## Pontos que o herói tem por fase: a proficiência com o talento, zero sem ele.
static func total(ficha: Ficha) -> int:
	if ficha == null or not ficha.tem_talento(Ficha.TALENTO_SORTUDO):
		return 0
	return ficha.bonus_proficiencia()


func repor(ficha: Ficha) -> void:
	pontos = total(ficha)
	armada = false


## Arma a sorte. false se não tem o talento, não tem ponto, já está armada ou o herói caiu.
func armar(ficha: Ficha, vivo: bool) -> bool:
	if total(ficha) == 0 or pontos <= 0 or armada or not vivo:
		return false
	armada = true
	return true


## A rolagem vai usar a sorte? Gasta o ponto se estava armada.
func gastar() -> bool:
	if not armada:
		return false
	armada = false
	pontos -= 1
	return true
