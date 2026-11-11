class_name Jogador
extends CharacterBody2D
## Herói de ação lateral. Este script guarda as "ferramentas de física" (gravidade, pulo,
## movimento) e repassa o comportamento para a MaquinaEstados (estados em estados/).
## Visual e câmera são filhos: o Jogador chama funções deles (call down).

## Emitido no quadro em que o pulo começa.
signal pulou
## Emitido no quadro em que toca o chão depois de estar no ar.
signal aterrissou
## O herói começou um golpe (`extra` = o da outra mão): o som do golpe no ar vem daqui.
signal golpe_iniciado(arma: Arma, extra: bool)
## O herói começou a morrer (antes da animação de morte e da tela "Você caiu!").
signal comecou_a_morrer
## Emitido quando volta para o início (ex.: caiu num buraco).
signal reapareceu
## Emitido quando a vida muda (ex.: ao criar o personagem).
signal vida_mudou(atual: int, maxima: int)
## Emitido quando os usos do Second Wind mudam (restantes e o total da classe).
signal folego_mudou(restantes: int, total: int)
## Apertou o Surto de Ação: a main vê se ele está liberado nesta fase e chama armar_surto().
signal surto_acao_pedido
## Apertou a Mente Tática: a main liga ou desliga.
signal mente_tatica_pedido
## O Surto ficou ativo (aura ligada, o próximo ataque sai em dobro) ou acabou: a interface acende o botão.
signal surto_ativo_mudou(ativo: bool)
## Os pontos de sorte ou a sorte armada mudaram: a interface mostra e acende o botão.
signal sorte_mudou(pontos: int, total: int, armada: bool)
## A janela de defesa do Duelista Defensivo abriu, fechou ou voltou a ficar pronta (botão da barra).
signal defesa_mudou(ativa: bool, pronta: bool)
## A defesa do Duelista Defensivo fez um golpe errar: parry.
signal aparou
## O modo da Investida mudou: true = empurra, false = dano extra.
signal investida_mudou(empurra: bool)
## Os dados de vida (Durável) mudaram.
signal dados_de_vida_mudou(restantes: int, total: int)
## O veneno (Envenenador ou o item) mudou: doses que restam e se a arma está envenenada agora.
signal veneno_mudou(doses: int, total: int, aplicado: bool)
## Atualização de nível e XP para o HUD.
signal progressao_mudou(nivel: int, experiencia: int, proximo_nivel: int)
## O ouro do herói mudou (saque, loja).
signal ouro_mudou(ouro: int)
## Emitido quando a vida chega a zero. Quem monta o jogo decide (ex.: tela "Você caiu!" e
## depois reviver()). Se ninguém escutar (cena aberta sozinha), o herói revive sozinho.
signal caiu
## Emitido ao arremessar ou disparar. Quem monta o jogo cria o projétil.
## `municao` preenchida = disparo: a arma fica na mão e essa munição é o que voa.
## Sem ninguém escutando (cena aberta sozinha), nada é gasto.
signal arma_arremessada(arma: Arma, golpe: Golpe, penalidade: int, origem: Vector2, direcao: int, forca: float, mira: float, municao: Municao, ignora_alcance_longo: bool, destreza: int)

