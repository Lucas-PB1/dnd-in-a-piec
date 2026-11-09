extends TesteBase
## A missão da fase: texto, contagem das mortes da cota e a linha na HUD.


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var missao := Missao.new("Limpe a clareira", 3)
	_checar(missao.existe() and not missao.cumprida(), "com 3 inimigos há missão e ela não está cumprida")
	_checar(missao.texto() == "Limpe a clareira: derrote todos os inimigos", "o texto não revela quantos inimigos há")
	missao.registrar_morte()
	missao.registrar_morte()
	_checar(missao.feitos == 2 and not missao.cumprida() and "/" not in missao.texto(), "duas mortes contam por dentro, sem aparecer no texto")
	missao.registrar_morte()
	missao.registrar_morte()  # morte a mais não passa do total
	_checar(missao.cumprida() and missao.feitos == 3 and "cumprida" in missao.texto(), "terceira morte cumpre e não passa do total")
	_checar(not Missao.new("X", 0).existe(), "sem inimigos não há missão")
	_checar(Missao.new("Limpe o pântano", 4, "Ankheg").texto() == "Limpe o pântano: derrote o Ankheg", "na fase de chefe o texto pede o chefe")
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	await physics_frame
	var rotulo := cena.get_node("Hud").find_child("Missao", true, false) as Label
	_checar(rotulo.visible and "Limpe a clareira" in rotulo.text and "/" not in rotulo.text, "a HUD mostra a missão da fase 1 sem a quantidade")
	cena.tirar_criaturas()
	_checar(not rotulo.visible, "sem inimigos a linha some")
	quit(_falhas)
