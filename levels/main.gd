class_name Main
extends Node2D
## Cena principal: monta o jogo ligando fase, herói e interface (só pelas APIs públicas).
## Fluxo: tela de título -> criação do personagem -> jogo. Título, criação e "Você caiu!"
## pausam o jogo.

const CENA_TITULO := preload("res://ui/titulo/tela_titulo.tscn")
const CENA_CRIACAO := preload("res://ui/criacao_personagem/tela_criacao.tscn")
const CENA_DERROTA := preload("res://ui/derrota/tela_derrota.tscn")
const CENA_VITORIA := preload("res://ui/vitoria/tela_vitoria.tscn")
const CENA_ARREMESSO := preload("res://features/arremesso/arma_arremessada.tscn")
const CENA_OOZE := preload("res://features/gray_ooze/gray_ooze.tscn")
const CENA_GOBLIN := preload("res://features/goblin/goblin.tscn")
const CENA_GOBLIN_GUERREIRO := preload("res://features/goblin/goblin_guerreiro.tscn")
const CENA_HOBGOBLIN := preload("res://features/goblin/hobgoblin_guerreiro.tscn")
const CENA_BUGBEAR := preload("res://features/goblin/bugbear_guerreiro.tscn")
const CENA_KOBOLD := preload("res://features/goblin/kobold_guerreiro.tscn")
const CENAS_FASE: Array[PackedScene] = [
	preload("res://levels/fase_1.tscn"),
	preload("res://levels/fase_2.tscn"),
	preload("res://levels/fase_3.tscn"),
	preload("res://levels/fase_4.tscn"),
	preload("res://levels/fase_5.tscn"),
]
## Páginas do bestiário, na ordem da lista.
const ENTRADAS_BESTIARIO: Array[EntradaBestiario] = [
	preload("res://data/bestiario/gray_ooze.tres"),
	preload("res://data/bestiario/goblin_minion.tres"),
	preload("res://data/bestiario/goblin_warrior.tres"),
	preload("res://data/bestiario/hobgoblin_warrior.tres"),
	preload("res://data/bestiario/bugbear_warrior.tres"),
	preload("res://data/bestiario/kobold_warrior.tres"),
]
## Talentos do livro (a tela de escolha do nível 4 lê daqui).
const PASTA_TALENTOS := "res://data/talentos"
const GRUPO_MONSTROS := &"monstros"
## O que o botão de ataque do celular passa a dizer perto de um baú ou de uma arma caída.
const ROTULO_ABRIR := "Abrir"
const ROTULO_PEGAR := "Pegar"
const TIPO_OOZE := &"ooze"
const TIPO_MINION := &"minion"
const TIPO_WARRIOR := &"warrior"
const TIPO_HOBGOBLIN := &"hobgoblin"
const TIPO_BUGBEAR := &"bugbear"
const TIPO_KOBOLD := &"kobold"
## Cena de cada tipo que a fase pode sortear. Tipo novo = uma linha aqui (e o nome em `Fase.tipos_permitidos`).
const CENAS_DOS_TIPOS: Dictionary[StringName, PackedScene] = {
	TIPO_OOZE: CENA_OOZE,
	TIPO_MINION: CENA_GOBLIN,
	TIPO_WARRIOR: CENA_GOBLIN_GUERREIRO,
	TIPO_HOBGOBLIN: CENA_HOBGOBLIN,
	TIPO_BUGBEAR: CENA_BUGBEAR,
	TIPO_KOBOLD: CENA_KOBOLD,
}
const INIMIGOS_EXTRA_POR_NIVEL := 1
## Onde a criatura trazida pela tela de comandos nasce, à frente do herói (pés).
const DISTANCIA_CRIATURA_PES := 15.0
const AVISO_PORTA := "A porta não abre"
const AVISO_MISSAO_CUMPRIDA := "Missão cumprida!"

## Começa pelo título e pela criação. Os testes desligam para jogar direto com a sugestão.
@export var mostrar_inicio: bool = true
## Classes que dá para escolher na criação.
@export var classes_disponiveis: Array[ClasseRPG] = []
## Semente do sorteio das armadilhas. Menor que 0 sorteia de novo a cada entrada.
@export var semente_armadilhas: int = -1

## True enquanto uma tela de pausa está aberta (título, criação, derrota, vitória): o inventário não abre.
var _em_tela_de_pausa: bool = false
## Instâncias da cota desta entrada. O que foi trazido por Comandos não entra aqui.
var _ids_da_cota: Array[int] = []
## A missão da fase atual (os inimigos da cota são o objetivo).
var _missao := Missao.new()
var _surto_usado: bool = false
## A tela aberta agora veio do menu de pausa: ao fechar, a pausa volta.
var _voltar_para_pausa: bool = false
## Quantas coisas com que dá para interagir (o baú, uma arma caída) estão perto do herói, por rótulo do botão.
var _interagiveis_perto: Dictionary[String, int] = {}
## O título está escondido porque as Opções abriram por cima dele; ao fechar, ele volta.
var _titulo_escondido: TelaTitulo
## Quantas vezes o herói derrotou cada criatura (o bestiário mostra e o save guarda).
var _bestiario := Bestiario.new()
## O que a loja da fase tem à venda (sorteado ao entrar na fase; o comprado sai daqui).
var _estoque_da_loja: Array[Item] = []
## O herói está em cima da porta agora.
var _heroi_na_porta: bool = false

