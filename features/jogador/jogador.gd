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
## Emitido quando os usos do Second Wind mudam (restantes e o total da classe).
signal folego_mudou(restantes: int, total: int)
## Emitido quando a vida chega a zero. Quem monta o jogo decide (ex.: tela "Você caiu!" e
## depois reviver()). Se ninguém escutar (cena aberta sozinha), o herói revive sozinho.
signal caiu
## Emitido ao arremessar ou disparar. Quem monta o jogo cria o projétil.
## `municao` preenchida = disparo: a arma fica na mão e essa munição é o que voa.
## Sem ninguém escutando (cena aberta sozinha), nada é gasto.
signal arma_arremessada(arma: Arma, golpe: Golpe, penalidade: int, origem: Vector2, direcao: int, forca: float, mira: float, municao: Municao, ignora_alcance_longo: bool, destreza: int)

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
## Tempo desde que a ação bônus foi gasta (golpe extra sem Corte Duplo, ou Second Wind).
var _tempo_desde_acao_bonus: float = INF
## Usos de Second Wind que ainda restam nesta luta.
var _usos_folego: int = 0
var _rng_folego := RandomNumberGenerator.new()
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
	_animacao.mao_por_cima = not _ataque.mao_fora_do_lugar()
	_animacao.mirando = nome_estado() == &"Arremessando" and disparo_na_mao()
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
	_repor_folego()


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


## Apertou atacar há pouco (buffer) e já pode golpear. Arma à distância não corta: o tiro é o K.
func pediu_ataque() -> bool:
	var na_mao := inventario.equipado(Item.ESPACO_MAO) as Arma
	if na_mao and na_mao.disparavel():
		return false
	return _contador_buffer_ataque > 0.0 and pode_golpear()


## Apertou arremessar há pouco, já pode agir e a arma da mão arremessa ou dispara.
## Sem munição, avisa e não entra na pose.
func pediu_arremesso() -> bool:
	if _contador_buffer_arremesso <= 0.0 or not pode_golpear():
		return false
	var arma := _arma_do_k()
	if arma == null:
		return false
	if arma.disparavel() and not _tem_municao(arma):
		avisar(AVISO_SEM_MUNICAO)
		_contador_buffer_arremesso = 0.0
		return false
	return true


## Segundo K logo depois do tiro da Besta de Mão, com o talento: gasta a ação bônus e outro virote.
func quer_disparo_extra() -> bool:
	if _contador_buffer_arremesso <= 0.0 or ficha == null or not acao_bonus_livre():
		return false
	var arma := _arma_do_k()
	var de_mao := arma != null and arma.besta and arma.leve and arma.disparavel()
	return de_mao and ficha.tem_talento(Ficha.TALENTO_ESPECIALISTA_EM_BESTA) and _tem_municao(arma)


## Arma na mão, ou o ataque desarmado se a mão estiver vazia.
func arma_atual() -> Arma:
	return Equipamento.arma(inventario, ataque_desarmado)


## Arma leve na outra mão, ou null.
func arma_secundaria() -> Arma:
	return Equipamento.arma_secundaria(inventario)


## O 2º J durante o golpe pede o ataque extra, e as duas armas são leves.
## Sem Corte Duplo, o extra é a ação bônus: no máximo 1 por rodada.
func quer_golpe_extra() -> bool:
	if not _combo_pedido or _golpe_extra:
		return false
	var principal := inventario.equipado(Item.ESPACO_MAO) as Arma
	var segunda := arma_secundaria()
	if principal == null or principal.disparavel() or segunda == null or segunda.disparavel():
		return false
	var leves := principal.leve and segunda.leve
	return leves and (_tem_corte_duplo() or acao_bonus_livre())


## A ação bônus da rodada já voltou (o golpe extra sem Corte Duplo e o Second Wind a gastam).
func acao_bonus_livre() -> bool:
	return _tempo_desde_acao_bonus >= EscalaDnd.RODADA_SEGUNDOS


## Usos de Second Wind que ainda restam nesta luta.
func usos_folego() -> int:
	return _usos_folego


## Usos de Second Wind da classe (0 = ela não tem o poder).
func usos_folego_total() -> int:
	if classe == null:
		return 0
	return classe.usos_segundo_folego


## Second Wind: ação bônus, cura 1d10+nível, gasta um uso mesmo com a vida cheia.
## Devolve false se não havia uso, se a ação bônus já foi gasta ou se a classe não tem o poder.
func usar_folego() -> bool:
	if not _pode_usar_folego():
		return false
	_usos_folego -= 1
	_tempo_desde_acao_bonus = 0.0
	var ganho := _vida.curar(classe.cura_do_folego(_rng_folego))
	_texto.mostrar("Fôlego +%d" % ganho, TextoFlutuanteComponent.COR_CURA)
	_avisar_folego()
	return true