## Cores e tamanhos dos efeitos do Surto de Ação (dourado) e do Fôlego (verde).
const COR_SURTO := Color(1.0, 0.82, 0.3)
const COR_FOLEGO_AURA := Color(0.45, 1.0, 0.6)
const FAISCAS_ATIVAR_SURTO := 18
const FAISCAS_SEGUNDO_GOLPE := 22
const FAISCAS_FOLEGO := 14
const TEMPO_ANEL_FOLEGO := 0.7
## Golpe de corte com o corpo animado (features/jogador/sprites/heroi_corte.png): 8 quadros; os 5 primeiros
## preparam (os punhos sobem acima da cabeça) e o 6º (índice 5) é quando os punhos descem à frente.
## Tempo (s) da animação de morte antes da tela "Você caiu!" (12 quadros a 10 por segundo, e um respiro deitado).
const DURACAO_MORTE := 1.4
## Quanto o herói desliza para o lado ao cair (px/s por segundo): ele freia e fica deitado onde caiu.
const FREIO_DA_MORTE := 900.0
const ANIMACAO_CORTE := &"corte"
## Com duas armas, a da frente descansa erguida (graus; negativo = ponta para cima), como a de trás.
const ANGULO_GUARDA_DUPLA := -25.0
const QUADROS_CORTE := 8
const QUADRO_DO_ACERTO_CORTE := 5
## Golpe extra das duas armas: o corpo (`corte_duplo`, 8 quadros) estica o braço até o quadro 3 e volta à guarda.
const ANIMACAO_CORTE_DUPLO := &"corte_duplo"
const QUADRO_DO_ACERTO_CORTE_DUPLO := 3
## O anel da ativação do Surto de Ação dura meio segundo.
const DURACAO_ANEL_SURTO := 0.5
const TEMPO_BRILHO_SURTO := 0.5

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
var _rng_habilidades := RandomNumberGenerator.new()
var _mente_tatica_ligada: bool = false
## Segundos que faltam da Mudança Tática (bônus de deslocamento depois do Fôlego).
var _tempo_mudanca_tatica: float = 0.0
## Pixels de deslocamento livre após crítico (Atleta Notável do Campeão).
var _orcamento_atleta_px: float = 0.0
## Surto de Ação armado: o próximo ataque ganha um segundo golpe logo atrás do primeiro.
var _surto_armado: bool = false
## Golpes da mesma ação de Atacar que ainda vão sair logo atrás do atual (Ataque Extra, Surto de Ação, Mestre em Arma Grande).
var _golpes_encadeados: int = 0
## O Surto de Ação já abriu a ação de Atacar e a aura segue acesa até o último golpe.
var _surto_em_curso: bool = false
## O herói está morrendo (animação de morte): não responde a nada até reviver().
var _morrendo: bool = false
## Estado dos talentos (regras puras em features/jogador/talentos/): o herói só liga com a tela e o corpo.
var _recargas := RecargasPorRodada.new()
## O próximo golpe de escudo derruba (senão empurra); alterna a cada uso.
var _escudo_derruba_agora: bool = false
## O golpe que está sendo resolvido derruba o herói (a Defesa avisa antes do resultado).
var _derrubado_pendente: bool = false
var _sorte := SorteDoHeroi.new()
var _dados_de_vida := DadosDeVidaDoHeroi.new()
var _veneno := VenenoDoHeroi.new()
var _agarrao := AgarraoDoHeroi.new()
var _rng_agarrao := RandomNumberGenerator.new()
var _janela_defesa := JanelaDeDefesa.new()
var _investida := InvestidaDoHeroi.new()
## O "cabo" da haste (Mestre em Armas de Haste): o soco feito com a outra ponta, montado uma vez.
var _cabo_da_haste_arma: Arma
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
@onready var _aura: AuraComponent = $Aura


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
	MontagemDeCriatura.configurar_colisao_chao(self)
	_toque_duplo = ToqueDuplo.new(stats.janela_toque_duplo)
	aterrissou.connect(_animacao.tocar_aterrissagem)
	_vida.vida_mudou.connect(vida_mudou.emit)
	_vida.morreu.connect(_morrer, CONNECT_DEFERRED)  # depois que o golpe terminar de ser tratado
	_defesa.golpe_resolvido.connect(_ao_resolver_golpe)
	_defesa.aparou.connect(_ao_aparar)
	_defesa.agarrado.connect(_ao_ser_agarrado)
	_defesa.derrubado.connect(_ao_ser_derrubado)
	inventario.mudou.connect(_atualizar_equipamento)
	configurar_ficha(Ficha.new(classe, classe.atributos_sugeridos))
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	if _morrendo:
		_processar_morte(delta)
		return
	_atualizar_contadores(delta)
	_atualizar_invencibilidade(delta)
	_passar_recargas_de_talento(delta)
	_passar_defesa(delta)
	_passar_veneno(delta)
	_passar_agarrao(delta)
	_maquina.processar_fisica(delta)
	_prender_se_agarrado()
	var x_antes := global_position.x
	move_and_slide()
	_consumir_orcamento_atleta(absf(global_position.x - x_antes))
	_checar_aterrissagem()
	_medir_corrida(delta)
	_animacao.mao_por_cima = not _ataque.mao_fora_do_lugar()
	_animacao.mirando = nome_estado() == &"Arremessando" and disparo_na_mao()
	var corte := ANIMACAO_CORTE_DUPLO if _ataque.golpe_cruzado() else ANIMACAO_CORTE
	_animacao.animacao_do_golpe = corte if _ataque.corpo_acompanha() else &""
	if _ataque.corpo_acompanha():
		var acerto := QUADRO_DO_ACERTO_CORTE_DUPLO if _ataque.golpe_cruzado() else QUADRO_DO_ACERTO_CORTE
		_animacao.quadro_do_golpe = _ataque.quadro_do_corpo(QUADROS_CORTE, acerto)
	_animacao.atualizar(_maquina.nome_estado_atual(), velocity, direcao_olhar, velocidade_andar(), velocidade_corrida())
	var angulo_guarda := ANGULO_GUARDA_DUPLA if arma_secundaria() != null else _animacao.angulo_descanso()
	_ataque.seguir_mao(_animacao.ponto_da_mao(), angulo_guarda, direcao_olhar, arma_atual())
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
	_repor_sorte()
	_repor_dados_e_veneno()
	progressao_mudou.emit(ficha.nivel, ficha.experiencia, ficha.xp_proximo_nivel())
	ouro_mudou.emit(ficha.ouro)


## A ficha mudou depois de pronta (talento ou aumento de atributo): recalcula vida, CA e HUD.
func ao_mudar_ficha() -> void:
	if ficha == null:
		return
	_vida.aumentar_maximo(ficha.vida_maxima())
	_atualizar_salvaguardas()
	_atualizar_equipamento()
	_repor_dados_e_veneno()
	progressao_mudou.emit(ficha.nivel, ficha.experiencia, ficha.xp_proximo_nivel())


## Troca a mochila pelo pacote escolhido na criação (cópias próprias: cada uma com seu
## desgaste) e equipa o que o pacote manda. null = mantém a mochila como está.
func receber_pacote(pacote: PacoteInicial) -> void:
	if pacote == null:
		return
	inventario.em_silencio(func() -> void:
		inventario.limpar()
		for item in pacote.itens:
			var meu := item.duplicate() as Item
			inventario.adicionar(meu, pacote.itens[item])
			if item in pacote.equipar:
				inventario.equipar(meu)
	)


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


## Treme a câmera (um golpe pesado, um chefe saindo da terra).
func tremer_camera(forca: float, duracao: float) -> void:
	_camera.tremer(forca, duracao)


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


## Atleta: dá para escalar agora? Tem o talento, empurra o analógico ou a seta para uma parede e encosta nela.
func pode_escalar() -> bool:
	if ficha == null or not ficha.tem_talento(Ficha.TALENTO_ATLETA) or not is_on_wall():
		return false
	var dir := direcao()
	return dir != 0.0 and get_wall_normal().x * dir < 0.0


