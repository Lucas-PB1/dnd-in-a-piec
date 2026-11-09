class_name EfeitoDanoAdicional
extends EfeitoDeGolpe
## Dano que o acerto soma, de outro tipo (o "mais 7 (3d4) de Veneno" do Hobgoblin). Vale sempre que o golpe acerta;
## o crítico dobra os dados, como no livro. A resistência ao tipo extra não é separada do dano principal.

var dado: Dado


func _init(dado_extra: Dado) -> void:
	id = &"dano_adicional"
	por_rodada = false
	dado = dado_extra


func dano_extra(_golpe: Golpe, rng: RandomNumberGenerator, critico: bool) -> int:
	return dado.rolar(rng, critico)
