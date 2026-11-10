class_name Minotauro
extends CharacterBody2D
## Minotauro de Baphomet (D&D 2024, ND 3), o chefe da fase 6. Glaive Abissal (alcance de 10 pés, dano necrótico a mais) e
## Chifrada (recarga 5-6): investida em linha reta; se correu 10 pés ou mais antes do acerto, soma o dano e derruba o herói.
## A investida e o golpe de glaive quebram os blocos marcados (grupo "quebravel") à frente dele.
## Números na ficha (CriaturaRPG). Comportamento nos estados (estados/). Não conhece o herói: recebe um alvo por
## definir_alvo() e a Percepção passiva por definir_percepcao_passiva().

## Emitido quando termina de morrer (antes de sumir).
signal morreu
## A vida mudou (a main mostra a barra do chefe).
signal vida_mudou(atual: int, maxima: int)
## O chão tremeu (bloco quebrado, pancada da investida): a main treme a câmera do herói (força em px, duração em s).
signal abalou_o_chao(forca: float, duracao: float)

## Camada "mundo" do chão.
const MASCARA_MUNDO := 1
const GRUPO_QUEBRAVEL := &"quebravel"
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
## Quanto à frente da borda do corpo (px) o raio procura chão antes de descer do penhasco.
const DISTANCIA_BEIRA := 40.0
## Quanto tempo o sprite fica vermelho ao levar dano (s).
const TEMPO_PISCAR_DANO := 0.12
## Tremor da câmera: ao quebrar um bloco e ao acertar a Chifrada (px) e duração (s).
const FORCA_ABALO_BLOCO := 4.0
const FORCA_ABALO_CHIFRADA := 7.0
const DURACAO_ABALO := 0.3
## Faces do dado da recarga (1d6 do "Recarga 5-6").
const FACES_RECARGA := 6

## Bloco de estatísticas. Padrão: data/minotauro.tres.
@export var criatura: CriaturaRPG
## Ampliação da arte (os quadros têm 190 px; o corpo fica com uns 4 ladrilhos de altura).
@export var escala_arte: float = 0.9
## Altura (px) da área do golpe e metade da largura do corpo (px): o golpe começa na borda do corpo.
@export var altura_golpe: float = 64.0
@export var meia_largura_corpo: float = 30.0
## Largura (px) da ponta dos chifres na investida.
@export var largura_chifrada: float = 36.0
## Janela em que o glaive acerta (s desde o início da animação).
@export var inicio_acerto: float = 0.46
@export var fim_acerto: float = 0.62
## Distância máxima da investida (px) e tempo cansado se ela erra (s).
@export var distancia_investida: float = 320.0
@export var tempo_cansaco: float = 0.9
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
@export var cor_dano: Color = Color(1.0, 0.45, 0.45)
@export var cor_aviso: Color = Color(1.0, 0.9, 0.35)

var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1

var _rng := RandomNumberGenerator.new()
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _tempo_desde_ataque: float = INF
var _tempo_recarga: float = 0.0
var _chifrada_pronta: bool = true
var _chifrada_acertou: bool = false
var _empurrao_restante: float = 0.0
var _saltador: SaltadorDeMonstro

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _dissolver: DissolverComponent = $Dissolver
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _golpe: HitboxComponent = $Golpe
@onready var _forma_golpe: CollisionShape2D = $Golpe/Forma
@onready var _chifres: HitboxComponent = $Chifres
@onready var _forma_chifres: CollisionShape2D = $Chifres/Forma
@onready var _impacto: Area2D = $Impacto
@onready var _forma_impacto: CollisionShape2D = $Impacto/Forma
@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _condicoes: CondicoesComponent = $Condicoes


func _ready() -> void:
	if criatura == null:
		criatura = CriaturaRPG.new()  # cena aberta sozinha (F6) continua funcionando
	_saltador = MontagemDeCriatura.criar_saltador(self, criatura, _gravidade)
	MontagemDeCriatura.aplicar_ficha(criatura, _vida, _defesa, _condicoes, _rng, _texto)
	_vida.vida_mudou.connect(vida_mudou.emit)
	MontagemDeCriatura.ligar_sinais_padrao(
		_defesa, _vida, _dissolver, _ao_resolver_golpe, _ao_morrer, terminar_de_morrer
	)
	_chifres.alvo_atingido.connect(func(_alvo: HurtboxComponent) -> void: _chifrada_acertou = true)
	_preparar_condicoes()
	_preparar_areas()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_saltador.passar_tempo(delta)
	_recarregar_chifrada(delta)
	if not is_on_floor():
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.scale.x = escala_arte * direcao_olhar  # a arte olha para a direita
	for area: Node2D in [_golpe, _chifres, _impacto]:
		area.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


