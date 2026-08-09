extends Control

@onready var camera: Camera2D = $Camera

func _ready() -> void:
	$Camera/ColorRect.hide();

	GlobalSignals.move_camera.connect(func(y: int, delay: float, middle_callback: Callable):
		await transition(Color.BLACK, 0.25, delay, func():
			camera.position.y = y * 1000
			if middle_callback.is_valid(): middle_callback.call()
		)
	)

func _on_start_pressed():
	GlobalSignals.move_camera.emit(1, 0, func():
		$Who_are_you.start()
	)



func transition(color: Color, duration: float, delay: float, middle_callback: Callable = Callable()):
	var colorRect: ColorRect = $Camera/ColorRect
	colorRect = $Camera/ColorRect
	colorRect.color = color
	colorRect.show()
	colorRect.modulate.a = 0.0
	var tween := colorRect.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(colorRect, "modulate:a", 1.0, duration/2)
	if middle_callback.is_valid(): tween.tween_callback(middle_callback)
	tween.tween_property(colorRect, "modulate:a", 0.0, duration/2)
	tween.tween_callback(func(): colorRect.hide())
	return tween.finished
