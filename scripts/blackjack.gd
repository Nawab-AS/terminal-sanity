extends Node2D

@export var card: PackedScene
var tween: Tween
var dealable: bool = false
var player_total: int = 0
var dealer_total: int = 0
signal ended(winner: String)
enum Winner {PLAYER, DEALER, DRAW}

func set_player_total(value: int) -> void:
	player_total = value
	$player_total.text = "Points: %d" % player_total


func set_dealer_total(value: int) -> void:
	dealer_total = value
	$dealer_total.text = "Points: %d" % dealer_total

func _ready():
	$ending.hide()
	tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		deal_card(true, false)
	)
	tween.tween_interval(0.5)

	tween.tween_callback(func():
		deal_card(false, true)
		dealable = true
	)

func _deal_card_signal():
	if !dealable: return
	deal_card(false, true)
	if player_total == 21:
		bigText("BLACKJACK")
		_stand()
	if player_total > 21:
		dealable = false
		ending("BUST\n\nYOU LOSE", Winner.DEALER)


func _stand():
	dealable = false

	# Flip dealer cards and reveal score.
	for child in $dealer_hand.get_children():
		if child is Node and child.has_method("flip"):
			child.flip()

	$dealer_total.visible = true
	set_dealer_total(dealer_total)

	# Dealer hits until reaching 17.
	while dealer_total < 17:
		await get_tree().create_timer(0.75).timeout
		deal_card(true, true)
		if dealer_total > 21:
			break

	if dealer_total > 21:
		ending("BUST\n\nYOU WIN", Winner.PLAYER)
	elif dealer_total > player_total:
		ending("YOU LOSE", Winner.DEALER)
	elif dealer_total < player_total:
		ending("YOU WIN", Winner.PLAYER)
	else:
		ending("DRAW", Winner.DRAW)


func deal_card(to_dealer: bool, flip: bool):
	var hand = $dealer_hand if to_dealer else $player_hand
	var pos_marker: Node2D = $dealer_hand/new_card_pos if to_dealer else $player_hand/new_card_pos
	var new_card = card.instantiate()
	hand.add_child(new_card)
	new_card.randomizeCard()
	if to_dealer:
		set_dealer_total(dealer_total + new_card.get_value())
	else:
		set_player_total(player_total + new_card.get_value())
	new_card.global_position = $Hit.global_position

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



func ending(text: String, winner: Winner):
	dealable = false
	match winner:
		Winner.PLAYER:
			$ending.set("theme_override_colors/font_color", Color("#29BF12"))
		Winner.DEALER:
			$ending.set("theme_override_colors/font_color", Color("#FD151B"))
		Winner.DRAW:
			$ending.set("theme_override_colors/font_color", Color("F5FBEF"))
	
	
	var ending_tween := bigText(text)
	ending_tween.tween_callback(func():
		emit_signal("ended", winner)
	)

func bigText(text: String) -> Tween:
	$ending.show()
	$ending.text = text
	$ending.set("theme_override_font_sizes/font_size", 1)

	var ending_tween := create_tween()
	ending_tween.tween_interval(0.75)
	ending_tween.tween_property($ending, "theme_override_font_sizes/font_size", 150, 0.6)
	ending_tween.tween_interval(2)
	ending_tween.tween_callback(func():
		$ending.hide()
	)
	return ending_tween