@onready var _fase: Fase = $Fase
@onready var _jogador: Jogador = $Jogador
@onready var _hud: Hud = $Hud
@onready var _interface: CanvasLayer = $Interface
@onready var _inventario: TelaInventario = $Interface/TelaInventario
@onready var _bau: Bau = $Bau
@onready var _boneco: Node2D = $BonecoTreino
@onready var _tela_bau: TelaBau = $Interface/TelaBau
@onready var _lojista: Lojista = $Lojista
@onready var _tela_loja: TelaLoja = $Interface/TelaLoja
@onready var _comandos: TelaComandos = $Interface/TelaComandos
@onready var _pausa: TelaPausa = $Interface/TelaPausa
@onready var _tela_bestiario: TelaBestiario = $Interface/TelaBestiario
@onready var _tela_habilidades: TelaHabilidades = $Interface/TelaHabilidades
@onready var _tela_compendio: TelaCompendio = $Interface/TelaCompendio
@onready var _tela_talento: TelaTalento = $Interface/TelaTalento
@onready var _sons: Sons = $Sons
@onready var _musica: Musica = $Musica
@onready var _controles_toque: ControlesToque = $ControlesToque


## Os barramentos de áudio precisam existir antes de qualquer som nascer (os filhos ficam prontos antes da main).
func _enter_tree() -> void:
	OpcoesSom.carregar()
	OpcoesSom.preparar_barramentos()


func _ready() -> void:
	Comandos.carregar()
	OpcoesToque.carregar()
	_jogador.posicionar_no_inicio(_fase.posicao_inicio())
	_jogador.definir_limites_camera(_fase.area_jogavel())
	_jogador.limite_queda = _fase.limite_queda()
	_jogador.vida_mudou.connect(_hud.mostrar_vida)
	_jogador.folego_mudou.connect(_hud.mostrar_folego)
	_jogador.progressao_mudou.connect(_ao_mudar_progressao)
	_jogador.ouro_mudou.connect(_hud.mostrar_ouro)
	_jogador.surto_acao_pedido.connect(_usar_surto_acao)
	_jogador.mente_tatica_pedido.connect(_alternar_mente_tatica)
	_jogador.surto_ativo_mudou.connect(_ao_surto_ativo_mudou)
	_jogador.sorte_mudou.connect(_ao_mudar_sorte)
	_jogador.dados_de_vida_mudou.connect(_ao_mudar_dados_de_vida)
	_jogador.veneno_mudou.connect(_ao_mudar_veneno)
	_jogador.defesa_mudou.connect(func(_ativa: bool, _pronta: bool) -> void: _atualizar_botoes_toque())
	_jogador.investida_mudou.connect(_ao_mudar_investida)
	_jogador.folego_mudou.connect(func(_restantes: int, _total: int) -> void: _atualizar_botoes_toque())
	_jogador.caiu.connect(_ao_cair)
	_mostrar_personagem_no_hud()
	_inventario.abrir_pedido.connect(_abrir_inventario)
	_inventario.fechou.connect(_ao_fechar_modal)
	_bau.abrir_pedido.connect(_abrir_bau)
	_bau.perto_mudou.connect(_ao_mudar_interagivel.bind(ROTULO_ABRIR))
	_jogador.inventario.mudou.connect(_atualizar_botoes_toque)
	_tela_bau.fechou.connect(_ao_fechar_modal)
	_lojista.abrir_pedido.connect(_abrir_loja)
	_lojista.perto_mudou.connect(_ao_mudar_interagivel.bind(ROTULO_ABRIR))
	_tela_loja.fechou.connect(_ao_fechar_modal)
	_tela_loja.ouro_mudou.connect(_hud.mostrar_ouro)
	_pausa.fechou.connect(_ao_fechar_modal)
	_pausa.mochila_escolhida.connect(_abrir_pela_pausa.bind(_abrir_inventario))
	_pausa.opcoes_escolhidas.connect(_abrir_pela_pausa.bind(_abrir_comandos))
	_pausa.bestiario_escolhido.connect(_abrir_pela_pausa.bind(_abrir_bestiario))
	_tela_bestiario.fechou.connect(_ao_fechar_modal)
	_pausa.compendio_escolhido.connect(_abrir_pela_pausa.bind(_abrir_compendio))
	_tela_compendio.fechou.connect(_ao_fechar_modal)
	_pausa.talento_pedido.connect(_abrir_pela_pausa.bind(_abrir_talento))
	_tela_talento.fechou.connect(_ao_fechar_modal)
	_tela_talento.talento_escolhido.connect(_ao_escolher_talento)
	_pausa.habilidades_escolhidas.connect(_abrir_pela_pausa.bind(_abrir_habilidades))
	_tela_habilidades.fechou.connect(_ao_fechar_modal)
	_pausa.salvar_escolhido.connect(_salvar_jogo)
	_pausa.titulo_escolhido.connect(_voltar_ao_titulo)
	_comandos.abrir_pedido.connect(_abrir_comandos)
	_comandos.fechou.connect(_ao_fechar_modal)
	_comandos.trazer_pedido.connect(trazer_criatura)
	_comandos.tirar_pedido.connect(tirar_criaturas)
	_comandos.opcoes_toque_mudaram.connect(_atualizar_controles_toque)
	_comandos.editar_toque_pedido.connect(_editar_toque)
	_controles_toque.edicao_terminada.connect(func() -> void: get_tree().paused = false)
	_comandos.definir_criaturas(PackedStringArray(["Gray Ooze", "Goblin Minion", "Goblin Warrior", "Hobgoblin Warrior", "Bugbear Warrior", "Kobold Warrior"]), _cenas_criaturas())
	_jogador.arma_arremessada.connect(_ao_arremessar)
	_atualizar_botoes_toque()
	_ligar_porta()
	_atualizar_pecas_da_fase()
	_nascer_armadilhas()
	_sons.ligar_jogador(_jogador)
	_sons.ligar_telas(_interface)
	if mostrar_inicio:
		_abrir_titulo()
	else:
		_musica.tocar_da_fase(_fase.indice)


