class_name FerramentasPixel
extends RefCounted
## Ajudantes de pixel art usados pelos geradores de tools/ (armas, armaduras).


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
