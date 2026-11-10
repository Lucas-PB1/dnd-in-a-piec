class_name Ankheg
extends CharacterBody2D
## Ankheg (D&D 2024, ND 2), o chefe da fase 3. Mordida que agarra (vantagem contra quem já está agarrado), Borrifo Ácido em
## linha (salvaguarda de Destreza, recarga 6) e Escavação: some no chão, avança por baixo do herói e sai com a mordida.
## Números na ficha (CriaturaRPG). Comportamento nos estados (estados/). Não conhece o herói: recebe um alvo por
## definir_alvo() e a Percepção passiva por definir_percepcao_passiva().

## Emitido quando termina de morrer (antes de sumir).
signal morreu
## A vida mudou (a main mostra a barra do chefe).
signal vida_mudou(atual: int, maxima: int)
## O chão tremeu (o Ankheg saiu da terra): a main treme a câmera do herói com esta força (px) e duração (s).
signal abalou_o_chao(forca: float, duracao: float)

## Camada "mundo" do chão.
const MASCARA_CHAO := 1 | (1 << 5)  # MontagemDeCriatura.mascara_do_chao()
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
## Quanto à frente da borda do corpo (px) o raio procura chão antes de descer do penhasco.
const DISTANCIA_BEIRA := 40.0
## Escavação: só cava com o herói mais longe que isto (px), espera entre escavadas (s) e quanto procura chão para emergir (px).
const DISTANCIA_MINIMA_CAVAR := 150.0
const INTERVALO_CAVAR := 9.0
const ALCANCE_DO_CHAO := 160.0
## Quanto tempo o sprite fica vermelho ao levar dano (s).
const TEMPO_PISCAR_DANO := 0.12
## Ao emergir: o Ankheg salta do chão com este impulso (px/s) e cai no mesmo ponto; a tela treme na saída e mais forte no pouso (px, s).
const IMPULSO_DO_SALTO := 460.0
const FORCA_ABALO_SAIDA := 3.0
const FORCA_ABALO_POUSO := 8.0
const DURACAO_ABALO := 0.35
## Escavação só onde há terra: passo da checagem do chão no caminho (px).
const PASSO_DO_CAMINHO := 32.0
## Quanto o monte de terra cresce (fração a mais) enquanto o aviso enche.
const CRESCIMENTO_DO_MONTE := 0.8
## Jato do Borrifo: altura do respingo no fim da linha (px).
const ALTURA_DO_RESPINGO := 6.0

## Bloco de estatísticas. Padrão: data/ankheg.tres.
@export var criatura: CriaturaRPG
## Ampliação da arte (os quadros têm 200 px; o corpo fica com uns 2 ladrilhos de comprimento).
@export var escala_arte: float = 0.65
## Altura da área da mordida (px) e metade da largura do corpo (px): o golpe começa na borda do corpo.
@export var altura_golpe: float = 40.0
@export var meia_largura_corpo: float = 36.0
## Altura da boca acima dos pés (px): de onde sai o Borrifo.
@export var altura_boca: float = 30.0
## Janela em que a mordida acerta (s desde o início da animação) e a do Borrifo.
@export var inicio_acerto: float = 0.5
@export var fim_acerto: float = 0.7
@export var inicio_borrifo: float = 0.2
@export var fim_borrifo: float = 0.5
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
var _tempo_desde_cavar: float = INTERVALO_CAVAR / 2.0
var _emboscada: bool = false
var _escondido: bool = false
var _camada_corpo: int = 0
var _camada_hurtbox: int = 0
var _empurrao_restante: float = 0.0
var _saltador: SaltadorDeMonstro
## Borrifo Ácido da ficha (`linha_*`).
var _ataque_linha: LinhaDeCriatura

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _sombra: Polygon2D = $Sombra
@onready var _terra: Node2D = $Terra
@onready var _alerta: Polygon2D = $Terra/Alerta
@onready var _explosao: CPUParticles2D = $Explosao
@onready var _dissolver: DissolverComponent = $Dissolver
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _golpe: HitboxComponent = $Golpe
@onready var _forma_golpe: CollisionShape2D = $Golpe/Forma
@onready var _linha: HitboxComponent = $Linha
@onready var _forma_linha: CollisionShape2D = $Linha/Forma
@onready var _gotas: CPUParticles2D = $Linha/Gotas
@onready var _respingo: CPUParticles2D = $Linha/Respingo
@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _condicoes: CondicoesComponent = $Condicoes


