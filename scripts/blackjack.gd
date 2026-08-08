extends Node2D

@export var card: PackedScene
var dealer_cards: Array[PackedScene] = []

var tween = create_tween()
func _ready() -> void:
	tween.tween_interval(2)
	var new_card = card.instantiate()
	
	new_card.global_position = $CardSpawn.global_position
	$dealer_hand.add_child(new_card)
	dealer_cards.append(new_card)
	