## Direção do pedido de corrida neste quadro (-1 ou 1), ou 0: toque duplo ou "correr" segurado.
func pediu_corrida() -> int:
	return _pedido_corrida


## "correr" segurado (Shift no teclado; no celular, o analógico empurrado até a borda).
func correr_segurado() -> bool:
	return Input.is_action_pressed("correr")


## Velocidade andando (px/s): o deslocamento de D&D da ficha (30 pés -> ~128 px/s).
## Armadura que pede mais Força do que o herói tem tira 10 pés.
func velocidade_andar() -> float:
	var pes := Equipamento.deslocamento_pes(ficha, inventario)
	if _tempo_mudanca_tatica > 0.0:
		pes += MUDANCA_TATICA_PES
	return EscalaDnd.deslocamento_para_velocidade(pes)


## Correndo = Disparada (Dash) do D&D: o dobro do deslocamento.
func velocidade_corrida() -> float:
	var extra := 0.0
	if ficha != null and ficha.tem_talento(Ficha.TALENTO_INVESTIDA):  # Disparada Aprimorada: +10 pés na corrida
		extra = EscalaDnd.deslocamento_para_velocidade(DISPARADA_APRIMORADA_PES)
	return velocidade_andar() * EscalaDnd.MULTIPLICADOR_DISPARADA + extra


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
	if _extra_com_cabo():  # Mestre em Armas de Haste: a outra ponta da haste
		return acao_bonus_livre()
	var principal := inventario.equipado(Item.ESPACO_MAO) as Arma
	var segunda := arma_secundaria()
	if principal == null or principal.disparavel() or segunda == null or segunda.disparavel():
		return false
	var leves := principal.leve and (segunda.leve or ficha.tem_talento(Ficha.TALENTO_EMPUNHADURA_DUPLA))
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


## Atribui XP da cota. PV atuais sobem junto com o máximo ao ganhar nível; sobe = descanso longo.
func ganhar_experiencia(quantidade: int) -> int:
	if ficha == null:
		return 0
	var nivel_anterior := ficha.nivel
	var novos_niveis := ficha.adicionar_experiencia(quantidade)
	if novos_niveis > 0:
		_vida.aumentar_maximo(ficha.vida_maxima())
		_texto.mostrar("Nível %d!" % ficha.nivel, TextoFlutuanteComponent.COR_CURA)
		_dados_de_vida.ao_subir_de_nivel(ficha, novos_niveis)  # cada nível traz mais um dado de vida
		dados_de_vida_mudou.emit(_dados_de_vida.restantes, ficha.dados_de_vida())
		descansar_longo()
	progressao_mudou.emit(ficha.nivel, ficha.experiencia, ficha.xp_proximo_nivel())
	return ficha.nivel - nivel_anterior


## Soma o ouro do saque e avisa a tela.
func ganhar_ouro(quantidade: int) -> void:
	if ficha == null or quantidade <= 0:
		return
	ficha.ouro += quantidade
	_texto.mostrar("+%d po" % quantidade, COR_SURTO)
	ouro_mudou.emit(ficha.ouro)


## Põe na mochila a arma do saque; se não couber, avisa e a arma se perde.
func receber_saque(arma: Item) -> void:
	if arma == null:
		return
	var coube := inventario.adicionar(arma)
	_texto.mostrar(arma.nome if coube else "Mochila cheia", COR_SURTO if coube else TextoFlutuanteComponent.COR_ERRO)


## Mente Tática só é ativa a partir do nível 2.
func definir_mente_tatica(ligada: bool) -> void:
	_mente_tatica_ligada = ligada and ficha != null and ficha.nivel >= Ficha.NIVEL_HABILIDADES_GUERREIRO


func mente_tatica_ligada() -> bool:
	return _mente_tatica_ligada


## Surto de Ação: arma a aura. O próximo ataque sai em dobro (dois golpes seguidos, cada um com a
## sua rolagem). Devolve false se já estava ativo ou se o herói caiu.
func armar_surto() -> bool:
	if surto_ativo() or ficha == null or _vida.esta_morto():
		return false
	_surto_armado = true
	_aura.ligar(COR_SURTO)
	_aura.pulso(COR_SURTO, FAISCAS_ATIVAR_SURTO, DURACAO_ANEL_SURTO)
	_animacao.brilhar(COR_SURTO, TEMPO_BRILHO_SURTO)
	_texto.mostrar("Surto de Ação!", COR_SURTO)
	surto_ativo_mudou.emit(true)
	return true


## A aura do Surto está ligada (armado, ou o segundo golpe ainda vai sair).
func surto_ativo() -> bool:
	return _surto_armado or _surto_em_curso


## Ainda há golpe da mesma ação de Atacar a sair (Ataque Extra, Surto de Ação): o estado Atacando chama já.
func quer_golpe_do_surto() -> bool:
	return _golpes_encadeados > 0 and not esta_golpeando()


## O próximo golpe encadeado: a mesma arma, na hora, com rolagem nova. Com o Surto em curso, o último
## golpe gasta o Surto e apaga a aura.
func iniciar_golpe_do_surto() -> void:
	_golpes_encadeados -= 1
	if _surto_em_curso:
		_aura.pulso(COR_SURTO, FAISCAS_SEGUNDO_GOLPE, DURACAO_ANEL_SURTO)
		_animacao.brilhar(COR_SURTO, TEMPO_BRILHO_SURTO)
	_comecar_golpe(false, true)
	if _golpes_encadeados <= 0:
		_encerrar_surto_em_curso()


## O ataque foi interrompido (levou dano, por exemplo): os golpes que faltavam se perdem e a aura apaga.
func cancelar_golpe_do_surto() -> void:
	if _golpes_encadeados <= 0:
		return
	_golpes_encadeados = 0
	_encerrar_surto_em_curso()