func _pode_usar_folego() -> bool:
	if classe == null or classe.usos_segundo_folego <= 0 or _vida.esta_morto():
		return false
	if _usos_folego <= 0:
		avisar("Sem fôlego")
		return false
	if not acao_bonus_livre():
		avisar("Ação bônus")
		return false
	return true


func _repor_folego() -> void:
	_usos_folego = usos_folego_total()
	_avisar_folego()


func _avisar_folego() -> void:
	folego_mudou.emit(_usos_folego, usos_folego_total())


## Começa um golpe com a arma atual, para o lado em que o herói olha.
## Quem for atingido rola o ataque (d20 + bônus da ficha) contra a própria CA.
func iniciar_golpe() -> void:
	_comecar_golpe(false)


## 2º golpe do combo: a arma da outra mão, sem esperar a iniciativa de novo.
func iniciar_golpe_extra() -> void:
	_comecar_golpe(true)


## K ainda está apertado (carregando o arremesso)?
func segurando_arremesso() -> bool:
	return Input.is_action_pressed("arremessar")


## Pose de carregar. No arremesso, `fracao` de 0 a 1 inclina a arma. No disparo, é a força
## (pode parar antes de 1) e escolhe o quadro. `soltando` mostra a soltura. -1 sai da pose.
func carregar_arremesso(fracao: float, mira: float = 0.0, soltando: bool = false, progresso: float = 0.0) -> void:
	_ataque.carregar_arremesso(fracao, mira, soltando, progresso)


## Teto da força (0 a 1). No disparo, a Destreza limita; no arremesso, chega em 1.
func teto_da_carga() -> float:
	if not disparo_na_mao():
		return 1.0
	return ficha.teto_da_carga()


## Segundos para chegar nesse teto. No disparo encolhe com Destreza alta.
func tempo_ate_teto() -> float:
	if not disparo_na_mao():
		return Ficha.TEMPO_CARGA_DISPARO
	return ficha.tempo_ate_teto_da_carga()


## A arma da mão principal é de disparo (os quadros e a Destreza valem).
func disparo_na_mao() -> bool:
	var arma := inventario.equipado(Item.ESPACO_MAO) as Arma
	return arma != null and arma.disparavel() and ficha != null


## Enquanto carrega o K, W mira e não vira pulo.
func anular_buffer_pulo() -> void:
	_contador_buffer = 0.0


## Solta o K. Arremesso: a arma sai da mão. Disparo: a arma fica e gasta 1 munição.
## `forca` de 0 (alcance normal) a 1 (alcance longo). `mira` soma graus para cima no arco.
## `extra` = o segundo tiro da Besta de Mão (ação bônus).
## Sem ninguém escutando o sinal, nada é gasto.
func lancar_arma(forca: float = 0.0, mira: float = 0.0, extra: bool = false) -> void:
	var arma := _arma_do_k()
	if arma == null or arma_arremessada.get_connections().is_empty():
		return
	if arma.disparavel():
		_disparar(arma, forca, mira, extra)
		return
	_arremessar(arma, forca, mira)


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
	_tempo_desde_acao_bonus = INF
	_vida.curar_tudo()
	_repor_folego()
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
	_tempo_desde_acao_bonus += delta
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
	if Input.is_action_just_pressed("folego"):
		usar_folego()
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


## Começa o golpe da arma da mão (ou o extra, da outra mão). O extra sem Corte Duplo gasta
## a ação bônus: o próximo só depois de 1 rodada.
func _comecar_golpe(extra: bool) -> void:
	if not extra:
		_tempo_desde_golpe = 0.0
	elif not _tem_corte_duplo():
		_tempo_desde_acao_bonus = 0.0
	_contador_buffer_ataque = 0.0
	_combo_pedido = false
	_golpe_extra = extra
	var arma := arma_secundaria() if extra else arma_atual()
	_ataque.golpear(arma, _criar_golpe_de(arma, extra), extra, arma_atual() if extra else null)


func _criar_golpe_de(arma: Arma, extra: bool) -> Golpe:
	var golpe := Equipamento.golpe(ficha, inventario, arma, extra)
	_assinar(golpe)
	if inventario.esta_equipado(arma):
		golpe.arma_corroida.connect(_ao_corroer_arma.bind(arma))
	return golpe