# --- Início -----------------------------------------------------------------------

func _abrir_titulo() -> void:
	_pausar(true)
	_musica.tocar(Musica.TITULO)
	var titulo: TelaTitulo = CENA_TITULO.instantiate()
	titulo.novo_jogo_escolhido.connect(_ao_escolher_novo_jogo.bind(titulo))
	titulo.continuar_escolhido.connect(_ao_continuar.bind(titulo))
	titulo.opcoes_escolhidas.connect(_abrir_opcoes_do_titulo.bind(titulo))
	titulo.compendio_escolhido.connect(_abrir_compendio_do_titulo.bind(titulo))
	titulo.sair_escolhido.connect(get_tree().quit)
	_interface.add_child(titulo)
	titulo.mostrar_continuar(not Salvamento.ler().is_empty())


func _ao_escolher_novo_jogo(titulo: TelaTitulo) -> void:
	titulo.queue_free()
	_abrir_criacao()


## Opções a partir do título: ele se esconde e volta quando as Opções fecham (Esc ou Fechar).
func _abrir_opcoes_do_titulo(titulo: TelaTitulo) -> void:
	_titulo_escondido = titulo
	titulo.hide()
	_comandos.abrir(false)


## Abre o mesmo Compêndio da pausa usando a classe disponível na criação.
func _abrir_compendio_do_titulo(titulo: TelaTitulo) -> void:
	_titulo_escondido = titulo
	titulo.hide()
	_tela_compendio.abrir(Compendio.montar(_classe_padrao_do_compendio()))


func _classe_padrao_do_compendio() -> ClasseRPG:
	if not classes_disponiveis.is_empty():
		return classes_disponiveis[0]
	return _jogador.ficha.classe


## Carrega o jogo salvo: a ficha, a mochila e o começo da fase em que salvou.
func _ao_continuar(titulo: TelaTitulo) -> void:
	var dados := Salvamento.ler()
	var ficha := Salvamento.montar_ficha(dados)
	if ficha == null:
		return
	titulo.queue_free()
	_jogador.configurar_ficha(ficha)
	_jogador.definir_mente_tatica(false)
	Salvamento.restaurar_inventario(dados, _jogador.inventario)
	Salvamento.restaurar_bestiario(dados, _bestiario)
	var indice := clampi(Salvamento.fase_de(dados) - 1, 0, CENAS_FASE.size() - 1)
	_entrar_fase(CENAS_FASE[indice])
	_mostrar_personagem_no_hud()
	_apontar_monstros_para(_jogador)
	_pausar(false)
	_musica.tocar_da_fase(_fase.indice)


func _abrir_criacao() -> void:
	var tela: TelaCriacao = CENA_CRIACAO.instantiate()
	if not classes_disponiveis.is_empty():
		tela.classes = classes_disponiveis
	tela.arma_previa = _jogador.ataque_desarmado
	tela.confirmada.connect(_ao_criar_personagem.bind(tela))
	tela.voltar_ao_titulo_pedido.connect(_ao_voltar_da_criacao.bind(tela))
	_interface.add_child(tela)


## Esc no primeiro passo da criação: fecha a tela e mostra o título de novo.
func _ao_voltar_da_criacao(tela: TelaCriacao) -> void:
	tela.queue_free()
	_abrir_titulo()


func _ao_criar_personagem(ficha: Ficha, pacote: PacoteInicial, tela: TelaCriacao) -> void:
	_jogador.configurar_ficha(ficha)
	_jogador.definir_mente_tatica(false)
	_jogador.receber_pacote(pacote)
	_mostrar_personagem_no_hud()
	_apontar_monstros_para(_jogador)
	tela.queue_free()
	_pausar(false)
	_musica.tocar_da_fase(_fase.indice)


# --- Derrota ----------------------------------------------------------------------

func _ao_cair() -> void:
	_pausar(true)
	var tela: TelaDerrota = CENA_DERROTA.instantiate()
	tela.tentar_de_novo_escolhido.connect(_tentar_de_novo.bind(tela))
	_interface.add_child(tela)
	tela.mostrar_personagem(_jogador.ficha.nome, _jogador.ficha.classe.nome)


## Recomeça a fase atual: vida cheia e um sorteio novo das armadilhas.
func _tentar_de_novo(tela: TelaDerrota) -> void:
	tela.queue_free()
	_jogador.reviver()
	_nascer_armadilhas()
	_pausar(false)


func _abrir_vitoria() -> void:
	_pausar(true)
	_musica.tocar(Musica.TAVERNA)
	var tela: TelaVitoria = CENA_VITORIA.instantiate()
	tela.jogar_de_novo_escolhido.connect(_ao_jogar_de_novo.bind(tela))
	_interface.add_child(tela)


