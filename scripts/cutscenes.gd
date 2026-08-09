extends Node2D

var _random := RandomNumberGenerator.new()
var _event_panel: PanelContainer
var _status_panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _choice_container: VBoxContainer
var _status_label: Label
var _event_active: bool = false
var _waiting_for_continue: bool = false
var _pending_choice: Dictionary = {}
var _pending_resource: String = ""


func _ready() -> void:
    _random.randomize()
    _build_interface()
    GlobalSignals.map_move.connect(_on_map_move)
    GlobalSignals.game_started.connect(_on_game_started)
    GlobalSignals.game_state_changed.connect(_refresh_status)
    GlobalSignals.blackjack_finished.connect(_on_blackjack_finished)


func _build_interface() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 5
    add_child(layer)

    _status_panel = PanelContainer.new()
    _status_panel.position = Vector2(24, 24)
    _status_panel.size = Vector2(360, 62)
    _status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _status_panel.add_theme_stylebox_override("panel", _panel_style(Color("17242D")))
    layer.add_child(_status_panel)
    _status_label = Label.new()
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _status_label.add_theme_font_size_override("font_size", 18)
    _status_panel.add_child(_status_label)

    _event_panel = PanelContainer.new()
    _event_panel.position = Vector2(72, 390)
    _event_panel.size = Vector2(936, 270)
    _event_panel.add_theme_stylebox_override("panel", _panel_style(Color("17242D")))
    layer.add_child(_event_panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 8)
    _event_panel.add_child(content)
    _title_label = Label.new()
    _title_label.add_theme_font_size_override("font_size", 25)
    _title_label.add_theme_color_override("font_color", Color("F5FBEF"))
    content.add_child(_title_label)
    _body_label = Label.new()
    _body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body_label.add_theme_font_size_override("font_size", 16)
    _body_label.add_theme_color_override("font_color", Color("C9D5DB"))
    content.add_child(_body_label)
    _choice_container = VBoxContainer.new()
    _choice_container.add_theme_constant_override("separation", 5)
    content.add_child(_choice_container)
    _event_panel.hide()
    _status_panel.hide()


