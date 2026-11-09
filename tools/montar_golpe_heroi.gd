extends SceneTree
## Monta as animações "corte", "dano" e "morte" do herói a partir da folha do SpriteCook (heroi_corte_v4.png, quadros de
## 84x84): recorta cada quadro para 80x80 com os pés no mesmo lugar dos outros (centro de baixo) e
## põe a animação no heroi_frames.tres. Depois rode marcar_pontos_mao.gd (os pontos da mão deste golpe
## estão fixos lá, porque as mãos sobem acima da cabeça e a busca automática não as acha).
##   godot --headless --path . --script res://tools/montar_golpe_heroi.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/marcar_pontos_mao.gd

const PASTA := "res://features/jogador/sprites/"
const ORIGEM := PASTA + "heroi_corte_v4.png"
const DESTINO := PASTA + "heroi_corte.png"
const FRAMES := PASTA + "heroi_frames.tres"
const ANIMACAO := &"corte"
## Golpe extra das duas armas: o corpo faz o movimento (heroi_corte_duplo_v2.png, também de 8 quadros).
const ORIGEM_DUPLO := PASTA + "heroi_corte_duplo_v2.png"
const DESTINO_DUPLO := PASTA + "heroi_corte_duplo.png"
const ANIMACAO_DUPLA := &"corte_duplo"
const QUADROS := 8
const LADO_ORIGEM := 84
const LADO := 80
## Onde o quadro de 80 começa dentro do de 84: os pés do quadro parado ficam no centro de baixo,
## como no resto do herói (medido: corpo do 1º quadro em x 21..63, pés em y 84).
const RECORTE := Vector2i(2, 4)
## Só para a cena aberta sozinha: no jogo o quadro segue o tempo do golpe da arma.
const VELOCIDADE := 12.0
## Folhas do SpriteCook que já vêm em quadros de 80x80: nome -> [arquivo, quadros, quadros por segundo].
## O dano toca em ~0,3 s (o recuo do herói); a morte, em ~1,2 s.
const ANIMACOES_PRONTAS := {
	&"dano": ["heroi_dano_sc.png", 8, 26.0],
	&"morte": ["heroi_morte_sc.png", 12, 10.0],
}


func _initialize() -> void:
	_recortar(ORIGEM, DESTINO)
	_recortar(ORIGEM_DUPLO, DESTINO_DUPLO)
	print("Folhas salvas. Rode --import e depois rode este script de novo para ligar as animações.")
	if not ResourceLoader.exists(DESTINO) or not ResourceLoader.exists(DESTINO_DUPLO):
		quit()
		return
	_ligar_animacao()
	quit()


## Recorta cada quadro de 84x84 da folha do SpriteCook para 80x80, com os pés no lugar certo.
func _recortar(origem_png: String, destino_png: String) -> void:
	var folha := Image.load_from_file(ProjectSettings.globalize_path(origem_png))
	var saida := Image.create(LADO * QUADROS, LADO, false, Image.FORMAT_RGBA8)
	for i in QUADROS:
		var origem := Rect2i(Vector2i(i * LADO_ORIGEM, 0) + RECORTE, Vector2i(LADO, LADO))
		saida.blit_rect(folha, origem, Vector2i(i * LADO, 0))
	saida.save_png(ProjectSettings.globalize_path(destino_png))


func _ligar_animacao() -> void:
	var textura: Texture2D = load(DESTINO)
	if textura == null:
		print("Importe a folha primeiro (--import).")
		return
	var frames: SpriteFrames = load(FRAMES)
	_adicionar(frames, ANIMACAO, textura, QUADROS, VELOCIDADE)
	_adicionar(frames, ANIMACAO_DUPLA, load(DESTINO_DUPLO), QUADROS, VELOCIDADE)
	for nome in ANIMACOES_PRONTAS:
		var dados: Array = ANIMACOES_PRONTAS[nome]
		_adicionar(frames, nome, load(PASTA + dados[0]), dados[1], dados[2])
	ResourceSaver.save(frames, FRAMES)
	print("Animações ligadas em ", FRAMES)


func _adicionar(frames: SpriteFrames, nome: StringName, textura: Texture2D, quadros: int, velocidade: float) -> void:
	if frames.has_animation(nome):
		frames.remove_animation(nome)
	frames.add_animation(nome)
	frames.set_animation_speed(nome, velocidade)
	frames.set_animation_loop(nome, false)
	for i in quadros:
		var quadro := AtlasTexture.new()
		quadro.atlas = textura
		quadro.region = Rect2(i * LADO, 0, LADO, LADO)
		frames.add_frame(nome, quadro)