## Volta à primeira fase, com vida cheia e armadilhas novas.
func _ao_jogar_de_novo(tela: TelaVitoria) -> void:
	tela.queue_free()
	_entrar_fase(CENAS_FASE[0])
	_jogador.reviver()
	_pausar(false)


func _ligar_porta() -> void:
	if not _fase.porta_tocada.is_connected(_ao_tocar_porta):
		_fase.porta_tocada.connect(_ao_tocar_porta)
		_fase.porta_liberada.connect(_ao_sair_da_porta)


func _ao_tocar_porta(corpo: Node2D) -> void:
	if corpo != _jogador:
		return
	_heroi_na_porta = true
	_tentar_atravessar.call_deferred()


func _ao_sair_da_porta(corpo: Node2D) -> void:
	if corpo == _jogador:
		_heroi_na_porta = false


## A porta cobra a cota desta entrada. A última fase conclui o jogo.
func _tentar_atravessar() -> void:
	if not _heroi_na_porta or _em_tela_de_pausa:
		return
	if not _ids_da_cota.is_empty():
		_jogador.avisar(AVISO_PORTA)
		return
	_heroi_na_porta = false
	if _fase.ultima:
		_abrir_vitoria()
		return
	var seguinte := _fase.indice
	if seguinte < CENAS_FASE.size():
		_entrar_fase(CENAS_FASE[seguinte])
		_salvar_ao_entrar_na_fase()


func _entrar_fase(cena: PackedScene) -> void:
	_heroi_na_porta = false
	_jogador.descansar_longo()
	_surto_usado = false
	_jogador.ganhar_item_do_artesao()
	var antiga := _fase
	antiga.name = "FaseAntiga"
	_fase = cena.instantiate()
	_fase.name = "Fase"
	add_child(_fase)
	move_child(_fase, 0)
	antiga.queue_free()
	_ligar_porta()
	_jogador.posicionar_no_inicio(_fase.posicao_inicio())
	_jogador.definir_limites_camera(_fase.area_jogavel())
	_jogador.limite_queda = _fase.limite_queda()
	_atualizar_pecas_da_fase()
	_nascer_armadilhas()
	_hud.mostrar_surto(_jogador.ficha.nivel, true)
	_atualizar_botoes_toque()
	_musica.tocar_da_fase(_fase.indice)


## Baú e boneco ficam na clareira (e na fase reta de teste, índice 0). Nas outras fases não ocupam o caminho.
func _atualizar_pecas_da_fase() -> void:
	var na_primeira := _fase.indice <= 1
	_bau.visible = na_primeira
	_boneco.visible = na_primeira
	var modo := Node.PROCESS_MODE_INHERIT if na_primeira else Node.PROCESS_MODE_DISABLED
	_bau.process_mode = modo
	_boneco.process_mode = modo
	_posicionar_a_loja()


func _nascer_armadilhas() -> void:
	_apagar_monstros()
	_ids_da_cota.clear()
	var pontos := _fase.pontos_armadilha()
	var nivel := _jogador.ficha.nivel
	var quantidade := quantidade_inimigos_da_fase(nivel)
	var tipos := _tipos_da_fase(nivel)
	var escolhas := Armadilha.sortear(pontos, quantidade, tipos, _rng_da_fase())
	for escolha in escolhas:
		var tipo: StringName = escolha.tipo
		var monstro: Node2D = _cena_do_tipo(tipo).instantiate()
		monstro.add_to_group(GRUPO_MONSTROS)
		add_child(monstro)
		monstro.global_position = escolha.posicao
		var id := monstro.get_instance_id()
		_ids_da_cota.append(id)
		var criatura := monstro.get("criatura") as CriaturaRPG
		var experiencia := criatura.experiencia if criatura else 0
		var ouro := criatura.ouro if criatura else 0
		_ligar_morte_da_cota(monstro, id, experiencia, ouro)
		if monstro.has_method(&"definir_alvo"):
			monstro.call(&"definir_alvo", _jogador)
		_passar_percepcao(monstro)
		_passar_luz_do_sol(monstro)
	_missao = Missao.new(_fase.missao, _ids_da_cota.size())
	_mostrar_missao()


## A linha da missão na HUD (some se a fase não tem inimigos).
func _mostrar_missao() -> void:
	_hud.mostrar_missao(_missao.texto() if _missao.existe() else "", _missao.cumprida())


## Quando a criatura morre, o bestiário anota a derrota dela.
func _registrar_no_bestiario(monstro: Node2D) -> void:
	var criatura := monstro.get("criatura") as CriaturaRPG
	if criatura and monstro.has_signal(&"morreu"):
		monstro.connect(&"morreu", _bestiario.registrar_derrota.bind(criatura.nome))


func quantidade_inimigos_da_fase(nivel: int) -> int:
	var pontos := _fase.pontos_armadilha()
	return mini(_fase.quantidade + (nivel - 1) * INIMIGOS_EXTRA_POR_NIVEL, pontos.size())


## Todo monstro da cota tem o sinal `morreu`.
func _ligar_morte_da_cota(monstro: Node2D, id: int, experiencia: int, ouro: int) -> void:
	_registrar_no_bestiario(monstro)
	monstro.connect(&"morreu", _ao_morreu_da_cota.bind(id, experiencia, ouro))


