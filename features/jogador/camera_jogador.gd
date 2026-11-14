class_name CameraJogador
extends Camera2D
## Câmera filha do herói: cola no corpo. A suavização do Camera2D atrasava a tela
## (parecia lag). O "olhar à frente" fica no olhar_para() (call down).
## O callback permanece na física: com interpolação ligada, o Godot recusa o Idle.
## Também treme (tremer()) quando algo bate forte. Não conhece o Jogador.

## Quantos pixels a câmera adianta na direção em que o herói olha.
@export var olhar_frente: float = 56.0
## Quão rápido a câmera troca de lado quando o herói vira. Maior = mais rápido.
@export var velocidade_olhar: float = 3.0

var _direcao_alvo: int = 1
## Quanto a câmera está adiantada para o lado em que o herói olha (px).
var _olhar_x: float = 0.0
## Tremor: força inicial (px), duração total e o que ainda falta (s).
var _forca_tremor: float = 0.0
var _duracao_tremor: float = 0.0
var _resta_tremor: float = 0.0
var _rng := RandomNumberGenerator.new()


## Diz para que lado olhar: 1 = direita, -1 = esquerda.
func olhar_para(direcao: int) -> void:
	_direcao_alvo = direcao


## Treme a tela por `duracao` s, começando com `forca` px e acalmando até zero. Um tremor mais
## forte que o que está acontecendo toma o lugar dele.
func tremer(forca: float, duracao: float) -> void:
	var restante_atual := _forca_tremor * (_resta_tremor / maxf(_duracao_tremor, 0.001))
	if forca < restante_atual:
		return
	_forca_tremor = forca
	_duracao_tremor = maxf(duracao, 0.001)
	_resta_tremor = _duracao_tremor


func esta_tremendo() -> bool:
	return _resta_tremor > 0.0


func _process(delta: float) -> void:
	_olhar_x = lerpf(_olhar_x, _direcao_alvo * olhar_frente, 1.0 - exp(-velocidade_olhar * delta))
	offset = Vector2(_olhar_x, 0.0) + _desvio_do_tremor(delta)


## Deslocamento deste quadro: aleatório, proporcional ao que falta do tremor (acalma sozinho).
func _desvio_do_tremor(delta: float) -> Vector2:
	if _resta_tremor <= 0.0:
		return Vector2.ZERO
	_resta_tremor = maxf(_resta_tremor - delta, 0.0)
	var forca := _forca_tremor * (_resta_tremor / _duracao_tremor)
	return Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * forca


## Impede a câmera de mostrar fora da fase. `area` em pixels.
func definir_limites(area: Rect2) -> void:
	limit_left = int(area.position.x)
	limit_top = int(area.position.y)
	limit_right = int(area.end.x)
	limit_bottom = int(area.end.y)
	reset_smoothing()
