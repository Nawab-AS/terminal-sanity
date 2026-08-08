extends Node2D

enum Suites {HEARTS, DIAMONDS, SPADES, CLUBS }
enum Values {ACE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, JACK, QUEEN, KING}

@export var suite: Suites
@export var value: Values
@export var flipped: bool = true
@export var ClickFlipable: bool = false
@export var flippingTime: float = 0.20


var flipping: bool = false
var mouseInside: bool = false
var cardScale: float = 1

func _ready():
	updateCardImage()
	
func randomizeCard():
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var suites := [Suites.HEARTS, Suites.DIAMONDS, Suites.SPADES, Suites.CLUBS]
	var values := [
		Values.ACE, Values.TWO, Values.THREE, Values.FOUR, Values.FIVE, Values.SIX,
		Values.SEVEN, Values.EIGHT, Values.NINE, Values.JACK, Values.QUEEN, Values.KING
	]

	suite = suites[rng.randi_range(0, suites.size() - 1)]
	value = values[rng.randi_range(0, values.size() - 1)]

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


func get_value():
	match value:
		Values.ACE:
			return 1
		Values.TWO:
			return 2
		Values.THREE:
			return 3
		Values.FOUR:
			return 4
		Values.FIVE:
			return 5
		Values.SIX:
			return 6
		Values.SEVEN:
			return 7
		Values.EIGHT:
			return 8
		Values.NINE:
			return 9
		Values.JACK:
			return 10
		Values.QUEEN:
			return 10
		Values.KING:
			return 10
