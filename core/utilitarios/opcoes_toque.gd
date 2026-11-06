class_name OpcoesToque
extends RefCounted
## Opções dos controles de toque (celular), gravadas em user://toque.cfg: analógico ou
## setas, quando aparecem, e o layout que o jogador ajustou (posição, tamanho e
## transparência). A main chama carregar() no começo; quem muda chama salvar(). Não é
## autoload (como Comandos).

const ARQUIVO := "user://toque.cfg"
const SECAO := "toque"

enum Modo { ANALOGICO, SETAS }
enum Mostrar { AUTOMATICO, SEMPRE, NUNCA }

const NOMES_MODO: PackedStringArray = ["Analógico", "Setas"]
const NOMES_MOSTRAR: PackedStringArray = ["Só com tela de toque", "Sempre", "Nunca"]
const OPACIDADE_PADRAO := 1.0
const OPACIDADE_MINIMA := 0.2

static var modo: Modo = Modo.ANALOGICO
static var mostrar: Mostrar = Mostrar.AUTOMATICO
## Transparência dos controles (multiplica a cor; 1 = como foram desenhados).
static var opacidade: float = OPACIDADE_PADRAO
## Posições ajustadas pelo jogador: id do controle -> [canto x, canto y, centro x, centro y, raio].
## Vazio = posições padrão de ControlesToque.
static var posicoes: Dictionary = {}


static func carregar() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO) != OK:
		return
	modo = clampi(int(arquivo.get_value(SECAO, "modo", modo)), 0, Modo.size() - 1) as Modo
	mostrar = clampi(int(arquivo.get_value(SECAO, "mostrar", mostrar)), 0, Mostrar.size() - 1) as Mostrar
	opacidade = clampf(float(arquivo.get_value(SECAO, "opacidade", opacidade)), OPACIDADE_MINIMA, 1.0)
	posicoes = arquivo.get_value(SECAO, "posicoes", {})


static func salvar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value(SECAO, "modo", modo)
	arquivo.set_value(SECAO, "mostrar", mostrar)
	arquivo.set_value(SECAO, "opacidade", opacidade)
	arquivo.set_value(SECAO, "posicoes", posicoes)
	arquivo.save(ARQUIVO)


## Os controles aparecem? Automático = só se o aparelho tem tela de toque.
static func visiveis() -> bool:
	match mostrar:
		Mostrar.SEMPRE:
			return true
		Mostrar.NUNCA:
			return false
	return DisplayServer.is_touchscreen_available()
