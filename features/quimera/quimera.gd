class_name Quimera
extends CharacterBody2D
## Quimera (D&D 2024, ND 6), o chefe final da fase 10. Ataques Múltiplos: Cabeçada (derruba o herói), Mordida (dano maior se o
## alvo estava Caído, pois o ataque tem vantagem) e Garra; com o Sopro de Fogo pronto, ele toma o lugar da Garra. O Sopro (cone de
## 15 pés, salvaguarda de Destreza CD 15, 7d8 de fogo, metade se passar) recarrega 5-6.
## Voa (60 pés): sobe, sobrevoa o herói e mergulha. Também faz o bote e a investida; abaixo da metade da vida enfurece.
## Números na ficha (CriaturaRPG). Comportamento nos estados (estados/). Não conhece o herói: recebe um alvo por
## definir_alvo() e a Percepção passiva por definir_percepcao_passiva().

## Emitido quando termina de morrer (antes de sumir).
signal morreu
## A vida mudou (a main mostra a barra do chefe).
signal vida_mudou(atual: int, maxima: int)
## Percebeu o herói pela primeira vez (o rugido de entrada).
signal despertou
## O rugido e a cabeçada fazem o chão tremer: a main treme a câmera do herói (força em px, duração em s).
signal abalou_o_chao(forca: float, duracao: float)

const ATAQUE_CABECADA := &"cabecada"
const ATAQUE_MORDIDA := &"mordida"
const ATAQUE_GARRA := &"garra"
## O bote (garra que derruba ao cair em cima do herói) e o mergulho do voo (cabeçada que derruba).
const ATAQUE_BOTE := &"bote"
const ATAQUE_MERGULHO := &"mergulho"
## Nomes dos golpes do bote e do mergulho (aparecem no texto flutuante e distinguem do combo de perto).
const NOME_BOTE := "Bote"
const NOME_MERGULHO := "Mergulho"
## Nomes dos estados dos padrões de movimento (além do combo e do Sopro).
const PADRAO_BOTE := &"Bote"
const PADRAO_INVESTIDA := &"Investindo"
const PADRAO_VOO := &"Voando"
## Cada padrão: [recarga (s), distância mínima (px), distância máxima (px)] do herói em que ela o escolhe.
const PADROES := {
	PADRAO_BOTE: [4.0, 130.0, 380.0],
	PADRAO_INVESTIDA: [6.0, 260.0, 640.0],
	PADRAO_VOO: [9.0, 120.0, 700.0],
}
## Fúria (abaixo da metade da vida, regra da casa): recargas e aviso ficam mais curtos por este fator.
const FATOR_FURIA := 0.6
const FATOR_AVISO_FURIA := 0.7
## Diferença de altura (px) até a qual o bote e a investida valem; e quanto antes do herói o bote e o mergulho miram (px).
const DESNIVEL_MAXIMO := 96.0
const MARGEM_DE_MIRA := 30.0
## Voo: aceleração (px/s²), ganho do controle de altura e de pontaria, velocidade de subida e de ajuste lateral (px/s).
## Margem “em cima” e fração de altura mínima vêm de `VooDeCriatura`.
const ACELERACAO_VOO := 900.0
const ACELERACAO_MERGULHO := 2400.0
const GANHO_DO_CONTROLE := 4.0
const VELOCIDADE_SUBIDA := 240.0
const VELOCIDADE_AJUSTE := 360.0
## Tremor da câmera no mergulho (px).
const FORCA_ABALO_MERGULHO := 7.0
## Camada "mundo" do chão.
const MASCARA_CHAO := 1 | (1 << 5)  # MontagemDeCriatura.mascara_do_chao()
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
## Quanto à frente da borda do corpo (px) o raio procura chão antes de descer do penhasco.
const DISTANCIA_BEIRA := 40.0
## Quanto tempo o sprite fica vermelho ao levar dano (s); a animação `dano` pode durar mais.
const TEMPO_PISCAR_DANO := 0.12
const ANIM_DANO := &"dano"
## Tremor da câmera: no rugido e na cabeçada (px) e duração (s).
const FORCA_ABALO_RUGIDO := 5.0
const FORCA_ABALO_CABECADA := 4.0
const DURACAO_ABALO := 0.4
## Quadro da animação `morte` em que ela está deitada (o estado Caído congela nele).
const QUADRO_DEITADA := 4
## Quadros da animação `pular`: a queda (mergulho) e o pouso.
const QUADRO_QUEDA := 4
const QUADRO_POUSO := 5
## Abaixo desta velocidade (px/s) ela conta como parada.
const VELOCIDADE_PARADA := 8.0
## Limites do ritmo da passada em relação ao da animação (1 = a velocidade de andar do livro).
const PASSADA_MINIMA := 0.5
const PASSADA_MAXIMA := 2.5

