class_name HurtboxComponent
extends Area2D
## Área que pode ser atingida. Não sabe o que fazer com o golpe: só avisa pelo sinal
## (normalmente quem escuta é um DefesaComponent). Coloque um CollisionShape2D como filho
## e ajuste a camada (ex.: hurtbox_inimigo ou hurtbox_jogador).

## Emitido quando um HitboxComponent encosta nesta área.
signal golpe_recebido(golpe: Golpe, origem: Vector2)


## Chamado pelo HitboxComponent que encostou.
func receber_golpe(golpe: Golpe, origem: Vector2) -> void:
	golpe_recebido.emit(golpe, origem)