func _ao_morreu_da_cota(id: int, experiencia: int, ouro: int) -> void:
	_ids_da_cota.erase(id)
	_jogador.ganhar_experiencia(experiencia)
	_soltar_saque(ouro)
	_missao.registrar_morte()
	_mostrar_missao()
	if _missao.cumprida():
		_jogador.avisar(AVISO_MISSAO_CUMPRIDA)
	# Adia: quem morreu ainda está emitindo o sinal e não pode ser apagado agora.
	if _heroi_na_porta:
		_tentar_atravessar.call_deferred()


## Cada fase fica com mais um inimigo por nível; níveis mais altos liberam Guerreiro cedo.
func _tipos_da_fase(nivel: int) -> Array[StringName]:
	var tipos: Array[StringName] = _fase.tipos_permitidos.duplicate()
	var liberar_guerreiro := (nivel >= Ficha.NIVEL_HABILIDADES_GUERREIRO and _fase.indice >= 3) or (nivel >= 3 and _fase.indice >= 2)
	if liberar_guerreiro and TIPO_WARRIOR not in tipos:
		tipos.append(TIPO_WARRIOR)
	return tipos


## Surto de Ação: acende a aura do herói e o próximo ataque sai em dobro (dois golpes seguidos).
## Funciona sem inimigo por perto, uma vez por fase.
func _usar_surto_acao() -> void:
	if not _surto_disponivel():
		return
	if not _jogador.armar_surto():
		return
	_surto_usado = true
	_hud.mostrar_surto(_jogador.ficha.nivel, false, true)
	_atualizar_botoes_toque()


func _surto_disponivel() -> bool:
	if _em_tela_de_pausa:
		return false
	if _jogador.ficha.nivel < Ficha.NIVEL_HABILIDADES_GUERREIRO:
		_jogador.avisar("Surto de Ação: nível 2")
		return false
	if _surto_usado:
		_jogador.avisar("Surto já usado nesta fase")
		return false
	return true


## O Surto acendeu ou apagou (o segundo golpe saiu): atualiza o HUD e o botão da barra.
func _ao_surto_ativo_mudou(ativo: bool) -> void:
	_hud.mostrar_surto(_jogador.ficha.nivel, not _surto_usado, ativo)
	_atualizar_botoes_toque()


## A sorte do Sortudo mudou (ponto gasto, armada, descanso): atualiza o HUD e o botão da barra.
func _ao_mudar_sorte(pontos: int, total: int, armada: bool) -> void:
	_hud.mostrar_sorte(pontos, total, armada)
	_atualizar_botoes_toque()


## O modo da Investida mudou: a linha do HUD diz qual está valendo e o botão acende no empurrão.
func _ao_mudar_investida(empurra: bool) -> void:
	_hud.mostrar_investida(true, empurra)
	_atualizar_botoes_toque()


## Os dados de vida do Durável mudaram: o HUD mostra quantos restam.
func _ao_mudar_dados_de_vida(restantes: int, total: int) -> void:
	_hud.mostrar_dados_de_vida(restantes, total)
	_atualizar_botoes_toque()


## O veneno mudou (dose usada, arma envenenada, fase nova): o HUD diz o estado.
func _ao_mudar_veneno(doses: int, total: int, aplicado: bool) -> void:
	_hud.mostrar_veneno(doses, total, aplicado)
	_atualizar_botoes_toque()

## Defesa aberta = botão aceso; esperando a recarga = avermelhado; pronta = normal.
func _estado_da_defesa() -> BotaoToque.EstadoBotao:
	if _jogador.defesa_ativa():
		return BotaoToque.EstadoBotao.ACESO
	if not _jogador.defesa_pronta():
		return BotaoToque.EstadoBotao.DESLIGADO
	return BotaoToque.EstadoBotao.NORMAL

## Sorte armada = botão aceso; sem pontos = avermelhado; pronta = normal.
func _estado_da_sorte() -> BotaoToque.EstadoBotao:
	if _jogador.sorte_armada():
		return BotaoToque.EstadoBotao.ACESO
	if _jogador.pontos_sorte() <= 0:
		return BotaoToque.EstadoBotao.DESLIGADO
	return BotaoToque.EstadoBotao.NORMAL


## Mente Tática liga e desliga como as outras habilidades (tecla T, ou o botão na barra do celular).
func _alternar_mente_tatica() -> void:
	if _em_tela_de_pausa:
		return
	if _jogador.ficha.nivel < Ficha.NIVEL_HABILIDADES_GUERREIRO:
		_jogador.avisar("Mente Tática: nível 2")
		return
	_jogador.definir_mente_tatica(not _jogador.mente_tatica_ligada())
	_jogador.avisar("Mente Tática %s" % ("ligada" if _jogador.mente_tatica_ligada() else "desligada"))
	_atualizar_botoes_toque()


## O herói recebe o ouro e, às vezes, uma arma do inimigo derrotado; o Carisma dele melhora a sorte (Saque).
func _soltar_saque(ouro: int) -> void:
	var carisma := _jogador.ficha.modificador(Atributos.CARISMA)
	var rng := _rng_da_fase()
	_jogador.ganhar_ouro(Saque.ouro(ouro, carisma, rng))
	_jogador.receber_saque(Saque.arma(carisma, rng))


