extends Node

# main
signal move_camera(y: int, delay: float, middle_callback: Callable)
signal game_started
signal game_state_changed
signal game_finished(ending: String)

# blackjack
signal blackjack_start(attribute: String, total: int, wager: int, locked_wager: bool)
signal blackjack_done
signal blackjack_finished(winner: int, wager: int)

# map
signal map_move(x: int, y: int)

var attribute: String
var software_hardware: String
var transport: String
var social_energy: int = 5
var energy: int = 5
var project_progress: int = 0
var has_team: bool = false
var presented_stickers: bool = false
var stayed_up_late: bool = false
var lost_tournament_energy: bool = false
var current_event: int = 0
var flags: Dictionary = {}


func start_run(attribute_value: String, skill_value: String, transport_value: String) -> void:
    attribute = attribute_value
    software_hardware = skill_value
    transport = transport_value
    social_energy = 5
    energy = 5
    project_progress = 0
    has_team = false
    presented_stickers = false
    stayed_up_late = false
    lost_tournament_energy = false
    current_event = 0
    flags.clear()
    game_started.emit()
    game_state_changed.emit()


func can_wager(social_cost: int = 0, energy_cost: int = 0) -> bool:
    return social_energy >= social_cost and energy >= energy_cost


func spend_wager(social_cost: int = 0, energy_cost: int = 0) -> bool:
    if not can_wager(social_cost, energy_cost):
        return false
    social_energy -= social_cost
    energy -= energy_cost
    game_state_changed.emit()
    return true


func apply_result(social_delta: int = 0, energy_delta: int = 0, project_delta: int = 0) -> void:
    social_energy = maxi(0, social_energy + social_delta)
    energy = maxi(0, energy + energy_delta)
    project_progress = clampi(project_progress + project_delta, 0, 10)
    game_state_changed.emit()


func set_flag(flag_name: String, value: bool = true) -> void:
    flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
    return flags.get(flag_name, false)


func ending() -> String:
    if project_progress >= 10 and social_energy > 8:
        return "I platinum'd Polaris"
    if project_progress >= 8 and social_energy > 0:
        return "Polaris Podium"
    if project_progress >= 8:
        return "B > Avg"
    if has_team and social_energy > 0:
        return "Hack Club Was the Friends We Made Along the Way"
    if attribute == "big_back":
        return "We Will Big Back This Club"
    return "Merge Conflicts"


func _ready():
    pass
