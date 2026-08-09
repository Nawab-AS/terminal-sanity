extends Control

var attribute: String
var software_hardware: String
var transport: String
var questionNum: int


func start() -> void:
    for button in get_tree().get_nodes_in_group("questions"):
        if button is Button and not button.pressed.is_connected(_on_question_pressed):
            button.pressed.connect(_on_question_pressed.bind(button))

    _show_question(0)


func _on_question_pressed(button: Button) -> void:
    var question := button.get_parent()
    if question == null:
        return

    if question.name == "attribute":
        attribute = button.name
    elif question.name == "software_hardware":
        software_hardware = button.name
    elif question.name == "transport":
        transport = button.name

    var next_question := question.get_index() + 1
    if next_question < get_child_count():
        GlobalSignals.move_camera.emit(1, 0.1, func():
            _show_question(next_question)
        )
    else:
        GlobalSignals.move_camera.emit(9, 0.1, Callable())
        #GlobalSignals.blackjack_start.emit(attribute.replace("_", " "), 20)


func _show_question(index: int) -> void:
    for child in get_children():
        if child is Control:
            child.hide()

    if index >= 0 and index < get_child_count():
        var next_question := get_child(index)
        if next_question is Control:
            next_question.show()