func _ready() -> void:
	if criatura == null:
		criatura = CriaturaRPG.new()  # cena aberta sozinha (F6) continua funcionando
	MontagemDeCriatura.configurar_colisao_chao(self)
	_saltador = MontagemDeCriatura.criar_saltador(self, criatura, _gravidade)
	_ataque_linha = LinhaDeCriatura.new(criatura)
	MontagemDeCriatura.aplicar_ficha(criatura, _vida, _defesa, _condicoes, _rng, _texto)
	_vida.vida_mudou.connect(vida_mudou.emit)
	MontagemDeCriatura.ligar_sinais_padrao(
		_defesa, _vida, _dissolver, _ao_resolver_golpe, _ao_morrer, terminar_de_morrer
	)
	_preparar_condicoes()
	_preparar_areas()
	_terra.visible = false
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_tempo_desde_cavar += delta
	_saltador.passar_tempo(delta)
	_ataque_linha.passar_tempo(delta, _rng)
	if not _escondido and not is_on_floor():
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.scale.x = escala_arte * direcao_olhar  # a arte olha para a direita
	_golpe.scale.x = direcao_olhar
	_linha.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


## O Ankheg não se esconde: não rola Furtividade, então não usa a Percepção do herói.
func definir_percepcao_passiva(_valor: int) -> void:
	pass


func vida_atual() -> int:
	return _vida.vida_atual


func vida_maxima() -> int:
	return _vida.vida_maxima


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func borrifo_pronto() -> bool:
	return _ataque_linha.pronta()


## Só para testes / forçar a recarga do Borrifo.
func definir_borrifo_pronto(valor: bool) -> void:
	_ataque_linha.definir_pronta(valor)


# --- Ferramentas dos estados ----------------------------------------------------

func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px()


func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


## O Borrifo está recarregado e o herói está dentro da linha (à frente, no comprimento dela).
func quer_borrifar() -> bool:
	return alvo != null and _ataque_linha.pronta() and _ataque_linha.alvo_na_area(
		_distancia_horizontal(),
		meia_largura_corpo,
		absf(alvo.global_position.y - global_position.y),
		altura_golpe * 2.0,
	)


## Longe o bastante do herói, no chão, fora da espera e com terra firme até ele (vão ou paredão no caminho: nada de cavar,
## ele salta como os goblins): vale cavar para surpreender.
func quer_cavar() -> bool:
	return criatura.escavacao_pes > 0.0 and alvo != null and is_on_floor() and _tempo_desde_cavar >= INTERVALO_CAVAR \
		and _distancia_horizontal() >= DISTANCIA_MINIMA_CAVAR and _terra_ate(alvo.global_position.x)


## Barrado por parede ou degrau alto demais para o salto, com terra até o herói: cava por baixo e sai lá em cima.
func quer_cavar_para_transpor() -> bool:
	return criatura.escavacao_pes > 0.0 and alvo != null and is_on_floor() and is_on_wall() and _terra_ate(alvo.global_position.x)


## Diante de parede, degrau, vão ou queda, decide se vale saltar (regra em `SaltoDnd`, a mesma dos goblins).
func planejar_salto() -> SaltoDnd.Plano:
	virar_para_alvo()
	var direcao := float(direcao_olhar)
	var bloqueado := is_on_wall() or not _tem_chao_na(direcao)
	return _saltador.planejar(alvo, direcao, bloqueado, DISTANCIA_BEIRA)


