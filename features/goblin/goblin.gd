class_name Goblin
extends CharacterBody2D
## Goblin (D&D 2024). O Minion arremessa adagas; o Warrior atira com o arco curto (as flechas
## não acabam). Longe do corpo a corpo usa o ataque à distância (desvantagem além do alcance
## normal; cai no longo). Perto golpeia. Fuga Ágil: depois do golpe corpo a corpo Desengaja.
## Números na ficha (CriaturaRPG). Comportamento nos estados (estados/). Não conhece o herói:
## recebe um alvo por definir_alvo() e a Percepção passiva por definir_percepcao_passiva().

## Emitido quando termina de morrer (antes de sumir).
signal morreu

## Quanto à frente (px) o raio procura chão antes de descer do penhasco.
const DISTANCIA_BEIRA := 14.0
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
## Camada "mundo" do chão.
const MASCARA_MUNDO := 1
## Patrulha: anda nesta fração do deslocamento e considera que chegou a esta distância (px).
const FRACAO_PATRULHA := 0.5
const CHEGOU_PATRULHA := 6.0
## Grupo onde a main põe todos os monstros: de lá saem os aliados das Táticas de Matilha.
const GRUPO_ALIADOS := &"monstros"
## Cobertura: quanto tempo um tiro do herói ainda conta (s), de onde a busca começa e até onde vai (px), espera entre
## buscas (s) e a distância mínima do herói para valer se esconder (px).
const JANELA_DISPARO := 3.0
const PASSO_ABRIGO := 16.0
const ALCANCE_ABRIGO_PX := 192.0
const INTERVALO_ABRIGO := 2.0
const DISTANCIA_MINIMA_ABRIGO := 96.0
## Estratégia: espera entre afastamentos (s, uma rodada), folga além do "perto" para considerar a distância recuperada (px), espaço
## livre atrás para recuar (px), segurança de quem recua ferido (px) e até onde um aliado conta como "por perto" (px).
const INTERVALO_AFASTAR := 1.5
const FOLGA_DISTANCIA_PX := 64.0
const ESPACO_ATRAS_PX := 24.0
const DISTANCIA_SEGURA_FERIDO_PX := 256.0
const ALCANCE_ALIADO_PX := 256.0
const MOTIVO_DISTANCIA := &"distancia"
const MOTIVO_FERIDO := &"ferido"
## Flanqueio: espera entre manobras (s), até onde um aliado engajado puxa este monstro (px) e quanto antes do alvo ele
## para do lado oposto (fração do alcance).
const INTERVALO_FLANCO := 6.0
const ALCANCE_FLANCO_PX := 256.0
const FRACAO_ALCANCE_FLANCO := 0.6

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
## Animação do ataque à distância (a adaga arremessada ou o tiro de arco).
@export var animacao_distancia: StringName = &"atacar"

## Dentro desta distância (pés) quem tem arco guarda o tiro e fecha para o corpo a corpo.
@export var perto_pes: float = 20.0
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
## Pisca ao levar dano: cor do clarão.
@export var cor_dano: Color = Color(1.0, 0.45, 0.45)
## Cor do brilho do aviso antes do golpe.
@export var cor_aviso: Color = Color(1.0, 0.9, 0.35)
## Tinta do corpo (branco = a arte como é). As variantes (Hobgoblin, Bugbear, Kobold) reusam a arte do Goblin com outra cor.
@export var cor_corpo: Color = Color.WHITE

## Alvo perseguido (ex.: o herói). Sem alvo, fica parado.
var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1

