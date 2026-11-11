class_name OpcoesTela
extends RefCounted
## Modo da janela no PC (janela ou tela cheia), gravado em user://tela.cfg. A main chama
## carregar() + aplicar() no começo; a tela de opções muda e salva. Não é autoload.

const SECAO := "tela"
const JANELA := 0
const TELA_CHEIA := 1
const NOMES: PackedStringArray = ["Janela", "Tela cheia"]
## Janela padrão = 2× a resolução interna (640x360).
const LARGURA_JANELA := 1280
const ALTURA_JANELA := 720

## Onde as opções ficam gravadas. Os testes trocam por outro arquivo.
static var caminho: String = "user://tela.cfg"
static var modo: int = JANELA


static func carregar() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(caminho) != OK:
		return
	modo = clampi(int(arquivo.get_value(SECAO, "modo", modo)), JANELA, TELA_CHEIA)


static func salvar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value(SECAO, "modo", modo)
	arquivo.save(caminho)


## Aplica o modo na janela do jogo. Em headless / sem DisplayServer de janela, não faz nada.
static func aplicar() -> void:
	if DisplayServer.get_name() == &"headless":
		return
	var janela := DisplayServer.MAIN_WINDOW_ID
	if modo == TELA_CHEIA:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, janela)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, janela)
	DisplayServer.window_set_size(Vector2i(LARGURA_JANELA, ALTURA_JANELA), janela)


static func definir(novo: int) -> void:
	modo = clampi(novo, JANELA, TELA_CHEIA)
	aplicar()
