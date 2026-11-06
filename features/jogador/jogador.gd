class_name Jogador
extends CharacterBody2D
## Herói de ação lateral. Este script guarda as "ferramentas de física" (gravidade, pulo,
## movimento) e repassa o comportamento para a MaquinaEstados (estados em estados/).
## Visual e câmera são filhos: o Jogador chama funções deles (call down).

## Emitido no quadro em que o pulo começa.
signal pulou
## Emitido no quadro em que toca o chão depois de estar no ar.
signal aterrissou
## Emitido quando volta para o início (ex.: caiu num buraco).
signal reapareceu
## Emitido quando a vida muda (ex.: ao criar o personagem).
signal vida_mudou(atual: int, maxima: int)
## Emitido quando a vida chega a zero. Quem monta o jogo decide (ex.: tela "Você caiu!" e
## depois reviver()). Se ninguém escutar (cena aberta sozinha), o herói revive sozinho.
signal caiu
## Emitido ao arremessar a arma da mão. Quem monta o jogo cria o projétil.
## Sem ninguém escutando (cena aberta sozinha), a arma continua na mão.
signal arma_arremessada(arma: Arma, golpe: Golpe, penalidade: int, origem: Vector2, direcao: int)

## Números de balanceamento (velocidades, pulo). Padrão: data/jogador_padrao.tres.
@export var stats: StatsJogador
## Itens com que o herói começa (ficam no inventário, sem equipar).
@export var itens_iniciais: Array[Item] = []
## Golpe usado quando não há arma na mão (soco de D&D). Padrão: data/ataque_desarmado.tres.
@export var ataque_desarmado: Arma
## Classe de D&D (dado de vida, atributos sugeridos). Padrão: data/classe_guerreiro.tres.
@export var classe: ClasseRPG
## Se cair abaixo desta altura (Y), volta para o início.
@export var limite_queda: float = 600.0

## Para onde o herói está olhando: 1 = direita, -1 = esquerda.
var direcao_olhar: int = 1
var posicao_inicial: Vector2
## Ficha de D&D (atributos). Começa com a sugestão da classe; a tela de criação troca.
var ficha: Ficha
## Itens carregados e equipados.
var inventario := Inventario.new()

## De onde veio o último golpe que acertou o herói (o estado LevandoDano recua para longe dele).
var origem_ultimo_golpe: Vector2

var _contador_invencivel: float = 0.0
var _tempo_desde_golpe: float = INF
var _contador_buffer_ataque: float = 0.0
var _contador_buffer_arremesso: float = 0.0
## Segundo J durante o golpe: pede o ataque extra da outra mão.
var _combo_pedido: bool = false
## O golpe atual já é o extra (não encadeia um terceiro).
var _golpe_extra: bool = false
var _contador_coyote: float = 0.0
var _contador_buffer: float = 0.0
var _pedido_corrida: int = 0
var _estava_no_chao: bool = true
var _toque_duplo: ToqueDuplo

@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _animacao: AnimacaoJogador = $Sprite
@onready var _camera: CameraJogador = $Camera
@onready var _ataque: AtaqueJogador = $Ataque
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _escudo: EscudoJogador = $Escudo
@onready var _arma_tras: ArmaTras = $ArmaTras


func _ready() -> void:
	# Valores padrão seguros: a cena aberta sozinha (F6) continua funcionando.
	if stats == null:
		stats = StatsJogador.new()
	if ataque_desarmado == null:
		ataque_desarmado = Arma.new()
	for item in itens_iniciais:
		inventario.adicionar(item.duplicate())  # cópia própria: cada item tem seu desgaste
	if classe == null:
		classe = ClasseRPG.new()
	posicao_inicial = global_position
	_toque_duplo = ToqueDuplo.new(stats.janela_toque_duplo)
	aterrissou.connect(_animacao.tocar_aterrissagem)
	_vida.vida_mudou.connect(vida_mudou.emit)
	_vida.morreu.connect(_morrer, CONNECT_DEFERRED)  # depois que o golpe terminar de ser tratado
	_defesa.golpe_resolvido.connect(_ao_resolver_golpe)
	inventario.mudou.connect(_atualizar_equipamento)
	configurar_ficha(Ficha.new(classe, classe.atributos_sugeridos))
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_atualizar_contadores(delta)
	_atualizar_invencibilidade(delta)
	_maquina.processar_fisica(delta)
	move_and_slide()
	_checar_aterrissagem()
	_animacao.atualizar(_maquina.nome_estado_atual(), velocity, direcao_olhar, velocidade_andar(), velocidade_corrida())
	_ataque.seguir_mao(_animacao.ponto_da_mao(), _animacao.angulo_descanso(), direcao_olhar, arma_atual())
	var na_tras: Arma = null if _ataque.golpe_da_secundaria() else arma_secundaria()
	_arma_tras.mostrar(na_tras, _animacao.ponto_da_mao_de_tras(), direcao_olhar)
	_escudo.seguir_mao(_animacao.ponto_da_mao_de_tras(), direcao_olhar)
	_camera.olhar_para(direcao_olhar)
	if global_position.y > limite_queda:
		reaparecer()