var _rng := RandomNumberGenerator.new()
var _tempo_desde_ataque: float = INF
var _saltador: SaltadorDeMonstro
var _origem_disparo: Vector2 = Vector2.ZERO
var _tempo_desde_disparo: float = INF
var _tempo_desde_abrigo: float = INF
var _x_abrigo: float = 0.0
var _tempo_desde_afastar: float = INF
var _motivo_afastar: StringName = MOTIVO_DISTANCIA
var _ja_recuou_ferido: bool = false
var _prefere_distancia: bool = false
var _tempo_desde_flanco: float = INF
var _x_flanco: float = 0.0
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _empurrao_restante: float = 0.0
## Patrulha: onde começou (X, sorteado ao 1º passo) e o lado do próximo extremo.
var _base_x: float = INF
var _lado_patrulha: int = 1
## Arremesso da ficha (adagas etc.).
var _arremesso: ArremessoDeCriatura
## Disparo e Sensibilidade à Luz Solar (ficha).
var _disparo: DisparoDeCriatura
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
@onready var _sombra: Polygon2D = $Sombra
@onready var _tremor: TremorComponent = $Tremor
@onready var _dissolver: DissolverComponent = $Dissolver
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
	_saltador = MontagemDeCriatura.criar_saltador(self, criatura, _gravidade)
	MontagemDeCriatura.aplicar_ficha(criatura, _vida, _defesa, _condicoes, _rng, _texto)
	MontagemDeCriatura.ligar_sinais_padrao(
		_defesa, _vida, _dissolver, _ao_resolver_golpe, _ao_morrer, terminar_de_morrer
	)
	_arremesso = ArremessoDeCriatura.new(criatura)
	_disparo = DisparoDeCriatura.new(criatura)
	_prefere_distancia = EstrategiaDeMonstro.prefere_distancia(criatura.dano_medio(criatura.golpe()), criatura.dano_medio_a_distancia())
	_sprite.modulate = cor_corpo
	_preparar_condicoes()
	_preparar_golpe()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_saltador.passar_tempo(delta)
	_tempo_desde_disparo += delta
	_tempo_desde_abrigo += delta
	_tempo_desde_afastar += delta
	_tempo_desde_flanco += delta
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


## A main diz se a fase é de dia (o Kobold ataca com desvantagem ao sol).
func definir_luz_do_sol(ao_sol: bool) -> void:
	_disparo.luz_do_sol = ao_sol


func vida_atual() -> int:
	return _vida.vida_atual


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func adagas_restantes() -> int:
	return _arremesso.restantes()


## Menor que 0: as flechas não acabam.
func flechas_restantes() -> int:
	return _disparo.flechas_restantes()


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
	_sombra.visible = false


func revelar() -> void:
	if not _escondido:
		return
	_escondido = false
	collision_layer = _camada_corpo
	_hurtbox.collision_layer = _camada_hurtbox
	_sprite.visible = true
	_sombra.visible = true


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
	return _arremesso.tem_arma() and alvo != null and not alvo_ao_alcance() and _linha_de_tiro_livre() \
		and _arremesso.no_alcance_longo(_distancia_horizontal())


## Tem flecha, o alvo está longe o bastante para valer o arco e dentro do alcance longo.
func pode_atirar() -> bool:
	return _disparo.tem_flecha() and alvo != null and not _perto_para_oarco() and _linha_de_tiro_livre() \
		and _disparo.no_alcance_longo(_distancia_horizontal())


## Nada do mundo entre o peito de quem atira e o do alvo: senão o tiro bateria na parede.
func _linha_de_tiro_livre() -> bool:
	return alvo == null or DisparoDeCriatura.linha_de_tiro_livre(
		get_world_2d().direct_space_state,
		global_position + Vector2(0.0, -altura_mao),
		alvo.global_position + Vector2(0.0, -altura_alvo),
	)


## O herói atirou ou arremessou de `origem`: quem percebe passa a procurar abrigo.
func perceber_disparo(origem: Vector2) -> void:
	_origem_disparo = origem
	_tempo_desde_disparo = 0.0


## Segundos desde o último disparo do herói que este monstro percebeu.
func tempo_sem_disparo() -> float:
	return _tempo_desde_disparo


## Há abrigo perto contra o tiro recente do herói? Guarda o X dele (`x_do_abrigo`). Quem já está protegido fica; quem está
## no corpo a corpo ou perto demais do herói não se esconde.
func quer_cobertura() -> bool:
	if alvo == null or _tempo_desde_disparo > JANELA_DISPARO or _tempo_desde_abrigo < INTERVALO_ABRIGO:
		return false
	if alvo_ao_alcance() or not alvo_percebido() or _distancia_horizontal() < DISTANCIA_MINIMA_ABRIGO:
		return false
	_tempo_desde_abrigo = 0.0
	if protegido_do_disparo():
		_x_abrigo = global_position.x  # já está atrás da parede: só fica
		return true
	_x_abrigo = BuscaDeAbrigo.procurar(get_world_2d().direct_space_state, global_position, altura_mao, _origem_disparo,
		PASSO_ABRIGO, ceili(ALCANCE_ABRIGO_PX / PASSO_ABRIGO), MASCARA_MUNDO)
	return not is_nan(_x_abrigo)


## Há parede entre o último disparo do herói e o peito deste monstro.
func protegido_do_disparo() -> bool:
	return not SensorDeTerreno.linha_livre(get_world_2d().direct_space_state, _origem_disparo,
		global_position + Vector2(0.0, -altura_mao), MASCARA_MUNDO)


