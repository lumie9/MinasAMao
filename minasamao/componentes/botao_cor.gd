extends StaticBody3D
## Botão de parede que abre um painel para trocar a cor das paredes da sala.
##
## Como funciona:
##  - O player dispara um raycast ao clicar; se o objeto atingido tiver o método
##    `interagir()`, ele é chamado (ver player.gd).
##  - Todas as MeshInstance3D do grupo `grupo_paredes` recebem uma cópia do
##    material original, e o filtro de cor é aplicado em `albedo_color`
##    (multiplica a textura, sem apagar o relevo/desenho dela).
##  - A cor escolhida fica salva enquanto o jogo estiver aberto, por sala.

@export var grupo_paredes: StringName = &"parede_pintavel"

## Cores do filtro (multiplicam a textura). O 1º item é sempre o visual original.
@export var paleta: Array[Color] = [
	Color(1.0, 1.0, 1.0),        # Original (substituído pela cor do material)
	Color(1.0, 0.93, 0.78),      # Creme
	Color(0.85, 0.93, 1.0),      # Azul gelo
	Color(0.80, 0.95, 0.82),     # Verde menta
	Color(1.0, 0.82, 0.82),      # Rosa
	Color(0.95, 0.85, 0.60),     # Ocre
	Color(0.70, 0.78, 0.95),     # Azul colonial
	Color(0.55, 0.55, 0.58),     # Cinza grafite
]
@export var nomes_paleta: PackedStringArray = [
	"Original", "Creme", "Azul gelo", "Verde menta",
	"Rosa", "Ocre", "Azul colonial", "Grafite",
]
@export var duracao_transicao: float = 0.35

# Memória entre trocas de cena (mundo <-> exposição). Chave: .cfg da sala.
static var _cores_salvas: Dictionary = {}

@onready var _luz_botao: MeshInstance3D = $Botao

var _meshes: Array[MeshInstance3D] = []
var _material_filtro: StandardMaterial3D
var _cor_original: Color = Color.WHITE
var _cor_atual: Color = Color.WHITE
var _tween: Tween
var _painel: CanvasLayer
var _seletor: ColorPicker


func _ready() -> void:
	add_to_group("interagivel")
	# Espera um frame: garante que as paredes da cena já estão na árvore.
	await get_tree().process_frame
	_luz_botao.material_override = _luz_botao.material_override.duplicate() as Material
	_preparar_paredes()
	_construir_painel()
	_atualizar_brilho_botao()
	var chave := _chave_sala()
	if _cores_salvas.has(chave):
		_aplicar_cor(_cores_salvas[chave], false)


# --------------------------------------------------------------------------
# Interação (chamado pelo player)
# --------------------------------------------------------------------------
func interagir() -> void:
	if _painel == null:
		return
	_painel.visible = true
	_seletor.color = _cor_atual
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.camera_travada = true


func fechar_painel() -> void:
	if _painel == null or not _painel.visible:
		return
	_painel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.camera_travada = false


func painel_aberto() -> bool:
	return _painel != null and _painel.visible


# --------------------------------------------------------------------------
# Paredes / material
# --------------------------------------------------------------------------
func _chave_sala() -> String:
	# As 4 salas usam a mesma cena; o que muda é o .cfg carregado em DadosSala.
	# Por isso a cor é guardada por .cfg, e cada sala lembra a sua.
	var chave: String = DadosSala.caminho_obras
	if chave == "":
		var cena := get_tree().current_scene
		chave = cena.scene_file_path if cena else "sem_cena"
	return chave