## Marca o herói como autor do golpe (e do 2º ataque do Trespassar): Atormentar dá vantagem
## só a quem marcou o alvo.
func _assinar(golpe: Golpe) -> void:
	golpe.autor_id = get_instance_id()
	if golpe.trespassar:
		golpe.trespassar.autor_id = golpe.autor_id


## Corte Duplo (maestria) numa das armas leves: o golpe extra faz parte da ação de Ataque,
## sem gastar a ação bônus (sai em todo combo).
func _tem_corte_duplo() -> bool:
	var principal := inventario.equipado(Item.ESPACO_MAO) as Arma
	var segunda := arma_secundaria()
	var na_principal := principal != null and ficha.maestria_de(principal) == Proficiencias.CORTE_DUPLO
	var na_segunda := segunda != null and ficha.maestria_de(segunda) == Proficiencias.CORTE_DUPLO
	return na_principal or na_segunda


## Inimigo a até 5 pés: o tiro à distância sai com desvantagem (as bestas do talento, não).
const DISTANCIA_PERTO_TIRO_PES := 5.0
const GRUPO_INIMIGOS := &"monstros"
const AVISO_SEM_MUNICAO := "Sem munição"


func _arma_do_k() -> Arma:
	var arma := inventario.equipado(Item.ESPACO_MAO) as Arma
	if arma and (arma.arremessavel() or arma.disparavel()):
		return arma
	return null


func _arremessar(arma: Arma, forca: float, mira: float) -> void:
	var pen := inventario.penalidade(arma)
	var golpe := Equipamento.golpe(ficha, inventario, arma)
	_assinar(golpe)
	var extraida := inventario.extrair_uma(arma) as Arma
	_marcar_ataque(false, false)
	arma_arremessada.emit(extraida, golpe, pen, _ataque.global_position, direcao_olhar, forca, mira, null, false, _destreza())


func _disparar(arma: Arma, forca: float, mira: float, extra: bool) -> void:
	var pilha := _gastar_municao(arma)
	if pilha == null:
		avisar(AVISO_SEM_MUNICAO)
		_contador_buffer_arremesso = 0.0
		return
	var golpe := _criar_golpe_de(arma, false)
	if _inimigo_em_5_pes() and not _besta_ignora_perto(arma):
		golpe.desvantagem = true
	_marcar_ataque(extra, true)
	arma_arremessada.emit(arma, golpe, 0, _ataque.global_position, direcao_olhar, forca, mira, pilha,
		ficha.tem_talento(Ficha.TALENTO_ATIRADOR_DE_ELITE), _destreza())


func _marcar_ataque(extra: bool, manter_pose: bool) -> void:
	if extra:
		_tempo_desde_acao_bonus = 0.0
	else:
		_tempo_desde_golpe = 0.0
	_contador_buffer_arremesso = 0.0
	if not manter_pose:
		_ataque.carregar_arremesso(-1.0)


func _destreza() -> int:
	if ficha == null:
		return Ficha.DESTREZA_REFERENCIA
	return ficha.atributos[Atributos.DESTREZA]


func _gastar_municao(arma: Arma) -> Municao:
	var pilha := inventario.item_chamado(arma.municao) as Municao
	if pilha == null or inventario.extrair_uma(pilha) == null:
		return null
	return pilha


func _tem_municao(arma: Arma) -> bool:
	var pilha := inventario.item_chamado(arma.municao)
	return pilha != null and inventario.quantidade_de(pilha) > 0


func _inimigo_em_5_pes() -> bool:
	var limite := EscalaDnd.pes_para_pixels(DISTANCIA_PERTO_TIRO_PES)
	for n in get_tree().get_nodes_in_group(GRUPO_INIMIGOS):
		if n is Node2D and global_position.distance_to((n as Node2D).global_position) <= limite:
			return true
	return false


func _besta_ignora_perto(arma: Arma) -> bool:
	return arma.besta and ficha.tem_talento(Ficha.TALENTO_ESPECIALISTA_EM_BESTA)


## Forma Corrosiva (ex.: Gray Ooze): a arma não mágica que causou dano perde precisão
## e é destruída no limite.
func _ao_corroer_arma(penalidade: int, limite: int, arma: Arma) -> void:
	if inventario.desgastar(arma, penalidade, limite):
		_texto.mostrar("%s derreteu!" % arma.nome, TextoFlutuanteComponent.COR_DANO_SOFRIDO)
	else:
		_texto.mostrar("%s corroída -%d" % [arma.nome, inventario.penalidade(arma)], TextoFlutuanteComponent.COR_ERRO)
