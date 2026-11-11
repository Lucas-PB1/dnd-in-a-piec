extends TesteBase
## Saque: ouro (Intimidação) e arma (Sobrevivência).


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_checar(Saque.ouro(0, 3, rng) == 0, "criatura sem ouro não solta nada")
	_checar(Saque.ouro(1, -5, rng) >= 1, "quem vale ouro solta pelo menos 1")
	_checar(_media_do_ouro(10, 0) > 8.0 and _media_do_ouro(10, 0) < 12.0, "bônus 0: o ouro fica em volta do valor da criatura")
	_checar(_media_do_ouro(10, 3) > _media_do_ouro(10, 0) * 1.2, "Intimidação +3 rende bem mais ouro")
	_checar(_media_do_ouro(10, -2) < _media_do_ouro(10, 0), "Intimidação negativa rende menos ouro")
	_checar(is_equal_approx(Saque.chance_de_arma(0), Saque.CHANCE_BASE_DE_ARMA), "Sobrevivência 0: chance base de arma")
	_checar(Saque.chance_de_arma(3) > Saque.chance_de_arma(0), "Sobrevivência maior aumenta a chance de arma")
	_checar(Saque.chance_de_arma(-5) >= Saque.CHANCE_MINIMA_DE_ARMA, "a chance nunca some de vez")
	_checar(Saque.chance_de_arma(20) <= Saque.CHANCE_MAXIMA_DE_ARMA, "a chance tem teto")
	_checar(_armas_em(400, 5) > _armas_em(400, -2), "na prática, mais Sobrevivência solta mais armas")
	var arma := _primeira_arma()
	_checar(arma is Arma, "o saque é sempre uma arma (nunca armadura)")
	_terminar("saque de ouro e armas")


func _media_do_ouro(valor: int, intimidacao: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var total := 0
	for i in 500:
		total += Saque.ouro(valor, intimidacao, rng)
	return total / 500.0


func _armas_em(vezes: int, sobrevivencia: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var quantas := 0
	for i in vezes:
		if Saque.arma(sobrevivencia, rng) != null:
			quantas += 1
	return quantas


func _primeira_arma() -> Item:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 200:
		var item := Saque.arma(20, rng)
		if item != null:
			return item
	return null
