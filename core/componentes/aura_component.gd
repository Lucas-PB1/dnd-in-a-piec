class_name AuraComponent
extends Node2D
## Brilho em volta de uma criatura, tudo por código: uma aura que pulsa enquanto está ligada
## (Surto de Ação) e pulsos avulsos, com um anel que abre e faíscas (ativar o Surto, curar com o
## Fôlego). Fica atrás do corpo. Não decide nada: quem usa liga, desliga e manda pulsar.

## Metade da largura e da altura da aura (px): o corpo do herói cabe dentro.
const RAIO_X := 22.0
const RAIO_Y := 36.0
const CAMADAS_AURA := 3
const VELOCIDADE_PULSACAO := 5.0
const TEMPO_APARECER := 0.2
const TEMPO_SUMIR := 0.3
## Transparência da camada mais de dentro da aura (as de fora são mais fracas).
const OPACIDADE_AURA := 0.36
## Contorno da aura (o que faz ela ler bem sobre qualquer fundo).
const OPACIDADE_CONTORNO := 0.7
const LARGURA_CONTORNO := 2.0
const TEMPO_ANEL_PADRAO := 0.55
const ESCALA_ANEL_INICIAL := 0.5
const ESCALA_ANEL_FINAL := 2.2
const LARGURA_ANEL := 3.0
const PONTOS_DO_CIRCULO := 40
const LADO_PARTICULA := 4
const MOTES_QUANTIDADE := 16
const MOTES_VIDA := 0.9

var _ligada: bool = false
var _intensidade: float = 0.0
var _cor: Color = Color.WHITE
var _tempo: float = 0.0
## Anéis em andamento: {tempo, duracao, cor}.
var _aneis: Array[Dictionary] = []
var _motes: CPUParticles2D
var _quadradinho: ImageTexture


func _ready() -> void:
	show_behind_parent = true  # a aura fica atrás do corpo
	var imagem := Image.create(LADO_PARTICULA, LADO_PARTICULA, false, Image.FORMAT_RGBA8)
	imagem.fill(Color.WHITE)
	_quadradinho = ImageTexture.create_from_image(imagem)
	_motes = _criar_motes()
	add_child(_motes)
	set_process(false)


func esta_ligada() -> bool:
	return _ligada


## Liga a aura: ela surge, pulsa e solta faíscas devagar até desligar.
func ligar(cor: Color) -> void:
	_cor = cor
	_ligada = true
	_motes.color = cor
	_motes.emitting = true
	set_process(true)


func desligar() -> void:
	_ligada = false
	_motes.emitting = false


## Um pulso: anel que abre e faíscas que saem. `subindo` = faíscas que flutuam para cima (cura);
## senão elas explodem para os lados (poder).
func pulso(cor: Color, faiscas: int, duracao: float = TEMPO_ANEL_PADRAO, subindo: bool = false) -> void:
	_aneis.append({"tempo": 0.0, "duracao": duracao, "cor": cor})
	_soltar_faiscas(cor, faiscas, subindo)
	set_process(true)


func _process(delta: float) -> void:
	_tempo += delta
	var alvo := 1.0 if _ligada else 0.0
	var tempo_da_mudanca := TEMPO_APARECER if _ligada else TEMPO_SUMIR
	_intensidade = move_toward(_intensidade, alvo, delta / tempo_da_mudanca)
	for anel in _aneis:
		anel["tempo"] += delta
	_aneis = _aneis.filter(func(anel: Dictionary) -> bool: return anel["tempo"] < anel["duracao"])
	queue_redraw()
	if not _ligada and _intensidade <= 0.0 and _aneis.is_empty():
		set_process(false)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, RAIO_Y / RAIO_X))  # círculos viram elipses em pé
	if _intensidade > 0.0:
		_desenhar_aura()
	for anel in _aneis:
		_desenhar_anel(anel)


func _desenhar_aura() -> void:
	for camada in CAMADAS_AURA:
		var pulsar := 0.07 * sin(_tempo * VELOCIDADE_PULSACAO + camada)
		var raio := RAIO_X * (0.5 + 0.22 * camada + pulsar)
		var opacidade := OPACIDADE_AURA * _intensidade / (camada + 1)
		draw_circle(Vector2.ZERO, raio, Color(_cor, opacidade))
	var pulso_do_contorno := 0.75 + 0.25 * sin(_tempo * VELOCIDADE_PULSACAO)
	draw_arc(Vector2.ZERO, RAIO_X * 0.95, 0.0, TAU, PONTOS_DO_CIRCULO, Color(_cor, OPACIDADE_CONTORNO * _intensidade * pulso_do_contorno), LARGURA_CONTORNO, true)


func _desenhar_anel(anel: Dictionary) -> void:
	var fracao: float = anel["tempo"] / anel["duracao"]
	var suave := 1.0 - pow(1.0 - fracao, 3.0)  # abre rápido e desacelera
	var raio := RAIO_X * lerpf(ESCALA_ANEL_INICIAL, ESCALA_ANEL_FINAL, suave)
	var cor: Color = anel["cor"]
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, PONTOS_DO_CIRCULO, Color(cor, 1.0 - fracao), LARGURA_ANEL * (1.0 - fracao * 0.6), true)


func _criar_motes() -> CPUParticles2D:
	var motes := CPUParticles2D.new()
	motes.texture = _quadradinho
	motes.amount = MOTES_QUANTIDADE
	motes.lifetime = MOTES_VIDA
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(RAIO_X * 0.7, RAIO_Y * 0.6)
	motes.direction = Vector2.UP
	motes.spread = 20.0
	motes.initial_velocity_min = 12.0
	motes.initial_velocity_max = 30.0
	motes.gravity = Vector2.ZERO
	motes.scale_amount_min = 0.55
	motes.scale_amount_max = 1.1
	motes.emitting = false
	return motes


func _soltar_faiscas(cor: Color, quantidade: int, subindo: bool) -> void:
	var sopro := CPUParticles2D.new()
	sopro.texture = _quadradinho
	sopro.one_shot = true
	sopro.explosiveness = 0.9
	sopro.amount = quantidade
	sopro.lifetime = 0.7
	sopro.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sopro.emission_rect_extents = Vector2(RAIO_X * 0.6, RAIO_Y * 0.5)
	sopro.direction = Vector2.UP if subindo else Vector2.RIGHT
	sopro.spread = 25.0 if subindo else 180.0
	sopro.initial_velocity_min = 20.0 if subindo else 60.0
	sopro.initial_velocity_max = 50.0 if subindo else 130.0
	sopro.gravity = Vector2(0.0, -30.0) if subindo else Vector2(0.0, 120.0)
	sopro.scale_amount_min = 0.6
	sopro.scale_amount_max = 1.3
	sopro.color = cor
	sopro.emitting = true
	add_child(sopro)
	get_tree().create_timer(sopro.lifetime + 0.2, true, false, true).timeout.connect(sopro.queue_free)
