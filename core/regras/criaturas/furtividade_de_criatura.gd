class_name FurtividadeDeCriatura
extends RefCounted
## Capacidade de furtividade da ficha (`tem_furtividade`, bônus, `esconde_de_novo`).
## Rolagem secreta contra Percepção passiva e emboscada; esconder/revelar (sprite/colisão) fica na feature.

var _criatura: CriaturaRPG
## Percepção passiva de quem olha. 0 = o monstro sempre se esconde no teste.
var percepcao_passiva: int = 0
var _rolou: bool = false
var _foi_percebido: bool = false
var _emboscada: bool = false


func _init(criatura: CriaturaRPG) -> void:
	_criatura = criatura


static func tem_furtividade(criatura: CriaturaRPG) -> bool:
	return criatura.tem_furtividade


func tem() -> bool:
	return tem_furtividade(_criatura)


func esconde_de_novo() -> bool:
	return _criatura.esconde_de_novo


func teste_secreto_feito() -> bool:
	return _rolou


func foi_percebido() -> bool:
	return _foi_percebido


func tem_emboscada() -> bool:
	return _emboscada


## Uma vez, contra a passiva. Sem texto: o jogador só vê o monstro aparecer ou não.
func rolar(rng: RandomNumberGenerator) -> void:
	if _rolou:
		return
	_rolou = true
	var rolagem := rng.randi_range(1, Combate.FACES_D20) + _criatura.bonus_furtividade
	_foi_percebido = not Pericia.furtividade_passa(rolagem, percepcao_passiva)


## O primeiro golpe depois de não ser percebido sai com vantagem.
func marcar_emboscada() -> void:
	_emboscada = true


## True se tinha emboscada e gastou (dá vantagem no golpe).
func consumir_emboscada() -> bool:
	if not _emboscada:
		return false
	_emboscada = false
	return true


## Zera o teste secreto para a próxima vez que entrar em Escondido.
func reiniciar() -> void:
	_rolou = false
	_foi_percebido = false


## Emboscada: sem aviso antes do golpe.
func aviso_do_ataque(aviso_ficha: float) -> float:
	return 0.0 if _emboscada else aviso_ficha
