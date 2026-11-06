class_name Ficha
extends RefCounted
## Ficha de personagem de D&D (nível 1): nome, classe e atributos. Calcula vida e dano. Regra pura.

## Dano mínimo de um acerto (com modificador negativo o total poderia dar 0).
const DANO_MINIMO := Combate.DANO_MINIMO
## Bônus de proficiência no nível 1.
const BONUS_PROFICIENCIA := 2
## CA de quem não usa armadura (antes do modificador de Destreza).
const CA_BASE := 10
## Deslocamento por rodada (pés). Ainda não há raças: todo mundo é "humano" (30 pés).
const DESLOCAMENTO_PADRAO_PES := 30.0
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


## Dados de dano da arma já com o modificador (ex.: espada curta + 2 = "1d6+2").
func dado_dano(arma: Arma) -> Dado:
	return arma.dado().com_bonus(bonus_dano(arma))


## Rola o dano de um acerto com a arma (mínimo DANO_MINIMO). Crítico rola os dados em dobro.
func rolar_dano(arma: Arma, rng: RandomNumberGenerator, critico: bool = false) -> int:
	return maxi(dado_dano(arma).rolar(rng, critico), DANO_MINIMO)


## Texto do dano para a ficha, ex.: "1d6+2". Dano fixo (dado de 1 face, como o soco) vira o total: "3".
func texto_dano(arma: Arma) -> String:
	var dado := dado_dano(arma)
	if dado.faces == 1:
		return str(maxi(dado.minimo(), DANO_MINIMO))
	return dado.texto()


## Proficiente com a arma? Ataque desarmado (sem categoria) sempre é.
func proficiente_com(arma: Arma) -> bool:
	return arma.categoria == &"" or arma.categoria in classe.proficiencias_armas


## Bônus para acertar: o mesmo modificador do dano + proficiência, se for proficiente com
## a arma (sem proficiência a arma ainda funciona, só não soma o +2).
func bonus_ataque(arma: Arma) -> int:
	var proficiencia := BONUS_PROFICIENCIA if proficiente_com(arma) else 0
	return proficiencia + bonus_dano(arma)


## O ataque com a arma, pronto para ser resolvido contra a CA do alvo.
## `penalidade` = desgaste da arma (ex.: Corrosão), subtraído do bônus de ataque.
func golpe_com(arma: Arma, penalidade: int = 0) -> Golpe:
	return Golpe.new(arma.nome, bonus_ataque(arma) - penalidade, dado_dano(arma), arma.tipo_dano, arma.corroivel)


## Iniciativa = modificador de Destreza. Define o ritmo dos ataques (EscalaDnd).
func iniciativa() -> int:
	return modificador(Atributos.DESTREZA)


func deslocamento_pes() -> float:
	return DESLOCAMENTO_PADRAO_PES


## Classe de Armadura sem armadura: 10 + modificador de Destreza.
func classe_armadura() -> int:
	return CA_BASE + modificador(Atributos.DESTREZA)


func proficiente_em_salvaguarda(atributo: StringName) -> bool:
	return atributo in classe.salvaguardas_proficientes


## Bônus da salvaguarda: modificador + proficiência (se a classe for proficiente nela).
func bonus_salvaguarda(atributo: StringName) -> int:
	var extra := BONUS_PROFICIENCIA if proficiente_em_salvaguarda(atributo) else 0
	return modificador(atributo) + extra
