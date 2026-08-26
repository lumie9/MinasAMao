extends Node

const QUADRO_CENA = preload("res://componentes/quadro.tscn")
const ESCULTURA_CENA = preload("res://componentes/escultura.tscn")

const ALTURA_QUADRO = 3
const ALTURA_ESCULTURA = 0
const ESPACO_ENTRE = 4.0

func gerar(cena_pai: Node, caminho_cfg: String):
	var cfg = ConfigFile.new()
	if cfg.load(caminho_cfg) != OK:
		push_error("Gerador Quadros: nao conseguiu encontrar " + caminho_cfg)
		return
	
	var paredes = {}
	for secao in cfg.get_sections():
		var parede = cfg.get_value(secao, "parede", "")
		if parede == "":
			push_warning("Quadro " + secao + " nao tem parede definida, ignorando.")
			continue
		if not paredes.has(parede):
			paredes[parede] = []
		paredes[parede].append(secao)
	
	for parede in paredes:
		var secoes = paredes[parede]
		_colocar_na_parede(cena_pai, cfg, secoes, parede, caminho_cfg)
		

func _colocar_na_parede(pai: Node, _cfg: ConfigFile, secoes: Array, parede: String, caminho_cfg: String):
	var total = secoes.size()
	var largura_total = (total - 1) * ESPACO_ENTRE
	var inicio = -largura_total / 2.0

	for i in range(total):
		var secao = secoes[i]
		var offset = inicio + i * ESPACO_ENTRE
		var tipo = _cfg.get_value(secao, "tipo", "quadro")
		
		var item
		if tipo == "escultura":
			item = ESCULTURA_CENA.instantiate()
		else:
			item = QUADRO_CENA.instantiate()

		# define ANTES do add_child para o _ready() já pegar os valores certos
		item.id_quadro   = secao
		item.caminho_cfg = caminho_cfg
		var altura = ALTURA_ESCULTURA if tipo == "escultura" else ALTURA_QUADRO

		# posiciona conforme a parede
		match parede:
			"fundo":
				item.transform = Transform3D(
		Vector3(1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, 0, 1),
		Vector3(offset, altura, -12.2)
	)
			"frente":
				item.transform = Transform3D(
		Vector3(-1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, 0, -1),
		Vector3(offset, altura, 12.2)
	)
			"esquerda":
				item.transform = Transform3D(
					 Vector3(4.37114e-08, 0, -1),
					Vector3(0, 1, 0),
					Vector3(1, 0, 4.37114e-08),
					Vector3(-6.0, altura, offset)
				)  
			"direita":
				item.transform = Transform3D(
		Vector3(-4.37114e-08, 0, 1),
		Vector3(0, 1, 0),
		Vector3(-1, 0, -4.37114e-08),
		Vector3(6.0, altura, offset)
	)

		# add_child DEPOIS de tudo configurado
		pai.add_child(item)