## Bloco de estatísticas. Padrão: data/quimera.tres.
@export var criatura: CriaturaRPG
## Altura (px) da área dos golpes e metade da largura do corpo (px): o golpe começa na borda do corpo (a cara do leão).
@export var altura_golpe: float = 80.0
@export var meia_largura_corpo: float = 56.0
## Janelas em que cada golpe acerta (s desde o início da animação `ataque`, 12 quadros por segundo).
@export var inicio_cabecada: float = 0.14
@export var fim_cabecada: float = 0.26
@export var inicio_mordida: float = 0.26
@export var fim_mordida: float = 0.4
@export var inicio_garra: float = 0.4
@export var fim_garra: float = 0.55
## Janela em que o fogo queima (s desde o início da animação `sopro`, 8 quadros por segundo: o fogo aparece no 4º).
@export var inicio_sopro: float = 0.38
@export var fim_sopro: float = 0.7
## Quanto o corpo acelera ao sair e freia ao parar (px/s²): sem isso ela arrancaria e pararia de uma vez, "travando".
@export var aceleracao: float = 700.0
@export var freio: float = 900.0
## Com o herói mais longe que isto (px), ela corre na Disparada (o dobro da velocidade, regra do livro).
@export var distancia_disparada: float = 220.0
## Aceleração da investida (px/s²).
@export var aceleracao_investida: float = 1200.0
## Bote: tempo no ar (s) e velocidade horizontal máxima (px/s).
@export var tempo_do_bote: float = 0.75
@export var velocidade_maxima_bote: float = 420.0
## Voo: altura (px) sobre o herói em que ela sobrevoa, velocidade do mergulho (px/s) e o tempo máximo de sobrevoo (s).
@export var altura_de_voo: float = 150.0
@export var velocidade_do_mergulho: float = 640.0
@export var tempo_maximo_de_voo: float = 3.0
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
@export var cor_dano: Color = Color(1.0, 0.45, 0.45)
@export var cor_aviso: Color = Color(1.0, 0.7, 0.35)

var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1
## O ataque em andamento passou do combo para o Sopro (o Sopro entra sem novo aviso).
var combo_em_andamento: bool = false
## Está no ar por conta própria (voo e mergulho): a gravidade não puxa.
var voando: bool = false

var _recargas_dos_padroes: Dictionary = {}
var _ultimo_padrao: StringName = &""
var _enfurecida: bool = false
var _rugido_pendente: bool = false
var _golpe_acertou: bool = false
var _ritmo_forcado: float = 1.0
var _rng := RandomNumberGenerator.new()
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _tempo_desde_ataque: float = INF
var _empurrao_restante: float = 0.0
var _despertou: bool = false
## Reação visual ao hit: toca `dano` sem trocar de estado; bloqueia `tocar` até acabar.
var _reacao_dano_em_curso: bool = false
var _saltador: SaltadorDeMonstro
## Cabeçada / investida da ficha (`chifrada_*`).
var _investida: InvestidaDeCriatura
## Voo da ficha (`voo_pes`).
var _voo: VooDeCriatura
## Sopro de Fogo da ficha (`linha_*`).
var _ataque_linha: LinhaDeCriatura

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _dissolver: DissolverComponent = $Dissolver
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _golpe: HitboxComponent = $Golpe
@onready var _forma_golpe: CollisionShape2D = $Golpe/Forma
@onready var _sopro: HitboxComponent = $Sopro
@onready var _forma_sopro: CollisionShape2D = $Sopro/Forma
@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _condicoes: CondicoesComponent = $Condicoes