func _encerrar_surto_em_curso() -> void:
	if not _surto_em_curso:
		return
	_surto_em_curso = false
	_aura.desligar()
	surto_ativo_mudou.emit(false)


## Apaga o Surto sem usar (nova fase, o herói caiu).
func _apagar_surto() -> void:
	var estava_ativo := surto_ativo()
	_surto_armado = false
	_surto_em_curso = false
	_golpes_encadeados = 0
	_aura.desligar()
	if estava_ativo:
		surto_ativo_mudou.emit(false)

## Rola um teste de perícia e aplica Mente Tática automaticamente se estiver ligada.
## Campeão: Atletismo com vantagem (Atleta Notável).
func rolar_teste_pericia(pericia: StringName, cd: int,
		rng: RandomNumberGenerator = null) -> Dictionary:
	if ficha == null or Pericia.atributo_de(pericia) == &"":
		return {}
	var fonte := _rng_habilidades if rng == null else rng
	var pode_usar_mente := _mente_tatica_ligada and ficha.nivel >= Ficha.NIVEL_HABILIDADES_GUERREIRO
	var vantagem := ficha.vantagem_na_pericia(pericia)
	var resultado := Pericia.resolver_teste(ficha.bonus_pericia(pericia), cd, pode_usar_mente,
		pode_usar_mente and _usos_folego > 0, fonte, vantagem)
	if not resultado.passou and _gastar_sorte():  # Sortudo: um d20 novo, fica o melhor
		var segundo := Pericia.resolver_teste(ficha.bonus_pericia(pericia), cd, false, false, fonte, vantagem)
		if segundo.total > resultado.total:
			resultado = segundo
	if resultado.usou_mente_tatica:
		_usos_folego -= 1
		_avisar_folego()
		_texto.mostrar("Mente Tática +%d" % resultado.d10, TextoFlutuanteComponent.COR_CURA)
	return resultado


## Artesão: a cada fase nova cai um item aleatório do arsenal na mochila. Mochila cheia = não entra.
func ganhar_item_do_artesao() -> void:
	if ficha == null or not ficha.tem_talento(Ficha.TALENTO_ARTESAO):
		return
	var item := ItemAleatorio.sortear(_rng_habilidades)
	if item == null:
		return
	if inventario.adicionar(item):
		avisar("Artesão: %s" % item.nome)
	else:
		avisar("Mochila cheia")


## Descanso curto (sair de fase sem chefe): Fôlego, Sorte e ação bônus. Não enche PV nem tira drenar.
func descansar_curto() -> void:
	_apagar_surto()
	_tempo_desde_acao_bonus = INF
	_repor_folego()
	_repor_sorte()


## Descanso longo (sair de chefe, morrer ou começar/continuar): vida cheia, máximo, Fôlego, dados e veneno.
func descansar_longo() -> void:
	_apagar_surto()
	_tempo_desde_acao_bonus = INF
	_vida.restaurar_maximo()
	_vida.curar_tudo()
	_repor_folego()
	_repor_sorte()
	_repor_dados_e_veneno()


## Second Wind: ação bônus, cura 1d10+nível, gasta um uso mesmo com a vida cheia.
## Devolve false se não havia uso, se a ação bônus já foi gasta ou se a classe não tem o poder.
func usar_folego() -> bool:
	if not _pode_usar_folego():
		return false
	_usos_folego -= 1
	_tempo_desde_acao_bonus = 0.0
	var ganho := _vida.curar(classe.cura_do_folego(_rng_folego, ficha.nivel))
	_animacao.pulso_cura()
	_aura.pulso(COR_FOLEGO_AURA, FAISCAS_FOLEGO, TEMPO_ANEL_FOLEGO, true)
	_texto.mostrar_cura("Fôlego +%d" % ganho)
	_iniciar_mudanca_tatica()
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


## Pontos de sorte do Sortudo: a proficiência. Zero sem o talento.
func pontos_sorte_total() -> int:
	return SorteDoHeroi.total(ficha)


func pontos_sorte() -> int:
	return _sorte.pontos


func sorte_armada() -> bool:
	return _sorte.armada


## Arma a sorte: a próxima rolagem do herói (ataque ou teste) rola um d20 a mais e fica com o melhor.
## false se não tem o talento, não tem ponto, já está armada ou o herói caiu.
func armar_sorte() -> bool:
	if not _sorte.armar(ficha, not _vida.esta_morto()):
		return false
	_avisar_sorte()
	_texto.mostrar("Sorte!", TextoFlutuanteComponent.COR_CURA)
	return true


## Se a sorte está armada, gasta o ponto e diz que a rolagem vai usá-la.
func _gastar_sorte() -> bool:
	if not _sorte.gastar():
		return false
	_avisar_sorte()
	return true


func _repor_sorte() -> void:
	_sorte.repor(ficha)
	_avisar_sorte()


func _avisar_sorte() -> void:
	sorte_mudou.emit(_sorte.pontos, pontos_sorte_total(), _sorte.armada)


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
## Contrato: a `main` conecta `arma_arremessada` em `_ready`. Testes headless sem main não arremessam.
func lancar_arma(forca: float = 0.0, mira: float = 0.0, extra: bool = false) -> void:
	var arma := _arma_do_k()
	if arma == null or not arma_arremessada.has_connections():
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


## Volta para o início com descanso longo (ex.: "Tentar de novo" depois de cair).
func reviver() -> void:
	_agarrao.soltar()
	_cancelar_defesa()
	_morrendo = false
	_animacao.morrendo = false
	_mostrar_equipamento(true)
	_contador_invencivel = 0.0
	_defesa.invulneravel = false
	_animacao.piscando = false
	descansar_longo()
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


