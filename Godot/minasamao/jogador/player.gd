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
		var botao_cor = _botao_com_painel_aberto()
		if painel and painel.painel.visible:
			painel.fechar()
			_soltar_camera()
		elif botao_cor:
			botao_cor.fechar_painel()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var painel = _encontrar_painel()
			var painel_aberto = (painel and painel.painel.visible) or _botao_com_painel_aberto() != null
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
		# Objetos interagíveis (ex.: botão de cor das paredes)
		var interagivel = _encontrar_interagivel(resultado.collider)
		if interagivel:
			interagivel.interagir()
			get_viewport().set_input_as_handled()  # o mesmo clique não cai no painel que acabou de abrir
			return
		var quadro = _encontrar_quadro(resultado.collider)
		if quadro:
			var painel = _encontrar_painel()
			if painel:
				_travar_camera_em(quadro)
				painel.mostrar(quadro.get_info(), quadro)

func _travar_camera_em(quadro: Node):
	camera_travada = true
	#var player_y_chao = global_position.y - altura_head_original
	#var altura_alvo = quadro.global_position.y - player_y_chao
	
	#print("Quadro Y global: ", quadro.global_position.y)
	#print("Player Y global: ", player_y_chao)
	#print("Altura alvo head: ", altura_alvo)
	var altura_alvo = 3.9
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

func _encontrar_interagivel(no: Node) -> Node:
	var atual = no
	for i in range(3):
		if atual == null:
			break
		if atual.has_method("interagir"):
			return atual
		atual = atual.get_parent()
	return null

# Retorna o botão (grupo "interagivel") cujo painel está aberto, se houver.
func _botao_com_painel_aberto() -> Node:
	for no in get_tree().get_nodes_in_group("interagivel"):
		if no.has_method("painel_aberto") and no.painel_aberto():
			return no
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
