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
## Perícias que os antecedentes do livro usam (ainda sem teste no jogo, só na ficha).
const ARCANISMO := &"arcanismo"
const ATUACAO := &"atuacao"
const ENGANACAO := &"enganacao"
const INVESTIGACAO := &"investigacao"
const MEDICINA := &"medicina"
const NATUREZA := &"natureza"
const PRESTIDIGITACAO := &"prestidigitacao"
const RELIGIAO := &"religiao"

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
	ARCANISMO: Atributos.INTELIGENCIA,
	ATUACAO: Atributos.CARISMA,
	ENGANACAO: Atributos.CARISMA,
	INVESTIGACAO: Atributos.INTELIGENCIA,
	MEDICINA: Atributos.SABEDORIA,
	NATUREZA: Atributos.INTELIGENCIA,
	PRESTIDIGITACAO: Atributos.DESTREZA,
	RELIGIAO: Atributos.INTELIGENCIA,
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
	ARCANISMO: "Arcanismo",
	ATUACAO: "Atuação",
	ENGANACAO: "Enganação",
	INVESTIGACAO: "Investigação",
	MEDICINA: "Medicina",
	NATUREZA: "Natureza",
	PRESTIDIGITACAO: "Prestidigitação",
	RELIGIAO: "Religião",
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
	ARCANISMO: "Saber sobre magia e criaturas mágicas (Inteligência).",
	ATUACAO: "Cantar, dançar e entreter (Carisma).",
	ENGANACAO: "Mentir de forma convincente (Carisma).",
	INVESTIGACAO: "Procurar pistas e deduzir (Inteligência).",
	MEDICINA: "Estabilizar e tratar feridas (Sabedoria).",
	NATUREZA: "Conhecer plantas, bichos e o clima (Inteligência).",
	PRESTIDIGITACAO: "Truques de mão e bolsos leves (Destreza).",
	RELIGIAO: "Conhecer deuses e ritos (Inteligência).",
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


## Resolve um teste de habilidade; Mente Tática tenta o d10 só após uma falha e só gasta
## Second Wind quando o bônus muda a falha para sucesso. `vantagem`/`desvantagem` usam a
## mesma regra do ataque (2d20; as duas juntas se anulam).
static func resolver_teste(bonus: int, cd: int, mente_tatica_ligada: bool,
		pode_usar_folego: bool, rng: RandomNumberGenerator,
		vantagem: bool = false, desvantagem: bool = false) -> Dictionary:
	var d20 := Combate.rolar_d20(rng, desvantagem, vantagem)
	var total := d20 + bonus
	var passou := total >= cd
	var d10 := 0
	var usou_mente_tatica := false
	if not passou and mente_tatica_ligada and pode_usar_folego:
		d10 = rng.randi_range(1, 10)
		total += d10
		passou = total >= cd
		usou_mente_tatica = passou
	return {
		"d20": d20,
		"d10": d10,
		"total": total,
		"passou": passou,
		"usou_mente_tatica": usou_mente_tatica,
		"vantagem": vantagem and not desvantagem,
	}
