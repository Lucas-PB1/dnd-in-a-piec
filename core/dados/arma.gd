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
## Imagem da arma (pode estar na diagonal: veja angulo_arte e pegada).
@export var textura: Texture2D
## Para onde a lâmina aponta NA IMAGEM (graus; 0 = direita, -45 = para cima e à direita).
@export var angulo_arte: float = 0.0
## Ponto da imagem (px) onde a mão segura.
@export var pegada: Vector2 = Vector2(4.0, 3.5)
## Distância (px) da pegada até a ponta: é o que a ponta alcança a partir da mão.
@export var comprimento: float = 0.0

@export_group("Propriedades (D&D)")
## Leve: dá para usar uma 2ª arma leve na outra mão (combo com J de novo durante o golpe).
@export var leve: bool = false
## Pesada: atacar com FOR < 13 tem desvantagem.
@export var pesada: bool = false
## Duas Mãos: ocupa também a mão secundária (sem escudo nem 2ª arma).
@export var duas_maos: bool = false
## Versátil: dado de dano usando as duas mãos (mão secundária vazia). Vazio = não é versátil.
@export var dados_versatil: String = ""
## Alcance (Reach): a ponta chega a 10 pés em vez de 5 (poses + passo; ver tools/gerar_armas.gd).
@export var alcance_estendido: bool = false
## Arremesso: distância normal e longa (pés). 0 = não arremessa. Tecla K; a arma cai e se pega com E.
@export var arremesso_normal_pes: float = 0.0
@export var arremesso_longo_pes: float = 0.0
## Arremessada, voa de ponta (Azagaia, Lança, Tridente, Dardo) e finca no chão; senão, gira.
@export var arremesso_de_ponta: bool = false
## Maestria (Proficiencias.MAESTRIAS): só vale se a classe dominar a arma (fatia 11c).
@export var maestria: StringName = &""

@export_group("Referência")
## Nome no livro (inglês).
@export var nome_original: String = ""
@export var peso: String = ""
@export var preco: String = ""
@export var livro: String = ""
## Efeito visual do golpe (EFEITO_*): arco nos cortes, rastro nas estocadas, impacto nos
## contundentes. Vazio = nenhum (o chicote já desenha o estalo nos quadros).
@export var efeito: StringName = EFEITO_CORTE
## Cor do efeito do golpe.
@export var cor_corte: Color = Color(0.85, 0.95, 1.0, 0.9)

@export_group("Golpe")
## Poses-chave do golpe desta arma, em ordem de tempo (gerado por tools/gerar_armas.gd).
## A última pose marca o fim do golpe. A área de acerto acompanha a arma (pegada até a ponta).
@export var poses: Array[PoseGolpe] = []
## Quadros desenhados do golpe (armas flexíveis: mangual, chicote). Vazio = a imagem da arma
## gira com as poses. Com quadros, a pose i mostra o quadro i, sem girar (já desenhado
## com o herói olhando para a direita) e com a mão em `pegada_quadros`.
@export var quadros: Array[Texture2D] = []
@export var pegada_quadros: Vector2 = Vector2.ZERO
## Passo à frente (px) que o herói dá no golpe para a ponta chegar ao alcance da regra
## (5 pés; 10 com Alcance). Armas curtas dão um passo maior.
@export var passo: float = 0.0


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


# --- Golpe (poses no tempo) -----------------------------------------------------------

const EFEITO_CORTE := &"corte"
const EFEITO_RASTRO := &"rastro"
const EFEITO_IMPACTO := &"impacto"

## Curva do trecho que acerta (< 1 = rápido no começo e freia no fim, como um golpe de verdade).
const CURVA_ACERTO := 0.4


## Duração do golpe (s): o tempo da última pose.
func duracao() -> float:
	return poses[poses.size() - 1].tempo if not poses.is_empty() else 0.0


## Pose no instante `t` (s), interpolada entre as poses-chave.
func pose_em(t: float) -> PoseGolpe:
	var i := indice_da_pose(t)
	if i >= poses.size() - 1:
		return poses[poses.size() - 1]
	var a := poses[i]
	var b := poses[i + 1]
	var fracao := clampf((t - a.tempo) / maxf(b.tempo - a.tempo, 0.001), 0.0, 1.0)
	return PoseGolpe.entre(a, b, ease(fracao, CURVA_ACERTO) if a.acerta else smoothstep(0.0, 1.0, fracao))


## O golpe está acertando no instante `t`?
func acertando(t: float) -> bool:
	var i := indice_da_pose(t)
	return i < poses.size() - 1 and poses[i].acerta


## Fim do último trecho que acerta (s): até lá o herói dá o passo à frente.
func fim_do_acerto() -> float:
	for i in range(poses.size() - 2, -1, -1):
		if poses[i].acerta:
			return poses[i + 1].tempo
	return 0.0


## Índice da pose em que o instante `t` está (a última com tempo <= t).
func indice_da_pose(t: float) -> int:
	var i := 0
	while i < poses.size() - 1 and poses[i + 1].tempo <= t:
		i += 1
	return i


## Amostras por trecho que acerta, para medir até onde a ponta vai.
const AMOSTRAS_ALCANCE := 12


## Até onde a ponta chega à frente da mão (px) nos trechos que acertam, sem o passo.
func alcance_da_ponta() -> float:
	var mais_longe := 0.0
	for i in poses.size() - 1:
		if not poses[i].acerta:
			continue
		for s in AMOSTRAS_ALCANCE + 1:
			var pose := pose_em(lerpf(poses[i].tempo, poses[i + 1].tempo, float(s) / AMOSTRAS_ALCANCE))
			mais_longe = maxf(mais_longe, pose.mao.x + comprimento * pose.escala * cos(deg_to_rad(pose.angulo)))
	return mais_longe
