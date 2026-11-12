extends SceneTree
## Monta as animações de um personagem gerado por IA (Gemini): cada tira vem de um pedido separado e com o
## personagem numa escala diferente. Aqui tira o fundo, separa os quadros, mede o personagem (cabeça aos pés)
## num quadro de referência de cada tira e ajusta todas para a mesma altura, com os pés alinhados num quadro
## comum. Salva uma tira PNG por animação e uma prévia ao lado do herói e do Goblin Warrior.
## Rodar (sem --debug):
##   godot --headless --path . --script res://tools/montar_tiras_gemini.gd -- PASTA_SAIDA PREFIXO ALTURA_PX PREVIA.png \
##       arquivo.png:nome:quadros:quadro_de_referencia ...   (referência: começa em 0; o quadro precisa mostrar o corpo inteiro)

const TOLERANCIA_FUNDO := 0.12
## Franja clara na borda: pixels da borda a até esta distância da cor do fundo somem (contorno escuro não é tocado).
const TOLERANCIA_FRANJA := 0.3
const ALTURA_HEROI := 73
const ALTURA_WARRIOR := 49
const AMPLIACAO := 3
const MARGEM := 8
## Quanto a arma pode passar da divisa do quadro, em px da imagem original.
const FOLGA_LATERAL := 60
const COR_PAINEL := Color(0.16, 0.16, 0.2)
const ARTE_HEROI := "res://features/jogador/sprites/heroi_base.png"
const ARTE_WARRIOR := "res://features/humanoides/sprites/warrior_base_spritecook.png"

## Centro do corpo (x) da última tira medida por `_quadros`.
var _ancora_ultima: float = 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 5:
		push_error("Uso: -- PASTA PREFIXO ALTURA_PX PREVIA.png arquivo:nome:quadros:referencia ...")
		quit(1)
		return
	var altura := int(args[2])
	var animacoes: Dictionary = {}  # nome -> Array[Image]
	var ancoras: Dictionary = {}  # nome -> x (px, no quadro já na escala) do centro do corpo no quadro de referência
	for i in range(4, args.size()):
		var partes: PackedStringArray = args[i].rsplit(":", true, 3)
		animacoes[partes[1]] = _quadros(partes[0], int(partes[2]), int(partes[3]), altura)
		ancoras[partes[1]] = _ancora_ultima
	var canvas := _tamanho_comum(animacoes, ancoras)
	print("Quadro comum: %dx%d" % [canvas.x, canvas.y])
	var prontas: Dictionary = {}
	for nome in animacoes:
		prontas[nome] = _no_canvas(animacoes[nome], canvas, ancoras[nome])
		_salvar_tira(prontas[nome], canvas, "%s/%s_%s.png" % [args[0], args[1], nome])
	_salvar_previa(prontas, canvas, args[3])
	quit(0)


## Quadros de uma tira, já na escala certa. A escala sai do quadro de referência (altura do desenho = `altura`).
func _quadros(caminho: String, quantidade: int, referencia: int, altura: int) -> Array[Image]:
	var tira := Image.load_from_file(caminho)
	tira.convert(Image.FORMAT_RGBA8)
	var cor_fundo := tira.get_pixel(0, 0)
	FerramentasPixel.tirar_fundo(tira, TOLERANCIA_FUNDO)
	FerramentasPixel.limpar_franja(tira, cor_fundo, TOLERANCIA_FRANJA)
	var passo := float(tira.get_width()) / quantidade
	var fatias := _separar_por_formas(tira, quantidade, passo)
	var escala := float(altura) / fatias[referencia].get_used_rect().size.y
	var recorte := _uniao(fatias)
	# O corpo (e não a união dos quadros, que muda com o fogo, o bote e as asas) é que fica no meio: assim o personagem não
	# "pula de lado" ao trocar de animação.
	_ancora_ultima = (fatias[referencia].get_used_rect().get_center().x - recorte.position.x) * escala
	var saida: Array[Image] = []
	for fatia in fatias:
		var quadro := fatia.get_region(recorte)
		quadro.resize(roundi(recorte.size.x * escala), roundi(recorte.size.y * escala), Image.INTERPOLATE_NEAREST)
		FerramentasPixel.endurecer_alfa(quadro)
		saida.append(quadro)
	print("%s: %d quadros, desenho %dx%d (escala %.3f)" % [caminho.get_file(), quantidade, saida[0].get_width(), saida[0].get_height(), escala])
	return saida


## Cada forma conectada do desenho (corpo com espada e escudo) vai inteira para o quadro em que está o centro dela.
## Uma espada que passa da divisa não é cortada nem aparece no quadro vizinho. Cada quadro ganha uma folga lateral.
func _separar_por_formas(tira: Image, quantidade: int, passo: float) -> Array[Image]:
	var largura := tira.get_width()
	var altura := tira.get_height()
	var quadros: Array[Image] = []
	for i in quantidade:
		quadros.append(Image.create_empty(largura + 2 * FOLGA_LATERAL, altura, false, Image.FORMAT_RGBA8))
	var visitado := PackedByteArray()
	visitado.resize(largura * altura)
	for inicio in largura * altura:
		if visitado[inicio] == 1 or tira.get_pixel(inicio % largura, inicio / largura).a == 0.0:
			continue
		var forma := _forma_a_partir_de(tira, inicio, visitado)
		var soma_x := 0
		for indice in forma:
			soma_x += indice % largura
		var quadro := clampi(int(float(soma_x) / forma.size() / passo), 0, quantidade - 1)
		for indice in forma:
			quadros[quadro].set_pixel(indice % largura + FOLGA_LATERAL, indice / largura, tira.get_pixel(indice % largura, indice / largura))
	var saida: Array[Image] = []
	for i in quantidade:
		saida.append(quadros[i].get_region(Rect2i(roundi(i * passo), 0, floori(passo) + 2 * FOLGA_LATERAL, altura)))
	return saida


