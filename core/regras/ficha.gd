class_name Ficha
extends RefCounted
## Ficha de personagem de D&D (nível 1): nome, classe e atributos. Calcula vida e dano. Regra pura.

## Dano mínimo de um acerto (com modificador negativo o total poderia dar 0).
const DANO_MINIMO := 1
## Vida mínima no nível 1, mesmo com Constituição muito baixa.
const VIDA_MINIMA := 1
## Nome usado quando nenhum foi escolhido.
const NOME_PADRAO := "Aventureiro"
## Tamanho máximo do nome do personagem (letras).
const TAMANHO_MAXIMO_NOME := 16

var nome: String
var classe: ClasseRPG
var atributos: Dictionary[StringName, int] = {}


func _init(classe_rpg: ClasseRPG, valores: Dictionary, nome_personagem: String = NOME_PADRAO) -> void:
	classe = classe_rpg
	nome = limpar_nome(nome_personagem)
	if nome.is_empty():
		nome = NOME_PADRAO
	for atributo in Atributos.TODOS:
		atributos[atributo] = valores.get(atributo, Atributos.VALOR_MEDIO)


## Tira espaços das pontas e corta no tamanho máximo.
static func limpar_nome(texto: String) -> String:
	return texto.strip_edges().left(TAMANHO_MAXIMO_NOME)


## Um nome serve se, depois de limpo, sobrar pelo menos uma letra.
static func nome_valido(texto: String) -> bool:
	return not limpar_nome(texto).is_empty()


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
