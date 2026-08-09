extends Node2D

@export var card: PackedScene
var tween: Tween
var dealable: bool = false
var player_total: int = 0
var dealer_total: int = 0
var attribute: String
var total: int
var wager: int = 0
signal ended(winner: String)
enum Winner {PLAYER, DEALER, DRAW}


func set_player_total(value: int) -> void:
	player_total = value
	$player_total.text = "Points: %d" % player_total


func set_dealer_total(value: int) -> void:
	dealer_total = value
	$dealer_total.text = "Points: %d" % dealer_total


func _ready() -> void:
	$wager/more.pressed.connect(func():
		wager = clampi(wager + 1, 1, total)
		_refresh_wager_label()
	)
	$wager/less.pressed.connect(func():
		wager = clampi(wager - 1, 1, total)
		_refresh_wager_label()
	)
	_refresh_wager_label()
	$Hit.position.x = 1200
	$Stand.position.x = -100
	GlobalSignals.blackjack_start.connect(_on_blackjack_start)


func _on_blackjack_start(attribute2: String, total2: int) -> void:
	attribute = attribute2.replace("_", " ").capitalize()
	total = total2
	wager = 1
	_refresh_wager_label()
	GlobalSignals.move_camera.emit(2, 0.25, Callable())
	await $wager/start.pressed
	if wager <= 0 or wager > total:
		return
	total -= wager
	$wager.hide()
	var action_tween := create_tween().set_parallel()
	action_tween.tween_property($Hit, "position:x", 950.0, 0.35)
	action_tween.tween_property($Stand, "position:x", 150.0, 0.35)
	reset(true)
	$player_total.show()


func _refresh_wager_label() -> void:
	var attribute_suffix := ""
	if not attribute.is_empty():
		attribute_suffix = " %s" % attribute
	$wager/Label.text = "Wager: %d/%d %s" % [wager, total, attribute_suffix]
	$wager/more.disabled = wager >= total
	$wager/less.disabled = wager <= 1
	$wager/start.disabled = wager <= 0 or wager > total


func reset(deal: bool):
	dealable = false
	set_player_total(0)
	set_dealer_total(0)
	$dealer_total.hide()
	$player_total.hide()
	$ending.hide()

	# Stop any pending round sequence.
	if is_instance_valid(tween):
		tween.kill()
	
	# Move any existing cards back to the deck and ensure they're face-down.
	var deck_pos = $Hit.global_position
	var tweens_to_finish: Array[Tween] = []

	var player_marker: Node = $player_hand/new_card_pos
	for child in $player_hand.get_children():
		if child == player_marker:
			continue
		if child is Node2D and child.has_method("updateCardImage"):
			# `flipped = true` means face-down (card back frame).
			child.flipped = true
			child.updateCardImage()
			var move_tween := child.create_tween()
			move_tween.tween_property(child, "global_position", deck_pos, 0.25)
			move_tween.tween_callback(func():
				child.queue_free()
			)
			tweens_to_finish.append(move_tween)

	var dealer_marker: Node = $dealer_hand/new_card_pos
	for child in $dealer_hand.get_children():
		if child == dealer_marker:
			continue
		if child is Node2D and child.has_method("updateCardImage"):
			child.flipped = true
			child.updateCardImage()
			var move_tween := child.create_tween()
			move_tween.tween_property(child, "global_position", deck_pos, 0.25)
			move_tween.tween_callback(func():
				child.queue_free()
			)
			tweens_to_finish.append(move_tween)

	for t in tweens_to_finish:
		await t.finished

	if !deal:
		var action_tween := create_tween().set_parallel()
		action_tween.tween_property($Hit, "position:x", 1200.0, 0.35)
		action_tween.tween_property($Stand, "position:x", -100.0, 0.35)
		await action_tween.finished
		$wager.hide()
		GlobalSignals.blackjack_done.emit()
		return

	# initial dealing animation
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

func _hit():
	if !dealable: return
	deal_card(false, true)
	if player_total == 21:
		bigText("BLACKJACK")
		_stand()
	if player_total > 21:
		dealable = false
		ending("BUST\n\nYOU LOSE", Winner.DEALER)


func _stand():
	if !dealable:
		return
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
			total += wager * 2
		Winner.DRAW:
			total += wager
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
		reset(false)
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
