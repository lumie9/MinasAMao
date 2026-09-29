extends CharacterBody3D

@onready var head = $Head
@onready var camera = $Head/Camera3D

const SENS = 0.002
var speed := 7.0
var gravity := 12.0
var pitch = 0.0

var camera_travada := false
var altura_quadro := 1
var rotacao_alvo := 0.0
var altura_head_original: float= 0.0  


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	altura_head_original = head.position.y

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		var painel = _encontrar_painel()
		if painel and painel.painel.visible:
			painel.fechar()
			_soltar_camera()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var painel = _encontrar_painel()
			var painel_aberto = painel and painel.painel.visible
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not camera_travada:
				_verificar_quadro()
			elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not painel_aberto:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not camera_travada:
		rotate_y(-event.relative.x * SENS)
		pitch -= event.relative.y * SENS
		pitch = clamp(pitch, -1.5, 1.5)
		head.rotation.x = pitch

func _verificar_quadro():
	var espaco  = get_world_3d().direct_space_state
	var origem  = camera.global_position
	var destino = origem + (-camera.global_transform.basis.z * 4.0)
	var query   = PhysicsRayQueryParameters3D.create(origem, destino)
	query.exclude = [self]

	var resultado = espaco.intersect_ray(query)
	if resultado:
		var quadro = _encontrar_quadro(resultado.collider)
		if quadro:
			var painel = _encontrar_painel()
			if painel:
				_travar_camera_em()
				painel.mostrar(quadro.get_info(), quadro)

func _travar_camera_em():
	camera_travada = true
	# desconta a altura base do head (3.662) para chegar na posição local correta
	var altura_alvo = 4.75
	var tween = create_tween()
	tween.tween_property(head, "position:y", altura_alvo, 0.4)
	tween.parallel().tween_property(head, "rotation:x", 0.0, 0.4)

func _soltar_camera():
	camera_travada = false
	var tween = create_tween()
	tween.tween_property(head, "position:y", altura_head_original, 0.3)

func _encontrar_quadro(no: Node) -> Node:
	var atual = no
	for i in range(4):
		if atual == null:
			break
		if atual.has_method("get_info"):
			return atual
		atual = atual.get_parent()
	return null

func _encontrar_painel() -> Node:
	return _buscar_no(get_tree().current_scene, "PainelInfo")

func _buscar_no(no: Node, nome: String) -> Node:
	if no.name == nome:
		return no
	for filho in no.get_children():
		var r = _buscar_no(filho, nome)
		if r:
			return r
	return null

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if camera_travada:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	var input_dir = Input.get_vector("move_esq", "move_dir", "move_frente", "move_tras")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
