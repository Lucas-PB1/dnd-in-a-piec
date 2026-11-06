class_name Arma
extends Item
## Dados de uma arma corpo a corpo (item equipável na mão). Uma arma nova = um .tres novo em data/.
## Os tempos contam a partir do início do golpe.

## Dados de dano no formato de D&D (ex.: "1d6" para espada curta, "1d8" para espada longa).
@export var dados_dano: String = "1d6"
## Tipo de dano (TiposDano): espada curta = perfurante, soco = contundente.
@export var tipo_dano: StringName = TiposDano.CONTUNDENTE
## Categoria para proficiência (Proficiencias: simples ou marcial; espada curta = marcial).
## Vazio = ataque desarmado: todo mundo é proficiente.
@export var categoria: StringName = &""
## Acuidade (D&D): o dano usa o maior entre Força e Destreza. Sem ela, usa só Força.
@export var acuidade: bool = false
## Arma não mágica: sofre Corrosão (ex.: tocar o Gray Ooze). Falso para soco e armas mágicas.
@export var corroivel: bool = true
## Imagem da arma, desenhada apontando para a DIREITA com o cabo na origem.
@export var textura: Texture2D

@export_group("Propriedades (D&D)")
## Leve: dá para usar uma 2ª arma leve na outra mão (combo com J de novo durante o golpe).
@export var leve: bool = false
## Pesada: atacar com FOR < 13 tem desvantagem.
@export var pesada: bool = false
## Duas Mãos: ocupa também a mão secundária (sem escudo nem 2ª arma).
@export var duas_maos: bool = false
## Versátil: dado de dano usando as duas mãos (mão secundária vazia). Vazio = não é versátil.
@export var dados_versatil: String = ""
## Alcance (Reach): +5 pés no golpe (a área do golpe já inclui isso).
@export var alcance_estendido: bool = false
## Arremesso: distância normal e longa (pés). 0 = não arremessa. Tecla K; a arma cai e se pega com E.
@export var arremesso_normal_pes: float = 0.0
@export var arremesso_longo_pes: float = 0.0
## Maestria (Proficiencias.MAESTRIAS): só vale se a classe dominar a arma (fatia 11c).
@export var maestria: StringName = &""

@export_group("Referência")
## Nome no livro (inglês).
@export var nome_original: String = ""
@export var peso: String = ""
@export var preco: String = ""
@export var livro: String = ""
## Cor do arco de corte.
@export var cor_corte: Color = Color(0.85, 0.95, 1.0, 0.9)

@export_group("Área do golpe")
## Até onde o golpe alcança à frente do herói (px).
@export var alcance: float = 44.0
## Altura da área do golpe (px).
@export var altura: float = 40.0

@export_group("Tempos (s)")
## Duração total do golpe (o herói não pode golpear de novo antes disso).
@export var duracao: float = 0.32
## Quando o corte começa a acertar.
@export var inicio_acerto: float = 0.06
## Quando o corte para de acertar.
@export var fim_acerto: float = 0.16

@export_group("Movimento da arma (graus)")
## Ângulo da arma no começo do golpe (negativo = levantada para trás).
@export var angulo_inicial: float = -110.0
## Ângulo da arma no fim do golpe (positivo = abaixada à frente).
@export var angulo_final: float = 35.0


func _init() -> void:
	espaco = Item.ESPACO_MAO


## Os dados de dano já interpretados. Com `duas_maos_livres` e arma versátil, usa o dado maior.
## Se o texto estiver errado, avisa e usa 1d4.
func dado(duas_maos_livres: bool = false) -> Dado:
	var notacao := dados_versatil if duas_maos_livres and e_versatil() else dados_dano
	var resultado := Dado.de_texto(notacao)
	if resultado == null:
		push_warning("Arma '%s': dados '%s' inválidos, usando 1d4." % [nome, notacao])
		return Dado.new(1, 4)
	return resultado


func e_versatil() -> bool:
	return dados_versatil != ""


func arremessavel() -> bool:
	return arremesso_normal_pes > 0.0


## Duas Mãos ocupa também a mão secundária.
func espacos_extras() -> Array[StringName]:
	return [Item.ESPACO_MAO_SECUNDARIA] if duas_maos else []


## "Leve, Acuidade, Arremesso (20/60)" — propriedades em português, para a tela.
func texto_propriedades() -> String:
	var partes: PackedStringArray = []
	for par in [[acuidade, "Acuidade"], [leve, "Leve"], [pesada, "Pesada"], [duas_maos, "Duas Mãos"],
			[alcance_estendido, "Alcance"]]:
		if par[0]:
			partes.append(par[1])
	if e_versatil():
		partes.append("Versátil (%s)" % dados_versatil)
	if arremessavel():
		partes.append("Arremesso (%d/%d)" % [arremesso_normal_pes, arremesso_longo_pes])
	return ", ".join(partes)