func _rng_da_fase() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if semente_armadilhas < 0:
		rng.randomize()
	else:
		rng.seed = semente_armadilhas
	return rng


func _cena_do_tipo(tipo: StringName) -> PackedScene:
	return CENAS_DOS_TIPOS.get(tipo, CENA_OOZE)


func _apagar_monstros() -> void:
	for monstro in get_tree().get_nodes_in_group(GRUPO_MONSTROS):
		if not is_instance_valid(monstro) or monstro.is_queued_for_deletion():
			continue
		monstro.free()


## Todo nó do grupo "monstros" persegue o herói. Quem se esconde também recebe a passiva.
func _apontar_monstros_para(alvo: Node2D) -> void:
	for monstro in get_tree().get_nodes_in_group(GRUPO_MONSTROS):
		monstro.definir_alvo(alvo)
		_passar_percepcao(monstro)
		_passar_luz_do_sol(monstro)


func _passar_percepcao(monstro: Node) -> void:
	if monstro.has_method(&"definir_percepcao_passiva"):
		monstro.call(&"definir_percepcao_passiva", _jogador.ficha.percepcao_passiva())


## Quem é sensível ao sol (Kobold) precisa saber se a fase é de dia.
func _passar_luz_do_sol(monstro: Node) -> void:
	if monstro.has_method(&"definir_luz_do_sol"):
		monstro.call(&"definir_luz_do_sol", _fase != null and _fase.luz_do_sol)


## Cenas da lista "Trazer" da tela de comandos, na ordem dos nomes.
func _cenas_criaturas() -> Array[PackedScene]:
	var cenas: Array[PackedScene] = [CENA_OOZE, CENA_GOBLIN, CENA_GOBLIN_GUERREIRO, CENA_HOBGOBLIN, CENA_BUGBEAR, CENA_KOBOLD]
	return cenas


# --- Interface --------------------------------------------------------------------

## Alguma tela ou o modo de edição dos botões ocupa o jogo? `exceto` é a própria tela que está tentando abrir
## (ela não conta contra si mesma). Um lugar só: tela nova entra em `_telas_modais()` e vale em toda parte.
func _ha_menu_aberto(exceto: Control = null) -> bool:
	return _em_tela_de_pausa or _controles_toque.esta_editando() or _ha_tela_aberta(exceto)


func _ha_tela_aberta(exceto: Control = null) -> bool:
	for tela in _telas_modais():
		if tela != exceto and tela.visible:
			return true
	return false


func _telas_modais() -> Array[Control]:
	return [_inventario, _tela_bau, _tela_loja, _comandos, _pausa, _tela_bestiario, _tela_compendio, _tela_habilidades, _tela_talento]


## Esc (ou o botão Menu) abre a pausa se nenhuma tela por cima já usou a tecla para voltar.
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"pausa"):
		_abrir_pausa()


## Pausa (Esc ou o botão Menu): Continuar, Mochila, Habilidades, Bestiário, Compêndio, Opções, Salvar e Menu principal.
func _abrir_pausa() -> void:
	if _ha_menu_aberto(_pausa):
		return
	_pausa.abrir()
	_controles_toque.atualizar(true)


## Salva a ficha, a mochila e a fase atual. Ao continuar, o herói volta ao começo da fase.
func _salvar_jogo() -> void:
	var gravou := Salvamento.gravar(_jogador.ficha, _jogador.inventario, _fase.indice, _bestiario)
	if gravou:
		_sons.tocar(&"confirmar")
	_pausa.mostrar_aviso("Jogo salvo" if gravou else "Não foi possível salvar")


## Entrou numa fase nova: guarda o progresso sozinho. Só no jogo de verdade (os testes pulam o início).
func _salvar_ao_entrar_na_fase() -> void:
	if mostrar_inicio and Salvamento.gravar(_jogador.ficha, _jogador.inventario, _fase.indice, _bestiario):
		_jogador.avisar("Jogo salvo")


func _voltar_ao_titulo() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _abrir_habilidades() -> void:
	if _ha_menu_aberto(_tela_habilidades):
		return
	_tela_habilidades.abrir(_jogador.ficha)
	_controles_toque.atualizar(true)


## Abre a escolha do talento do nível 4 (sozinha ao subir de nível; depois, pelo botão da pausa).
func _abrir_talento() -> void:
	if _jogador.ficha.escolhas_de_talento_pendentes() <= 0:
		return
	if _ha_menu_aberto(_tela_talento):
		return
	var talentos: Array[TalentoRPG] = []
	talentos.assign(Recursos.da_pasta(PASTA_TALENTOS))
	_tela_talento.abrir(_jogador.ficha, talentos)
	_controles_toque.atualizar(true)


## O talento já está na ficha: o herói recalcula vida e CA.
func _ao_escolher_talento(talento: TalentoRPG) -> void:
	_jogador.ao_mudar_ficha()
	_jogador.avisar(talento.nome)


func _abrir_compendio() -> void:
	if _ha_menu_aberto(_tela_compendio):
		return
	_tela_compendio.abrir(Compendio.montar(_jogador.ficha.classe))
	_controles_toque.atualizar(true)


func _abrir_bestiario() -> void:
	if _ha_menu_aberto(_tela_bestiario):
		return
	_tela_bestiario.abrir(_bestiario, ENTRADAS_BESTIARIO)
	_controles_toque.atualizar(true)