## Todos os pixels opacos ligados a `inicio` (8 vizinhos).
func _forma_a_partir_de(tira: Image, inicio: int, visitado: PackedByteArray) -> PackedInt32Array:
	var largura := tira.get_width()
	var altura := tira.get_height()
	var forma := PackedInt32Array()
	var pilha := PackedInt32Array([inicio])
	visitado[inicio] = 1
	while not pilha.is_empty():
		var atual := pilha[pilha.size() - 1]
		pilha.resize(pilha.size() - 1)
		forma.append(atual)
		var x := atual % largura
		var y := atual / largura
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx := x + dx
				var ny := y + dy
				if nx < 0 or ny < 0 or nx >= largura or ny >= altura:
					continue
				var vizinho := ny * largura + nx
				if visitado[vizinho] == 0 and tira.get_pixel(nx, ny).a > 0.0:
					visitado[vizinho] = 1
					pilha.append(vizinho)
	return forma


func _uniao(fatias: Array[Image]) -> Rect2i:
	var uniao := fatias[0].get_used_rect()
	for fatia in fatias:
		uniao = uniao.merge(fatia.get_used_rect())
	return uniao


## Quadro comum: largura simétrica em volta da âncora (o centro do corpo) que cabe todas as animações; altura do mais alto.
func _tamanho_comum(animacoes: Dictionary, ancoras: Dictionary) -> Vector2i:
	var meia_largura := 0.0
	var altura := 0
	for nome in animacoes:
		var quadros: Array[Image] = animacoes[nome]
		var ancora: float = ancoras[nome]
		meia_largura = maxf(meia_largura, maxf(ancora, quadros[0].get_width() - ancora))
		altura = maxi(altura, quadros[0].get_height())
	return Vector2i(ceili(meia_largura) * 2, altura)


## Pés embaixo, corpo (âncora) no centro: todo quadro vai para o mesmo tamanho de quadro.
func _no_canvas(quadros: Array[Image], canvas: Vector2i, ancora: float) -> Array[Image]:
	var saida: Array[Image] = []
	for quadro in quadros:
		var folha := Image.create_empty(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
		var destino := Vector2i(roundi(canvas.x / 2.0 - ancora), canvas.y - quadro.get_height())
		folha.blit_rect(quadro, Rect2i(Vector2i.ZERO, quadro.get_size()), destino)
		saida.append(folha)
	return saida


func _salvar_tira(quadros: Array[Image], canvas: Vector2i, caminho: String) -> void:
	var tira := Image.create_empty(canvas.x * quadros.size(), canvas.y, false, Image.FORMAT_RGBA8)
	for i in quadros.size():
		tira.blit_rect(quadros[i], Rect2i(Vector2i.ZERO, canvas), Vector2i(i * canvas.x, 0))
	tira.save_png(caminho)
	print("Tira: " + caminho)


## Uma linha por animação (quadros na altura do jogo) e, embaixo, o herói e o Goblin Warrior para comparar.
func _salvar_previa(animacoes: Dictionary, canvas: Vector2i, caminho: String) -> void:
	var linhas: Array[Array] = []
	for nome in animacoes:
		linhas.append(animacoes[nome])
	linhas.append([_na_altura(_arte(ARTE_HEROI), ALTURA_HEROI), _na_altura(_arte(ARTE_WARRIOR), ALTURA_WARRIOR), animacoes.values()[0][0]])
	var largura := 0
	var altura := MARGEM
	for linha in linhas:
		var soma := MARGEM
		for quadro: Image in linha:
			soma += quadro.get_width() + MARGEM
		largura = maxi(largura, soma)
		altura += _altura_da_linha(linha, canvas.y) + MARGEM
	var painel := Image.create_empty(largura, altura, false, Image.FORMAT_RGBA8)
	painel.fill(COR_PAINEL)
	var y := MARGEM
	for linha in linhas:
		var x := MARGEM
		for quadro: Image in linha:
			painel.blend_rect(quadro, Rect2i(Vector2i.ZERO, quadro.get_size()), Vector2i(x, y + _altura_da_linha(linha, canvas.y) - quadro.get_height()))
			x += quadro.get_width() + MARGEM
		y += _altura_da_linha(linha, canvas.y) + MARGEM
	painel.resize(painel.get_width() * AMPLIACAO, painel.get_height() * AMPLIACAO, Image.INTERPOLATE_NEAREST)
	painel.save_png(caminho)
	print("Prévia: " + caminho)


func _arte(caminho: String) -> Image:
	var imagem := (load(caminho) as Texture2D).get_image()
	imagem.convert(Image.FORMAT_RGBA8)
	return imagem.get_region(imagem.get_used_rect())


func _na_altura(imagem: Image, altura: int) -> Image:
	var copia := imagem.duplicate() as Image
	copia.resize(roundi(copia.get_width() * float(altura) / copia.get_height()), altura, Image.INTERPOLATE_NEAREST)
	return copia


## Altura de uma linha da prévia: a do quadro comum ou a do mais alto (o herói, na última linha).
func _altura_da_linha(linha: Array, altura_canvas: int) -> int:
	var maior := altura_canvas
	for quadro: Image in linha:
		maior = maxi(maior, quadro.get_height())
	return maior
