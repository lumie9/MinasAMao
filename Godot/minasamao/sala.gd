extends Node3D

@export var cena_destino: String = "res://cena/expos_1.tscn"
@export var exposicao: String = "expo1"

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", cena_destino)