func x_do_abrigo() -> float:
	return _x_abrigo


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


## O Warrior, depois do recuo, rola Furtividade de novo. O Minion não.
func esconde_de_novo() -> bool:
	return criatura.esconde_de_novo


## Zera o teste secreto para a próxima vez que entrar em Escondido.
func reiniciar_furtividade() -> void:
	_rolou_furtividade = false
	_foi_percebido = false


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


## Anda na direção do alvo no deslocamento da ficha, menos a Lentidão (maestria).
func andar_para_alvo() -> void:
	virar_para_alvo()
	if not _tem_chao_na(float(direcao_olhar)):
		parar()
		return
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(_deslocamento_pes())


## Fuga Ágil: corre de costas para longe do alvo (Disparada), ainda olhando para ele.
func recuar() -> void:
	if not _tem_chao_na(-float(direcao_olhar)):
		parar()
		return
	velocity.x = -direcao_olhar * _velocidade_fuga()


## Quanto dura o recuo da Fuga Ágil (s): a distância dela na velocidade de Disparada.
func tempo_de_fuga() -> float:
	var velocidade := _velocidade_fuga()
	return EscalaDnd.pes_para_pixels(recuo_fuga_pes) / velocidade if velocidade > 0.0 else 0.0


func parar() -> void:
	velocity.x = 0.0


## Diante de uma parede, degrau, vão ou queda, decide se vale saltar (regra em `SaltoDnd`). Sem alvo, no ar ou
## sem obstáculo à frente, devolve um plano vazio.
func planejar_salto() -> SaltoDnd.Plano:
	virar_para_alvo()
	var direcao := float(direcao_olhar)
	var bloqueado := is_on_wall() or not _tem_chao_na(direcao)
	return _saltador.planejar(alvo, direcao, bloqueado, DISTANCIA_BEIRA)


## Dá o impulso do plano: corre na velocidade da ficha e sobe o bastante para o degrau ou para cobrir o vão.
func iniciar_salto(plano: SaltoDnd.Plano) -> void:
	_saltador.iniciar(plano, float(direcao_olhar), EscalaDnd.deslocamento_para_velocidade(_deslocamento_pes()), meia_largura_corpo)


## No ar do salto: mantém a corrida (uma batida na parede zera o x).
func correr_no_ar() -> void:
	_saltador.correr_no_ar(float(direcao_olhar))


## False na beira: o próximo passo não tem chão. Empurrão ainda pode derrubar.
func _tem_chao_na(direcao: float) -> bool:
	var mundo := get_world_2d()
	if mundo == null:
		return true
	var origem := global_position + Vector2(direcao * DISTANCIA_BEIRA, -FOLGA_PE)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, PROFUNDIDADE_BEIRA + FOLGA_PE))
	consulta.collision_mask = MASCARA_MUNDO
	return not mundo.direct_space_state.intersect_ray(consulta).is_empty()


## Toca a animação desde o primeiro quadro (se já estiver tocando ela, não reinicia).
func tocar(animacao: StringName) -> void:
	if _sprite.animation == animacao and _sprite.is_playing():
		return
	_sprite.animation = animacao  # trocar a animação volta para o quadro 0
	_sprite.play()


## A arte tem esta animação (a morte própria, p. ex.)?
func tem_animacao(animacao: StringName) -> bool:
	return _sprite.sprite_frames.has_animation(animacao)


func animacao_terminou() -> bool:
	return not _sprite.is_playing()


func iniciar_ataque(animacao: StringName = &"atacar") -> void:
	_tempo_desde_ataque = 0.0
	virar_para_alvo()
	parar()
	tocar(animacao)


## Enfraquecido (maestria): este ataque sai com desvantagem e a condição se gasta.
func ligar_golpe() -> void:
	_golpe.ligar(_golpe_da_ficha())


func desligar_golpe() -> void:
	_golpe.desligar()


## Solta uma arma arremessada na direção do alvo (mira no peito dele). Gasta uma da ficha.
func arremessar_adaga() -> void:
	if alvo == null:
		return
	var mao := global_position + Vector2(direcao_olhar * meia_largura_corpo, -altura_mao)
	var destino := alvo.global_position + Vector2(0.0, -altura_alvo)
	_arremesso.arremessar(self, _golpe_do_arremesso(), mao, destino, _gravidade)


## Solta o que a ficha tiver à distância: arremesso, ou flecha se as armas acabaram.
func soltar_distancia() -> void:
	if _arremesso.tem_arma():
		arremessar_adaga()
	elif _disparo.tem_flecha():
		atirar()


