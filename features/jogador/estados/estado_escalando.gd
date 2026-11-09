extends EstadoJogador
## Escalando (talento Atleta): empurrando contra uma parede, o herói sobe por ela na velocidade de andar
## (Deslocamento de Escalada igual ao Deslocamento), sem gravidade, até acabar a parede. No topo, um
## empurrão para cima e para a frente o põe em cima do degrau. Pular solta da parede; soltar o botão
## ou perder a parede troca para NoAr (ou Parado se já estiver no chão).

## Para cima, ao chegar no topo, para passar a quina (px/s).
const IMPULSO_NO_TOPO := 110.0
## Empurrão mínimo contra a parede, para ela continuar encostada (px/s).
const EMPURRAO_NA_PAREDE := 30.0

## Lado da parede (-1 esquerda, 1 direita).
var _lado: float = 1.0


func entrar() -> void:
	_lado = signf(jogador.direcao())
	jogador.velocity.x = _lado * EMPURRAO_NA_PAREDE


func processar_fisica(_delta: float) -> void:
	if Input.is_action_just_pressed("pular"):
		jogador.velocity = Vector2(-_lado * jogador.velocidade_andar(), -jogador.stats.forca_pulo())
		trocar_para.emit(&"NoAr")
		return
	var dir := jogador.direcao()
	if signf(dir) != _lado:
		trocar_para.emit(&"Parado" if jogador.is_on_floor() else &"NoAr")
		return
	if not jogador.is_on_wall():  # chegou no topo da parede
		jogador.velocity = Vector2(_lado * jogador.velocidade_andar(), -IMPULSO_NO_TOPO)
		trocar_para.emit(&"NoAr")
		return
	jogador.velocity = Vector2(_lado * EMPURRAO_NA_PAREDE, -jogador.velocidade_andar())
