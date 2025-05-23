extends Camera2D

@export var target: Node2D

func _process(delta: float) -> void:
    if target:
        position = target.position