## Dispara uma flecha na direção do alvo (mira no peito dele).
func atirar() -> void:
	if alvo == null:
		return
	var mao := global_position + Vector2(direcao_olhar * meia_largura_corpo, -altura_mao)
	var destino := alvo.global_position + Vector2(0.0, -altura_alvo)
	_disparo.atirar(self, _golpe_do_disparo(), mao, destino, _gravidade)


## Levou dano: o sprite treme por `duracao` s.
func tremer(duracao: float) -> void:
	_tremor.tremer(duracao)


func parar_tremor() -> void:
	_tremor.parar()


## Aviso antes do golpe: quanto tempo dura (0 na emboscada: o herói não viu o monstro).
func tempo_aviso() -> float:
	return 0.0 if _emboscada else criatura.aviso_ataque


## Começa o aviso: para, olha para o alvo e brilha.
func preparar_aviso() -> void:
	parar()
	virar_para_alvo()
	tocar(&"parado")
	_sprite.modulate = cor_aviso


func encerrar_aviso() -> void:
	_sprite.modulate = cor_corpo


func quer_patrulhar() -> bool:
	return criatura.patrulha_pes > 0.0


## Próximo extremo da patrulha: alterna os lados de onde a patrulha começou.
func proximo_extremo_patrulha() -> float:
	if _base_x == INF:
		_base_x = global_position.x
	_lado_patrulha = -_lado_patrulha
	return _base_x + _lado_patrulha * EscalaDnd.pes_para_pixels(criatura.patrulha_pes)


## Anda até `x` devagar, vigiando (ou correndo, em Disparada). True quando chegou, bateu numa parede ou acabou o chão.
func andar_ate(x: float, correndo: bool = false) -> bool:
	var falta := x - global_position.x
	if absf(falta) <= CHEGOU_PATRULHA:
		parar()
		return true
	direcao_olhar = 1 if falta > 0.0 else -1
	if is_on_wall() or not _tem_chao_na(float(direcao_olhar)):
		parar()
		return true
	var fracao := EscalaDnd.MULTIPLICADOR_DISPARADA if correndo else FRACAO_PATRULHA
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(_deslocamento_pes() * fracao)
	return false


## Levou dano: pisca na cor do dano.
func piscar(ligado: bool) -> void:
	_sprite.modulate = cor_dano if ligado else cor_corpo


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Deitado (Caído): o corpo gira e fica no chão, os pés na origem; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_sprite.rotation_degrees = -90.0 * direcao_olhar if deitado else 0.0


## Morte por código: pisca, some em fumaça e, ao acabar, sai do jogo.
func dissolver() -> void:
	_dissolver.dissolver()


## Sai do jogo depois de dissolver.
func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

func _golpe_da_ficha() -> Golpe:
	return _com_autor(criatura.golpe())


func _golpe_do_disparo() -> Golpe:
	var golpe := _com_autor(criatura.golpe_disparo())
	golpe.corpo_a_corpo = false
	return golpe


## A adaga arremessada vem de longe: o parry do Duelista Defensivo não vale.
func _golpe_do_arremesso() -> Golpe:
	var golpe := _com_autor(criatura.golpe_arremesso())
	golpe.corpo_a_corpo = false
	return golpe


func _com_autor(golpe: Golpe) -> Golpe:
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem() or _disparo.desvantagem_solar()
	if _emboscada or _tem_matilha_com_o_alvo():
		golpe.vantagem = true
		_emboscada = false
	return golpe


## Táticas de Matilha: um aliado em pé (nem Caído nem morto) a 5 pés do alvo.
func _tem_matilha_com_o_alvo() -> bool:
	if not criatura.taticas_de_matilha or alvo == null:
		return false
	return TaticasDeMatilha.vale(alvo.global_position, _posicoes_dos_aliados())


## Onde estão os aliados em pé (nem Caídos nem mortos) do grupo de monstros.
func _posicoes_dos_aliados() -> Array[Vector2]:
	var posicoes: Array[Vector2] = []
	for aliado in _aliados_em_pe():
		posicoes.append(aliado.global_position)
	return posicoes


func _aliados_em_pe() -> Array[Goblin]:
	var aliados: Array[Goblin] = []
	for no in get_tree().get_nodes_in_group(GRUPO_ALIADOS):
		var aliado := no as Goblin
		if aliado != null and aliado != self and not aliado.is_queued_for_deletion() \
				and not aliado.esta_caido() and aliado.vida_atual() > 0:
			aliados.append(aliado)
	return aliados