## Agarrado (Ankheg): o corpo fica onde está até escapar.
func esta_agarrado() -> bool:
	return _agarrao.esta_agarrado()


func _atualizar_contadores(delta: float) -> void:
	# Coyote time: um tempinho de "graça" depois de sair da beirada.
	_contador_coyote = stats.tempo_coyote if is_on_floor() else _contador_coyote - delta
	# Buffer: guarda o aperto do botão de pulo por um instante.
	_contador_buffer = stats.tempo_buffer if Input.is_action_just_pressed("pular") else _contador_buffer - delta
	# Ritmo de ataque (iniciativa) e buffer do botão de atacar.
	_tempo_desde_golpe += delta
	_tempo_desde_acao_bonus += delta
	_tempo_mudanca_tatica = maxf(_tempo_mudanca_tatica - delta, 0.0)
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
	if Input.is_action_just_pressed("surto_acao"):
		surto_acao_pedido.emit()
	if Input.is_action_just_pressed("mente_tatica"):
		mente_tatica_pedido.emit()
	if Input.is_action_just_pressed("sorte"):
		armar_sorte()
	if Input.is_action_just_pressed("defesa"):
		defender()
	if Input.is_action_just_pressed("dado_de_vida"):
		gastar_dado_de_vida()
	if Input.is_action_just_pressed("veneno"):
		aplicar_veneno()
	if Input.is_action_just_pressed("investida"):
		alternar_investida()
	# Toque duplo para correr, ou segurar "correr" (Shift; o analógico na borda).
	_toque_duplo.janela = stats.janela_toque_duplo
	var apertada := _direcao_apertada_agora()
	_pedido_corrida = apertada if _toque_duplo.registrar(apertada, delta) else 0
	if _pedido_corrida == 0 and correr_segurado() and direcao() != 0.0:
		_pedido_corrida = int(signf(direcao()))


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
	_maquina.trocar(&"Caido" if _derrubado_pendente else &"LevandoDano")
	_derrubado_pendente = false


func _atualizar_invencibilidade(delta: float) -> void:
	if _contador_invencivel <= 0.0:
		return
	_contador_invencivel -= delta
	if _contador_invencivel <= 0.0:
		_defesa.invulneravel = false
	_animacao.piscando = esta_invencivel()


## Vida zerou: avisa quem monta o jogo. Sem ninguém escutando, revive sozinho.
func _morrer() -> void:
	_agarrao.soltar()
	_defesa.invulneravel = true
	comecou_a_morrer.emit()
	_apagar_surto()
	_cancelar_defesa()
	_ataque.cancelar()
	_morrendo = true
	_animacao.morrendo = true
	_mostrar_equipamento(false)
	await get_tree().create_timer(DURACAO_MORTE, false).timeout
	if not _morrendo:
		return  # reviveu antes do fim da animação
	# Contrato: a `main` conecta `caiu` (tela de derrota). Sem ouvinte (teste), revive no lugar.
	if caiu.has_connections():
		caiu.emit()
	else:
		reviver()


## Cai e fica deitado: só a gravidade age; a animação de morte toca até o fim.
func _processar_morte(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FREIO_DA_MORTE * delta)
	aplicar_gravidade(delta)
	move_and_slide()
	_animacao.atualizar(&"Morrendo", velocity, direcao_olhar, velocidade_andar(), velocidade_corrida())


## Arma, escudo e a mão por cima do corpo: somem enquanto o herói morre e voltam ao reviver.
func _mostrar_equipamento(mostrar: bool) -> void:
	_ataque.visible = mostrar
	_escudo.visible = mostrar
	_arma_tras.visible = mostrar
	_animacao.mao_por_cima = mostrar


## Equipamento mudou (vestiu, tirou, quebrou): recalcula a CA e troca o visual.
func _atualizar_equipamento() -> void:
	if ficha == null:
		return
	_defesa.classe_armadura = classe_armadura()
	_defesa.reducao_fisica = _reducao_fisica()
	inventario.segunda_arma_livre = ficha.tem_talento(Ficha.TALENTO_EMPUNHADURA_DUPLA)
	_animacao.vestir(armadura_atual())
	_escudo.equipar(escudo_atual())


## Durável: gasta um dado de vida (ação bônus) e cura o valor rolado. false se não pode agora.
func gastar_dado_de_vida() -> bool:
	if ficha == null or ficha.dados_de_vida() <= 0 or _vida.esta_morto():
		return false
	var motivo := _dados_de_vida.motivo_de_nao_poder(_vida.vida_atual >= _vida.vida_maxima, acao_bonus_livre())
	if motivo != "":
		avisar(motivo)
		return false
	_tempo_desde_acao_bonus = 0.0
	var ganho := _vida.curar(_dados_de_vida.gastar(classe.dado_vida, _rng_folego))
	_animacao.pulso_cura()
	_texto.mostrar_cura("Dado de vida +%d" % ganho)
	dados_de_vida_mudou.emit(_dados_de_vida.restantes, ficha.dados_de_vida())
	return true


func dados_de_vida_restantes() -> int:
	return _dados_de_vida.restantes


## Envenenador: passa uma dose potente na arma (ação bônus). Sem dose, usa o item Veneno Básico da mochila.
func aplicar_veneno() -> bool:
	if ficha == null or _vida.esta_morto() or _veneno.na_arma != &"":
		return false
	var arma := arma_atual()
	if arma == null or arma.categoria == &"":
		avisar("Veneno: precisa de arma")
		return false
	var tipo := _veneno.tipo_disponivel(arma, tem_item_veneno())
	if tipo == &"":
		avisar("Sem veneno")
		return false
	if not acao_bonus_livre():
		avisar("Ação bônus")
		return false
	if tipo == VenenoDoHeroi.BASICO:
		inventario.extrair_uma(_item_veneno_basico())
	_veneno.aplicar(tipo)
	_tempo_desde_acao_bonus = 0.0
	_texto.mostrar("Arma envenenada", COR_VENENO)
	_avisar_veneno()
	return true