func _abrir_inventario() -> void:
	if _ha_menu_aberto(_inventario):
		return
	_inventario.abrir(_jogador.inventario, _jogador.ficha, _jogador.vida_atual(),
		_jogador.vida_maxima(), _jogador.ataque_desarmado)
	_controles_toque.atualizar(true)


func _ao_arremessar(arma: Arma, golpe: Golpe, penalidade: int, origem: Vector2, direcao: int, forca: float, mira: float, municao: Municao, ignora_alcance_longo: bool, destreza: int) -> void:
	_avisar_monstros_do_disparo(origem)
	var voo: ArmaArremessada = CENA_ARREMESSO.instantiate()
	voo.perto_mudou.connect(_ao_mudar_interagivel.bind(ROTULO_PEGAR))
	if municao == null:
		voo.recolhida.connect(_ao_recolher_arma.bind(voo))
		voo.derreteu.connect(_jogador.avisar)
	add_child(voo)
	voo.global_position = origem
	voo.lancar(arma, golpe, penalidade, direcao, forca, mira, municao, ignora_alcance_longo, destreza)


## Quem vê o herói atirar ou arremessar procura abrigo (a decisão é de cada monstro).
func _avisar_monstros_do_disparo(origem: Vector2) -> void:
	for monstro in get_tree().get_nodes_in_group(GRUPO_MONSTROS):
		if monstro.has_method(&"perceber_disparo"):
			monstro.call(&"perceber_disparo", origem)


func _ao_recolher_arma(arma: Arma, penalidade: int, voo: ArmaArremessada) -> void:
	if _jogador.recolher_arma(arma, penalidade):
		voo.queue_free()
	else:
		voo.avisar_cheia()


func _abrir_bau(itens: Array[Item]) -> void:
	if _ha_menu_aberto(_tela_bau):
		return
	_sons.tocar(&"bau")
	_tela_bau.abrir(itens, _jogador.inventario)
	_controles_toque.atualizar(true)


## A banca do lojista fica ao lado do começo da fase, com o estoque novo dela.
func _posicionar_a_loja() -> void:
	_lojista.global_position = _fase.posicao_inicio() + _fase.deslocamento_loja
	_estoque_da_loja = Loja.sortear_estoque(_fase.indice, _rng_da_fase())


func _abrir_loja() -> void:
	if _ha_menu_aberto(_tela_loja):
		return
	_sons.tocar(&"bau")
	_tela_loja.abrir(_estoque_da_loja, _jogador.ficha, _jogador.inventario)
	_controles_toque.atualizar(true)


func _abrir_comandos() -> void:
	if _ha_menu_aberto(_comandos):
		return
	_comandos.abrir()
	_controles_toque.atualizar(true)


func _reabrir_pausa() -> void:
	if _voltar_para_pausa:
		_voltar_para_pausa = false
		_pausa.abrir()


## Mochila ou Opções abertas pela pausa: ao fechar (Esc ou Fechar), a pausa volta.
func _abrir_pela_pausa(abrir_tela: Callable) -> void:
	_voltar_para_pausa = true
	abrir_tela.call()
	if not _ha_tela_aberta():
		_voltar_para_pausa = false
		_pausa.abrir()


func _ao_fechar_modal() -> void:
	if _titulo_escondido != null:
		_titulo_escondido.show()
		_titulo_escondido.mostrar_continuar(not Salvamento.ler().is_empty())
		_titulo_escondido = null
		_pausar(true)  # as Opções despausaram o jogo; o título continua pausando
		return
	if _voltar_para_pausa:
		_reabrir_pausa.call_deferred()  # adia: Ajustar botões cancela o retorno logo depois de fechar
		return
	_atualizar_controles_toque()


## Esconde os botões de toque que não servem agora (Surto antes do nível 2, Fôlego sem a habilidade, Lançar
## sem arma na mão) e faz o botão de ataque dizer Abrir ou Pegar perto de um baú ou de uma arma caída.
func _atualizar_botoes_toque() -> void:
	var tem_nivel_2 := _jogador.ficha.nivel >= Ficha.NIVEL_HABILIDADES_GUERREIRO
	_controles_toque.mostrar_acao(&"surto_acao", tem_nivel_2)
	_controles_toque.mostrar_acao(&"mente_tatica", tem_nivel_2)
	_controles_toque.mostrar_acao(&"sorte", _jogador.pontos_sorte_total() > 0)
	_controles_toque.mostrar_acao(&"defesa", _jogador.ficha.tem_talento(Ficha.TALENTO_DUELISTA_DEFENSIVO))
	_controles_toque.mostrar_acao(&"investida", _jogador.ficha.tem_talento(Ficha.TALENTO_INVESTIDA))
	_controles_toque.mostrar_acao(&"dado_de_vida", _jogador.ficha.dados_de_vida() > 0)
	_controles_toque.mostrar_acao(&"veneno", _jogador.doses_de_veneno() > 0 or _jogador.veneno_na_arma() != &"" or _jogador.tem_item_veneno())
	_controles_toque.mostrar_acao(&"folego", _jogador.usos_folego_total() > 0)
	_controles_toque.mostrar_acao(&"arremessar", _jogador.inventario.equipado(Item.ESPACO_MAO) != null)
	_controles_toque.definir_interacao(_rotulo_de_interacao())
	_acender_habilidades()