## Um aliado já segura o herói de perto do MEU lado e eu ainda não o alcancei: vale dar a volta para o lado oposto
## (flanqueio). Guarda o X do outro lado (`x_do_flanco`). Uma vez a cada 6 s.
func quer_flanquear() -> bool:
	if alvo == null or not alvo_percebido() or alvo_ao_alcance() or _tempo_desde_flanco < INTERVALO_FLANCO:
		return false
	if _vida.vida_atual * 3 <= _vida.vida_maxima:
		return false  # ferido não se arrisca: recua
	if _distancia_horizontal() > ALCANCE_FLANCO_PX:
		return false
	var meu_lado := Flanqueio.lado(alvo.global_position.x, global_position.x)
	for aliado in _aliados_em_pe():
		if aliado.alvo_ao_alcance() and Flanqueio.lado(alvo.global_position.x, aliado.global_position.x) == meu_lado:
			_tempo_desde_flanco = 0.0
			_x_flanco = alvo.global_position.x - meu_lado * (_alcance_px() * FRACAO_ALCANCE_FLANCO + meia_largura_corpo)
			return true
	return false


func x_do_flanco() -> float:
	return _x_flanco


## Estratégia: recua para manter distância (quem atira de longe tão bem quanto bate de perto) enquanto há espaço e o
## herói ainda não está no corpo a corpo (aí vale a espada) ou, ferido, para junto
## dos aliados. Guarda o motivo (`motivo_afastar`). Uma vez por vida no caso do ferido.
func quer_afastar() -> bool:
	if alvo == null or not alvo_percebido():
		return false
	virar_para_alvo()
	if _quer_recuar_ferido():
		return _comecar_a_afastar(MOTIVO_FERIDO)
	if _quer_manter_distancia():
		return _comecar_a_afastar(MOTIVO_DISTANCIA)
	return false


func motivo_afastar() -> StringName:
	return _motivo_afastar


## Já se afastou o bastante para o motivo atual?
func afastado_o_bastante() -> bool:
	if _motivo_afastar == MOTIVO_FERIDO:
		return _distancia_horizontal() >= DISTANCIA_SEGURA_FERIDO_PX
	return _distancia_horizontal() > EscalaDnd.pes_para_pixels(perto_pes) + FOLGA_DISTANCIA_PX


func _comecar_a_afastar(motivo: StringName) -> bool:
	_motivo_afastar = motivo
	_tempo_desde_afastar = 0.0
	_ja_recuou_ferido = _ja_recuou_ferido or motivo == MOTIVO_FERIDO
	return true


func _quer_recuar_ferido() -> bool:
	if _ja_recuou_ferido or _tempo_desde_afastar < INTERVALO_AFASTAR:
		return false
	var aliados_perto := 0
	for posicao in _posicoes_dos_aliados():
		if absf(posicao.x - global_position.x) <= ALCANCE_ALIADO_PX:
			aliados_perto += 1
	return EstrategiaDeMonstro.deve_recuar_ferido(_vida.vida_atual, _vida.vida_maxima, aliados_perto) and _tem_espaco_atras()


func _quer_manter_distancia() -> bool:
	return _prefere_distancia and (_disparo.tem_flecha() or _arremesso.tem_arma()) and _tempo_desde_afastar >= INTERVALO_AFASTAR \
		and _perto_para_oarco() and not alvo_ao_alcance() and _tem_espaco_atras()


## Chão firme e sem parede para recuar de costas.
func _tem_espaco_atras() -> bool:
	var costas := -float(direcao_olhar)
	var peito := global_position + Vector2(0.0, -altura_mao)
	return _tem_chao_na(costas) and SensorDeTerreno.linha_livre(get_world_2d().direct_space_state, peito,
		peito + Vector2(costas * ESPACO_ATRAS_PX, 0.0), MASCARA_MUNDO)


func _deslocamento_pes() -> float:
	return MontagemDeCriatura.deslocamento_efetivo_pes(criatura, _condicoes)


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
	MontagemDeCriatura.preparar_condicoes(
		criatura, _condicoes, _texto,
		func(deslocamento: Vector2) -> void: _empurrao_restante = deslocamento.x
	)


## Empurrar: desliza o que falta do empurrão (com colisão), por cima do que o estado mandou.
func _aplicar_empurrao(delta: float) -> void:
	_empurrao_restante = MontagemDeCriatura.aplicar_empurrao(
		self, _empurrao_restante, velocidade_empurrao, delta
	)


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_golpe()
	piscar(false)
	_maquina.trocar(&"Morrendo")