func _ready() -> void:
	if criatura == null:
		criatura = CriaturaRPG.new()  # cena aberta sozinha (F6) continua funcionando
	MontagemDeCriatura.configurar_colisao_chao(self)
	_saltador = MontagemDeCriatura.criar_saltador(self, criatura, _gravidade)
	MontagemDeCriatura.aplicar_ficha(criatura, _vida, _defesa, _condicoes, _rng, _texto)
	_investida = InvestidaDeCriatura.new(criatura)
	_voo = VooDeCriatura.new(criatura, altura_de_voo)
	_ataque_linha = LinhaDeCriatura.new(criatura)
	_vida.vida_mudou.connect(vida_mudou.emit)
	_vida.vida_mudou.connect(_ao_mudar_vida)
	_golpe.alvo_atingido.connect(func(_alvo: HurtboxComponent) -> void: _golpe_acertou = true)
	MontagemDeCriatura.ligar_sinais_padrao(
		_defesa, _vida, _dissolver, _ao_resolver_golpe, _ao_morrer, terminar_de_morrer
	)
	_preparar_condicoes()
	_preparar_areas()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_saltador.passar_tempo(delta)
	_ataque_linha.passar_tempo(delta, _rng, FATOR_FURIA if _enfurecida else 1.0)
	_recarregar_padroes(delta)
	if not is_on_floor() and not voando:
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.speed_scale = _ritmo_da_passada()
	_sprite.scale.x = direcao_olhar  # a arte olha para a direita
	_golpe.scale.x = direcao_olhar
	_sopro.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


## A Quimera não se esconde: não rola Furtividade, então não usa a Percepção do herói.
func definir_percepcao_passiva(_valor: int) -> void:
	pass


func vida_atual() -> int:
	return _vida.vida_atual


func vida_maxima() -> int:
	return _vida.vida_maxima


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func sopro_pronto() -> bool:
	return _ataque_linha.pronta()


## Só para testes / forçar a recarga do Sopro.
func definir_sopro_pronto(valor: bool) -> void:
	_ataque_linha.definir_pronta(valor)


# --- Ferramentas dos estados ----------------------------------------------------

func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px() \
		and absf(alvo.global_position.y - global_position.y) <= altura_golpe


func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


## O Sopro recarregou e o herói está dentro do cone (à frente, na mesma altura, sem passar do comprimento dele).
func quer_soprar() -> bool:
	return alvo != null and is_on_floor() and _ataque_linha.pronta() and _ataque_linha.alvo_na_area(
		_distancia_horizontal(),
		meia_largura_corpo,
		absf(alvo.global_position.y - global_position.y),
		altura_golpe,
	)


## Primeira vez que percebe o herói: avisa a main (uma vez só).
func despertar() -> void:
	if _despertou:
		return
	_despertou = true
	despertou.emit()


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


## Anda até o herói acelerando aos poucos; longe, corre na Disparada (o dobro da velocidade).
func andar_para_alvo() -> void:
	virar_para_alvo()
	if not _tem_chao_na(float(direcao_olhar)):
		parar()
		return
	var multiplicador := EscalaDnd.MULTIPLICADOR_DISPARADA if _distancia_horizontal() > distancia_disparada else 1.0
	var desejada := direcao_olhar * _velocidade_de_andar() * multiplicador
	velocity.x = move_toward(velocity.x, desejada, aceleracao * get_physics_process_delta_time())


