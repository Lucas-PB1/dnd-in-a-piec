class_name TelaIntroLore
extends Control
## Intro de lore após a criação: mostra o texto e avisa Continuar/Pular. Não conhece o herói.

## Jogador leu (ou pulou) e quer começar.
signal seguir_pedido

@onready var _titulo: Label = %Titulo
@onready var _texto: Label = %Texto
@onready var _continuar: Button = %Continuar
@onready var _pular: Button = %Pular


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continuar.pressed.connect(seguir_pedido.emit)
	_pular.pressed.connect(seguir_pedido.emit)
	_continuar.grab_focus()


## Preenche título e corpo a partir do Resource (ou deixa o padrão da cena).
func configurar(lore: IntroLoreRPG) -> void:
	if lore == null:
		return
	if not lore.titulo.is_empty():
		_titulo.text = lore.titulo
	if not lore.texto.is_empty():
		_texto.text = lore.texto
