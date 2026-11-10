class_name Flanqueio
extends RefCounted
## Flanqueio dos monstros: só manobra, sem vantagem no ataque (decisão do usuário). Quando um aliado já segura o
## herói de perto, outro dá a volta e o pega pelo lado oposto. Num jogo lateral, "lado" é esquerda ou direita do alvo.
## Regra pura.


## Esquerda (-1) ou direita (1) do alvo; em cima do alvo conta como direita.
static func lado(alvo_x: float, x: float) -> int:
	return -1 if x < alvo_x else 1
