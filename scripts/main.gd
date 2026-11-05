extends Node2D
## Cena principal: coloca o herói no início da fase e limita a câmera ao tamanho da fase.

@onready var fase: Node2D = $FaseTeste
@onready var jogador: Jogador = $Jogador


func _ready() -> void:
	var inicio: Marker2D = fase.get_node("InicioJogador")
	jogador.global_position = inicio.global_position
	jogador.posicao_inicial = inicio.global_position
	jogador.reset_physics_interpolation()

	var terreno: TileMapLayer = fase.get_node("Terreno")
	var celulas := terreno.get_used_rect()
	var tam := Vector2(terreno.tile_set.tile_size)
	# Sem as paredes das pontas (1 ladrilho de cada lado) e sem o céu acima da fase.
	var area := Rect2(
		Vector2(celulas.position.x + 1, 0) * tam,
		Vector2(celulas.size.x - 2, celulas.end.y) * tam)
	(jogador.get_node("Camera") as CameraJogador).definir_limites(area)
	# Cair um pouco abaixo do fundo da fase = buraco.
	jogador.limite_queda = area.end.y + 64.0