## Dá o impulso do plano: corre na velocidade da ficha e sobe o bastante para o degrau ou para cobrir o vão.
func iniciar_salto(plano: SaltoDnd.Plano) -> void:
	_saltador.iniciar(plano, float(direcao_olhar), MontagemDeCriatura.velocidade_andar(criatura, _condicoes), meia_largura_corpo)


## No ar do salto: mantém a corrida (uma batida na parede zera o x).
func correr_no_ar() -> void:
	_saltador.correr_no_ar(float(direcao_olhar))


## True se há terra para atravessar por baixo até `x`: chão em todos os pontos do caminho (degrau e paredão são terra, vão não).
func _terra_ate(x: float) -> bool:
	var sentido := signf(x - global_position.x)
	var ponto := global_position.x
	while absf(x - ponto) > PASSO_DO_CAMINHO:
		ponto += sentido * PASSO_DO_CAMINHO
		if is_nan(chao_em(ponto)):
			return false
	return true


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


func tocar(animacao: StringName) -> void:
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


func ligar_golpe() -> void:
	_golpe.ligar(_golpe_da_mordida())


func desligar_golpe() -> void:
	_golpe.desligar()


## Solta o Borrifo Ácido: liga a área da linha e mostra o jato; gasta a recarga.
func ligar_borrifo() -> void:
	var golpe := _ataque_linha.golpe()
	golpe.autor_id = get_instance_id()
	_linha.ligar(golpe)
	_gotas.restart()
	_respingo.restart()
	_gotas.emitting = true
	_respingo.emitting = true
	_ataque_linha.consumir()


func desligar_borrifo() -> void:
	_linha.desligar()
	_gotas.emitting = false
	_respingo.emitting = false


## Aviso antes do ataque (0 na emboscada: o herói não viu o Ankheg sair do chão).
func tempo_aviso() -> float:
	return 0.0 if _emboscada else criatura.aviso_ataque


func preparar_aviso() -> void:
	parar()
	virar_para_alvo()
	tocar(&"parado")
	_sprite.modulate = cor_aviso


func encerrar_aviso() -> void:
	_sprite.modulate = Color.WHITE


## Escavação: some (sem sprite, sem colisão, sem hurtbox) e anda por baixo do chão, seguindo o herói.
func esconder() -> void:
	if _escondido:
		return
	_escondido = true
	_tempo_desde_cavar = 0.0
	_camada_corpo = collision_layer
	_camada_hurtbox = _hurtbox.collision_layer
	collision_layer = 0
	collision_mask = 0
	_hurtbox.collision_layer = 0
	_sprite.visible = false
	_sombra.visible = false
	_terra.visible = true


func revelar() -> void:
	if not _escondido:
		return
	_escondido = false
	collision_layer = _camada_corpo
	MontagemDeCriatura.configurar_colisao_chao(self)
	_hurtbox.collision_layer = _camada_hurtbox
	_sprite.visible = true
	_sombra.visible = true
	_terra.visible = false


func esta_escondido() -> bool:
	return _escondido


## Por baixo da terra: anda até `x` na velocidade da escavação (em Disparada). True quando chegou.
func cavar_ate(x: float) -> bool:
	var falta := x - global_position.x
	var velocidade := EscalaDnd.deslocamento_para_velocidade(criatura.escavacao_pes * EscalaDnd.MULTIPLICADOR_DISPARADA)
	var sentido := 1 if falta > 0.0 else -1
	var proximo := global_position.x + sentido * PASSO_DO_CAMINHO
	if absf(falta) <= velocidade * get_physics_process_delta_time() or is_nan(chao_em(proximo)):  # acabou a terra: emerge
		velocity = Vector2.ZERO
		return true
	direcao_olhar = sentido
	velocity = Vector2(direcao_olhar * velocidade, 0.0)
	return false