## Freia aos poucos (o corpo tem peso), em vez de travar no lugar.
func parar() -> void:
	velocity.x = move_toward(velocity.x, 0.0, freio * get_physics_process_delta_time())


## Ainda se movendo (corre, ou freando): a animação de andar continua em vez de pular para a pose parada.
func em_movimento() -> bool:
	return absf(velocity.x) > VELOCIDADE_PARADA


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
	if _reacao_dano_em_curso and animacao != &"morte":
		return
	if animacao == &"morte":
		_reacao_dano_em_curso = false
	if _sprite.animation == animacao and _sprite.is_playing():
		return
	_sprite.animation = animacao
	_sprite.play()


func animacao_terminou() -> bool:
	return not _sprite.is_playing()


## Começa uma animação do primeiro quadro (o ataque de perto, o Sopro, o rugido).
func iniciar_ataque(animacao: StringName) -> void:
	_tempo_desde_ataque = 0.0
	virar_para_alvo()
	parar()
	reiniciar(animacao)


## Toca a animação do primeiro quadro sem mexer na velocidade (o bote e a investida já estão em movimento).
func reiniciar(animacao: StringName) -> void:
	_reacao_dano_em_curso = false
	_sprite.animation = animacao
	_sprite.frame = 0
	_sprite.play()


## Congela num quadro (a queda do mergulho, o pouso).
func mostrar_quadro(animacao: StringName, quadro: int) -> void:
	_reacao_dano_em_curso = false
	_sprite.animation = animacao
	_sprite.frame = mini(quadro, _sprite.sprite_frames.get_frame_count(animacao) - 1)
	_sprite.pause()


## Ritmo das animações que não são a passada (o bote roda mais devagar para durar o tempo do salto).
func definir_ritmo(ritmo: float) -> void:
	_ritmo_forcado = ritmo


# --- Padrões (bote, investida, voo) ---------------------------------------------

## O próximo padrão de ataque: o combo de perto se o herói está ao alcance; senão sorteia entre o Sopro e os padrões prontos
## cuja distância vale, sem repetir o último. Vazio se nenhum serve (ela segue andando).
func escolher_padrao() -> StringName:
	if alvo_ao_alcance():
		return _escolhido(&"Atacando")
	var validos: Array[StringName] = []
	if quer_soprar():
		validos.append(&"Soprando")
	for padrao: StringName in PADROES:
		if _padrao_valido(padrao):
			validos.append(padrao)
	if validos.size() > 1:
		validos.erase(_ultimo_padrao)
	if validos.is_empty():
		return &""
	return _escolhido(validos[_rng.randi() % validos.size()])


func enfurecida() -> bool:
	return _enfurecida


func deve_rugir() -> bool:
	return _rugido_pendente


## Impulso (px/s) do bote: sai do chão e cai um pouco antes do herói em `tempo_do_bote`.
func planejar_bote() -> Vector2:
	virar_para_alvo()
	var dx := alvo.global_position.x - direcao_olhar * MARGEM_DE_MIRA - global_position.x
	var dy := clampf(alvo.global_position.y - global_position.y, -DESNIVEL_MAXIMO, DESNIVEL_MAXIMO)
	var vx := clampf(dx / tempo_do_bote, -velocidade_maxima_bote, velocidade_maxima_bote)
	return Vector2(vx, (dy - 0.5 * _gravidade * tempo_do_bote * tempo_do_bote) / tempo_do_bote)


func iniciar_bote(impulso: Vector2) -> void:
	velocity = impulso
	reiniciar(&"pular")


## A investida de cabeçada: corre na Disparada em linha reta, com a cabeçada (derruba) ligada.
func iniciar_investida() -> void:
	virar_para_alvo()
	_golpe_acertou = false
	reiniciar(&"andar")
	_golpe.ligar(_golpe_de(ATAQUE_CABECADA))


