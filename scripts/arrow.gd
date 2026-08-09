extends Sprite2D

enum Direction {UP, DOWN, LEFT, RIGHT}

@export var direction: Direction = Direction.UP


func _ready() -> void:
	$Area2D.input_pickable = true


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GlobalSignals.map_move.emit(_movement.x, _movement.y)


var _movement: Vector2i:
	get:
		match direction:
			Direction.UP:
				return Vector2i.UP
			Direction.DOWN:
				return Vector2i.DOWN
			Direction.LEFT:
				return Vector2i.LEFT
			Direction.RIGHT:
				return Vector2i.RIGHT
		return Vector2i.ZERO

