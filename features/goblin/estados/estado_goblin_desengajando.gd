extends EstadoGoblin
## Fuga Ágil (ação bônus): Desengaja e corre para longe do alvo, ainda olhando para ele.
## Na beira, salta o vão/degrau na direção do recuo. Para quando acaba o tempo ou bate numa parede.


func entrar() -> void:
	if goblin.fuga_restante() <= 0.0:
		goblin.iniciar_fuga()
		goblin.virar_para_alvo()
	goblin.tocar(&"correr")


func processar_fisica(delta: float) -> void:
	var costas := -float(goblin.direcao_olhar)
	if goblin.is_on_wall() or not goblin.tem_chao_na(costas):
		var plano := goblin.planejar_salto(costas)
		if plano.tipo != SaltoDnd.Tipo.NENHUM:
			goblin.iniciar_salto(plano, costas, &"Desengajando")
			trocar_para.emit(&"Pulando")
			return
	goblin.recuar()
	if goblin.tick_fuga(delta) or goblin.is_on_wall():
		goblin.parar()
		goblin.limpar_fuga()
		if goblin.esconde_de_novo():
			goblin.reiniciar_furtividade()
			trocar_para.emit(&"Escondido")
		else:
			trocar_para.emit(&"Perseguindo")
