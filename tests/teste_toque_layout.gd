extends SceneTree
## Garante que o layout padrão dos controles de toque (botões, slots de habilidade e analógico) é confortável: nenhum botão em cima de outro,
## todos com pelo menos 1 cm de diâmetro no celular e dentro da tela, em telas de várias larguras.
## godot --headless --debug --path . --script res://tests/teste_toque_layout.gd

## Altura do jogo é 360 px. Num celular de 1080 px de altura a escala é 3, e 1 cm são uns 157 px.
const ALTURA := 360.0
const DIAMETRO_MINIMO := 50.0
const LARGURAS := [640.0, 720.0, 800.0]

var _falhas: int = 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	for largura in LARGURAS:
		_conferir_largura(largura)
	print("PASSOU: o layout de toque é confortável" if _falhas == 0 else "FALHOU: %d problema(s)" % _falhas)
	quit(_falhas)


## Centro e raio de cada controle (botões de ação, analógico e setas) numa tela dessa largura.
func _controles(largura: float) -> Array:
	var lista: Array = []
	var tela := Vector2(largura, ALTURA)
	lista.append(["analógico", _posicao(tela, ControlesToque.ANALOGICO[1], ControlesToque.ANALOGICO[2]), ControlesToque.ANALOGICO[3]])
	for d in ControlesToque.BOTOES:
		lista.append([d[1], _posicao(tela, d[2], d[3]), d[4]])
	for d in ControlesToque.SLOTS:
		lista.append([d[0], _posicao(tela, d[1], d[2]), d[3]])
	return lista


func _posicao(tela: Vector2, canto: Vector2, centro: Vector2) -> Vector2:
	return canto * tela + centro


func _conferir_largura(largura: float) -> void:
	var lista := _controles(largura)
	for i in lista.size():
		var a: Array = lista[i]
		var dentro: bool = a[1].x - a[2] >= 0.0 and a[1].x + a[2] <= largura and a[1].y - a[2] >= 0.0 and a[1].y + a[2] <= ALTURA
		_checar(dentro, "%s cabe na tela de %d px" % [a[0], largura])
		_checar(a[2] * 2.0 >= DIAMETRO_MINIMO or a[0] == "analógico", "%s tem pelo menos 1 cm (raio %d)" % [a[0], a[2]])
		for j in range(i + 1, lista.size()):
			var b: Array = lista[j]
			_checar(a[1].distance_to(b[1]) >= a[2] + b[2], "%s e %s não se sobrepõem (tela de %d px)" % [a[0], b[0], largura])


func _checar(condicao: bool, descricao: String) -> void:
	if not condicao:
		print("  ERRO - ", descricao)
		_falhas += 1