func correr_na_investida() -> void:
	var desejada := direcao_olhar * _velocidade_de_andar() * EscalaDnd.MULTIPLICADOR_DISPARADA
	velocity.x = move_toward(velocity.x, desejada, aceleracao_investida * get_physics_process_delta_time())


func golpe_acertou() -> bool:
	return _golpe_acertou


func limpar_acerto() -> void:
	_golpe_acertou = false


## Bateu em parede ou chegou à beira de uma queda: a investida acaba.
func investida_barrada() -> bool:
	return is_on_wall() or not _tem_chao_na(float(direcao_olhar))


## Decola: a gravidade deixa de puxar e a arte de voar roda em laço.
func comecar_voo() -> void:
	voando = true
	tocar(&"voar")


func terminar_voo() -> void:
	voando = false


## Sobe até a altura de voo e voa (`voo_pes` da ficha) para cima do herói.
func voar_para_alvo() -> void:
	virar_para_alvo()
	_voo.altura_px = altura_de_voo
	var passo := ACELERACAO_VOO * get_physics_process_delta_time()
	var dx := alvo.global_position.x - global_position.x
	velocity.x = move_toward(velocity.x, _voo.velocidade_horizontal_desejada(dx), passo)
	var dy := _voo.altura_alvo_y(alvo.global_position.y) - global_position.y
	velocity.y = move_toward(velocity.y, clampf(dy * GANHO_DO_CONTROLE, -VELOCIDADE_SUBIDA, VELOCIDADE_SUBIDA), passo)


## Está em cima do herói e já na altura de voo: hora de mergulhar.
func sobre_o_alvo() -> bool:
	if alvo == null:
		return false
	_voo.altura_px = altura_de_voo
	return _voo.sobre_o_alvo(global_position, alvo.global_position)


## Cai sobre o herói: acelera para baixo e corrige a pontaria na horizontal.
func mergulhar() -> void:
	virar_para_alvo()
	var passo := ACELERACAO_VOO * get_physics_process_delta_time()
	var mira_x := alvo.global_position.x - direcao_olhar * MARGEM_DE_MIRA
	velocity.x = move_toward(velocity.x, clampf((mira_x - global_position.x) * GANHO_DO_CONTROLE, -VELOCIDADE_AJUSTE, VELOCIDADE_AJUSTE), passo)
	velocity.y = move_toward(velocity.y, velocidade_do_mergulho, ACELERACAO_MERGULHO * get_physics_process_delta_time())


## Chegou ao chão no mergulho: para, a tela treme e a cabeçada (derruba) cai em cima do herói.
func aterrissar_do_mergulho() -> void:
	voando = false
	velocity = Vector2.ZERO
	mostrar_quadro(&"pular", QUADRO_POUSO)
	abalou_o_chao.emit(FORCA_ABALO_MERGULHO, DURACAO_ABALO)
	_golpe.ligar(_golpe_de(ATAQUE_MERGULHO))


## O bote: a garra que derruba sai na descida (o herói caído dá vantagem à mordida seguinte).
func ligar_bote() -> void:
	_golpe.ligar(_golpe_de(ATAQUE_BOTE))


## O Sopro: gasta a recarga e toca a animação.
func iniciar_sopro() -> void:
	_ataque_linha.consumir()
	iniciar_ataque(&"sopro")


## O rugido (de entrada e o da fúria): toca e treme a tela.
func rugir() -> void:
	_rugido_pendente = false
	iniciar_ataque(&"rugido")
	abalou_o_chao.emit(FORCA_ABALO_RUGIDO, DURACAO_ABALO)


## Qual golpe de perto está na janela agora (`tempo` desde o início da animação `ataque`); vazio se nenhum.
func ataque_na_janela(tempo: float) -> StringName:
	if tempo >= inicio_cabecada and tempo < fim_cabecada:
		return ATAQUE_CABECADA
	if tempo >= inicio_mordida and tempo < fim_mordida:
		return ATAQUE_MORDIDA
	if tempo >= inicio_garra and tempo < fim_garra:
		return ATAQUE_GARRA
	return &""


