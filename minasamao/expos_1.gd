extends Node3D

const GERADOR = preload("res://componentes/gerador_quadros.gd")

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	call_deferred("_gerar_quadros")

func _gerar_quadros():
	if DadosSala.caminho_obras == "":
		push_warning("ExposicaoBase: DadosSala.caminho_obras esta vazio.")
		return
	var gerador = GERADOR.new()
	add_child(gerador)
	gerador.gerar(self, DadosSala.caminho_obras)

func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", DadosSala.cena_retorno)
