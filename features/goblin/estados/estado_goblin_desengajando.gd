extends EstadoGoblin
## Fuga Ágil (ação bônus): Desengaja e corre para longe do alvo, ainda olhando para ele.
## Para quando percorreu a distância da fuga ou bateu numa parede.

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	goblin.virar_para_alvo()
	goblin.tocar(&"correr")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	goblin.recuar()
	if _tempo >= goblin.tempo_de_fuga() or goblin.is_on_wall():
		goblin.parar()
		if goblin.esconde_de_novo():
			goblin.reiniciar_furtividade()
			trocar_para.emit(&"Escondido")
		else:
			trocar_para.emit(&"Perseguindo")
