class_name EntradaBestiario
extends Resource
## Uma página do bestiário: a criatura (ficha do livro), o retrato e os textos que o jogo mostra.

@export var criatura: CriaturaRPG
## Um quadro parado da criatura.
@export var retrato: Texture2D
## Tamanho e tipo em português (ex.: "Gosma média, sem tendência").
@export var tipo_texto: String = ""
@export_multiline var descricao: String = ""
## Conselho de combate, escrito para o jogador.
@export_multiline var dica: String = ""