# --- API pública (para a fase/main e para os testes) ----------------------------

## Define onde o herói começa e o coloca lá.
func posicionar_no_inicio(posicao: Vector2) -> void:
	posicao_inicial = posicao
	global_position = posicao
	reset_physics_interpolation()


## Troca a ficha de D&D (ex.: vinda da tela de criação) e recalcula a vida e a CA.
func configurar_ficha(nova: Ficha) -> void:
	ficha = nova
	classe = nova.classe
	_vida.configurar(ficha.vida_maxima())
	_atualizar_equipamento()


## Troca a mochila pelo pacote escolhido na criação (cópias próprias: cada uma com seu
## desgaste) e equipa o que o pacote manda. null = mantém a mochila como está.
func receber_pacote(pacote: PacoteInicial) -> void:
	if pacote == null:
		return
	inventario.limpar()
	for item in pacote.itens:
		var meu := item.duplicate() as Item
		inventario.adicionar(meu, pacote.itens[item])
		if item in pacote.equipar:
			inventario.equipar(meu)


## Armadura vestida (espaço corpo), ou null.
func armadura_atual() -> Armadura:
	return Equipamento.armadura(inventario)


## Escudo na mão secundária, ou null.
func escudo_atual() -> Armadura:
	return Equipamento.escudo(inventario)


## CA com a armadura e o escudo vestidos (e o desgaste da armadura).
func classe_armadura() -> int:
	return Equipamento.classe_armadura(ficha, inventario)


func esta_invencivel() -> bool:
	return _contador_invencivel > 0.0


func vida_atual() -> int:
	return _vida.vida_atual


func vida_maxima() -> int:
	return _vida.vida_maxima


## Impede a câmera de mostrar fora da `area` da fase (pixels).
func definir_limites_camera(area: Rect2) -> void:
	_camera.definir_limites(area)


## Volta para o início da fase.
func reaparecer() -> void:
	posicionar_no_inicio(posicao_inicial)
	velocity = Vector2.ZERO
	_maquina.trocar(&"NoAr")
	reapareceu.emit()


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func esta_correndo() -> bool:
	return nome_estado() == &"Correndo"


# --- Ferramentas de física (usadas pelos estados) -------------------------------

## Direção segurada: -1 (esquerda) a 1 (direita).
func direcao() -> float:
	return Input.get_axis("mover_esquerda", "mover_direita")


## Direção do toque duplo neste quadro (-1 ou 1), ou 0 se não houve.
func pediu_corrida() -> int:
	return _pedido_corrida


## Velocidade andando (px/s): o deslocamento de D&D da ficha (30 pés -> ~128 px/s).
## Armadura que pede mais Força do que o herói tem tira 10 pés.
func velocidade_andar() -> float:
	return EscalaDnd.deslocamento_para_velocidade(Equipamento.deslocamento_pes(ficha, inventario))


## Correndo = Disparada (Dash) do D&D: o dobro do deslocamento.
func velocidade_corrida() -> float:
	return velocidade_andar() * EscalaDnd.MULTIPLICADOR_DISPARADA


## Segundos entre golpes, pela iniciativa (ex.: +2 -> 0,8 s).
func intervalo_entre_golpes() -> float:
	return EscalaDnd.intervalo_ataque(ficha.iniciativa())


## Já passou o intervalo da iniciativa desde o último golpe?
func pode_golpear() -> bool:
	return tempo_para_proximo_golpe() <= 0.0


## Quanto falta (s) para poder golpear de novo (0 = já pode).
func tempo_para_proximo_golpe() -> float:
	return maxf(intervalo_entre_golpes() - _tempo_desde_golpe, 0.0)


## Apertou atacar há pouco (buffer) e já pode golpear.
func pediu_ataque() -> bool:
	return _contador_buffer_ataque > 0.0 and pode_golpear()


## Apertou arremessar há pouco, já pode agir e a arma da mão arremessa.
func pediu_arremesso() -> bool:
	return _contador_buffer_arremesso > 0.0 and pode_golpear() and _arma_arremessavel() != null


## Arma na mão, ou o ataque desarmado se a mão estiver vazia.
func arma_atual() -> Arma:
	return Equipamento.arma(inventario, ataque_desarmado)


## Arma leve na outra mão, ou null.
func arma_secundaria() -> Arma:
	return Equipamento.arma_secundaria(inventario)