## Habilidade ativa = botão aceso; desligada ou sem uso = botão avermelhado; pronta = botão normal.
func _acender_habilidades() -> void:
	var estado_do_surto := BotaoToque.EstadoBotao.NORMAL
	if _jogador.surto_ativo():
		estado_do_surto = BotaoToque.EstadoBotao.ACESO
	elif _surto_usado:
		estado_do_surto = BotaoToque.EstadoBotao.DESLIGADO
	_controles_toque.definir_estado(&"surto_acao", estado_do_surto)
	_controles_toque.definir_estado(&"mente_tatica", BotaoToque.EstadoBotao.ACESO if _jogador.mente_tatica_ligada() else BotaoToque.EstadoBotao.DESLIGADO)
	_controles_toque.definir_estado(&"sorte", _estado_da_sorte())
	_controles_toque.definir_estado(&"defesa", _estado_da_defesa())
	_controles_toque.definir_estado(&"dado_de_vida", BotaoToque.EstadoBotao.NORMAL if _jogador.dados_de_vida_restantes() > 0 else BotaoToque.EstadoBotao.DESLIGADO)
	_controles_toque.definir_estado(&"veneno", BotaoToque.EstadoBotao.ACESO if _jogador.veneno_na_arma() != &"" else BotaoToque.EstadoBotao.NORMAL)
	_controles_toque.definir_estado(&"investida", BotaoToque.EstadoBotao.ACESO if _jogador.investida_empurra() else BotaoToque.EstadoBotao.NORMAL)
	_controles_toque.definir_estado(&"folego", BotaoToque.EstadoBotao.NORMAL if _jogador.usos_folego() > 0 else BotaoToque.EstadoBotao.DESLIGADO)


func _ao_mudar_interagivel(perto: bool, rotulo: String) -> void:
	_interagiveis_perto[rotulo] = maxi(_interagiveis_perto.get(rotulo, 0) + (1 if perto else -1), 0)
	_atualizar_botoes_toque()


## "Abrir" ou "Pegar" se há algo perto (o baú vem primeiro); vazio se não há nada.
func _rotulo_de_interacao() -> String:
	for rotulo in [ROTULO_ABRIR, ROTULO_PEGAR]:
		if _interagiveis_perto.get(rotulo, 0) > 0:
			return rotulo
	return ""


func _atualizar_controles_toque() -> void:
	_controles_toque.atualizar(_em_tela_de_pausa or get_tree().paused)


## Ajustar os controles de toque: o jogo fica pausado até o Pronto.
func _editar_toque() -> void:
	_voltar_para_pausa = false
	get_tree().paused = true
	_controles_toque.editar()


## Põe uma cópia da criatura à frente do herói. Não entra na lista do "Tentar de novo".
func trazer_criatura(cena: PackedScene) -> void:
	if cena == null:
		return
	var monstro: Node2D = cena.instantiate()
	monstro.add_to_group(GRUPO_MONSTROS)
	add_child(monstro)
	var frente := Vector2(EscalaDnd.pes_para_pixels(DISTANCIA_CRIATURA_PES) * _jogador.direcao_olhar, 0.0)
	monstro.global_position = _jogador.global_position + frente
	_registrar_no_bestiario(monstro)
	if monstro.has_method(&"definir_alvo"):
		monstro.call(&"definir_alvo", _jogador)
	_passar_percepcao(monstro)
	_passar_luz_do_sol(monstro)


## Apaga os monstros que estão na fase (a cota e os trazidos). A porta fica livre.
func tirar_criaturas() -> void:
	_ids_da_cota.clear()
	_missao = Missao.new()
	_mostrar_missao()
	_apagar_monstros()
	if _heroi_na_porta:
		_tentar_atravessar.call_deferred()


## Telas de pausa (título, criação, derrota) param o jogo e escondem o HUD.
func _pausar(pausar: bool) -> void:
	_em_tela_de_pausa = pausar
	get_tree().paused = pausar
	_hud.visible = not pausar
	_controles_toque.atualizar(pausar)


func _mostrar_personagem_no_hud() -> void:
	_atualizar_botoes_toque()
	_hud.mostrar_personagem(_jogador.ficha.nome, _jogador.ficha.classe.nome)
	_hud.mostrar_vida(_jogador.vida_atual(), _jogador.vida_maxima())
	_hud.mostrar_folego(_jogador.usos_folego(), _jogador.usos_folego_total())
	_hud.mostrar_progressao(_jogador.ficha.nivel, _jogador.ficha.experiencia, _jogador.ficha.xp_proximo_nivel())
	_hud.mostrar_surto(_jogador.ficha.nivel, not _surto_usado)


func _ao_mudar_progressao(nivel: int, experiencia: int, proximo_nivel: int) -> void:
	_hud.mostrar_investida(_jogador.ficha != null and _jogador.ficha.tem_talento(Ficha.TALENTO_INVESTIDA), _jogador.investida_empurra())
	_pausa.mostrar_talento(_jogador.ficha != null and _jogador.ficha.escolhas_de_talento_pendentes() > 0)
	if _jogador.ficha != null and _jogador.ficha.escolhas_de_talento_pendentes() > 0 and not _em_tela_de_pausa:
		_abrir_talento.call_deferred()
	_atualizar_botoes_toque()
	_hud.mostrar_progressao(nivel, experiencia, proximo_nivel)
	_hud.mostrar_surto(nivel, not _surto_usado)

