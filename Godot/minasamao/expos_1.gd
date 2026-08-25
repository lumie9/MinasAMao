extends Node3D

const GERADOR = preload("res://componentes/gerador_quadros.gd")

func _ready():
	# conecta a Area3D da porta para voltar ao world
	$Area3D.body_entered.connect(_on_body_entered)
	call_deferred("_gerar_quadros")

func _gerar_quadros():
	var gerador = GERADOR.new()
	add_child(gerador)
	gerador.gerar(self, "res://dados/expo1/obras.cfg")

func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", "res://cena/world.tscn")
