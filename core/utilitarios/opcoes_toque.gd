class_name OpcoesToque
extends RefCounted
## Opções dos controles de toque (celular), gravadas em user://toque.cfg: analógico ou
## setas, quando aparecem, e o layout que o jogador ajustou (posição, tamanho e
## transparência). A main chama carregar() no começo; quem muda chama salvar(). Não é
## autoload (como Comandos).

## Onde as opções ficam gravadas. Os testes trocam por outro arquivo, para não mexer na configuração de verdade.
static var caminho: String = "user://toque.cfg"
const SECAO := "toque"

enum Modo { ANALOGICO, SETAS }
enum Mostrar { AUTOMATICO, SEMPRE, NUNCA }

const NOMES_MODO: PackedStringArray = ["Analógico", "Setas"]
const NOMES_MOSTRAR: PackedStringArray = ["Só com tela de toque", "Sempre", "Nunca"]
const OPACIDADE_PADRAO := 1.0
const OPACIDADE_MINIMA := 0.2
## Habilidades especiais que dá para pôr nos slots da barra de atalhos do celular (ação -> nome no botão).
## Atacar, Pular e Lançar são ações básicas e ficam sempre na tela, fora dos slots.
const HABILIDADES: Dictionary[StringName, String] = {
	&"folego": "Fôlego",
	&"surto_acao": "Surto",
	&"mente_tatica": "Mente",
	&"sorte": "Sorte",
	&"defesa": "Defesa",
	&"investida": "Investida",
	&"rajada": "Rajada",
	&"dado_de_vida": "Dado",
	&"veneno": "Veneno",
}
const NOME_SLOT_VAZIO := "Vazio"
## Quantos slots a barra tem. Os oito vêm com Fôlego, Surto, Mente Tática, Sorte, Defesa, Investida, Dado de vida e Veneno; os outros esperam habilidades novas (Subclasse, magias).
const QUANTIDADE_SLOTS := 8

static var modo: Modo = Modo.ANALOGICO
static var mostrar: Mostrar = Mostrar.AUTOMATICO
## Transparência dos controles (multiplica a cor; 1 = como foram desenhados).
static var opacidade: float = OPACIDADE_PADRAO
## Posições ajustadas pelo jogador: id do controle -> [canto x, canto y, centro x, centro y, raio].
## Vazio = posições padrão de ControlesToque.
static var posicoes: Dictionary = {}
## O que vai em cada slot da barra de atalhos (ação da habilidade, ou vazio).
static var slots: Array[StringName] = padrao_slots()


static func carregar() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(caminho) != OK:
		restaurar_padrao()
		return
	modo = clampi(int(arquivo.get_value(SECAO, "modo", Modo.ANALOGICO)), 0, Modo.size() - 1) as Modo
	mostrar = clampi(int(arquivo.get_value(SECAO, "mostrar", Mostrar.AUTOMATICO)), 0, Mostrar.size() - 1) as Mostrar
	opacidade = clampf(float(arquivo.get_value(SECAO, "opacidade", OPACIDADE_PADRAO)), OPACIDADE_MINIMA, 1.0)
	posicoes = arquivo.get_value(SECAO, "posicoes", {})
	slots = _ler_slots(arquivo.get_value(SECAO, "slots", []))


## Fábrica do celular: analógico, automático, opacidade cheia, slots das 8 habilidades, posições padrão.
static func restaurar_padrao() -> void:
	modo = Modo.ANALOGICO
	mostrar = Mostrar.AUTOMATICO
	opacidade = OPACIDADE_PADRAO
	posicoes = {}
	slots = padrao_slots()


static func salvar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value(SECAO, "modo", modo)
	arquivo.set_value(SECAO, "mostrar", mostrar)
	arquivo.set_value(SECAO, "opacidade", opacidade)
	arquivo.set_value(SECAO, "posicoes", posicoes)
	arquivo.set_value(SECAO, "slots", slots.map(func(acao: StringName) -> String: return String(acao)))
	arquivo.save(caminho)


## Slots de fábrica: Fôlego, Surto, Mente Tática, Sorte, Defesa, Investida, Dado de vida e Veneno; o resto vazio.
static func padrao_slots() -> Array[StringName]:
	var padrao: Array[StringName] = []
	for i in QUANTIDADE_SLOTS:
		padrao.append(HABILIDADES.keys()[i] if i < HABILIDADES.size() else &"")
	return padrao


## Nome que aparece no botão (vazio vira "Vazio").
static func nome_da_habilidade(acao: StringName) -> String:
	return HABILIDADES.get(acao, NOME_SLOT_VAZIO)


## Lê os slots salvos: o que não for uma habilidade conhecida vira vazio, e a lista fecha no tamanho certo.
static func _ler_slots(valor: Variant) -> Array[StringName]:
	var lidos: Array[StringName] = []
	var lista: Array = valor if valor is Array else []
	for i in QUANTIDADE_SLOTS:
		var acao := StringName(str(lista[i])) if i < lista.size() else &""
		lidos.append(acao if HABILIDADES.has(acao) else &"")
	return lidos if not lista.is_empty() else padrao_slots()


## Os controles aparecem? Automático = só se o aparelho tem tela de toque.
static func visiveis() -> bool:
	match mostrar:
		Mostrar.SEMPRE:
			return true
		Mostrar.NUNCA:
			return false
	return DisplayServer.is_touchscreen_available()
