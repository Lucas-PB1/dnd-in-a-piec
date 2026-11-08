class_name DissolverComponent
extends Node2D
## Morte por código, sem animação própria: o sprite estoura em branco (cresce um pouco e pisca),
## some de uma vez e no lugar sai uma explosão de fragmentos e fumaça. A sombra some junto. Avisa
## com `terminou` quando a nuvem acaba, e quem usa decide o que fazer (em geral, sair do jogo).
## Vale para qualquer criatura; a cor dos fragmentos vem da própria criatura.

signal terminou
## Emitido ao começar a morrer (o clarão), com o ponto do corpo no mundo: o tremor e a pausa entram aqui.
signal morrendo(onde: Vector2)

## Sprite que estoura e sombra opcional que o acompanha.
@export var sprite: AnimatedSprite2D
@export var sombra: CanvasItem
## Cor dos fragmentos (a pele da criatura) e da fumaça.
@export var cor_fragmento: Color = Color(0.45, 0.62, 0.25)
@export var cor_fumaca: Color = Color(0.82, 0.8, 0.76, 0.85)
## Altura do meio do corpo acima dos pés (px; negativo = para cima), de onde sai a explosão.
@export var altura_do_corpo: float = -22.0
## Tempo do clarão antes de estourar (s).
@export var tempo_clarao: float = 0.12
## O sprite cresce esta fração durante o clarão.
@export var crescer: float = 0.15

## Cor acima de 1 deixa o sprite "estourado" (branco) sem mudar a textura.
const COR_CLARAO := Color(3.0, 3.0, 3.0, 1.0)
const FRAGMENTOS_QUANTIDADE := 22
const FRAGMENTOS_VIDA := 0.55
const FUMACA_QUANTIDADE := 14
const FUMACA_VIDA := 0.6
## Quadradinho branco das partículas (sem textura elas saem com 1 px, quase invisíveis).
const LADO_PARTICULA := 4

var _em_curso: bool = false


## Começa a morrer. Chamar duas vezes não reinicia.
func dissolver() -> void:
	if sprite == null or _em_curso:
		return
	_em_curso = true
	morrendo.emit(sprite.global_position)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate", COR_CLARAO, tempo_clarao)
	tween.tween_property(sprite, "scale", sprite.scale * (1.0 + crescer), tempo_clarao)
	tween.chain().tween_callback(_estourar)


func _estourar() -> void:
	sprite.visible = false
	if sombra != null:
		sombra.visible = false
	_soltar(FRAGMENTOS_QUANTIDADE, cor_fragmento, 170.0, 90.0, FRAGMENTOS_VIDA, 1.6, 380.0)
	_soltar(FUMACA_QUANTIDADE, cor_fumaca, 60.0, 35.0, FUMACA_VIDA, 2.4, -20.0)
	get_tree().create_timer(FUMACA_VIDA, true, false, true).timeout.connect(terminou.emit)


func _textura_quadrada() -> ImageTexture:
	var imagem := Image.create(LADO_PARTICULA, LADO_PARTICULA, false, Image.FORMAT_RGBA8)
	imagem.fill(Color.WHITE)
	return ImageTexture.create_from_image(imagem)


## Sopro de quadradinhos que saem do corpo para todos os lados.
func _soltar(quantidade: int, cor: Color, velocidade: float, espalhar: float, vida: float, tamanho: float, gravidade: float) -> void:
	var nuvem := CPUParticles2D.new()
	nuvem.position = Vector2(0.0, altura_do_corpo)  # o componente é um Node2D na raiz da criatura
	nuvem.one_shot = true
	nuvem.explosiveness = 1.0
	nuvem.amount = quantidade
	nuvem.lifetime = vida
	nuvem.direction = Vector2.UP
	nuvem.spread = 180.0
	nuvem.initial_velocity_min = maxf(velocidade - espalhar, 0.0)
	nuvem.initial_velocity_max = velocidade + espalhar
	nuvem.gravity = Vector2(0.0, gravidade)
	nuvem.scale_amount_min = tamanho * 0.6
	nuvem.scale_amount_max = tamanho
	nuvem.color = cor
	nuvem.texture = _textura_quadrada()
	nuvem.emitting = true
	add_child(nuvem)
