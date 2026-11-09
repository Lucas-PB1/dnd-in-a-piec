class_name AnimacaoJogador
extends AnimatedSprite2D
## Componente visual do herói. Não conhece o Jogador: recebe o estado e a velocidade
## pelo atualizar(), chamado pelo dono a cada passo de física (call down).

## Velocidade vertical (px/s) a partir da qual troca de "topo do pulo" para subindo/caindo.
@export var limite_topo_pulo: float = 80.0
## Velocidade mínima da animação de passos, para não ficar em câmera lenta ao acelerar.
@export var escala_minima_passos: float = 0.5
## Onde fica a mão em cada quadro (gerado por tools/marcar_pontos_mao.gd).
@export var pontos_mao: PontosMao
## Transparência nos quadros "apagados" do piscar de invencibilidade.
@export var alfa_piscar: float = 0.3
## A cada quantos passos de física o piscar alterna.
@export var passos_por_piscada: int = 4

## Enquanto true, o herói pisca (invencível depois de apanhar). O dono liga e desliga.
var piscando: bool = false
## Mão da frente desenhada por cima da arma e do escudo (os dedos ficam sobre o cabo).
## O dono desliga quando a mão sai do lugar (golpe, carga do arremesso).
var mao_por_cima: bool = true
## Atirando com arma de disparo: usa a pose de mira (braço esticado na altura do peito).
var mirando: bool = false
## O herói está morrendo: toca a animação de morte e fica deitado (a arma e o escudo somem).
var morrendo: bool = false
## Golpe com corpo próprio (ex.: &"corte"): o quadro vem de fora (o tempo do golpe da arma), não do relógio.
## Vazio = o golpe usa a animação "ataque" de sempre.
var animacao_do_golpe: StringName = &""
var quadro_do_golpe: int = 0

@onready var _mao_frente: AnimatedSprite2D = get_node_or_null("MaoFrente")

var _pulso: Tween
var _ultimo_estado: StringName = &""
## Verde claro do Second Wind, antes de voltar ao branco.
const COR_FOLEGO := Color(0.55, 1.0, 0.7)
const TEMPO_FOLEGO := 0.55
const ANIMACAO_DANO := &"dano"
const ANIMACAO_MORTE := &"morte"


func _ready() -> void:
	frame_changed.connect(_sincronizar_mao)
	animation_changed.connect(_sincronizar_mao)


## Escolhe a animação para o `estado` atual da máquina do herói.
## `vel_andar` e `vel_corrida` (px/s) servem para os passos acompanharem a velocidade.
func atualizar(estado: StringName, velocidade: Vector2, direcao_olhar: int, vel_andar: float, vel_corrida: float) -> void:
	flip_h = direcao_olhar < 0
	speed_scale = 1.0
	_atualizar_piscar()
	if morrendo:
		if animation != ANIMACAO_MORTE:
			play(ANIMACAO_MORTE)
		_sincronizar_mao()
		return
	match estado:
		&"LevandoDano":
			if _ultimo_estado != estado:
				play(ANIMACAO_DANO)  # só no começo do recuo: não reinicia a cada quadro
		&"NoAr":
			_animar_no_ar(velocidade.y)
		&"Andando":
			_animar_passos(&"walk", absf(velocidade.x) / vel_andar)
		&"Correndo":
			_animar_passos(&"correr", absf(velocidade.x) / vel_corrida)
		&"Escalando":
			_animar_passos(&"walk", absf(velocidade.y) / vel_andar)  # as pernas andam na parede
		&"Atacando", &"Arremessando":
			if animacao_do_golpe != &"" and not mirando:
				_mostrar_quadro_do_golpe()
			else:
				play(&"mirar" if mirando else &"ataque")
		_:
			_animar_parado()
	_ultimo_estado = estado
	_sincronizar_mao()


## Quadro escolhido pelo tempo do golpe: o corpo sobe e desce junto com a arma, em qualquer arma de corte.
func _mostrar_quadro_do_golpe() -> void:
	if animation != animacao_do_golpe:
		animation = animacao_do_golpe
	pause()
	frame = clampi(quadro_do_golpe, 0, sprite_frames.get_frame_count(animacao_do_golpe) - 1)


## A camada da mão acompanha o quadro e o lado do herói.
func _sincronizar_mao() -> void:
	if _mao_frente == null:
		return
	_mao_frente.animation = animation
	_mao_frente.frame = frame
	_mao_frente.flip_h = flip_h
	_mao_frente.visible = mao_por_cima


## Ponto da mão da frente no quadro atual, relativo aos pés e já espelhado se virado.
func ponto_da_mao() -> Vector2:
	if pontos_mao == null:
		return Vector2.ZERO
	return _espelhar(pontos_mao.ponto(animation, frame))


## Ponto da mão de trás (a do escudo) no quadro atual.
func ponto_da_mao_de_tras() -> Vector2:
	if pontos_mao == null:
		return Vector2.ZERO
	return _espelhar(pontos_mao.ponto_de_tras(animation, frame))


## Second Wind: o corpo fica verde e volta ao normal.
func pulso_cura() -> void:
	brilhar(COR_FOLEGO, TEMPO_FOLEGO)


## O corpo pega a `cor` de uma vez e volta ao normal em `tempo` (Surto de Ação, Fôlego).
func brilhar(cor: Color, tempo: float) -> void:
	if _pulso:
		_pulso.kill()
	modulate = cor
	_pulso = create_tween()
	_pulso.tween_property(self, "modulate", Color.WHITE, tempo)


## Pinta a roupa com a `armadura` (shader roupa_armadura). null = túnica normal.
func vestir(armadura: Armadura) -> void:
	var shader := material as ShaderMaterial
	if shader == null:
		return
	shader.set_shader_parameter(&"vestida", armadura != null)
	if armadura:
		shader.set_shader_parameter(&"cor_armadura", armadura.cor)
		shader.set_shader_parameter(&"detalhe", armadura.detalhe)
		shader.set_shader_parameter(&"tem_detalhe", armadura.detalhe != null)


func _espelhar(ponto: Vector2) -> Vector2:
	return Vector2(-ponto.x, ponto.y) if flip_h else ponto


## Ângulo em que o herói segura a arma na animação atual (graus, olhando para a direita).
func angulo_descanso() -> float:
	return pontos_mao.angulo(animation) if pontos_mao else PontosMao.ANGULO_PADRAO


## Toca a agachadinha de aterrissagem (ligado ao sinal `aterrissou` do dono).
func tocar_aterrissagem() -> void:
	play(&"aterrissar")


func _atualizar_piscar() -> void:
	# Alterna a cada `passos_por_piscada` passos: apagado na 1ª metade de cada ciclo.
	var apagado := piscando and Engine.get_physics_frames() % (2 * passos_por_piscada) < passos_por_piscada
	modulate.a = alfa_piscar if apagado else 1.0


func _animar_no_ar(velocidade_vertical: float) -> void:
	if velocidade_vertical < -limite_topo_pulo:
		play(&"pulo_subindo")
	elif velocidade_vertical > limite_topo_pulo:
		play(&"pulo_caindo")
	else:
		play(&"pulo_topo")


## Os passos acompanham a velocidade (evita o pé "patinar").
func _animar_passos(nome: StringName, fracao_da_maxima: float) -> void:
	play(nome)
	speed_scale = maxf(fracao_da_maxima, escala_minima_passos)


func _animar_parado() -> void:
	if animation == &"aterrissar" and is_playing():
		return  # deixa a aterrissagem terminar
	play(&"idle")
