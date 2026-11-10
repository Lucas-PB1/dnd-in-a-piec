extends TesteBase
## Teste unitário do ToqueDuplo (não precisa de cena).
## godot --headless --path . --script res://tests/ui/teste_toque_duplo.gd

const QUADRO := 1.0 / 60.0


func _initialize() -> void:
	var t := ToqueDuplo.new(0.25)
	_checar(not t.registrar(1, QUADRO), "primeiro toque não é duplo")
	_checar(not _avancar(t, 5), "sem toque não dispara")
	_checar(t.registrar(1, QUADRO), "segundo toque rápido na mesma direção é duplo")
	_checar(not t.registrar(1, QUADRO), "terceiro toque começa contagem nova")

	t = ToqueDuplo.new(0.25)
	t.registrar(1, QUADRO)
	_checar(not t.registrar(-1, QUADRO), "direções diferentes não contam")

	t = ToqueDuplo.new(0.25)
	t.registrar(1, QUADRO)
	_avancar(t, 30)  # 0,5 s depois
	_checar(not t.registrar(1, QUADRO), "segundo toque lento demais não conta")

	if _falhas == 0:
		print("PASSOU: todos os testes do ToqueDuplo")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## Passa `quadros` sem apertar nada. Retorna true se algum quadro disparou (não deveria).
func _avancar(t: ToqueDuplo, quadros: int) -> bool:
	var disparou := false
	for i in quadros:
		disparou = t.registrar(0, QUADRO) or disparou
	return disparou
