extends Node2D

@export var card: PackedScene
var tween: Tween

func _ready():
	tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		deal_card(true, false)
	)
	tween.tween_interval(0.5)

	tween.tween_callback(func():
		deal_card(false, true)
	)

func _deal_card_signal():
	deal_card(false, true, true)


func deal_card(to_dealer: bool, flip: bool, from_signal: bool = false):
	var hand = $dealer_hand if to_dealer else $player_hand
	var pos_marker: Node2D = $dealer_hand/new_card_pos if to_dealer else $player_hand/new_card_pos
	var new_card = card.instantiate()
	hand.add_child(new_card)
	new_card.randomizeCard()
	new_card.global_position = $CardSpawn.global_position

	var spacing := 125.0
	var cards: Array[Node2D] = []
	for child in hand.get_children():
		if child != pos_marker and child is Node2D:
			cards.append(child)

	var n := cards.size()
	for i in range(n):
		var c := cards[i]
		var x_offset := spacing * (i - (n - 1) / 2.0)
		var target_pos := Vector2(hand.global_position.x + x_offset, pos_marker.global_position.y)
		var move_tween := c.create_tween()
		move_tween.tween_property(c, "global_position", target_pos, 0.25)
		if c == new_card and flip:
			move_tween.tween_callback(func(): c.flip())