## O 2º J durante o golpe pede o ataque extra, e as duas armas são leves.
func quer_golpe_extra() -> bool:
	if not _combo_pedido or _golpe_extra:
		return false
	var principal := inventario.equipado(Item.ESPACO_MAO) as Arma
	var segunda := arma_secundaria()
	return principal != null and principal.leve and segunda != null and segunda.leve


## Começa um golpe com a arma atual, para o lado em que o herói olha.
## Quem for atingido rola o ataque (d20 + bônus da ficha) contra a própria CA.
func iniciar_golpe() -> void:
	_comecar_golpe(false)


## 2º golpe do combo: a arma da outra mão, sem esperar a iniciativa de novo.
func iniciar_golpe_extra() -> void:
	_comecar_golpe(true)


## Solta a arma da mão. Sem ninguém escutando o sinal, ela continua equipada.
func lancar_arma() -> void:
	var arma := _arma_arremessavel()
	if arma == null or arma_arremessada.get_connections().is_empty():
		return
	var pen := inventario.penalidade(arma)
	var golpe := Equipamento.golpe(ficha, inventario, arma)
	var extraida := inventario.extrair_uma(arma)
	_tempo_desde_golpe = 0.0
	_contador_buffer_arremesso = 0.0
	arma_arremessada.emit(extraida, golpe, pen, _ataque.global_position, direcao_olhar)


## Arma caída volta para a mochila (e para a mão, se ela estiver vazia). false = mochila cheia.
func recolher_arma(arma: Arma, penalidade_arma: int) -> bool:
	if not inventario.adicionar_com_desgaste(arma, penalidade_arma):
		return false
	if arma in inventario.itens and inventario.equipado(Item.ESPACO_MAO) == null:
		inventario.equipar(arma)
	return true


## Texto flutuante (ex.: arma que derreteu no ar).
func avisar(texto: String) -> void:
	_texto.mostrar(texto, TextoFlutuanteComponent.COR_DANO_SOFRIDO)


## O golpe da arma atual (com o desgaste dela). Se um alvo corrosivo avisar, a arma se desgasta.
func criar_golpe() -> Golpe:
	return _criar_golpe_de(arma_atual(), false)


## Volta para o início com a vida cheia (ex.: "Tentar de novo" depois de cair).
func reviver() -> void:
	_contador_invencivel = 0.0
	_defesa.invulneravel = false
	_animacao.piscando = false
	_vida.curar_tudo()
	reaparecer()


func esta_golpeando() -> bool:
	return _ataque.esta_golpeando()


## Velocidade horizontal (px/s, já com o lado) do passo à frente do golpe; 0 fora dele.
func velocidade_do_passo() -> float:
	return _ataque.velocidade_do_passo() * direcao_olhar


func aplicar_gravidade(delta: float) -> void:
	var g := stats.gravidade() if velocity.y < 0.0 else stats.gravidade() * stats.multiplicador_queda
	velocity.y = minf(velocity.y + g * delta, stats.velocidade_max_queda)


## Pula se o botão foi apertado há pouco (buffer) e ainda está no chão ou no coyote time.
func tentar_pular() -> bool:
	if _contador_buffer <= 0.0 or _contador_coyote <= 0.0:
		return false
	velocity.y = -stats.forca_pulo()
	_contador_buffer = 0.0
	_contador_coyote = 0.0
	pulou.emit()
	return true


## Pulo de altura variável: soltou o botão subindo -> corta a subida.
func cortar_pulo_se_soltou() -> void:
	if Input.is_action_just_released("pular") and velocity.y < 0.0:
		velocity.y *= stats.corte_pulo


## Acelera até `dir * maxima` (px/s). Com `virar`, o herói olha para o lado do movimento.
func mover_horizontal(dir: float, maxima: float, delta: float, virar: bool = true) -> void:
	velocity.x = move_toward(velocity.x, dir * maxima, _taxa_aceleracao(dir) * delta)
	if virar and dir != 0.0:
		direcao_olhar = 1 if dir > 0.0 else -1


# --- Interno --------------------------------------------------------------------

