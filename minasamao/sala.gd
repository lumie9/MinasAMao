extends Node3D

@export var cena_destino: String = "res://cena/expos_1.tscn"
@export var caminho_obras: String = "res://dados/expo1/obras.cfg"

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		DadosSala.caminho_obras = caminho_obras
		get_tree().call_deferred("change_scene_to_file", cena_destino)