## O Minotauro não se esconde: não rola Furtividade, então não usa a Percepção do herói.
func definir_percepcao_passiva(_valor: int) -> void:
	pass


func vida_atual() -> int:
	return _vida.vida_atual


func vida_maxima() -> int:
	return _vida.vida_maxima


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func chifrada_pronta() -> bool:
	return _chifrada_pronta


# --- Ferramentas dos estados ----------------------------------------------------

func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px()


func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


## A Chifrada recarregou e o herói está longe o bastante para dar a corrida de 10 pés (e perto o bastante para valer o bote),
## na mesma altura e com chão firme à frente.
func quer_investir() -> bool:
	if not _chifrada_pronta or alvo == null or not is_on_floor():
		return false
	var distancia := _distancia_horizontal()
	var minima := meia_largura_corpo + _alcance_chifrada_px() + _carreira_px()
	return distancia >= minima and distancia <= distancia_investida + minima \
		and absf(alvo.global_position.y - global_position.y) <= altura_golpe and _tem_chao_na(float(direcao_olhar))


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


func andar_para_alvo() -> void:
	virar_para_alvo()
	if not _tem_chao_na(float(direcao_olhar)):
		parar()
		return
	velocity.x = direcao_olhar * MontagemDeCriatura.velocidade_andar(criatura, _condicoes)


func parar() -> void:
	velocity.x = 0.0


## Diante de parede, degrau, vão ou queda que vale transpor, planeja o salto (regra em `SaltoDnd`; plano vazio se não há).
func planejar_salto() -> SaltoDnd.Plano:
	virar_para_alvo()
	var direcao := float(direcao_olhar)
	var bloqueado := is_on_wall() or not _tem_chao_na(direcao)
	return _saltador.planejar(alvo, direcao, bloqueado, meia_largura_corpo + DISTANCIA_BEIRA)


func iniciar_salto(plano: SaltoDnd.Plano) -> void:
	_saltador.iniciar(plano, float(direcao_olhar), MontagemDeCriatura.velocidade_andar(criatura, _condicoes), meia_largura_corpo)


func correr_no_ar() -> void:
	_saltador.correr_no_ar(float(direcao_olhar))


func tocar(animacao: StringName) -> void:
	if not _sprite.sprite_frames.has_animation(animacao):
		animacao = &"parado"  # animação que a arte não tem: fica na pose parada
	if _sprite.animation == animacao and _sprite.is_playing():
		return
	_sprite.animation = animacao
	_sprite.play()


func animacao_terminou() -> bool:
	return not _sprite.is_playing()


func iniciar_ataque(animacao: StringName, quadro_inicial: int = 0) -> void:
	_tempo_desde_ataque = 0.0
	virar_para_alvo()
	parar()
	tocar(animacao)
	_sprite.frame = quadro_inicial


func ligar_glaive() -> void:
	_golpe.ligar(_golpe_do_glaive())
	quebrar_a_frente()


func desligar_glaive() -> void:
	_golpe.desligar()


## Aviso antes do ataque: para, olha o herói e brilha (dá tempo de esquivar).
func tempo_aviso() -> float:
	return criatura.aviso_ataque


func preparar_aviso(animacao: StringName) -> void:
	parar()
	virar_para_alvo()
	tocar(animacao)
	_sprite.modulate = cor_aviso


func encerrar_aviso() -> void:
	_sprite.modulate = Color.WHITE


## Começa a investida: gasta a recarga, olha para o herói e liga os chifres sem a corrida (a corrida ainda não valeu).
func iniciar_investida() -> void:
	virar_para_alvo()
	_chifrada_pronta = false
	_tempo_recarga = 0.0
	_chifrada_acertou = false
	tocar(&"investida")
	_chifres.ligar(_golpe_da_chifrada(false))


## Corre na Disparada (o dobro do deslocamento) na direção em que olha.
func correr_na_investida() -> void:
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(criatura.deslocamento_pes * EscalaDnd.MULTIPLICADOR_DISPARADA)


## Correu 10 pés em linha reta: a Chifrada passa a somar o dano e a derrubar.
func completar_carreira() -> void:
	_chifres.ligar(_golpe_da_chifrada(true))


func carreira_px() -> float:
	return _carreira_px()


func desligar_chifres() -> void:
	_chifres.desligar()


func chifrada_acertou() -> bool:
	return _chifrada_acertou


## Bateu em parede ou chegou à beira de uma queda: a investida acaba.
func investida_barrada() -> bool:
	return is_on_wall() or not _tem_chao_na(float(direcao_olhar))


## Encostado em um bloco marcado que barra o caminho: vale golpeá-lo com o glaive para abrir passagem (senão o herói se
## esconderia atrás do pilar e o chefe ficaria preso).
func bloqueado_por_bloco() -> bool:
	return is_on_wall() and not _blocos_a_frente().is_empty()


