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
## Armadura com Força mínima que o personagem não alcança: perde isto de deslocamento.
const PERDA_DESLOCAMENTO_SEM_FORCA := 10.0
## Arma Pesada com Força abaixo disto: desvantagem no ataque.
const FORCA_MINIMA_ARMA_PESADA := 13
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
## `duas_maos` = empunhando com as duas mãos (arma Versátil usa o dado maior).
## `ataque_extra` = 2º golpe de arma leve: não soma modificador positivo.
func dado_dano(arma: Arma, duas_maos: bool = false, ataque_extra: bool = false) -> Dado:
	return arma.dado(duas_maos).com_bonus(_bonus_no_dano(arma, ataque_extra))


## Rola o dano de um acerto com a arma (mínimo DANO_MINIMO). Crítico rola os dados em dobro.
func rolar_dano(arma: Arma, rng: RandomNumberGenerator, critico: bool = false, duas_maos: bool = false) -> int:
	return maxi(dado_dano(arma, duas_maos).rolar(rng, critico), DANO_MINIMO)


## Texto do dano para a ficha, ex.: "1d6+2". Dano fixo (dado de 1 face, como o soco) vira o total: "3".
func texto_dano(arma: Arma, duas_maos: bool = false, ataque_extra: bool = false) -> String:
	var dado := dado_dano(arma, duas_maos, ataque_extra)
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
## `armadura` vestida: sem treinamento nela, o ataque (teste de FOR/DES) tem desvantagem.
## Arma Pesada com FOR < 13 também dá desvantagem. `duas_maos`: Versátil com as duas mãos.
## `ataque_extra`: 2º golpe de arma leve (o d20 soma o modificador; o dano, não).
func golpe_com(arma: Arma, penalidade: int = 0, armadura: Armadura = null, duas_maos: bool = false,
		ataque_extra: bool = false) -> Golpe:
	var dado := dado_dano(arma, duas_maos, ataque_extra)
	var golpe := Golpe.new(arma.nome, bonus_ataque(arma) - penalidade, dado, arma.tipo_dano, arma.corroivel)
	golpe.desvantagem = desvantagem_por_armadura(armadura) or fraco_para(arma)
	return golpe


## Arma Pesada pede FOR 13: abaixo disso, o ataque tem desvantagem.
func fraco_para(arma: Arma) -> bool:
	return arma.pesada and atributos[Atributos.FORCA] < FORCA_MINIMA_ARMA_PESADA


## Iniciativa = modificador de Destreza. Define o ritmo dos ataques (EscalaDnd).
func iniciativa() -> int:
	return modificador(Atributos.DESTREZA)


## Deslocamento (pés). Armadura com Força mínima que o personagem não tem: -10 pés.
func deslocamento_pes(armadura: Armadura = null) -> float:
	if falta_forca_para(armadura):
		return DESLOCAMENTO_PADRAO_PES - PERDA_DESLOCAMENTO_SEM_FORCA
	return DESLOCAMENTO_PADRAO_PES


# --- Armadura ------------------------------------------------------------------------

## Classe de Armadura com a `armadura` e o `escudo` vestidos (null = sem eles).
## Sem armadura: 10 + DES. Leve: base + DES. Média: base + DES até o máximo. Pesada: base.
## `desgaste_armadura` (ex.: corrosão) é subtraído do que a armadura oferece.
## Escudo só soma se tiver treinamento com escudos.
func classe_armadura(armadura: Armadura = null, escudo: Armadura = null, desgaste_armadura: int = 0) -> int:
	var ca := CA_BASE + modificador(Atributos.DESTREZA)
	if armadura:
		ca = armadura.ca_base - desgaste_armadura + _destreza_na_armadura(armadura)
	if escudo and treinado_com(escudo):
		ca += escudo.ca_base
	return ca


## Treinado na categoria da armadura ou escudo? (Guerreiro: em todas.)
func treinado_com(armadura: Armadura) -> bool:
	return armadura.categoria in classe.treinamento_armaduras


## Vestir armadura (não escudo) sem treinamento dá desvantagem nos testes de FOR e DES.
func desvantagem_por_armadura(armadura: Armadura) -> bool:
	return armadura != null and not armadura.e_escudo() and not treinado_com(armadura)


## A armadura pede mais Força do que o personagem tem?
func falta_forca_para(armadura: Armadura) -> bool:
	return armadura != null and atributos[Atributos.FORCA] < armadura.forca_minima


## Ataque extra de arma leve: modificador positivo não entra no dano.
func _bonus_no_dano(arma: Arma, ataque_extra: bool) -> int:
	var bonus := bonus_dano(arma)
	return mini(bonus, 0) if ataque_extra else bonus


func _destreza_na_armadura(armadura: Armadura) -> int:
	if not armadura.soma_destreza:
		return 0
	var mod := modificador(Atributos.DESTREZA)
	return mini(mod, armadura.max_destreza) if armadura.max_destreza >= 0 else mod


func proficiente_em_salvaguarda(atributo: StringName) -> bool:
	return atributo in classe.salvaguardas_proficientes


## Bônus da salvaguarda: modificador + proficiência (se a classe for proficiente nela).
func bonus_salvaguarda(atributo: StringName) -> int:
	var extra := BONUS_PROFICIENCIA if proficiente_em_salvaguarda(atributo) else 0
	return modificador(atributo) + extra
