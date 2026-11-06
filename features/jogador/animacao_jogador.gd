class_name AnimacaoJogador
extends AnimatedSprite2D
## Componente visual do herói. Não conhece o Jogador: recebe o estado e a velocidade
## pelo atualizar(), chamado pelo dono a cada passo de física (call down).

## Velocidade vertical (px/s) a partir da qual troca de "topo do pulo" para subindo/caindo.
@export var limite_topo_pulo: float = 80.0
## Velocidade mínima da animação de passos, para não ficar em câmera lenta ao acelerar.
@export var escala_minima_passos: float = 0.5


## Escolhe a animação para o `estado` atual da máquina do herói.
func atualizar(estado: StringName, velocidade: Vector2, direcao_olhar: int, stats: StatsJogador) -> void:
	flip_h = direcao_olhar < 0
	speed_scale = 1.0
	match estado:
		&"NoAr":
			_animar_no_ar(velocidade.y)
		&"Andando":
			_animar_passos(&"walk", absf(velocidade.x) / stats.velocidade)
		&"Correndo":
			_animar_passos(&"correr", absf(velocidade.x) / stats.velocidade_corrida)
		&"Atacando":
			play(&"ataque")
		_:
			_animar_parado()


## Toca a agachadinha de aterrissagem (ligado ao sinal `aterrissou` do dono).
func tocar_aterrissagem() -> void:
	play(&"aterrissar")


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
