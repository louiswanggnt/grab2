extends Node2D

@onready var metal_container = $MetalContainer
@onready var money_label = $UI/MoneyLabel
@onready var boat = $Boat
var metal_scene = preload("res://MetalObject.tscn")

func _ready():
	spawn_metals()

func _process(_delta):
	money_label.text = "Money: $" + str(boat.money)

func spawn_metals():
	# 在海底（1500-1900深度）生成金屬物
	for i in range(20):
		var metal = metal_scene.instantiate()
		metal_container.add_child(metal)
		metal.position = Vector2(randf_range(50, 1100), randf_range(1500, 1900))