func veneno_na_arma() -> StringName:
	return _veneno.na_arma


func doses_de_veneno() -> int:
	return _veneno.doses




## Tem o item Veneno Básico na mochila? (a interface mostra o botão Veneno só se há o que passar)
func tem_item_veneno() -> bool:
	return _item_veneno_basico() != null


func _item_veneno_basico() -> Item:
	for item in inventario.itens:
		if item.nome == VenenoDoHeroi.NOME_ITEM_BASICO:
			return item
	return null


func _aplicar_veneno_ao_golpe(golpe: Golpe) -> void:
	_veneno.aplicar_ao_golpe(golpe, ficha)


func _apagar_veneno_da_arma() -> void:
	_veneno.apagar()
	_avisar_veneno()


func _passar_veneno(delta: float) -> void:
	if _veneno.passar(delta):
		_avisar_veneno()


func _avisar_veneno() -> void:
	veneno_mudou.emit(_veneno.doses, ficha.doses_de_veneno() if ficha else 0, _veneno.na_arma != &"")


## Dados de vida e doses de veneno voltam no descanso longo (e quando a ficha muda).
func _repor_dados_e_veneno() -> void:
	_dados_de_vida.repor(ficha)
	_veneno.repor(ficha)
	dados_de_vida_mudou.emit(_dados_de_vida.restantes, _dados_de_vida.restantes)
	_avisar_veneno()

## Duelista Defensivo: abre a janela de defesa (+proficiência na CA contra golpes corpo a corpo). Pede uma
## arma de acuidade na mão. false se não pode agora.
func defender() -> bool:
	if ficha == null or not ficha.tem_talento(Ficha.TALENTO_DUELISTA_DEFENSIVO) or not _janela_defesa.pronta() or _vida.esta_morto():
		return false
	var arma := arma_atual()
	if arma == null or not arma.acuidade:
		avisar("Defesa: arma de acuidade")
		return false
	_janela_defesa.abrir()
	_defesa.bonus_ca_corpo_a_corpo = ficha.bonus_proficiencia()
	_aura.pulso(COR_PARRY, FAISCAS_SEGUNDO_GOLPE, DURACAO_ANEL_SURTO)
	defesa_mudou.emit(true, false)
	return true


func defesa_ativa() -> bool:
	return _janela_defesa.ativa()


func defesa_pronta() -> bool:
	return _janela_defesa.pronta()


## Fecha a janela de defesa na hora (o herói caiu ou voltou): sem bônus de CA sobrando nem espera.
func _cancelar_defesa() -> void:
	_janela_defesa.cancelar()
	_defesa.bonus_ca_corpo_a_corpo = 0
	defesa_mudou.emit(false, true)


func _passar_defesa(delta: float) -> void:
	match _janela_defesa.passar(delta):
		JanelaDeDefesa.Evento.FECHOU:
			_defesa.bonus_ca_corpo_a_corpo = 0
			defesa_mudou.emit(false, false)
		JanelaDeDefesa.Evento.PRONTA:
			defesa_mudou.emit(false, true)


## O bônus de CA fez um golpe errar: parry.
func _ao_aparar(_origem: Vector2) -> void:
	_aura.pulso(COR_PARRY, FAISCAS_SEGUNDO_GOLPE, DURACAO_ANEL_SURTO)
	_animacao.brilhar(COR_PARRY, TEMPO_BRILHO_SURTO)
	_texto.mostrar("Aparado!", COR_PARRY)
	aparou.emit()


## Investida: alterna entre empurrar e dano extra no ataque feito correndo.
func alternar_investida() -> bool:
	if ficha == null or not ficha.tem_talento(Ficha.TALENTO_INVESTIDA):
		return false
	_investida.alternar()
	_texto.mostrar("Investida: %s" % ("empurrão" if _investida.empurra else "dano"), COR_PARRY)
	investida_mudou.emit(_investida.empurra)
	return true


func investida_empurra() -> bool:
	return _investida.empurra


## Quanto correu em linha reta: zera quando para, anda devagar ou vira.
func _medir_corrida(delta: float) -> void:
	_investida.medir(esta_correndo(), velocity.x, direcao_olhar, delta)


## Investida: o golpe feito depois de correr 10 pés em linha reta leva o efeito escolhido (uma vez por rodada).
func _aplicar_investida(golpe: Golpe) -> void:
	if ficha == null or not ficha.tem_talento(Ficha.TALENTO_INVESTIDA) or not _investida.carregada():
		return
	if not _recargas.em_recarga(Proficiencias.EFEITO_INVESTIDA):
		_investida.aplicar(golpe)


## O Atleta se recupera na hora de levar um golpe (sem o instante sem controle).
func tempo_de_recuo() -> float:
	return 0.0 if ficha != null and ficha.tem_talento(Ficha.TALENTO_ATLETA) else stats.tempo_recuo