func ligar_golpe(ataque: StringName) -> void:
	if ataque == ATAQUE_CABECADA:
		abalou_o_chao.emit(FORCA_ABALO_CABECADA, DURACAO_ABALO)
	_golpe.ligar(_golpe_de(ataque))


func desligar_golpe() -> void:
	_golpe.desligar()


func ligar_sopro() -> void:
	_sopro.ligar(_com_autor(_ataque_linha.golpe()))


func desligar_sopro() -> void:
	_sopro.desligar()


## Aviso antes do ataque: se encolhe (animação `armar`), olha o herói e brilha (dá tempo de esquivar).
func tempo_aviso() -> float:
	return criatura.aviso_ataque * (FATOR_AVISO_FURIA if _enfurecida else 1.0)


func preparar_aviso() -> void:
	parar()
	virar_para_alvo()
	tocar(&"armar")
	_sprite.modulate = cor_aviso


func encerrar_aviso() -> void:
	_sprite.modulate = Color.WHITE


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Caído (maestria Derrubar): congela no quadro da morte em que ela está deitada; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	if not deitado:
		return
	_sprite.animation = &"morte"
	_sprite.frame = QUADRO_DEITADA
	_sprite.pause()


func dissolver() -> void:
	_dissolver.dissolver()


func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

func _recarregar_padroes(delta: float) -> void:
	for padrao: StringName in _recargas_dos_padroes:
		_recargas_dos_padroes[padrao] = maxf(float(_recargas_dos_padroes[padrao]) - delta, 0.0)


## O padrão serve agora: recarregou, o herói está na faixa de distância e o chão permite.
func _padrao_valido(padrao: StringName) -> bool:
	if float(_recargas_dos_padroes.get(padrao, 0.0)) > 0.0 or not is_on_floor() or alvo == null:
		return false
	var dados: Array = PADROES[padrao]
	var distancia := _distancia_horizontal()
	if distancia < float(dados[1]) or distancia > float(dados[2]):
		return false
	var mesma_altura := absf(alvo.global_position.y - global_position.y) <= DESNIVEL_MAXIMO
	match padrao:
		PADRAO_BOTE:
			return mesma_altura
		PADRAO_INVESTIDA:
			return InvestidaDeCriatura.tem_chifrada(criatura) and mesma_altura \
				and _tem_chao_na(float(direcao_olhar))
		PADRAO_VOO:
			return _voo.tem()
	return true


## Marca o padrão como usado: começa a recarga (mais curta em fúria) e o ritmo entre ataques.
func _escolhido(padrao: StringName) -> StringName:
	_ultimo_padrao = padrao
	_tempo_desde_ataque = 0.0
	if PADROES.has(padrao):
		_recargas_dos_padroes[padrao] = float((PADROES[padrao] as Array)[0]) * (FATOR_FURIA if _enfurecida else 1.0)
	return padrao


## Abaixo da metade da vida ela se enfurece (regra da casa): ruge e fica mais rápida entre os padrões.
func _ao_mudar_vida(atual: int, maxima: int) -> void:
	if _enfurecida or atual <= 0 or atual * 2 > maxima:
		return
	_enfurecida = true
	_rugido_pendente = true


func _golpe_de(ataque: StringName) -> Golpe:
	match ataque:
		ATAQUE_CABECADA:
			return _com_autor(_investida.golpe(true))
		ATAQUE_MERGULHO:
			var mergulho := _com_autor(_investida.golpe(true))
			mergulho.nome = NOME_MERGULHO
			return mergulho
		ATAQUE_GARRA:
			return _com_autor(criatura.golpe_garra())
		ATAQUE_BOTE:
			var bote := _com_autor(criatura.golpe_garra())
			bote.nome = NOME_BOTE
			bote.efeitos.append(EfeitosDeTalento.Derrubada.new())
			return bote
	return _com_autor(criatura.golpe())


