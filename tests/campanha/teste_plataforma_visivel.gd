extends TesteBase
## Prancha da floresta é ilha (grama+rocha), não só faixa verde que some no fundo.
## godot --headless --debug --path . --script res://tests/campanha/teste_plataforma_visivel.gd

const ATLAS := "res://assets/tiles/ladrilhos.png"
const COLUNA_PLATAFORMA := 2
## Na fileira da Clareira (tema 0), a metade de baixo da prancha deve ter pixels opacos (rocha/terra).
const MINIMO_OPAQUE_ABAIXO := 40


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var img: Image = (load(ATLAS) as Texture2D).get_image()
	_checar(img != null, "atlas de ladrilhos carrega")
	var origem := Vector2i(COLUNA_PLATAFORMA * 32, 0)
	var opaque_baixo := 0
	var tem_cinza_ou_marrom := false
	for y in range(16, 32):
		for x in 32:
			var c := img.get_pixelv(origem + Vector2i(x, y))
			if c.a < 0.2:
				continue
			opaque_baixo += 1
			# Rocha cinza ou terra marrom — contraste com o fundo verde.
			if c.r > 0.25 and c.g > 0.25 and absf(c.r - c.g) < 0.15 and c.b < c.g + 0.05:
				tem_cinza_ou_marrom = true
			elif c.r > c.g and c.r > c.b and c.r > 0.3:
				tem_cinza_ou_marrom = true
	_checar(opaque_baixo >= MINIMO_OPAQUE_ABAIXO,
		"prancha da floresta tem corpo abaixo da grama (%d px opacos)" % opaque_baixo)
	_checar(tem_cinza_ou_marrom, "prancha da floresta tem rocha/terra (contraste com o fundo)")
	_terminar("plataforma da floresta visível")
