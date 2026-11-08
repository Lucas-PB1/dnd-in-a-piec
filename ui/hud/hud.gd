class_name Hud
extends CanvasLayer
## Informações na tela durante o jogo: nome e classe, barra de vida, Fôlego em quadradinhos, barra de XP e o estado das habilidades.

## Quadradinhos do Fôlego (px) e as cores de aceso e apagado.
const LADO_PONTO := 9.0
const COR_PONTO_CHEIO := Color(0.45, 0.95, 0.55, 1.0)
const COR_PONTO_VAZIO := Color(0.15, 0.2, 0.17, 0.9)

@onready var _personagem: Label = %Personagem
@onready var _vida: Label = %Vida
@onready var _folego: Label = %Folego
@onready var _progressao: Label = %Progressao
@onready var _surto: Label = %Surto
@onready var _barra_vida: ProgressBar = %BarraVida
@onready var _barra_xp: ProgressBar = %BarraXp
@onready var _pontos_folego: HBoxContainer = %Pontos


## Mostra "Nome (Classe)".
func mostrar_personagem(nome: String, classe: String) -> void:
	_personagem.text = "%s (%s)" % [nome, classe]


## Mostra a vida no formato "PV 12/12".
func mostrar_vida(atual: int, maxima: int) -> void:
	_vida.text = "PV %d/%d" % [atual, maxima]
	_barra_vida.max_value = maxi(maxima, 1)
	_barra_vida.value = atual


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


## Um quadradinho por uso do Fôlego: aceso se ainda há, apagado se já foi gasto.
func _atualizar_pontos(restantes: int, total: int) -> void:
	for ponto in _pontos_folego.get_children():
		ponto.queue_free()
	for i in total:
		var ponto := ColorRect.new()
		ponto.custom_minimum_size = Vector2(LADO_PONTO, LADO_PONTO)
		ponto.color = COR_PONTO_CHEIO if i < restantes else COR_PONTO_VAZIO
		_pontos_folego.add_child(ponto)


func mostrar_surto(nivel: int, disponivel: bool, ativo: bool = false) -> void:
	_surto.visible = nivel >= Ficha.NIVEL_HABILIDADES_GUERREIRO  # só mostra o que o herói já tem
	if ativo:
		_surto.text = "Surto de Ação · ativo"
	else:
		_surto.text = "Surto de Ação · %s" % ("pronto" if disponivel else "usado nesta fase")