func _panel_style(background_color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background_color
    style.border_color = Color("6EC1B9")
    style.set_border_width_all(2)
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_left = 6
    style.corner_radius_bottom_right = 6
    style.content_margin_left = 18
    style.content_margin_top = 14
    style.content_margin_right = 18
    style.content_margin_bottom = 14
    return style


func _on_game_started() -> void:
    $map.position = Vector2.ZERO
    _status_panel.show()
    _refresh_status()
    _show_event()


func _on_map_move(x: int, y: int) -> void:
    $map.position -= Vector2(x * 900, y * 900)
    if not _event_active:
        _show_event()


func _show_event() -> void:
    var event: Dictionary = _event_data(GlobalSignals.current_event)
    _event_active = true
    _waiting_for_continue = false
    _title_label.text = event["title"]
    _body_label.text = event["body"]
    _clear_choices()
    for choice: Dictionary in event["choices"]:
        _add_choice(choice)
    _event_panel.show()


func _add_choice(choice: Dictionary) -> void:
    var social_cost: int = choice.get("social", 0)
    var energy_cost: int = choice.get("energy", 0)
    var button := Button.new()
    button.custom_minimum_size = Vector2(0, 34)
    button.add_theme_font_size_override("font_size", 16)
    button.text = "%s  [%s]" % [choice["label"], _cost_text(social_cost, energy_cost)]
    button.disabled = not GlobalSignals.can_wager(social_cost, energy_cost)
    if button.disabled:
        button.text += " - insufficient resources"
    button.pressed.connect(_choose.bind(choice))
    _choice_container.add_child(button)


func _cost_text(social_cost: int, energy_cost: int) -> String:
    var costs: Array[String] = []
    if social_cost > 0:
        costs.append("%d social" % social_cost)
    if energy_cost > 0:
        costs.append("%d energy" % energy_cost)
    return "no wager" if costs.is_empty() else " + ".join(costs)


func _choose(choice: Dictionary) -> void:
    if _waiting_for_continue:
        _event_active = false
        _event_panel.hide()
        return
    var social_cost: int = choice.get("social", 0)
    var energy_cost: int = choice.get("energy", 0)
    if not GlobalSignals.can_wager(social_cost, energy_cost):
        return
    if social_cost > 0 or energy_cost > 0:
        _pending_choice = choice
        _pending_resource = "social" if social_cost > 0 else "energy"
        _event_panel.hide()
        var available: int = GlobalSignals.social_energy if _pending_resource == "social" else GlobalSignals.energy
        var wager: int = social_cost if _pending_resource == "social" else energy_cost
        var resource_label := "social energy" if _pending_resource == "social" else "energy"
        GlobalSignals.blackjack_start.emit(resource_label, available, wager, true)
        return
    _complete_choice(_resolve_choice(choice))


func _on_blackjack_finished(winner: int, wager: int) -> void:
    if _pending_choice.is_empty():
        return
    var choice := _pending_choice
    var won := winner == 0
    var pushed := winner == 2
    if _pending_resource == "social":
        GlobalSignals.apply_result(wager if won else -wager if not pushed else 0, 0, 0)
    else:
        GlobalSignals.apply_result(0, wager if won else -wager if not pushed else 0, 0)
    _pending_choice = {}
    _pending_resource = ""
    GlobalSignals.move_camera.emit(9, 0.1, func():
        _complete_choice(_resolve_choice(choice, won, pushed))
    )


func _complete_choice(outcome: String) -> void:
    GlobalSignals.current_event += 1
    _refresh_status()
    if GlobalSignals.current_event >= 14:
        _show_ending()
        return
    _title_label.text = "Outcome"
    _body_label.text = outcome
    _clear_choices()
    _waiting_for_continue = true
    var continue_button := Button.new()
    continue_button.custom_minimum_size = Vector2(0, 36)
    continue_button.text = "Continue exploring"
    continue_button.pressed.connect(_choose.bind({}))
    _choice_container.add_child(continue_button)


func _resolve_choice(choice: Dictionary, won: bool = true, pushed: bool = false) -> String:
    var result: Dictionary = choice["result"]
    if pushed:
        result = {"text": "Push. Your wager is returned, but the event has no effect."}
    elif not won:
        result = choice.get("failure", {"text": "You lose the blackjack wager and the opportunity passes."})
    GlobalSignals.apply_result(result.get("social", 0), result.get("energy", 0), result.get("project", 0))
    if result.has("team"):
        GlobalSignals.has_team = result["team"]
    if result.has("presented"):
        GlobalSignals.presented_stickers = result["presented"]
    if result.has("late"):
        GlobalSignals.stayed_up_late = result["late"]
    if result.has("tournament"):
        GlobalSignals.lost_tournament_energy = result["tournament"]
    if result.has("flag"):
        GlobalSignals.set_flag(result["flag"])
    return result["text"]


func _clear_choices() -> void:
    for child in _choice_container.get_children():
        child.queue_free()


func _choice(id: String, label: String, result: Dictionary, social_cost: int = 0, energy_cost: int = 0, chance: float = -1.0, failure: Dictionary = {}) -> Dictionary:
    var choice := {"id": id, "label": label, "result": result, "social": social_cost, "energy": energy_cost}
    if chance >= 0.0:
        choice["chance"] = chance
        choice["failure"] = failure
    return choice


func _show_ending() -> void:
    _event_active = true
    _waiting_for_continue = true
    _title_label.text = "Final Presentation"
    _body_label.text = "%s\n\nProject: %d/10    Social: %d    Energy: %d" % [GlobalSignals.ending(), GlobalSignals.project_progress, GlobalSignals.social_energy, GlobalSignals.energy]
    _clear_choices()
    var restart_button := Button.new()
    restart_button.custom_minimum_size = Vector2(0, 36)
    restart_button.text = "Return to title"
    restart_button.pressed.connect(func():
        GlobalSignals.game_finished.emit(GlobalSignals.ending())
        _event_panel.hide()
        _status_panel.hide()
        GlobalSignals.move_camera.emit(0, 0.0, Callable())
    )
    _choice_container.add_child(restart_button)
    _event_panel.show()


func _refresh_status() -> void:
    _status_label.text = "SOCIAL %d    ENERGY %d    PROJECT %d / 10" % [GlobalSignals.social_energy, GlobalSignals.energy, GlobalSignals.project_progress]


func _event_data(index: int) -> Dictionary:
    match index:
        0:
            var first_choice := _choice("explore", "Explore the venue", {"social": 2, "text": "You meet a few people and gain social energy."}, 1)
            if GlobalSignals.attribute == "big_back":
                first_choice = _choice("eat", "Eat before exploring", {"energy": 1, "text": "You eat first. The venue can wait."})
            return {"title": "Main Hall: First Move", "body": "The venue is alive. How do you enter the night?", "choices": [first_choice, _choice("talk", "Talk with people", {"social": 2, "team": true, "text": "A conversation turns into a project team."}, 1), _choice("self", "Keep to yourself", {"project": 1, "text": "You protect your energy and sketch your project."})]}
        1:
            return {"title": "7:30 PM Orientation", "body": "Participation costs social energy, but it can pay off.", "choices": [_choice("orientation", "Participate", {"social": 5, "text": "The wager returns a net gain of three social energy."}, 2), _choice("observe", "Stay on the edge", {"text": "You save your social energy for later."})]}
        2:
            if GlobalSignals.has_team:
                return {"title": "After Orientation", "body": "You already have people to build with.", "choices": [_choice("team", "Commit to the team", {"social": 1, "team": true, "text": "Your team makes a plan and gets moving."})]}
            if GlobalSignals.software_hardware == "hardware":
                return {"title": "Find a Team", "body": "Hardware work needs collaborators. You need to join a team.", "choices": [_choice("team", "Look for a team", {"social": 1, "team": true, "text": "You find collaborators and get a social boost."}, 0, 1)]}
            return {"title": "After Orientation", "body": "You can search for a team or build solo.", "choices": [_choice("team", "Look for a team", {"social": 1, "team": true, "text": "You find collaborators and get a social boost."}, 0, 1), _choice("solo", "Build solo", {"energy": 1, "text": "Solo work costs social energy but gives you momentum."}, 2)]}
        3:
            return {"title": "Sticker Ideas", "body": "A chance to present your idea opens up.", "choices": [_choice("stickers", "Present your sticker idea", {"social": 2, "presented": true, "text": "Your idea lands for a net social gain."}, 1), _choice("skip", "Keep it to yourself", {"text": "You keep the idea in your notebook."})]}
        4:
            var late_progress := 1 if GlobalSignals.attribute in ["lazy", "procrastinating"] else 3
            return {"title": "How Late Do You Work?", "body": "Energy is now a wager. More effort can mean more progress and a rough morning.", "choices": [_choice("midnight", "Stop at midnight", {"project": 2, "text": "You stop at midnight with steady project progress."}, 0, 1), _choice("late", "Push until 3 AM", {"project": late_progress, "late": true, "text": "You work until 3 AM and add %d project points." % late_progress}, 0, 2)]}
        5:
            return {"title": "Morning Alarm", "body": "The next day starts early. Your choice changes how much energy remains.", "choices": [_choice("early", "Wake at 6:48", {"energy": -1, "text": "You catch the early schedule, at an energy cost."}, 0, 1), _choice("late_wake", "Wake later", {"flag": "woke_late", "text": "You wake late and lose some room in the day."})]}
        6:
            if GlobalSignals.software_hardware == "hardware":
                return {"title": "Godot Workshop", "body": "Hardware skills mean the workshop is part of the route.", "choices": [_choice("workshop", "Take the workshop", {"project": 1, "text": "The workshop gives your project a practical improvement."}, 0, 1)]}
            return {"title": "Godot Workshop", "body": "You already know the software side. Time is the real resource.", "choices": [_choice("skip_workshop", "Skip it and keep building", {"project": 1, "text": "You use the time to advance your build."})]}
        7:
            if GlobalSignals.has_team:
                return {"title": "Lunch", "body": "Your team is eating together before heading back out.", "choices": [_choice("team_lunch", "Eat with the team", {"social": 1, "text": "Lunch restores some social energy."})]}
            var lunch_progress := 0 if GlobalSignals.attribute == "big_back" else 1
            return {"title": "Lunch Alone", "body": "You can work while you eat, unless eating becomes the whole plan.", "choices": [_choice("solo_lunch", "Eat and work", {"project": lunch_progress, "text": "You add %d project point." % lunch_progress})]}
        8:
            if not GlobalSignals.has_team:
                return {"title": "Spikeball Tournament", "body": "Without a team, you can put the time into your project.", "choices": [_choice("skip_spikeball", "Skip tournament and work", {"project": 1, "text": "You put the tournament time into your project."})]}
            var spike_choices: Array[Dictionary] = [_choice("average", "Go average", {"social": 1, "tournament": true, "text": "You gain social energy but spend stamina."}, 0, 1)]
            if GlobalSignals.attribute not in ["big_back", "lazy"]:
                spike_choices.push_front(_choice("lockin", "Lock in", {"social": 2, "tournament": true, "text": "You lock in, gain social energy, and spend stamina."}, 0, 2))
            return {"title": "Spikeball Tournament", "body": "Your team is playing. Wager energy for a social payoff.", "choices": spike_choices}
        9:
            return {"title": "API Workshop", "body": "It has no direct project value. It only trades your remaining time.", "choices": [_choice("api", "Attend the workshop", {"project": -1, "text": "The workshop costs project time."}), _choice("api_skip", "Keep working", {"project": 1, "text": "You gain a focused hour of project work."})]}
        10:
            var energy_return := 2 if GlobalSignals.lost_tournament_energy else 0
            return {"title": "Lightning Talks", "body": "A risky social wager can restore tournament energy.", "choices": [_choice("lightning", "Attempt a lightning talk", {"social": 2, "energy": energy_return, "text": "The talk lands and restores your momentum."}, 2, 0, 0.55, {"social": -1, "text": "The talk misses. You lose one more social energy."}), _choice("watch", "Watch from the crowd", {"text": "You save your social energy."})]}
        11:
            return {"title": "Karaoke", "body": "Karaoke is optional, but a little chaos can help your social energy.", "choices": [_choice("karaoke", "Take the mic", {"social": 1, "text": "Karaoke gives you a social energy boost."}), _choice("quiet", "Call it a night", {"text": "You keep the night quiet."})]}
        12:
            if GlobalSignals.has_team and GlobalSignals.social_energy > 0:
                return {"title": "Last-Night Clutch", "body": "Your team can wager three social energy for five project points.", "choices": [_choice("clutch", "Clutch with the team", {"project": 5, "text": "The clutch works: five project points."}, 3, 0, 0.6, {"text": "The clutch falls short. The wager is gone."}), _choice("small_block", "Work a smaller block", {"project": 2, "text": "You make a smaller, steadier push."})]}
            if GlobalSignals.has_team:
                return {"title": "Last-Night Clutch", "body": "With no social energy left, you can trade stamina for two project points.", "choices": [_choice("energy_crunch", "Spend energy to finish", {"project": 2, "text": "You trade stamina for two project points."}, 0, 2)]}
            var solo_progress := 1 if GlobalSignals.lost_tournament_energy else 3
            if GlobalSignals.stayed_up_late:
                solo_progress -= 1
            return {"title": "Last-Night Work", "body": "The final hours decide whether the project comes together.", "choices": [_choice("solo_crunch", "Stay awake and work", {"project": solo_progress, "text": "You add %d project points." % solo_progress})]}
        13:
            return {"title": "The Presentation", "body": "It is time to show what you built.", "choices": [_choice("presentation", "Present the project", {"text": "You take the stage."})]}
    return {"title": "End", "body": "", "choices": []}
