extends Node
class_name State

# 状态机
var state_machine: StateMachine
# 硬切换，直接切换到新的状态（new_state）
signal transitioned(new_state: State)
# 栈切换，从状态栈中弹出当前状态，返回到上一个状态
signal pop_state
# 栈切换，将新状态压入状态栈，保留当前状态
signal push_state(new_state: State)

# 进入状态执行
func enter() -> void:
    pass

# 
func exit() -> void:
    pass

func process(delta: float) -> void:
    pass

func physics_process(delta: float) -> void:
    pass

func input(event: InputEvent) -> void:
    pass
