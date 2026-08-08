extends AnimatedSprite2D

@export var hoverTime: float = 0.2

signal deal_card

var hover_tween
func _on_mouse_exited():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($".", "scale", Vector2(2.5, 2.5), hoverTime)

func _on_mouse_entered():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($".", "scale", Vector2(2.75, 2.75), hoverTime)


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("deal_card")
