extends CharacterBody2D

class_name Player

# 玩家移动属性
@export var speed: float = 300.0         # 水平移动速度
@export var jump_velocity: float = -400.0 # 初始跳跃速度（负值表示向上移动）
@export var gravity_strength: float = 980.0 # 重力强度

# 节点引用
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 返回用于物理计算的重力值
func calculate_gravity() -> Vector2:
	return Vector2(0, gravity_strength)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement()
	update_animation()
	move_and_slide()

# 当玩家在空中时应用重力
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += calculate_gravity() * delta

# 当跳跃按钮被按下且玩家在地面上时处理跳跃
func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# 根据输入处理水平移动
func handle_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

# 根据移动状态更新角色动画
func update_animation() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# 更新角色朝向
	if direction > 0:
		animated_sprite_2d.flip_h = false  # 面向右侧
	elif direction < 0:
		animated_sprite_2d.flip_h = true   # 面向左侧
	
	# 设置适当的动画
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")  # 站立不动
		else:
			animated_sprite_2d.play("run")   # 奔跑
	else:
		animated_sprite_2d.play("jump")      # 在空中
