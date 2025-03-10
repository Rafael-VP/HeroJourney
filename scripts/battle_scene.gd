extends Node2D

signal battle_ended
signal game_over

@onready var label = get_node("Label")
@onready var og_villain = get_node("../Main/Villain")
@onready var health = get_node("Health")
@onready var enemy_health = get_node("EnemyHealth")
@onready var enemy = get_node("Enemy")
@onready var ar = get_node("CanvasLayer/Ar")
@onready var fogo = get_node("CanvasLayer/Fogo")
@onready var agua = get_node("CanvasLayer/Agua")
@onready var raio = get_node("CanvasLayer/Raio")
@onready var terra = get_node("CanvasLayer/Terra")
@onready var elements_assets = [fogo, agua, ar, terra, raio]

var hero: Node2D
var hero_stats: Node2D

const MAX_HEIGHT = 15

# Dicionário de vantagens elementais
var vantagens = {
	"agua": "fogo",
	"fogo": "ar",
	"ar": "raio",
	"raio": "terra",
	"terra": "agua"
}

var elementos_indices = {
	"fogo": 0,
	"agua": 1,
	"ar": 2,
	"terra": 3,
	"raio": 4
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func initialize(original_hero: Node2D, height: int, villain: Node2D):
	print("Height: ", height)
	hero_stats = original_hero
	hero = original_hero.duplicate()
	print(hero.elements)
	print(enemy.elements)
	add_child(hero)
	hero.position = Vector2(160, 480)
	
	if height == MAX_HEIGHT:
		villain = og_villain.duplicate()
		#var villain_body = villain.duplicate()
		villain.position = enemy.position
		add_child(villain)
		enemy.visible = false
		enemy = og_villain
	else:
		enemy.set_frame(randi_range(0, 1))
		enemy.elements = generate_charges(height)
	
	for i in range(5):
		elements_assets[i].set_frame(enemy.elements[i])


func _on_button_pressed() -> void:
	var poder_heroi = calcular_poder(hero_stats, enemy)
	var poder_vilao = calcular_poder(enemy, hero_stats)
	var hero_hit = simular_dado(poder_heroi, poder_vilao)

	print(enemy.health)
	
	# testing purposes
	hero_hit = true
	
	if hero_hit:
		label.text = "Hit!"
		print("Herói acertou")
		update_health(enemy)
	else:
		label.text = "Miss!"
	
	var enemy_hit = simular_dado(poder_vilao, poder_heroi)

	if enemy_hit:
		print("Inimigo acertou")
		update_health(hero)

	print("Poder do Herói: ", snapped(poder_heroi, 0.001))
	print("Poder do Vilão: ", snapped(poder_vilao, 0.001))
	pass # Replace with function body.

func generate_charges(height: int):
	var elements := [0, 0, 0, 0, 0]  # Inicializa o vetor de elementos
	var charges = height / 3  # Calcula o número de cargas com base na altura
	print("Cargas iniciais: ", charges)

	while charges > 0:
		var idx = randi() % 5  # Escolhe um índice aleatório (0 a 4)

		# Define o valor a ser adicionado com base na altura
		var value_to_add := 1
		if height >= 9 && height <= 14:
			value_to_add = 2
		elif height > 14:
			value_to_add = 3

		# Verifica se o valor a ser adicionado ultrapassa o limite de 5
		if elements[idx] + value_to_add <= 5:
			elements[idx] += value_to_add
			charges -= value_to_add
		else:
			# Se ultrapassar, adiciona o máximo possível e recalcula o excesso
			var excess = (elements[idx] + value_to_add) - 5
			elements[idx] = 5  # Define o valor máximo para o índice atual
			charges -= (value_to_add - excess)  # Reduz as cargas pelo valor adicionado

			# Redistribui o excesso para outros índices
			while excess > 0:
				var new_idx = randi() % 5  # Escolhe um novo índice aleatório
				if elements[new_idx] < 5:  # Verifica se o novo índice pode receber o excesso
					var add_amount = min(excess, 5 - elements[new_idx])
					elements[new_idx] += add_amount
					excess -= add_amount
	
	print("Gerado:")
	print(elements)
	return elements


func update_health(target: Node2D):
	target.health -= 1;
	
	if target == hero:
		health.set_frame(3 - hero.health)
	
		if (hero.health == 0):
			emit_signal("game_over")
			return

	elif target == enemy:
		enemy_health.set_frame(3 - enemy.health)
		
		if(enemy.health == 0):
			print("It's over")
			emit_signal("battle_ended")
			return

func calcular_poder(personagem, oponente):
	var poder_base = 100
	var poder_total = poder_base

	# Itera pelos índices do array de elementos
	for i in range(personagem.elements.size()):
		var carga_personagem = personagem.elements[i]  # Quantidade de cargas do personagem para o elemento atual
		
		# Obtém o nome do elemento correspondente ao índice
		var elemento = elementos_indices.keys()[i]  
		var elemento_vantajoso = vantagens.get(elemento, "")  # Elemento que sofre desvantagem

		var carga_oponente = 0  # Define um valor padrão

		# Se o elemento vantajoso existir no dicionário de índices, pega a carga correspondente do oponente
		if elemento_vantajoso in elementos_indices:
			var index_oponente = elementos_indices[elemento_vantajoso]
			carga_oponente = oponente.elements[index_oponente]  # Quantidade de cargas do oponente

		# Ajusta o poder baseado nas vantagens e cargas
		if carga_personagem > 0:
			if carga_oponente > 0:
				poder_total *= pow(1.3, carga_personagem)
			else:
				poder_total *= pow(1.15, carga_personagem)  # Pequeno bônus se houver carga

	return poder_total
	
# Função para calcular a probabilidade de vitória
func calcular_probabilidade(poder_personagem, poder_oponente):
	var soma_poderes = poder_personagem + poder_oponente
	var probabilidade_personagem = poder_personagem / soma_poderes
	var probabilidade_oponente = poder_oponente / soma_poderes
	return [probabilidade_personagem, probabilidade_oponente]

# Função para simular o D20 e decidir o vencedor
func simular_dado(poder_personagem, poder_oponente):
	var probabilidades = calcular_probabilidade(poder_personagem, poder_oponente)
	var probabilidade_personagem = probabilidades[0]  # Acessa a probabilidade do personagem
	var limite_personagem = int(probabilidade_personagem * 20)  # Mapeia para o D20

	var dado = randi() % 20 + 1  # Simula um lançamento de D20
	if dado <= limite_personagem:
		return true
	else:
		return false
		