func _preparar_paredes() -> void:
	_meshes.clear()
	for no in get_tree().get_nodes_in_group(grupo_paredes):
		if no is MeshInstance3D:
			_meshes.append(no)

	if _meshes.is_empty():
		push_warning("BotaoCor: nenhum nó no grupo '%s'. Adicione as paredes a esse grupo." % grupo_paredes)
		return

	# Todas as paredes usam o mesmo material (parede_frente.tres). Duplicamos para
	# que a mudança afete só esta sala e não o recurso salvo em disco.
	var original := _meshes[0].material_override as StandardMaterial3D
	if original == null:
		push_warning("BotaoCor: a primeira parede não tem StandardMaterial3D em material_override.")
		return
	_material_filtro = original.duplicate() as StandardMaterial3D
	# A cor original do material (o creme de parede_frente.tres) é o "Original".
	_cor_original = original.albedo_color
	_cor_atual = _cor_original
	for m in _meshes:
		m.material_override = _material_filtro


func _aplicar_cor(cor: Color, animar: bool = true) -> void:
	_cor_atual = cor
	_cores_salvas[_chave_sala()] = cor
	if _material_filtro == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if animar and duracao_transicao > 0.0:
		_tween = create_tween()
		_tween.tween_property(_material_filtro, "albedo_color", cor, duracao_transicao)
	else:
		_material_filtro.albedo_color = cor
	_atualizar_brilho_botao()


func _atualizar_brilho_botao() -> void:
	if _luz_botao and _luz_botao.material_override is StandardMaterial3D:
		(_luz_botao.material_override as StandardMaterial3D).emission = _cor_atual


# --------------------------------------------------------------------------
# Painel de cores (UI criada por código)
# --------------------------------------------------------------------------
func _construir_painel() -> void:
	_painel = CanvasLayer.new()
	_painel.layer = 10
	_painel.visible = false
	add_child(_painel)

	var centro := CenterContainer.new()
	_painel.add_child(centro)
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fundo := PanelContainer.new()
	centro.add_child(fundo)

	var margem := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 16)
	fundo.add_child(margem)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	margem.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "Cor das paredes"
	titulo.add_theme_font_size_override("font_size", 22)
	caixa.add_child(titulo)

	caixa.add_child(HSeparator.new())

	# Grade de cores prontas
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	caixa.add_child(grade)

	for i in paleta.size():
		var cor := paleta[i]
		if i == 0:
			cor = _cor_original   # primeiro item sempre restaura o visual original
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 48)
		b.tooltip_text = nomes_paleta[i] if i < nomes_paleta.size() else ""
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = cor
		estilo.set_corner_radius_all(6)
		estilo.set_border_width_all(2)
		estilo.border_color = Color(0, 0, 0, 0.35)
		b.add_theme_stylebox_override("normal", estilo)
		var estilo_hover := estilo.duplicate() as StyleBoxFlat
		estilo_hover.border_color = Color(1, 1, 1, 0.9)
		b.add_theme_stylebox_override("hover", estilo_hover)
		b.add_theme_stylebox_override("pressed", estilo_hover)
		b.add_theme_stylebox_override("focus", estilo_hover)
		b.pressed.connect(_ao_escolher_cor.bind(cor))
		grade.add_child(b)

	# Cor livre
	var lbl_livre := Label.new()
	lbl_livre.text = "Ou escolha uma cor:"
	caixa.add_child(lbl_livre)

	_seletor = ColorPicker.new()
	_seletor.edit_alpha = false
	_seletor.sampler_visible = false
	_seletor.presets_visible = false
	_seletor.color_modes_visible = false
	_seletor.hex_visible = true
	_seletor.color = _cor_atual
	_seletor.color_changed.connect(_ao_mudar_picker)
	caixa.add_child(_seletor)

	caixa.add_child(HSeparator.new())

	var btn_fechar := Button.new()
	btn_fechar.text = "Fechar [ESC]"
	btn_fechar.pressed.connect(fechar_painel)
	caixa.add_child(btn_fechar)


func _ao_escolher_cor(cor: Color) -> void:
	_aplicar_cor(cor)
	if _seletor and _seletor.color != cor:
		_seletor.color = cor


func _ao_mudar_picker(cor: Color) -> void:
	_aplicar_cor(cor, false)
