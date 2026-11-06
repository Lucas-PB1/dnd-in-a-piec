class_name Ficha
extends RefCounted
## Ficha de personagem de D&D (nível 1): nome, classe e atributos. Calcula vida e dano. Regra pura.

## Dano mínimo de um acerto (com modificador negativo o total poderia dar 0).
const DANO_MINIMO := Combate.DANO_MINIMO
## Bônus de proficiência no nível 1.
const BONUS_PROFICIENCIA := 2
## Base da CD das maestrias (8 + modificador + proficiência).
const CD_BASE_MAESTRIA := 8
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
## Maestria em Armas: nomes dos tipos de arma que o personagem domina (Guerreiro: 3,
## escolhidos na criação). Só com elas a maestria da arma vale.
var armas_dominadas: Array[String] = []
## Talentos (origem e geral). Começa vazia: o antecedente é que vai marcar o de origem.
var talentos: Array[String] = []

## Destreza da ficha sugerida: o teto da carga e o tempo de voo do disparo são os dela.
const DESTREZA_REFERENCIA := 14
## Segundos para essa Destreza encher a carga até o teto dela.
const TEMPO_CARGA_DISPARO := 0.6
## Força da carga (0 = mínima, 1 = cheia) com modificador de Destreza −1.
const FORCA_MINIMA_DA_CARGA := 0.2
## Modificador a partir do qual segurar o K chega na força cheia.
const MOD_CARGA_CHEIA := 2
## Tiro longo sem a desvantagem de distância.
const TALENTO_ATIRADOR_DE_ELITE := "Atirador de Elite"
## Besta: sem a desvantagem de atirar colado no inimigo; a Besta de Mão dispara de novo
## na ação bônus.
const TALENTO_ESPECIALISTA_EM_BESTA := "Especialista em Besta"


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


## Atributo do ataque e do dano. À distância usa Destreza. Acuidade usa o maior entre
## Força e Destreza. As outras usam Força.
func atributo_do_ataque(arma: Arma) -> StringName:
	if arma.disparavel():
		return Atributos.DESTREZA
	if arma.acuidade and modificador(Atributos.DESTREZA) > modificador(Atributos.FORCA):
		return Atributos.DESTREZA
	return Atributos.FORCA


## Modificador somado ao ataque e ao dano.
func bonus_dano(arma: Arma) -> int:
	return modificador(atributo_do_ataque(arma))


func tem_talento(talento: String) -> bool:
	return talento in talentos


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
	golpe.maestria = maestria_de(arma)
	golpe.cd_maestria = cd_maestria(arma)
	if golpe.maestria == Proficiencias.RASPAO:
		golpe.dano_raspao = maxi(bonus_dano(arma), 0)
	if golpe.maestria == Proficiencias.TRESPASSAR and not ataque_extra:
		# 2º alvo: mesmo ataque, mas o dano não soma o modificador positivo (como o ataque extra).
		golpe.trespassar = golpe_com(arma, penalidade, armadura, duas_maos, true)
	return golpe


## Domina este tipo de arma (Maestria em Armas)? Só vale se a arma tem maestria.
func domina(arma: Arma) -> bool:
	return arma.maestria != &"" and arma.nome in armas_dominadas


## A maestria que vale com esta arma (vazio = não domina).
func maestria_de(arma: Arma) -> StringName:
	return arma.maestria if domina(arma) else &""


## CD da salvaguarda das maestrias (Derrubar): 8 + modificador do ataque + proficiência.
func cd_maestria(arma: Arma) -> int:
	return CD_BASE_MAESTRIA + bonus_dano(arma) + BONUS_PROFICIENCIA


## Arma Pesada pede FOR 13: abaixo disso, o ataque tem desvantagem.
func fraco_para(arma: Arma) -> bool:
	return arma.pesada and atributos[Atributos.FORCA] < FORCA_MINIMA_ARMA_PESADA


## Iniciativa = modificador de Destreza. Define o ritmo dos ataques (EscalaDnd).
func iniciativa() -> int:
	return modificador(Atributos.DESTREZA)


## Até onde o disparo enche (0 = toque, velocidade mínima; 1 = velocidade cheia da arma).
## Destreza 14 ou mais chega em 1.
func teto_da_carga() -> float:
	var fracao := clampf(float(modificador(Atributos.DESTREZA) + 1) / float(MOD_CARGA_CHEIA + 1), 0.0, 1.0)
	return lerpf(FORCA_MINIMA_DA_CARGA, 1.0, fracao)


## Segundos para chegar nesse teto. Destreza alta enche a dela mais rápido.
func tempo_ate_teto_da_carga() -> float:
	var des := maxi(atributos[Atributos.DESTREZA], 1)
	return TEMPO_CARGA_DISPARO * float(DESTREZA_REFERENCIA) / float(des)


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
