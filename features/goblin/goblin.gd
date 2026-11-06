class_name Goblin
extends CharacterBody2D
## Goblin (D&D 2024). O Minion arremessa adagas; o Warrior atira com o arco curto (as flechas
## não acabam). Longe do corpo a corpo usa o ataque à distância (desvantagem além do alcance
## normal; cai no longo). Perto golpeia. Fuga Ágil: depois do golpe corpo a corpo Desengaja.
## Números na ficha (CriaturaRPG). Comportamento nos estados (estados/). Não conhece o herói:
## recebe um alvo por definir_alvo() e a Percepção passiva por definir_percepcao_passiva().

## Emitido quando termina de morrer (antes de sumir).
signal morreu

const CENA_ADAGA := preload("res://features/goblin/adaga_goblin.tscn")
const CENA_FLECHA := preload("res://features/goblin/flecha_goblin.tscn")
const FLECHA := preload("res://data/municoes/flecha.tres")

## Bloco de estatísticas. Padrão: data/goblin_minion.tres.
@export var criatura: CriaturaRPG
## Ampliação da arte (o pacote é 32x32; Pequeno fica com uns 3/4 da altura do herói).
@export var escala_arte: float = 2.0
## Altura do corpo usada na área do golpe (px).
@export var altura_golpe: float = 28.0
## Metade da largura do corpo (px): o golpe começa a partir daqui.
@export var meia_largura_corpo: float = 10.0
## Altura (px acima dos pés) de onde a adaga sai e para onde ela mira no alvo.
@export var altura_mao: float = 28.0
@export var altura_alvo: float = 36.0
## Fuga Ágil: quanto se afasta ao Desengajar (pés), correndo (Disparada).
@export var recuo_fuga_pes: float = 15.0
## Janela em que o golpe corpo a corpo acerta (s desde o início da animação).
@export var inicio_acerto: float = 0.1
@export var fim_acerto: float = 0.3
## Quando a adaga ou a flecha sai da mão (s desde o início da animação).
@export var momento_soltura: float = 0.15
## Dentro desta distância (pés) quem tem arco guarda o tiro e fecha para o corpo a corpo.
@export var perto_pes: float = 20.0
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
## Pisca ao levar dano: cor do clarão.
@export var cor_dano: Color = Color(1.0, 0.45, 0.45)

## Alvo perseguido (ex.: o herói). Sem alvo, fica parado.
var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1

var _rng := RandomNumberGenerator.new()
var _tempo_desde_ataque: float = INF
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _empurrao_restante: float = 0.0
var _adagas: int = 0
## Cópias do disparo da ficha. Menor que 0 = não acaba.
var _flechas: int = 0
## Percepção passiva de quem olha. 0 (ninguém passou) = o goblin sempre se esconde.
var _percepcao_passiva: int = 0
var _rolou_furtividade: bool = false
var _foi_percebido: bool = false
## O próximo golpe sai com vantagem (a emboscada de quem não foi percebido).
var _emboscada: bool = false
var _escondido: bool = false
var _camada_corpo: int = 0
var _camada_hurtbox: int = 0

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _golpe: HitboxComponent = $Golpe
@onready var _forma_golpe: CollisionShape2D = $Golpe/Forma
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
	_adagas = criatura.arremessos
	_flechas = criatura.disparos
	_preparar_condicoes()
	_preparar_golpe()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	if not is_on_floor():
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.scale.x = escala_arte * direcao_olhar  # a arte olha para a direita
	_golpe.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


## A main passa a Percepção passiva do herói. O goblin não lê a ficha dele.
func definir_percepcao_passiva(valor: int) -> void:
	_percepcao_passiva = valor


func vida_atual() -> int:
	return _vida.vida_atual


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func adagas_restantes() -> int:
	return _adagas


## Menor que 0: as flechas não acabam.
func flechas_restantes() -> int:
	return _flechas


# --- Ferramentas dos estados ----------------------------------------------------

func tem_furtividade() -> bool:
	return criatura.tem_furtividade


func esta_escondido() -> bool:
	return _escondido


func teste_secreto_feito() -> bool:
	return _rolou_furtividade


func foi_percebido() -> bool:
	return _foi_percebido


## Some: sem sprite, sem colisão com o herói e sem hurtbox (um golpe no vazio não acerta).
func esconder() -> void:
	if _escondido:
		return
	_escondido = true
	_camada_corpo = collision_layer
	_camada_hurtbox = _hurtbox.collision_layer
	collision_layer = 0
	_hurtbox.collision_layer = 0
	_sprite.visible = false


func revelar() -> void:
	if not _escondido:
		return
	_escondido = false
	collision_layer = _camada_corpo
	_hurtbox.collision_layer = _camada_hurtbox
	_sprite.visible = true


## Uma vez, contra a passiva. Sem texto: o jogador só vê o goblin aparecer ou não.
func rolar_furtividade() -> void:
	if _rolou_furtividade:
		return
	_rolou_furtividade = true
	var rolagem := _rng.randi_range(1, Combate.FACES_D20) + criatura.bonus_furtividade
	_foi_percebido = not Pericia.furtividade_passa(rolagem, _percepcao_passiva)


## O primeiro golpe depois de não ser percebido sai com vantagem.
func marcar_emboscada() -> void:
	_emboscada = true


## Visão no Escuro 60 pés: percebe o alvo até essa distância.
func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


