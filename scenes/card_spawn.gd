extends AnimatedSprite2D

@export var hoverTime: float = 0.2

signal deal_card
signal stand

var hover_tween
func _on_mouse_exited():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($".", "scale", Vector2(2.5, 2.5), hoverTime)

func _on_mouse_entered():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($".", "scale", Vector2(2.75, 2.75), hoverTime)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		if name == "Hit":
			emit_signal("deal_card")
		elif name == "Stand":
			emit_signal("stand")

func _input(event: InputEvent):
	if event.is_action_pressed("Hit") && name == "Hit":
		emit_signal("deal_card")
	elif event.is_action_pressed("Stand") && name == "Stand":
		emit_signal("stand")
