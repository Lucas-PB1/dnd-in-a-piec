extends SceneTree
## Monta a animação "parado" do lojista a partir da folha do SpriteCook (lojista_idle_sc.png, 8 quadros de 88x88):
## reduz os quadros para ficarem do tamanho do herói e põe tudo no lojista_frames.tres.
##   godot --headless --path . --script res://tools/montar_lojista.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/montar_lojista.gd   (de novo, para ligar os quadros)

const PASTA := "res://features/loja/"
const ORIGEM := PASTA + "lojista_idle_sc.png"
const DESTINO := PASTA + "lojista_idle.png"
const FRAMES := PASTA + "lojista_frames.tres"
const ANIMACAO := &"parado"
const QUADROS := 8
const LADO_ORIGEM := 88
## O lojista fica um pouco menor que o herói (os quadros de 88 viram 75).
const LADO := 75
const VELOCIDADE := 8.0


func _initialize() -> void:
	var folha := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM))
	folha.resize(LADO * QUADROS, LADO, Image.INTERPOLATE_NEAREST)
	folha.save_png(ProjectSettings.globalize_path(DESTINO))
	var textura := load(DESTINO) as Texture2D if ResourceLoader.exists(DESTINO) else null
	if textura == null:
		print("Folha salva. Rode --import e depois este script de novo para ligar os quadros.")
		quit()
		return
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(ANIMACAO)
	frames.set_animation_speed(ANIMACAO, VELOCIDADE)
	frames.set_animation_loop(ANIMACAO, true)
	for i in QUADROS:
		var quadro := AtlasTexture.new()
		quadro.atlas = textura
		quadro.region = Rect2(i * LADO, 0, LADO, LADO)
		frames.add_frame(ANIMACAO, quadro)
	ResourceSaver.save(frames, FRAMES)
	print("Animação do lojista salva em ", FRAMES)
	quit()
