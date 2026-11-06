class_name AtaqueJogador
extends Node2D
## Arma na mão do herói. Fora do golpe, a arma equipada fica na mão, no ângulo de
## descanso da animação. No golpe, gira a partir da mão, mostra o arco de corte e liga a
## Hitbox só na janela de acerto da Arma. O dono chama seguir_mao() todo quadro e
## golpear() para golpear (call down).

## Curva do giro da arma (< 1 = rápido no começo e freia no fim, como um golpe de verdade).
const CURVA_GOLPE := 0.4
## A mão segura o cabo a esta distância (px) da ponta de trás da arma.
const PEGADA := 4.0
## Em repouso, a ponta da arma fica pelo menos isto (px) acima do chão (os pés).
const FOLGA_DO_CHAO := 2.0

var _arma: Arma
var _golpe: Golpe
var _tempo: float = 0.0
var _golpeando: bool = false
var _direcao: int = 1

@onready var _espada: Sprite2D = $Espada
@onready var _corte: AnimatedSprite2D = $Corte
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _forma: CollisionShape2D = $Hitbox/Forma


func _ready() -> void:
	_espada.hide()
	_corte.hide()


## Coloca a arma na `mao` (pixels, relativo aos pés, já espelhado) virada para `direcao`.
## Fora do golpe, mostra a `arma` em repouso no `angulo` (graus), menos inclinada se for
## comprida demais e a ponta fosse entrar no chão. Arma sem imagem (soco) some.
func seguir_mao(mao: Vector2, angulo: float, direcao: int, arma: Arma) -> void:
	position = mao
	_virar(direcao)
	if _golpeando:
		return
	_mostrar_arma(arma.textura)
	_espada.rotation_degrees = _angulo_sem_tocar_chao(angulo, mao.y, arma.textura)


## Começa um golpe com a `arma`; quem for atingido resolve o `golpe` contra a própria CA.
func golpear(arma: Arma, golpe: Golpe) -> void:
	_arma = arma
	_golpe = golpe
	_tempo = 0.0
	_golpeando = true
	_preparar_visual()
	_preparar_area()


func esta_golpeando() -> bool:
	return _golpeando


## Interrompe o golpe no meio (ex.: o herói apanhou).
func cancelar() -> void:
	if _golpeando:
		_terminar()


func _physics_process(delta: float) -> void:
	if not _golpeando:
		return
	_tempo += delta
	_girar_arma()
	_atualizar_acerto()
	if _tempo >= _arma.duracao:
		_terminar()


## Espelha a arma, o corte e a área do golpe. Ao trocar de lado, não deixa a
## interpolação "arrastar" a espada pelo meio do corpo.
func _virar(direcao: int) -> void:
	if direcao == _direcao:
		return
	_direcao = direcao
	scale.x = direcao
	reset_physics_interpolation()


func _preparar_visual() -> void:
	_mostrar_arma(_arma.textura)
	_espada.rotation_degrees = _arma.angulo_inicial
	_corte.modulate = _arma.cor_corte
	_corte.hide()


## Põe a imagem da arma na mão, centrada na altura. Sem imagem (soco), esconde.
func _mostrar_arma(textura: Texture2D) -> void:
	_espada.visible = textura != null
	if textura == null or textura == _espada.texture:
		return
	_espada.texture = textura
	_espada.offset = Vector2(-PEGADA, -textura.get_height() / 2.0)


## Limita o ângulo para baixo: a ponta (comprimento após a pegada) não passa dos pés.
## `altura_mao` = y da mão (negativo = acima dos pés).
func _angulo_sem_tocar_chao(angulo: float, altura_mao: float, textura: Texture2D) -> float:
	if textura == null:
		return angulo
	var comprimento := textura.get_width() - PEGADA
	var seno_maximo := clampf((-altura_mao - FOLGA_DO_CHAO) / comprimento, -1.0, 1.0)
	return minf(angulo, rad_to_deg(asin(seno_maximo)))


func _preparar_area() -> void:
	var retangulo := _forma.shape as RectangleShape2D
	retangulo.size = Vector2(_arma.alcance, _arma.altura)
	_forma.position = Vector2(_arma.alcance / 2.0, 0.0)


## A arma desce do ângulo inicial ao final até o fim da janela de acerto, depois fica parada.
func _girar_arma() -> void:
	var progresso := clampf(_tempo / _arma.fim_acerto, 0.0, 1.0)
	var suave := ease(progresso, CURVA_GOLPE)
	_espada.rotation_degrees = lerpf(_arma.angulo_inicial, _arma.angulo_final, suave)


func _atualizar_acerto() -> void:
	var na_janela := _tempo >= _arma.inicio_acerto and _tempo < _arma.fim_acerto
	if na_janela and not _hitbox.esta_ligada():
		_hitbox.ligar(_golpe)
		_corte.show()
		_corte.play(&"corte")
	elif not na_janela and _hitbox.esta_ligada():
		_hitbox.desligar()


## Fim do golpe: a arma volta para o repouso no próximo seguir_mao().
func _terminar() -> void:
	_golpeando = false
	_hitbox.desligar()
	_corte.hide()