func _com_autor(golpe: Golpe) -> Golpe:
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem()
	return golpe


func _velocidade_de_andar() -> float:
	return MontagemDeCriatura.velocidade_andar(criatura, _condicoes)


## A passada acompanha o chão: na velocidade de andar a animação roda no ritmo normal, na Disparada roda mais depressa (os
## pés não deslizam). Fora da animação de andar, o ritmo é o normal.
func _ritmo_da_passada() -> float:
	if _sprite.animation != &"andar":
		return _ritmo_forcado
	return clampf(absf(velocity.x) / _velocidade_de_andar(), PASSADA_MINIMA, PASSADA_MAXIMA)


func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


func _tem_chao_na(direcao: float) -> bool:
	var origem := global_position + Vector2(direcao * (meia_largura_corpo + DISTANCIA_BEIRA), -FOLGA_PE)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, PROFUNDIDADE_BEIRA + FOLGA_PE))
	consulta.collision_mask = MASCARA_CHAO
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


## Os golpes cobrem do centro do corpo até o alcance; o Sopro (o cone, aproximado por um retângulo) sai da borda do corpo.
func _preparar_areas() -> void:
	var comprimento := meia_largura_corpo + _alcance_px()
	(_forma_golpe.shape as RectangleShape2D).size = Vector2(comprimento, altura_golpe)
	_forma_golpe.position = Vector2(comprimento / 2.0, -altura_golpe / 2.0)
	var tamanho := _ataque_linha.tamanho_hitbox_px()
	(_forma_sopro.shape as RectangleShape2D).size = tamanho
	_forma_sopro.position = Vector2(_ataque_linha.offset_x_centro(meia_largura_corpo), -tamanho.y / 2.0)


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado)
	if _vida.esta_morto():
		return
	if _condicoes.esta_caido() and nome_estado() != &"Caido":
		_maquina.trocar(&"Caido")
	elif resultado.acertou:
		_piscar_dano()


## Chefe não troca de estado ao apanhar: toca a arte `dano` + vermelho, depois volta à pose.
func _piscar_dano() -> void:
	_sprite.modulate = cor_dano
	if _reacao_dano_em_curso or not _sprite.sprite_frames.has_animation(ANIM_DANO):
		await get_tree().create_timer(TEMPO_PISCAR_DANO).timeout
		if is_inside_tree() and not _vida.esta_morto():
			_sprite.modulate = Color.WHITE
		return
	_reacao_dano_em_curso = true
	var anim_antes := _sprite.animation
	var quadro_antes := _sprite.frame
	var tocava := _sprite.is_playing()
	_sprite.animation = ANIM_DANO
	_sprite.frame = 0
	_sprite.play()
	var n := _sprite.sprite_frames.get_frame_count(ANIM_DANO)
	var vel := _sprite.sprite_frames.get_animation_speed(ANIM_DANO)
	var duracao := maxf(TEMPO_PISCAR_DANO, float(n) / maxf(vel, 0.001))
	await get_tree().create_timer(duracao).timeout
	if not is_inside_tree() or _vida.esta_morto():
		_reacao_dano_em_curso = false
		return
	_sprite.modulate = Color.WHITE
	if _sprite.animation == ANIM_DANO:
		_sprite.animation = anim_antes
		_sprite.frame = quadro_antes
		if tocava:
			_sprite.play()
		else:
			_sprite.pause()
	_reacao_dano_em_curso = false


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
	_reacao_dano_em_curso = false
	_sprite.modulate = Color.WHITE
	_defesa.invulneravel = true
	desligar_golpe()
	desligar_sopro()
	_sprite.modulate = Color.WHITE
	_maquina.trocar(&"Morrendo")
