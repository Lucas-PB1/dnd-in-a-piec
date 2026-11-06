class_name Hud
extends CanvasLayer
## Informações na tela durante o jogo: nome e classe do personagem e pontos de vida.

signal mente_tatica_mudou(ligada: bool)

@onready var _personagem: Label = %Personagem
@onready var _vida: Label = %Vida
@onready var _folego: Label = %Folego
@onready var _progressao: Label = %Progressao
@onready var _surto: Label = %Surto
@onready var _mente_tatica: CheckButton = %MenteTatica


func _ready() -> void:
	_mente_tatica.toggled.connect(func(ligada: bool) -> void: mente_tatica_mudou.emit(ligada))


## Mostra "Nome (Classe)".
func mostrar_personagem(nome: String, classe: String) -> void:
	_personagem.text = "%s (%s)" % [nome, classe]


## Mostra a vida no formato "PV 12/12".
func mostrar_vida(atual: int, maxima: int) -> void:
	_vida.text = "PV %d/%d" % [atual, maxima]


## Mostra os usos do Second Wind ("Fôlego 2/2"). Total 0 some com a linha.
func mostrar_folego(restantes: int, total: int) -> void:
	if total <= 0:
		_folego.text = ""
		return
	_folego.text = "Fôlego %d/%d" % [restantes, total]


func mostrar_progressao(nivel: int, experiencia: int, proximo_nivel: int) -> void:
	if proximo_nivel <= 0:
		_progressao.text = "Nível %d · XP %d (máximo)" % [nivel, experiencia]
		return
	_progressao.text = "Nível %d · XP %d/%d" % [nivel, experiencia, proximo_nivel]


func mostrar_surto(nivel: int, disponivel: bool) -> void:
	if nivel < Ficha.NIVEL_HABILIDADES_GUERREIRO:
		_surto.text = "Surto de Ação · nível 2"
		return
	_surto.text = "Surto de Ação · %s" % ("pronto" if disponivel else "usado nesta fase")


func marcar_mente_tatica(ligada: bool, habilitada: bool = true) -> void:
	_mente_tatica.set_pressed_no_signal(ligada)
	_mente_tatica.disabled = not habilitada
	_mente_tatica.text = "Mente Tática: %s" % ("ligada" if ligada else "desligada")
