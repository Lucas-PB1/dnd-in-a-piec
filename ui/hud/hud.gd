class_name Hud
extends CanvasLayer
## Informações na tela durante o jogo: nome e classe, barra de vida, Fôlego em quadradinhos, barra de XP, o estado das habilidades e a barra do chefe.

## Quadradinhos do Fôlego (px) e as cores de aceso e apagado.
const LADO_PONTO := 9.0
const COR_PONTO_CHEIO := Color(0.45, 0.95, 0.55, 1.0)
const COR_PONTO_VAZIO := Color(0.15, 0.2, 0.17, 0.9)
const COR_MISSAO := Color(0.95, 0.9, 0.7, 1.0)
const COR_MISSAO_CUMPRIDA := Color(0.55, 0.95, 0.62, 1.0)

@onready var _personagem: Label = %Personagem
@onready var _vida: Label = %Vida
@onready var _folego: Label = %Folego
@onready var _progressao: Label = %Progressao
@onready var _ouro: Label = %Ouro
@onready var _missao: Label = %Missao
@onready var _surto: Label = %Surto
@onready var _sorte: Label = %Sorte
@onready var _investida: Label = %Investida
@onready var _dados_de_vida: Label = %DadosDeVida
@onready var _veneno: Label = %Veneno
@onready var _barra_vida: ProgressBar = %BarraVida
@onready var _barra_xp: ProgressBar = %BarraXp
@onready var _pontos_folego: HBoxContainer = %Pontos
@onready var _chefe: VBoxContainer = %Chefe
@onready var _nome_chefe: Label = %NomeChefe
@onready var _barra_chefe: ProgressBar = %BarraChefe


## Mostra "Nome (Classe)".
func mostrar_personagem(nome: String, classe: String) -> void:
	_personagem.text = "%s (%s)" % [nome, classe]


## Mostra a vida no formato "PV 12/12".
func mostrar_vida(atual: int, maxima: int) -> void:
	_vida.text = "PV %d/%d" % [atual, maxima]
	_barra_vida.max_value = maxi(maxima, 1)
	_barra_vida.value = atual


## A barra de vida do chefe, no alto da tela (o nome e os pontos de vida que restam).
func mostrar_chefe(atual: int, maxima: int, nome: String) -> void:
	_chefe.visible = true
	_nome_chefe.text = nome
	_barra_chefe.max_value = maxi(maxima, 1)
	_barra_chefe.value = atual


## O chefe caiu (ou a fase não tem): some a barra.
func esconder_chefe() -> void:
	_chefe.visible = false


## Mostra os usos do Second Wind ("Fôlego 2/2"). Total 0 some com a linha.
func mostrar_folego(restantes: int, total: int) -> void:
	if total <= 0:
		_folego.text = ""
		_atualizar_pontos(0, 0)
		return
	_folego.text = "Fôlego %d/%d" % [restantes, total]
	_atualizar_pontos(restantes, total)


func mostrar_progressao(nivel: int, experiencia: int, proximo_nivel: int) -> void:
	if proximo_nivel <= 0:
		_progressao.text = "Nível %d · XP %d (máximo)" % [nivel, experiencia]
		_barra_xp.max_value = 1
		_barra_xp.value = 1
		return
	_progressao.text = "Nível %d · XP %d/%d" % [nivel, experiencia, proximo_nivel]
	_barra_xp.max_value = maxi(proximo_nivel, 1)
	_barra_xp.value = experiencia


## A linha da missão da fase. Texto vazio some; cumprida ela fica verde.
func mostrar_missao(texto: String, cumprida: bool) -> void:
	_missao.visible = texto != ""
	_missao.text = texto
	_missao.add_theme_color_override(&"font_color", COR_MISSAO_CUMPRIDA if cumprida else COR_MISSAO)


## Mostra o ouro em peças ("Ouro 12").
func mostrar_ouro(ouro: int) -> void:
	_ouro.text = "Ouro %d" % ouro


## Um quadradinho por uso do Fôlego: aceso se ainda há, apagado se já foi gasto.
func _atualizar_pontos(restantes: int, total: int) -> void:
	for ponto in _pontos_folego.get_children():
		ponto.queue_free()
	for i in total:
		var ponto := ColorRect.new()
		ponto.custom_minimum_size = Vector2(LADO_PONTO, LADO_PONTO)
		ponto.color = COR_PONTO_CHEIO if i < restantes else COR_PONTO_VAZIO
		_pontos_folego.add_child(ponto)


## A linha dos dados de vida (Durável). Sem dados some.
func mostrar_dados_de_vida(restantes: int, total: int) -> void:
	_dados_de_vida.visible = total > 0
	_dados_de_vida.text = "Dados de vida %d/%d" % [restantes, total]


## A linha do veneno: doses (Envenenador), frasco pronto na arma certa, ou já na lâmina. Sem nada some.
func mostrar_veneno(doses: int, total: int, aplicado: bool, frasco_pronto: bool = false) -> void:
	_veneno.visible = total > 0 or aplicado or frasco_pronto
	if total > 0:
		_veneno.text = "Veneno %d/%d%s" % [doses, total, " · na arma" if aplicado else ""]
	elif aplicado:
		_veneno.text = "Veneno · na arma"
	elif frasco_pronto:
		_veneno.text = "Veneno · N na arma"
	else:
		_veneno.text = ""

## A linha da Investida (talento): qual modo vale agora, empurrão ou dano. Sem o talento some.
func mostrar_investida(tem: bool, empurra: bool) -> void:
	_investida.visible = tem
	_investida.text = "Investida: %s" % ("empurrão" if empurra else "dano")

## A linha da Sorte (Sortudo): pontos que restam e se a próxima rolagem está com a sorte armada. Total 0 some.
func mostrar_sorte(pontos: int, total: int, armada: bool) -> void:
	_sorte.visible = total > 0
	_sorte.text = "Sorte %d/%d%s" % [pontos, total, " · armada" if armada else ""]


func mostrar_surto(nivel: int, disponivel: bool, ativo: bool = false) -> void:
	_surto.visible = nivel >= Ficha.NIVEL_HABILIDADES_GUERREIRO  # só mostra o que o herói já tem
	if ativo:
		_surto.text = "Surto de Ação · ativo"
	else:
		_surto.text = "Surto de Ação · %s" % ("pronto" if disponivel else "usado nesta fase")
