class_name Pericia
extends RefCounted
## Perícias de D&D (PHB 2024). A ficha guarda as escolhidas; o teste usa o atributo.
## Quem se esconde rola Furtividade contra a Percepção passiva de quem olha.

## Base da perícia passiva (10 + modificador, + proficiência se treinada).
const PASSIVA_BASE := 10

const ACROBACIA := &"acrobacia"
const LIDAR_COM_ANIMAIS := &"lidar_com_animais"
const ATLETISMO := &"atletismo"
const HISTORIA := &"historia"
const INTUICAO := &"intuicao"
const INTIMIDACAO := &"intimidacao"
const PERSUASAO := &"persuasao"
const PERCEPCAO := &"percepcao"
const SOBREVIVENCIA := &"sobrevivencia"
## Não entra na lista do Guerreiro. Os goblins rolam esta.
const FURTIVIDADE := &"furtividade"

const ATRIBUTO := {
	ACROBACIA: Atributos.DESTREZA,
	LIDAR_COM_ANIMAIS: Atributos.SABEDORIA,
	ATLETISMO: Atributos.FORCA,
	HISTORIA: Atributos.INTELIGENCIA,
	INTUICAO: Atributos.SABEDORIA,
	INTIMIDACAO: Atributos.CARISMA,
	PERSUASAO: Atributos.CARISMA,
	PERCEPCAO: Atributos.SABEDORIA,
	SOBREVIVENCIA: Atributos.SABEDORIA,
	FURTIVIDADE: Atributos.DESTREZA,
}

const NOMES := {
	ACROBACIA: "Acrobacia",
	LIDAR_COM_ANIMAIS: "Lidar com Animais",
	ATLETISMO: "Atletismo",
	HISTORIA: "História",
	INTUICAO: "Intuição",
	INTIMIDACAO: "Intimidação",
	PERSUASAO: "Persuasão",
	PERCEPCAO: "Percepção",
	SOBREVIVENCIA: "Sobrevivência",
	FURTIVIDADE: "Furtividade",
}

const DESCRICOES := {
	ACROBACIA: "Equilíbrio e piruetas (Destreza).",
	LIDAR_COM_ANIMAIS: "Acalmar e conduzir um animal (Sabedoria).",
	ATLETISMO: "Escalar, saltar e agarrar (Força).",
	HISTORIA: "Lembrar de fatos e ruínas (Inteligência).",
	INTUICAO: "Perceber a intenção de alguém (Sabedoria).",
	INTIMIDACAO: "Assustar para conseguir algo (Carisma).",
	PERSUASAO: "Convencer com jeito (Carisma).",
	PERCEPCAO: "Notar o que está escondido. Sobe a Percepção passiva (Sabedoria).",
	SOBREVIVENCIA: "Seguir trilha e achar abrigo (Sabedoria).",
	FURTIVIDADE: "Passar sem ser notado (Destreza).",
}


## Atributo da perícia. Vazio se o id não existe.
static func atributo_de(pericia: StringName) -> StringName:
	return ATRIBUTO.get(pericia, &"")


static func nome_de(pericia: StringName) -> String:
	return NOMES.get(pericia, String(pericia))


static func descricao(pericia: StringName) -> String:
	return DESCRICOES.get(pericia, nome_de(pericia))


## "Percepção (Sabedoria)", para a lista da criação.
static func texto_da_lista(pericia: StringName) -> String:
	var atributo := atributo_de(pericia)
	if atributo == &"":
		return nome_de(pericia)
	return "%s (%s)" % [nome_de(pericia), Atributos.NOMES[atributo]]


## Perícia passiva: 10 + bônus do teste (modificador, e + proficiência se treinada).
static func passiva(bonus: int) -> int:
	return PASSIVA_BASE + bonus


## Furtividade que alcança a passiva continua escondida. Abaixo dela, foi percebida.
static func furtividade_passa(rolagem: int, passiva_do_alvo: int) -> bool:
	return rolagem >= passiva_do_alvo
