extends Node2D


func _ready() -> void:
    GlobalSignals.map_move.connect(_on_map_move)

func _on_map_move(x: int, y: int):
    var target_position: Vector2 = $map.position - Vector2(x * 900, y * 900)
    $map.position = target_position
