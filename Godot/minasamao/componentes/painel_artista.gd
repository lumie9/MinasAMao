extends CanvasLayer

@onready var painel = $Painel
@onready var lbl_nome = $Painel/VBox/LblNome
@onready var lbl_instagram = $Painel/VBox/LblInstagram
@onready var lbl_descricao = $Painel/VBox/LblDescricao
@onready var btn_fechar = $Painel/VBox/BtnFechar

func _ready():
	painel.visible = false
	btn_fechar.pressed.connect(fechar)

func mostrar(info: Dictionary):
	lbl_nome.text      = info.get("artista_nome_completo", "")
	lbl_instagram.text = info.get("artista_instagram", "")
	lbl_descricao.text = info.get("artista_descricao", "")
	painel.visible = true

func fechar():
	painel.visible = false
