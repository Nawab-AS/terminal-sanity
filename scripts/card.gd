extends Node2D

enum Suites {HEARTS, DIAMONDS, SPADES, CLUBS }
enum Values {ACE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, JACK, QUEEN, KING}

@export var suite: Suites
@export var value: Values
@export var flipped: bool = true
@export var ClickFlipable: bool = true
@export var flippingTime: float = 0.20


var flipping: bool = false
var mouseInside: bool = false
var cardScale: float = 1

func _ready():
	updateCardImage()

func flip():
	flipping = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property($hoverScale/image, "scale:x", 0.0, flippingTime/2)
	tween.tween_callback(func():
		flipped = !flipped
		updateCardImage()
	)
	tween.tween_property($hoverScale/image, "scale:x", 1.0, flippingTime)
	tween.tween_callback(func(): flipping = false)

func updateCardImage():
	if flipped:
		$hoverScale/image.frame = 52
	else:
		$hoverScale/image.frame = getCard(suite, value)

func getCard(suite: Suites, value: Values) -> int:
	var suiteInt: int = 0
	match suite:
		Suites.HEARTS:
			suiteInt = 0
		Suites.DIAMONDS:
			suiteInt = 1
		Suites.SPADES:
			suiteInt = 2
		Suites.CLUBS:
			suiteInt = 3
	
	var valueInt: int = 0
	match value:
		Values.ACE:
			valueInt = 1
		Values.TWO:
			valueInt = 2
		Values.THREE:
			valueInt = 3
		Values.FOUR:
			valueInt = 4
		Values.FIVE:
			valueInt = 5
		Values.SIX:
			valueInt = 6
		Values.SEVEN:
			valueInt = 7
		Values.EIGHT:
			valueInt = 8
		Values.NINE:
			valueInt = 9
		Values.JACK:
			valueInt = 10
		Values.QUEEN:
			valueInt = 11
		Values.KING:
			valueInt = 12
	
	return (suiteInt * 13) + valueInt - 1


var hover_tween
func _on_mouse_exited():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($hoverScale, "scale", Vector2.ONE, flippingTime/2)

func _on_mouse_entered():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($hoverScale, "scale", Vector2(1.05, 1.05), flippingTime/2)

func _on_input_event(viewport, event, shape_idx):
	# mouse clicked and currently not flipping
	if event is InputEventMouseButton && event.pressed \
			&& event.button_index == MOUSE_BUTTON_LEFT \
			&& !flipping && ClickFlipable:
		if hover_tween: hover_tween.kill()
		flip()
