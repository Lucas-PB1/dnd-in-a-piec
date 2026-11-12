extends EstadoGoblin
## Ronda: anda devagar até um extremo (a patrulha da ficha, a partir de onde começou) e volta
## a Parado, que depois manda para o outro lado. Na beira, tenta saltar (degrau/vão) e segue.
## Percebeu o alvo, persegue.


func entrar() -> void:
	goblin.tocar(&"correr")


func processar_fisica(_delta: float) -> void:
	if goblin.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
		return
	var destino := goblin.garantir_destino_patrulha()
	var direcao := 1.0 if destino >= goblin.global_position.x else -1.0
	if goblin.is_on_wall() or not goblin.tem_chao_na(direcao):
		var plano := goblin.planejar_salto(direcao)
		if plano.tipo != SaltoDnd.Tipo.NENHUM:
			goblin.iniciar_salto(plano, direcao, &"Patrulhando")
			trocar_para.emit(&"Pulando")
			return
	if goblin.andar_ate(destino):
		goblin.limpar_destino_patrulha()
		trocar_para.emit(&"Parado")
