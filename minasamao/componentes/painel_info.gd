extends CanvasLayer

@onready var painel         = $Painel
@onready var lbl_titulo     = $Painel/VBoxGeral/Titulo
@onready var lbl_autor      = $Painel/VBoxGeral/Autor
@onready var lbl_tecnica    = $Painel/VBoxGeral/Tecnica
@onready var lbl_tamanho    = $Painel/VBoxGeral/Tamanho
@onready var lbl_ano        = $Painel/VBoxGeral/Ano
@onready var lbl_descricao  = $Painel/VBoxGeral/Descricao
@onready var btn_fechar     = $Painel/VBoxGeral/BtnFechar
@onready var foto_principal = $Painel/VBoxGeral/Foto
@onready var btn_anterior   = $Painel/VBoxGeral/ContadorRow/BtnAnterior
@onready var btn_posterior  = $Painel/VBoxGeral/ContadorRow/BtnPosterior
@onready var lbl_contador   = $Painel/VBoxGeral/ContadorRow/Contador

var fotos: Array = []
var indice_atual: int = 0
var quadro_atual: Node = null

func _ready():
	painel.visible = false
	btn_fechar.pressed.connect(fechar)
	btn_anterior.pressed.connect(_foto_anterior)
	btn_posterior.pressed.connect(_foto_proxima)

func mostrar(info: Dictionary, quadro: Node):
	quadro_atual = quadro
	lbl_titulo.text    = info.get("titulo", "")
	lbl_autor.text     = "Autor: "   + info.get("autor", "")
	lbl_tecnica.text   = "Técnica: " + info.get("tecnica", "")
	lbl_tamanho.text   = "Tamanho: " + info.get("tamanho", "")
	lbl_ano.text      = "Ano: "     + info.get("ano", "")
	lbl_descricao.text = info.get("descricao", "")
	lbl_descricao.visible = info.get("descricao", "") != ""

	fotos = info.get("fotos", [])
	indice_atual = 0
	_atualizar_foto()
	
	var painel_artista= _encontrar_painel_artista()
	if painel_artista:
		painel_artista.mostrar(info)
	
	painel.visible = true
	foto_principal.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	
	

func fechar():
	painel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player._soltar_camera()
	
	var painel_artista = _encontrar_painel_artista()
	if painel_artista:
		painel_artista.fechar()

func _encontrar_painel_artista() -> Node:
	var raiz = get_tree().current_scene
	return _buscar_no(raiz, "PainelArtista")

func _buscar_no(no: Node, nome: String) -> Node:
	if no.name == nome:
		return no
	for filho in no.get_children():
		var r = _buscar_no(filho, nome)
		if r:
			return r
	return null

func _foto_anterior():
	if fotos.size() == 0:
		return
	indice_atual = (indice_atual - 1 + fotos.size()) % fotos.size()
	_atualizar_foto()

func _foto_proxima():
	if fotos.size() == 0:
		return
	indice_atual = (indice_atual + 1) % fotos.size()
	_atualizar_foto()

func _atualizar_foto():
	if fotos.size() == 0:
		foto_principal.texture = null
		lbl_contador.text = ""
		btn_anterior.visible = false
		btn_posterior.visible = false
		return

	var caminho = fotos[indice_atual].strip_edges()
	var tex = load(caminho)
	if tex:
		foto_principal.texture = tex
	
	if quadro_atual:
		quadro_atual.trocar_foto(caminho)
	
	lbl_contador.text = str(indice_atual + 1) + " / " + str(fotos.size())
	btn_anterior.visible = fotos.size() > 1
	btn_posterior.visible = fotos.size() > 1
