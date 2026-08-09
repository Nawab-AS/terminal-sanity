extends Node

# main
signal move_camera(y: int, delay: float, middle_callback: Callable)
# signal start_game(attribute: String, software_hardware: String, transport: String)

# blackjack
signal blackjack_start(attribute: String, total: int)
signal blackjack_done

# map
signal map_move(x: int, y: int)

var attribute: String
var software_hardware: String
var transport: String
func _ready():
    pass
    # start_game.connect(func(attribute2: String, software_hardware2: String, transport2: String):
    #     print("Game started with attribute: %s, software_hardware: %s, transport: %s" % [attribute2, software_hardware2, transport2])
    #     attribute = attribute2; software_hardware = software_hardware2; transport = transport2
    # )