## Mestre em Armadura Pesada: com armadura pesada vestida, o dano físico sofrido cai na proficiência.
func _reducao_fisica() -> int:
	var armadura := armadura_atual()
	var pesada := armadura != null and armadura.categoria == Proficiencias.ARMADURA_PESADA
	return ficha.bonus_proficiencia() if pesada and ficha.tem_talento(Ficha.TALENTO_MESTRE_ARMADURA_PESADA) else 0

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
func _comecar_golpe(extra: bool, do_surto: bool = false) -> void:
	if not extra and not do_surto:
		_abrir_acao_de_atacar()
	if not extra:
		_tempo_desde_golpe = 0.0
	elif not _tem_corte_duplo():
		_tempo_desde_acao_bonus = 0.0
	_contador_buffer_ataque = 0.0
	_combo_pedido = false
	_golpe_extra = extra
	var cabo := extra and _extra_com_cabo()
	var arma := _cabo_da_haste() if cabo else (arma_secundaria() if extra else arma_atual())
	_ataque.golpear(arma, _criar_golpe_de(arma, extra and not cabo), extra, arma_atual() if extra and not cabo else null)
	golpe_iniciado.emit(arma, extra)


func _criar_golpe_de(arma: Arma, extra: bool) -> Golpe:
	var golpe := Equipamento.golpe(ficha, inventario, arma, extra)
	_assinar(golpe)
	if not arma.disparavel():
		_aplicar_investida(golpe)
	_aplicar_veneno_ao_golpe(golpe)
	if inventario.esta_equipado(arma):
		golpe.arma_corroida.connect(_ao_corroer_arma.bind(arma))
	return golpe


## O golpe com a outra ponta da haste: um soco de 1d4 contundente, com o modificador de Força inteiro.
func _cabo_da_haste() -> Arma:
	if _cabo_da_haste_arma == null:
		_cabo_da_haste_arma = ataque_desarmado.duplicate() as Arma
		_cabo_da_haste_arma.nome = "Golpe com a Haste"
		_cabo_da_haste_arma.dados_dano = "1d4"
		_cabo_da_haste_arma.categoria = &"simples"
		_cabo_da_haste_arma.tipo_dano = TiposDano.CONTUNDENTE
	return _cabo_da_haste_arma


## O golpe extra deste herói é o da haste (tem o talento e uma arma de haste na mão)?
func _extra_com_cabo() -> bool:
	return ficha != null and ficha.tem_talento(Ficha.TALENTO_MESTRE_ARMAS_DE_HASTE) and ficha.e_arma_de_haste(inventario.equipado(Item.ESPACO_MAO) as Arma)

## Marca o herói como autor do golpe (e do 2º ataque do Trespassar): Atormentar dá vantagem
## só a quem marcou o alvo.
func _assinar(golpe: Golpe) -> void:
	golpe.autor_id = get_instance_id()
	golpe.limiar_critico = ficha.limiar_critico() if ficha != null else Combate.ACERTO_CRITICO
	if _gastar_sorte():  # Sortudo: o ataque rola um d20 a mais e fica o melhor
		golpe.vantagem = true
		if golpe.trespassar:
			golpe.trespassar.vantagem = true
	golpe.resolvido.connect(_ao_resolver_golpe_do_atacante)
	_ligar_efeitos_de_talento(golpe)
	if golpe.trespassar:
		golpe.trespassar.autor_id = golpe.autor_id
		golpe.trespassar.limiar_critico = golpe.limiar_critico
		golpe.trespassar.resolvido.connect(_ao_resolver_golpe_do_atacante)
		_ligar_efeitos_de_talento(golpe.trespassar)


## Os efeitos de "uma vez por rodada" (Atacante Selvagem, Retalhador, Agarrador...) só entram no golpe se a recarga
## acabou; quando o golpe gasta o efeito, a recarga começa. A regra é a mesma para todos (`EfeitoDeGolpe.por_rodada`).
func _ligar_efeitos_de_talento(golpe: Golpe) -> void:
	golpe.efeitos.assign(golpe.efeitos.filter(func(e: EfeitoDeGolpe) -> bool: return not (e.por_rodada and _recargas.em_recarga(e.id))))
	var escudo := golpe.efeito(Proficiencias.EFEITO_ESCUDO) as EfeitosDeTalento.GolpeDeEscudo
	if escudo != null:
		escudo.derruba = _escudo_derruba_agora
	if golpe.tem(Proficiencias.EFEITO_ARMA_GRANDE):
		golpe.resolvido.connect(_ao_resolver_golpe_do_mestre.bind(golpe))
	golpe.efeito_usado.connect(_ao_gastar_efeito)


## Mestre em Arma Grande: crítico ou abate com arma Pesada dá um golpe extra, como o do Surto de Ação.
func _ao_resolver_golpe_do_mestre(resultado: Combate.Resultado, abateu: bool, golpe: Golpe) -> void:
	if not resultado.acertou or not (resultado.critico or abateu) or not golpe.tem(Proficiencias.EFEITO_ARMA_GRANDE) or surto_ativo():
		return
	_ao_gastar_efeito(Proficiencias.EFEITO_ARMA_GRANDE)
	_golpes_encadeados += 1
	_surto_em_curso = true
	_aura.ligar(COR_SURTO)
	_aura.pulso(COR_SURTO, FAISCAS_SEGUNDO_GOLPE, DURACAO_ANEL_SURTO)
	_texto.mostrar("Golpe extra!", COR_SURTO)


func _ao_gastar_efeito(efeito: StringName) -> void:
	if efeito == Proficiencias.EFEITO_VENENO:
		_apagar_veneno_da_arma()  # o acerto gastou o veneno
	if efeito == Proficiencias.EFEITO_ESCUDO:
		_escudo_derruba_agora = not _escudo_derruba_agora  # o golpe de escudo alterna entre empurrar e derrubar
	_recargas.gastar(efeito)


