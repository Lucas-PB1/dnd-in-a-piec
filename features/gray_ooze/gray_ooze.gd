class_name GrayOoze
extends CharacterBody2D
## Gray Ooze (D&D 5e): gosma lenta que persegue o alvo que percebe e ataca com o Pseudópode
## no ritmo da iniciativa. Números em data/gray_ooze.tres (CriaturaRPG). Comportamento nos
## estados (estados/). Não conhece o herói: recebe um alvo qualquer por definir_alvo().

## Emitido quando termina de morrer (antes de sumir).
signal morreu

## Bloco de estatísticas. Padrão: data/gray_ooze.tres.
@export var criatura: CriaturaRPG
## Altura do corpo usada na área do Pseudópode (px).
@export var altura_pseudopode: float = 24.0
## Metade da largura do corpo (px): o Pseudópode começa a partir daqui.
@export var meia_largura_corpo: float = 20.0
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
## Achatamento do sprite enquanto está Caído.
@export var escala_caido: Vector2 = Vector2(1.25, 0.55)

## Alvo perseguido (ex.: o herói). Sem alvo, fica parado.
var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1

var _rng := RandomNumberGenerator.new()
var _tempo_desde_ataque: float = INF
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
## Quanto ainda falta do empurrão (px, com sinal).
var _empurrao_restante: float = 0.0
var _posicao_sprite: Vector2

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _pseudopode: HitboxComponent = $Pseudopode
@onready var _forma_pseudopode: CollisionShape2D = $Pseudopode/Forma
@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _condicoes: CondicoesComponent = $Condicoes


func _ready() -> void:
	if criatura == null:
		criatura = CriaturaRPG.new()  # cena aberta sozinha (F6) continua funcionando
	_vida.configurar(criatura.vida_maxima(_rng))
	_defesa.classe_armadura = criatura.classe_armadura
	_defesa.resistencias = criatura.resistencias
	_defesa.golpe_resolvido.connect(_ao_resolver_golpe)
	_vida.morreu.connect(_ao_morrer)
	_preparar_condicoes()
	_posicao_sprite = _sprite.position
	_preparar_pseudopode()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	if not is_on_floor():
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.flip_h = direcao_olhar > 0  # a arte original olha para a esquerda
	_pseudopode.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


func vida_atual() -> int:
	return _vida.vida_atual


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


# --- Ferramentas dos estados ----------------------------------------------------

func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


## True se o alvo está dentro do alcance do Pseudópode.
func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px()


## Ritmo pela iniciativa da ficha (Gray Ooze: -2 -> um ataque a cada 1,2 s).
func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


## Anda na direção do alvo no deslocamento da ficha (pés por rodada -> px/s), menos a
## Lentidão (maestria), se estiver Lento.
func andar_para_alvo() -> void:
	virar_para_alvo()
	var pes := maxf(criatura.deslocamento_pes - _condicoes.reducao_deslocamento_pes(), 0.0)
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(pes)


func parar() -> void:
	velocity.x = 0.0


## Toca a animação desde o primeiro quadro (se já estiver tocando ela, não reinicia).
func tocar(animacao: StringName) -> void:
	if _sprite.animation == animacao and _sprite.is_playing():
		return
	_sprite.animation = animacao  # trocar a animação volta para o quadro 0
	_sprite.play()


func animacao_terminou() -> bool:
	return not _sprite.is_playing()


func iniciar_ataque() -> void:
	_tempo_desde_ataque = 0.0
	virar_para_alvo()
	parar()
	tocar(&"atacar")


## Enfraquecido (maestria): este ataque sai com desvantagem e a condição se gasta.
func ligar_pseudopode() -> void:
	var golpe := criatura.golpe()
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem()
	_pseudopode.ligar(golpe)


func desligar_pseudopode() -> void:
	_pseudopode.desligar()


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Deitado (Caído) achata o sprite no chão; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_sprite.scale = escala_caido if deitado else Vector2.ONE
	_sprite.position = Vector2(_posicao_sprite.x, _posicao_sprite.y * escala_caido.y) if deitado else _posicao_sprite


## Some do jogo depois da animação de morte.
func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


## Área do Pseudópode: começa na borda do corpo e vai até o alcance da ficha (5 pés).
func _preparar_pseudopode() -> void:
	var retangulo := _forma_pseudopode.shape as RectangleShape2D
	retangulo.size = Vector2(_alcance_px(), altura_pseudopode)
	_forma_pseudopode.position = Vector2(meia_largura_corpo + _alcance_px() / 2.0, -altura_pseudopode / 2.0)


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado)
	_corroer_arma_se_preciso(resultado)
	if _vida.esta_morto():
		return
	if _condicoes.esta_caido():
		if nome_estado() != &"Caido":
			_maquina.trocar(&"Caido")
	elif resultado.acertou:
		_maquina.trocar(&"LevandoDano")


## A ficha diz as salvaguardas (Derrubar pede CON); avisos e empurrão vêm das condições.
func _preparar_condicoes() -> void:
	for atributo in Atributos.TODOS:
		_condicoes.bonus_salvaguardas[atributo] = criatura.bonus_salvaguarda(atributo)
	_condicoes.aviso.connect(func(texto: String) -> void: _texto.mostrar(texto, TextoFlutuanteComponent.COR_CONDICAO))
	_condicoes.empurrado.connect(func(deslocamento: Vector2) -> void: _empurrao_restante = deslocamento.x)


## Empurrar: desliza o que falta do empurrão (com colisão), por cima do que o estado mandou.
func _aplicar_empurrao(delta: float) -> void:
	if is_zero_approx(_empurrao_restante):
		return
	var passo := signf(_empurrao_restante) * minf(absf(_empurrao_restante), velocidade_empurrao * delta)
	velocity.x = passo / delta
	_empurrao_restante -= passo


## Forma Corrosiva: arma não mágica que CAUSA DANO no Ooze leva penalidade cumulativa no
## ataque e é destruída no limite. Quem decide o que fazer com a arma é o dono dela.
func _corroer_arma_se_preciso(resultado: Combate.Resultado) -> void:
	if criatura.corrosao_por_toque <= 0 or resultado.dano <= 0 or not resultado.golpe.arma_corroivel:
		return
	resultado.golpe.arma_corroida.emit(criatura.corrosao_por_toque, criatura.corrosao_limite)


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_pseudopode()
	_maquina.trocar(&"Morrendo")