func _atualizar_contadores(delta: float) -> void:
	# Coyote time: um tempinho de "graça" depois de sair da beirada.
	_contador_coyote = stats.tempo_coyote if is_on_floor() else _contador_coyote - delta
	# Buffer: guarda o aperto do botão de pulo por um instante.
	_contador_buffer = stats.tempo_buffer if Input.is_action_just_pressed("pular") else _contador_buffer - delta
	# Ritmo de ataque (iniciativa) e buffer do botão de atacar.
	_tempo_desde_golpe += delta
	if Input.is_action_just_pressed("atacar"):
		_contador_buffer_ataque = stats.tempo_buffer_ataque
		if nome_estado() == &"Atacando" and not _golpe_extra:
			_combo_pedido = true
	else:
		_contador_buffer_ataque -= delta
	if Input.is_action_just_pressed("arremessar"):
		_contador_buffer_arremesso = stats.tempo_buffer_ataque
	else:
		_contador_buffer_arremesso -= delta
	# Toque duplo para correr.
	_toque_duplo.janela = stats.janela_toque_duplo
	var apertada := _direcao_apertada_agora()
	_pedido_corrida = apertada if _toque_duplo.registrar(apertada, delta) else 0


func _direcao_apertada_agora() -> int:
	if Input.is_action_just_pressed("mover_direita"):
		return 1
	if Input.is_action_just_pressed("mover_esquerda"):
		return -1
	return 0


func _taxa_aceleracao(dir: float) -> float:
	if not is_on_floor():
		return stats.aceleracao_no_ar
	return stats.aceleracao if dir != 0.0 else stats.desaceleracao


func _checar_aterrissagem() -> void:
	if is_on_floor() and not _estava_no_chao:
		aterrissou.emit()
	_estava_no_chao = is_on_floor()


# --- Levar dano -----------------------------------------------------------------

func _ao_resolver_golpe(resultado: Combate.Resultado, origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado, TextoFlutuanteComponent.COR_DANO_SOFRIDO)
	if not resultado.acertou:
		return
	if resultado.golpe.corroi_armadura:
		_corroer_armadura()
	origem_ultimo_golpe = origem
	_ataque.cancelar()
	_contador_invencivel = stats.tempo_invencibilidade
	_defesa.invulneravel = true
	_maquina.trocar(&"LevandoDano")


func _atualizar_invencibilidade(delta: float) -> void:
	if _contador_invencivel <= 0.0:
		return
	_contador_invencivel -= delta
	if _contador_invencivel <= 0.0:
		_defesa.invulneravel = false
	_animacao.piscando = esta_invencivel()


## Vida zerou: avisa quem monta o jogo. Sem ninguém escutando, revive sozinho.
func _morrer() -> void:
	_defesa.invulneravel = true
	if caiu.get_connections().is_empty():
		reviver()
	else:
		caiu.emit()


## Equipamento mudou (vestiu, tirou, quebrou): recalcula a CA e troca o visual.
func _atualizar_equipamento() -> void:
	if ficha == null:
		return
	_defesa.classe_armadura = classe_armadura()
	_animacao.vestir(armadura_atual())
	_escudo.equipar(escudo_atual())


## Pseudópode do Gray Ooze: a armadura não mágica perde 1 de CA; é destruída quando a CA
## que ela oferece chega a 10.
func _corroer_armadura() -> void:
	var armadura := armadura_atual()
	if armadura == null or not armadura.corroivel:
		return
	var limite := armadura.ca_base - Ficha.CA_BASE
	if inventario.desgastar(armadura, 1, limite):
		_texto.mostrar("%s se desfez!" % armadura.nome, TextoFlutuanteComponent.COR_DANO_SOFRIDO)
	else:
		_texto.mostrar("%s corroída -%d" % [armadura.nome, inventario.penalidade(armadura)], TextoFlutuanteComponent.COR_ERRO)


## Forma Corrosiva (ex.: Gray Ooze): a arma não mágica que causou dano perde precisão
## e é destruída no limite.
func _comecar_golpe(extra: bool) -> void:
	if not extra:
		_tempo_desde_golpe = 0.0
	_contador_buffer_ataque = 0.0
	_combo_pedido = false
	_golpe_extra = extra
	var arma := arma_secundaria() if extra else arma_atual()
	_ataque.golpear(arma, _criar_golpe_de(arma, extra), extra)


func _criar_golpe_de(arma: Arma, extra: bool) -> Golpe:
	var golpe := Equipamento.golpe(ficha, inventario, arma, extra)
	if inventario.esta_equipado(arma):
		golpe.arma_corroida.connect(_ao_corroer_arma.bind(arma))
	return golpe


func _arma_arremessavel() -> Arma:
	var arma := inventario.equipado(Item.ESPACO_MAO) as Arma
	if arma and arma.arremessavel():
		return arma
	return null


func _ao_corroer_arma(penalidade: int, limite: int, arma: Arma) -> void:
	if inventario.desgastar(arma, penalidade, limite):
		_texto.mostrar("%s derreteu!" % arma.nome, TextoFlutuanteComponent.COR_DANO_SOFRIDO)
	else:
		_texto.mostrar("%s corroída -%d" % [arma.nome, inventario.penalidade(arma)], TextoFlutuanteComponent.COR_ERRO)