func _passar_recargas_de_talento(delta: float) -> void:
	_recargas.passar(delta)

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
const COR_PARRY := Color(0.65, 0.88, 1.0)
const DISPARADA_APRIMORADA_PES := 10.0
## Mudança Tática (nível 5): ao usar o Fôlego, +15 pés de deslocamento por 3 s (regra da casa; no livro é um
## movimento livre sem ataque de oportunidade, que o jogo não tem).
const MUDANCA_TATICA_PES := 15.0
const MUDANCA_TATICA_SEGUNDOS := 3.0
const COR_VENENO := Color(0.55, 0.9, 0.4)


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
	return ficha.tem_talento(Ficha.TALENTO_ATIRADOR_DE_ELITE) or (arma.besta and ficha.tem_talento(Ficha.TALENTO_ESPECIALISTA_EM_BESTA))


## Forma Corrosiva (ex.: Gray Ooze): a arma não mágica que causou dano perde precisão
## e é destruída no limite.
func _ao_corroer_arma(penalidade: int, limite: int, arma: Arma) -> void:
	if inventario.desgastar(arma, penalidade, limite):
		_texto.mostrar("%s derreteu!" % arma.nome, TextoFlutuanteComponent.COR_DANO_SOFRIDO)
	else:
		_texto.mostrar("%s corroída -%d" % [arma.nome, inventario.penalidade(arma)], TextoFlutuanteComponent.COR_ERRO)


# --- Derrubado ---------------------------------------------------------------------

## A Defesa avisou, antes de resolver o golpe, que ele derruba: o estado Caído entra no lugar do recuo comum.
func _ao_ser_derrubado(_autor_id: int) -> void:
	_derrubado_pendente = true


## Deitado (Caído): o corpo gira e fica no chão; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_animacao.rotation = -direcao_olhar * PI / 2.0 if deitado else 0.0


# --- Agarrado ---------------------------------------------------------------------

func _ao_ser_agarrado(autor_id: int, cd: int) -> void:
	_agarrao.agarrar(autor_id, cd)
	_texto.mostrar("Agarrado!", TextoFlutuanteComponent.COR_CONDICAO)


## A cada rodada tenta escapar; pular antecipa. Se quem agarrou sumiu, solta.
func _passar_agarrao(delta: float) -> void:
	if not _agarrao.esta_agarrado():
		return
	if instance_from_id(_agarrao.autor_id()) == null:
		_agarrao.soltar()
		return
	var hora := _agarrao.passar(delta)
	if hora or (Input.is_action_just_pressed(&"pular") and _agarrao.pode_antecipar()):
		_tentar_escapar_do_agarrao()


func _tentar_escapar_do_agarrao() -> void:
	var bonus := maxi(ficha.bonus_salvaguarda(Atributos.FORCA), ficha.bonus_salvaguarda(Atributos.DESTREZA))
	if _agarrao.tentar_escapar(bonus, _rng_agarrao):
		_texto.mostrar("Soltou-se!", TextoFlutuanteComponent.COR_CONDICAO)
	else:
		_texto.mostrar("Preso!", TextoFlutuanteComponent.COR_CONDICAO)


## Agarrado não anda nem pula (ainda pode golpear).
func _prender_se_agarrado() -> void:
	if not _agarrao.esta_agarrado():
		return
	velocity.x = 0.0
	velocity.y = maxf(velocity.y, 0.0)


## A defesa rola as salvaguardas do herói (Borrifo Ácido) com os bônus da ficha.
func _atualizar_salvaguardas() -> void:
	for atributo in Atributos.TODOS:
		_defesa.bonus_salvaguardas[atributo] = ficha.bonus_salvaguarda(atributo)


## Uma nova ação de Atacar: o Ataque Extra faz dela dois golpes, e o Surto de Ação dobra a ação inteira
## (quatro golpes no nível 5). O golpe da outra mão (ação bônus) não entra na conta.
func _abrir_acao_de_atacar() -> void:
	var golpes := ficha.golpes_por_ataque() if ficha != null else 1
	if _surto_armado:
		_surto_armado = false
		_surto_em_curso = true
		golpes *= 2
	_golpes_encadeados = golpes - 1


## Mudança Tática: o Fôlego também dá pressa por alguns segundos, a partir do nível 5.
func _iniciar_mudanca_tatica() -> void:
	if ficha == null or ficha.nivel < Ficha.NIVEL_ATAQUE_EXTRA:
		return
	_tempo_mudanca_tatica = MUDANCA_TATICA_SEGUNDOS
	_texto.mostrar("Mudança Tática!", COR_FOLEGO_AURA)


## A Mudança Tática está valendo (bônus de deslocamento).
func mudanca_tatica_ativa() -> bool:
	return _tempo_mudanca_tatica > 0.0


## Atleta Notável: ainda há deslocamento livre depois do crítico.
func orcamento_atleta_ativo() -> bool:
	return _orcamento_atleta_px > 0.0


func orcamento_atleta_px() -> float:
	return _orcamento_atleta_px


## Crítico do herói: Campeão libera metade do deslocamento (OA não existe no jogo).
func _ao_resolver_golpe_do_atacante(resultado: Combate.Resultado, _abateu: bool) -> void:
	if not resultado.critico or ficha == null:
		return
	var fracao := ficha.fracao_movimento_pos_critico()
	if fracao <= 0.0:
		return
	var pes := Equipamento.deslocamento_pes(ficha, inventario) * fracao
	_orcamento_atleta_px = EscalaDnd.pes_para_pixels(pes)
	_texto.mostrar("Atleta Notável!", COR_FOLEGO_AURA)


func _consumir_orcamento_atleta(pixels_andados: float) -> void:
	if _orcamento_atleta_px <= 0.0 or pixels_andados <= 0.0:
		return
	_orcamento_atleta_px = maxf(_orcamento_atleta_px - pixels_andados, 0.0)
