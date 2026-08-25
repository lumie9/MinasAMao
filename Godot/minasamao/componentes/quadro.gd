extends Node3D

@export var id_quadro: String = "quadro_1"
@export var caminho_cfg: String = "res://dados/expo1/obras.cfg"

@onready var material_quadro = $MeshInstance3D2

var Dados: Dictionary = {} 

func _ready() -> void:
	var mat = material_quadro.material_override.duplicate()
	material_quadro.material_override = mat
	_carregar_dados()
	
func _carregar_dados():
	var cfg = ConfigFile.new()
	var erro = cfg.load(caminho_cfg)
	if erro != OK:
		push_error("Quadro não conseguiu carregar " + caminho_cfg)
		return
	Dados = {
		"titulo":   cfg.get_value(id_quadro, "titulo",   "Sem título"),
		"autor":    cfg.get_value(id_quadro, "autor",    "Desconhecido"),
		"tecnica":  cfg.get_value(id_quadro, "tecnica",  ""),
		"tamanho":  cfg.get_value(id_quadro, "tamanho",  ""),
		"ano":      cfg.get_value(id_quadro, "ano",      ""),
		"descricao":cfg.get_value(id_quadro, "descricao",""),
		"fotos":    cfg.get_value(id_quadro, "fotos",    "").split(",", false),
		"artista_nome_completo": cfg.get_value(id_quadro, "artista_nome_completo", ""),
		"artista_instagram":     cfg.get_value(id_quadro, "artista_instagram",     ""),
		"artista_descricao":     cfg.get_value(id_quadro, "artista_descricao",     ""),
	}
	
	var fotos = Dados.get("fotos", [])
	if fotos.size() > 0:
		var tex = load(fotos[0].strip_edges())
		if tex:
			material_quadro.material_override.albedo_texture = tex

func get_info() -> Dictionary:
	print(Dados)
	return Dados

func trocar_foto(caminho: String):
	var tex = load(caminho)
	if tex:
		material_quadro.material_override.albedo_texture = tex
