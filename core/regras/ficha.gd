class_name Ficha
extends RefCounted
## Ficha de personagem de D&D (nível 1): atributos + classe. Calcula vida e dano. Regra pura.

## Dano mínimo de um acerto (com modificador negativo o total poderia dar 0).
const DANO_MINIMO := 1
## Vida mínima no nível 1, mesmo com Constituição muito baixa.
const VIDA_MINIMA := 1

var classe: ClasseRPG
var atributos: Dictionary[StringName, int] = {}


func _init(classe_rpg: ClasseRPG, valores: Dictionary) -> void:
	classe = classe_rpg
	for atributo in Atributos.TODOS:
		atributos[atributo] = valores.get(atributo, Atributos.VALOR_MEDIO)


func modificador(atributo: StringName) -> int:
	return Atributos.modificador(atributos[atributo])


## Nível 1: valor máximo do dado de vida da classe + modificador de Constituição.
func vida_maxima() -> int:
	return maxi(classe.dado_vida + modificador(Atributos.CONSTITUICAO), VIDA_MINIMA)


## Modificador somado ao dano: Força, ou o maior entre Força e Destreza se a arma tem acuidade.
func bonus_dano(arma: Arma) -> int:
	var mod_forca := modificador(Atributos.FORCA)
	if arma.acuidade:
		return maxi(mod_forca, modificador(Atributos.DESTREZA))
	return mod_forca


## Rola o dano de um acerto com a arma: dados da arma + bônus (mínimo DANO_MINIMO).
func rolar_dano(arma: Arma, rng: RandomNumberGenerator) -> int:
	return maxi(arma.dado().rolar(rng) + bonus_dano(arma), DANO_MINIMO)


## Texto do dano para a ficha, ex.: "1d6+2". Dano fixo (dado de 1 face, como o soco) vira o total: "3".
func texto_dano(arma: Arma) -> String:
	var bonus := bonus_dano(arma)
	if arma.dado().faces == 1:
		return str(maxi(arma.dado().quantidade + bonus, DANO_MINIMO))
	if bonus == 0:
		return arma.dado().texto()
	var sinal := "+" if bonus > 0 else ""  # negativo já vem com "-"
	return "%s%s%d" % [arma.dado().texto(), sinal, bonus]
