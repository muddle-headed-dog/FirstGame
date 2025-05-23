extends Node
class_name StateMachine

var current_state: State
var state_stack: Array[State]

func _ready() -> void:
    current_state = initial_state
    current_state.enter()

func _process(delta: float) -> void:
    pass
