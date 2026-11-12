extends TesteBase
## Ícone do jogo: PNG próprio (não o robô do Godot), 128×128.
## godot --headless --debug --path . --script res://tests/ui/teste_icone.gd

const CAMINHO := "res://icon.png"
const LADO := 128


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_checar(ResourceLoader.exists(CAMINHO), "icon.png existe")
	_checar(not ResourceLoader.exists("res://icon.svg"), "icon.svg padrão foi arquivado")
	var img := Image.load_from_file(ProjectSettings.globalize_path(CAMINHO))
	_checar(img != null and img.get_width() == LADO and img.get_height() == LADO,
		"ícone tem %dx%d" % [LADO, LADO])
	var opacos := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				opacos += 1
	_checar(opacos > LADO * LADO / 4, "ícone não está vazio")
	var cfg := ConfigFile.new()
	_checar(cfg.load("res://project.godot") == OK
		and str(cfg.get_value("application", "config/icon", "")) == CAMINHO,
		"project.godot aponta para icon.png")
	_terminar("ícone do jogo")