## Quebra os blocos marcados que estão à frente (ao alcance do golpe). Devolve quantos quebrou e treme a tela.
func quebrar_a_frente() -> int:
	var blocos := _blocos_a_frente()
	for bloco in blocos:
		bloco.call(&"quebrar")
	var quebrados := blocos.size()
	if quebrados > 0:
		abalou_o_chao.emit(FORCA_ABALO_BLOCO, DURACAO_ABALO)
	return quebrados


## A pancada da Chifrada: a tela treme.
func abalar_com_a_chifrada() -> void:
	abalou_o_chao.emit(FORCA_ABALO_CHIFRADA, DURACAO_ABALO)


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Deitado (Caído): o corpo gira e fica no chão; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_sprite.rotation_degrees = -90.0 * direcao_olhar if deitado else 0.0


func dissolver() -> void:
	_dissolver.dissolver()


func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

## Recarga 5-6: no começo de cada rodada rola 1d6; com o número da ficha ou mais, a Chifrada volta.
func _recarregar_chifrada(delta: float) -> void:
	if _chifrada_pronta or criatura.chifrada_recarga <= 0:
		return
	_tempo_recarga += delta
	if _tempo_recarga < EscalaDnd.RODADA_SEGUNDOS:
		return
	_tempo_recarga -= EscalaDnd.RODADA_SEGUNDOS
	_chifrada_pronta = _rng.randi_range(1, FACES_RECARGA) >= criatura.chifrada_recarga


func _golpe_do_glaive() -> Golpe:
	var golpe := criatura.golpe()
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem()
	return golpe


func _golpe_da_chifrada(com_carreira: bool) -> Golpe:
	var golpe := criatura.golpe_chifrada(com_carreira)
	golpe.autor_id = get_instance_id()
	return golpe


## Os blocos quebráveis (do grupo) que a área de impacto toca agora.
func _blocos_a_frente() -> Array[Node]:
	var blocos: Array[Node] = []
	for corpo in _impacto.get_overlapping_bodies():
		if corpo.is_in_group(GRUPO_QUEBRAVEL) and corpo.has_method(&"quebrar"):
			blocos.append(corpo)
	return blocos


func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _alcance_chifrada_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.chifrada_alcance_pes)


func _carreira_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.chifrada_carreira_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


func _tem_chao_na(direcao: float) -> bool:
	var origem := global_position + Vector2(direcao * (meia_largura_corpo + DISTANCIA_BEIRA), -FOLGA_PE)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, PROFUNDIDADE_BEIRA + FOLGA_PE))
	consulta.collision_mask = MASCARA_MUNDO
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


## O glaive cobre do centro do corpo até o alcance; os chifres ficam na ponta do corpo; o impacto (para quebrar blocos)
## cobre a frente do corpo até o alcance do glaive.
func _preparar_areas() -> void:
	var comprimento := meia_largura_corpo + _alcance_px()
	(_forma_golpe.shape as RectangleShape2D).size = Vector2(comprimento, altura_golpe)
	_forma_golpe.position = Vector2(comprimento / 2.0, -altura_golpe / 2.0)
	(_forma_chifres.shape as RectangleShape2D).size = Vector2(largura_chifrada, altura_golpe)
	_forma_chifres.position = Vector2(meia_largura_corpo + largura_chifrada / 2.0, -altura_golpe / 2.0)
	(_forma_impacto.shape as RectangleShape2D).size = Vector2(comprimento, altura_golpe)
	_forma_impacto.position = Vector2(comprimento / 2.0, -altura_golpe / 2.0)


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado)
	if _vida.esta_morto():
		return
	if _condicoes.esta_caido() and nome_estado() != &"Caido":
		_maquina.trocar(&"Caido")
	elif resultado.acertou:
		_piscar_dano()


## Chefe não se assusta com golpe: só pisca (não interrompe o que está fazendo).
func _piscar_dano() -> void:
	_sprite.modulate = cor_dano
	await get_tree().create_timer(TEMPO_PISCAR_DANO).timeout
	if is_inside_tree() and not _vida.esta_morto():
		_sprite.modulate = Color.WHITE


func _preparar_condicoes() -> void:
	MontagemDeCriatura.preparar_condicoes(
		criatura, _condicoes, _texto,
		func(deslocamento: Vector2) -> void: _empurrao_restante = deslocamento.x
	)


func _aplicar_empurrao(delta: float) -> void:
	_empurrao_restante = MontagemDeCriatura.aplicar_empurrao(
		self, _empurrao_restante, velocidade_empurrao, delta
	)


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_glaive()
	desligar_chifres()
	_sprite.modulate = Color.WHITE
	_maquina.trocar(&"Morrendo")