## Y do chão sob `x` (procura a partir de acima do Ankheg). NAN se não há chão ali (buraco).
func chao_em(x: float) -> float:
	var de := Vector2(x, global_position.y - ALCANCE_DO_CHAO)
	var ate := Vector2(x, global_position.y + ALCANCE_DO_CHAO)
	var consulta := PhysicsRayQueryParameters2D.create(de, ate)
	consulta.collision_mask = MASCARA_CHAO
	var acerto := get_world_2d().direct_space_state.intersect_ray(consulta)
	return NAN if acerto.is_empty() else (acerto["position"] as Vector2).y


## O aviso da terra enche de 0 a 1: o monte cresce e a marca vermelha mostra onde o Ankheg vai sair.
func avisar_terra(fracao: float) -> void:
	_terra.scale = Vector2(1.0 + CRESCIMENTO_DO_MONTE * fracao, 1.0 + CRESCIMENTO_DO_MONTE * 1.5 * fracao)
	_alerta.visible = true
	_alerta.modulate.a = 0.4 + 0.6 * fracao


## Sai do chão em `x` num salto: sobe e cai no mesmo ponto (`aterrissar`). A mordida seguinte é a emboscada (sem aviso e com vantagem).
func emergir_em(x: float) -> void:
	var y := chao_em(x)
	global_position = Vector2(x, global_position.y if is_nan(y) else y)
	velocity = Vector2(0.0, -IMPULSO_DO_SALTO)
	revelar()
	virar_para_alvo()
	tocar(&"saltar")
	_emboscada = true
	_terra.scale = Vector2.ONE
	_alerta.visible = false
	_explosao.restart()
	abalou_o_chao.emit(FORCA_ABALO_SAIDA, DURACAO_ABALO)


## O pouso do salto: terra para os lados e a tela treme forte.
func aterrissar() -> void:
	_explosao.restart()
	abalou_o_chao.emit(FORCA_ABALO_POUSO, DURACAO_ABALO)


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

func _golpe_da_mordida() -> Golpe:
	var golpe := criatura.golpe()
	golpe.autor_id = get_instance_id()
	golpe.vantagem = _emboscada or _alvo_agarrado()  # Mordida: vantagem contra quem está agarrado
	_emboscada = false
	golpe.desvantagem = _condicoes.consumir_desvantagem()
	return golpe


func _alvo_agarrado() -> bool:
	return alvo != null and alvo.has_method(&"esta_agarrado") and alvo.call(&"esta_agarrado")


func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


func _tem_chao_na(direcao: float) -> bool:
	var origem := global_position + Vector2(direcao * (meia_largura_corpo + DISTANCIA_BEIRA), -FOLGA_PE)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, PROFUNDIDADE_BEIRA + FOLGA_PE))
	consulta.collision_mask = MASCARA_CHAO
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


## A mordida cobre do centro do corpo até o alcance (quem está embaixo dele, na saída do chão, também é mordido); o Borrifo começa na borda do corpo e vai até o alcance e o comprimento da ficha.
func _preparar_areas() -> void:
	var mordida := _forma_golpe.shape as RectangleShape2D
	var comprimento_mordida := meia_largura_corpo + _alcance_px()
	mordida.size = Vector2(comprimento_mordida, altura_golpe)
	_forma_golpe.position = Vector2(comprimento_mordida / 2.0, -altura_golpe / 2.0)
	var linha := _forma_linha.shape as RectangleShape2D
	linha.size = _ataque_linha.tamanho_hitbox_px()
	_forma_linha.position = Vector2(_ataque_linha.offset_x_centro(meia_largura_corpo), -altura_boca)
	_gotas.position = Vector2(meia_largura_corpo, -altura_boca)  # o jato sai da boca
	_respingo.position = Vector2(meia_largura_corpo + _ataque_linha.comprimento_px(), -ALTURA_DO_RESPINGO)


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
	if _escondido:
		return
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
	if _escondido:
		return
	_empurrao_restante = MontagemDeCriatura.aplicar_empurrao(
		self, _empurrao_restante, velocidade_empurrao, delta
	)


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_golpe()
	desligar_borrifo()
	_sprite.modulate = Color.WHITE
	revelar()
	_maquina.trocar(&"Morrendo")