## True se o alvo está ao alcance da adaga em corpo a corpo (5 pés).
func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px()


## Ainda tem adaga, o alvo está fora do corpo a corpo e dentro do alcance longo.
func pode_arremessar() -> bool:
	return _adagas > 0 and alvo != null and not alvo_ao_alcance() \
		and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.arremesso_longo_pes)


## Tem flecha, o alvo está longe o bastante para valer o arco e dentro do alcance longo.
func pode_atirar() -> bool:
	return _tem_flecha() and alvo != null and not _perto_para_oarco() \
		and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.disparo_longo_pes)


## Ritmo pela iniciativa da ficha (Goblin: +2 -> um ataque a cada 0,8 s).
func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


## O arco espera uma rodada inteira (1,5 s). Mais rápido que isso vira metralhadora.
func pode_disparar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.RODADA_SEGUNDOS


## Perto demais para o arco: fecha e usa a arma de corpo a corpo.
func _perto_para_oarco() -> bool:
	return _distancia_horizontal() <= EscalaDnd.pes_para_pixels(perto_pes)


func tem_fuga_agil() -> bool:
	return criatura.fuga_agil


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


## Anda na direção do alvo no deslocamento da ficha, menos a Lentidão (maestria).
func andar_para_alvo() -> void:
	virar_para_alvo()
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(_deslocamento_pes())


## Fuga Ágil: corre de costas para longe do alvo (Disparada), ainda olhando para ele.
func recuar() -> void:
	velocity.x = -direcao_olhar * _velocidade_fuga()


## Quanto dura o recuo da Fuga Ágil (s): a distância dela na velocidade de Disparada.
func tempo_de_fuga() -> float:
	var velocidade := _velocidade_fuga()
	return EscalaDnd.pes_para_pixels(recuo_fuga_pes) / velocidade if velocidade > 0.0 else 0.0


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
func ligar_golpe() -> void:
	_golpe.ligar(_golpe_da_ficha())


func desligar_golpe() -> void:
	_golpe.desligar()


## Solta uma adaga na direção do alvo (mira no peito dele). Gasta uma das adagas.
func arremessar_adaga() -> void:
	if _adagas <= 0 or alvo == null:
		return
	_adagas -= 1
	var adaga: AdagaGoblin = CENA_ADAGA.instantiate()
	add_child(adaga)
	var mao := global_position + Vector2(direcao_olhar * meia_largura_corpo, -altura_mao)
	var destino := alvo.global_position + Vector2(0.0, -altura_alvo)
	adaga.lancar(_golpe_da_ficha(), criatura.arma_arremesso, mao, destino,
		EscalaDnd.pes_para_pixels(criatura.arremesso_normal_pes),
		EscalaDnd.pes_para_pixels(criatura.arremesso_longo_pes), _gravidade)


## Solta o que a ficha tiver à distância: adaga, ou flecha se as adagas acabaram.
func soltar_distancia() -> void:
	if _adagas > 0:
		arremessar_adaga()
	elif _tem_flecha():
		atirar()


## Dispara uma flecha na direção do alvo (mira no peito dele).
func atirar() -> void:
	if not _tem_flecha() or alvo == null:
		return
	if _flechas > 0:
		_flechas -= 1
	var flecha: FlechaGoblin = CENA_FLECHA.instantiate()
	add_child(flecha)
	var mao := global_position + Vector2(direcao_olhar * meia_largura_corpo, -altura_mao)
	var destino := alvo.global_position + Vector2(0.0, -altura_alvo)
	flecha.lancar(_golpe_do_disparo(), FLECHA, mao, destino,
		EscalaDnd.pes_para_pixels(criatura.disparo_normal_pes),
		EscalaDnd.pes_para_pixels(criatura.disparo_longo_pes), _gravidade)


## Levou dano: pisca na cor do dano.
func piscar(ligado: bool) -> void:
	_sprite.modulate = cor_dano if ligado else Color.WHITE


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Deitado (Caído): o corpo gira e fica no chão, os pés na origem; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_sprite.rotation_degrees = -90.0 * direcao_olhar if deitado else 0.0


## Some do jogo depois da animação de morte.
func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

func _golpe_da_ficha() -> Golpe:
	return _com_autor(criatura.golpe())


func _golpe_do_disparo() -> Golpe:
	return _com_autor(criatura.golpe_disparo())


func _com_autor(golpe: Golpe) -> Golpe:
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem()
	if _emboscada:
		golpe.vantagem = true
		_emboscada = false
	return golpe


func _tem_flecha() -> bool:
	return _flechas < 0 or _flechas > 0


func _deslocamento_pes() -> float:
	return maxf(criatura.deslocamento_pes - _condicoes.reducao_deslocamento_pes(), 0.0)


func _velocidade_fuga() -> float:
	return EscalaDnd.deslocamento_para_velocidade(_deslocamento_pes()) * EscalaDnd.MULTIPLICADOR_DISPARADA


func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


## Área do golpe: começa na borda do corpo e vai até o alcance da ficha (5 pés).
func _preparar_golpe() -> void:
	var retangulo := _forma_golpe.shape as RectangleShape2D
	retangulo.size = Vector2(_alcance_px(), altura_golpe)
	_forma_golpe.position = Vector2(meia_largura_corpo + _alcance_px() / 2.0, -altura_golpe / 2.0)


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado)
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


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_golpe()
	piscar(false)
	_maquina.trocar(&"Morrendo")
