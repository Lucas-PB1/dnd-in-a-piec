extends SceneTree
## Recorta a porta em arco da folha CC0 do castelo (rubberduck, OpenGameArt) e tira a margem transparente.
##   godot --headless --path . --script res://tools/recortar_porta.gd
## Entra assets/tiles/castelo/castle_tileset_part3.png; sai assets/tiles/castelo/porta.png.

const ORIGEM := "res://assets/tiles/castelo/castle_tileset_part3.png"
const DESTINO := "res://assets/tiles/castelo/porta.png"
## Onde está a porta pequena de perfil na folha (x, y, largura, altura), com folga.
const REGIAO := Rect2i(36, 36, 56, 98)


func _initialize() -> void:
	var folha := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM))
	var recorte := folha.get_region(REGIAO)
	var util := recorte.get_used_rect()
	var porta := recorte.get_region(util)
	porta.save_png(ProjectSettings.globalize_path(DESTINO))
	print("Porta recortada: %dx%d" % [porta.get_width(), porta.get_height()])
	quit()
