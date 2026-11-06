extends EstadoJogador
## Correndo no chão (entrou com dois toques ou segurando "correr"). Soltou, inverteu a
## direção ou largou o "correr" com que entrou -> Andando.

var _direcao_corrida: float = 0.0
## Entrou segurando "correr": largar o botão (ou o analógico voltar do fim) volta a andar.
var _pelo_botao: bool = false


func entrar() -> void:
	var dir := jogador.direcao()
	_direcao_corrida = signf(dir) if dir != 0.0 else float(jogador.direcao_olhar)
	_pelo_botao = jogador.correr_segurado()


func processar_fisica(delta: float) -> void:
	var dir := jogador.direcao()
	jogador.mover_horizontal(dir, jogador.velocidade_corrida(), delta)
	if _foi_atacar() or _foi_arremessar() or _foi_para_o_ar():
		return
	if dir == 0.0 or signf(dir) != _direcao_corrida or (_pelo_botao and not jogador.correr_segurado()):
		trocar_para.emit(&"Andando")
