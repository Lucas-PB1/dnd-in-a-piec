class_name HurtboxComponent
extends Area2D
## Área que pode ser atingida. Não sabe o que fazer com o golpe: só avisa o dono pelo sinal.
## Coloque um CollisionShape2D como filho e ajuste a camada (ex.: hurtbox_inimigo).

## Emitido quando um HitboxComponent acerta esta área.
signal golpe_recebido(dano: int, origem: Vector2)


## Chamado pelo HitboxComponent que acertou.
func receber_golpe(dano: int, origem: Vector2) -> void:
	golpe_recebido.emit(dano, origem)
