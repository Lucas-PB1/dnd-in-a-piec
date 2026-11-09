class_name FerramentasPixel
extends RefCounted
## Ajudantes de pixel art usados pelos geradores de tools/ (armas, armaduras).

## Para as ilhas de fundo (dentro de um arco), a tolerância é esta fração da usada nas bordas: só a cor quase exata.
const FRACAO_TOLERANCIA_ILHAS := 0.4

## Reduz para `tamanho` escolhendo, em cada bloco, o pixel opaco de luz mediana: as linhas
## finas (hastes diagonais de 1 px) não somem, como sumiriam pegando um pixel fixo.
static func reduzir(img: Image, tamanho: int) -> Image:
	var bloco := img.get_width() / tamanho
	var saida := Image.create(tamanho, tamanho, false, Image.FORMAT_RGBA8)
	for y in tamanho:
		for x in tamanho:
			var opacos: Array[Color] = []
			for dy in bloco:
				for dx in bloco:
					var cor := img.get_pixel(x * bloco + dx, y * bloco + dy)
					if cor.a > 0.0:
						opacos.append(cor)
			if opacos.is_empty():
				continue
			opacos.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
			saida.set_pixel(x, y, opacos[opacos.size() / 2])
	return saida


## Apaga o fundo liso: anda a partir das bordas e tira o que for parecido com a cor do canto (aguenta degradê leve).
static func tirar_fundo(imagem: Image, tolerancia: float) -> void:
	var largura := imagem.get_width()
	var altura := imagem.get_height()
	var visitado := PackedByteArray()
	visitado.resize(largura * altura)
	var fila: Array[Vector2i] = []
	for x in largura:
		fila.append(Vector2i(x, 0))
		fila.append(Vector2i(x, altura - 1))
	for y in altura:
		fila.append(Vector2i(0, y))
		fila.append(Vector2i(largura - 1, y))
	var referencia := imagem.get_pixel(0, 0)
	while not fila.is_empty():
		var p: Vector2i = fila.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= largura or p.y >= altura or visitado[p.y * largura + p.x] == 1:
			continue
		visitado[p.y * largura + p.x] = 1
		if _distancia_de_cor(imagem.get_pixel(p.x, p.y), referencia) > tolerancia:
			continue
		imagem.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		fila.append_array([p + Vector2i.LEFT, p + Vector2i.RIGHT, p + Vector2i.UP, p + Vector2i.DOWN])
	_apagar_ilhas_de_fundo(imagem, referencia, tolerancia * FRACAO_TOLERANCIA_ILHAS)


## O vazio dentro de um arco ou de uma argola não se liga às bordas: apaga também o que tem a cor quase exata do fundo.
static func _apagar_ilhas_de_fundo(imagem: Image, referencia: Color, tolerancia: float) -> void:
	for y in imagem.get_height():
		for x in imagem.get_width():
			var cor := imagem.get_pixel(x, y)
			if cor.a > 0.0 and _distancia_de_cor(cor, referencia) <= tolerancia:
				imagem.set_pixel(x, y, Color(0, 0, 0, 0))


## Depois de reduzir sem suavizar sobram pixels meio transparentes: ou é opaco ou some.
static func endurecer_alfa(imagem: Image, limiar: float = 0.5) -> void:
	for y in imagem.get_height():
		for x in imagem.get_width():
			var cor := imagem.get_pixel(x, y)
			cor.a = 1.0 if cor.a >= limiar else 0.0
			imagem.set_pixel(x, y, cor)


static func _distancia_de_cor(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


## Tira a franja clara que a IA deixa na borda do desenho (mistura do contorno com o fundo): só mexe em pixels que
## encostam no vazio e ainda têm a cor do fundo. Contorno escuro e cores do corpo ficam.
static func limpar_franja(imagem: Image, referencia: Color, tolerancia: float, passadas: int = 2) -> void:
	for passada in passadas:
		var apagar: Array[Vector2i] = []
		for y in imagem.get_height():
			for x in imagem.get_width():
				var cor := imagem.get_pixel(x, y)
				if cor.a > 0.0 and _distancia_de_cor(cor, referencia) <= tolerancia and _encosta_no_vazio(imagem, x, y):
					apagar.append(Vector2i(x, y))
		for ponto in apagar:
			imagem.set_pixel(ponto.x, ponto.y, Color(0, 0, 0, 0))


static func _encosta_no_vazio(imagem: Image, x: int, y: int) -> bool:
	for vizinho in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
		if vizinho.x < 0 or vizinho.y < 0 or vizinho.x >= imagem.get_width() or vizinho.y >= imagem.get_height():
			return true
		if imagem.get_pixel(vizinho.x, vizinho.y).a == 0.0:
			return true
	return false
