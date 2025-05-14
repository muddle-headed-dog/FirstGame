extends Node2D
class_name Slime

# 敌人移动属性
@export var patrol_speed: float = 10  # 史莱姆巡逻速度

# 移动方向 (1 = 右, -1 = 左)
var direction: int = 1  

# 节点引用
@onready var raycast_left: RayCast2D = $RayCast2DLeft    # 检测左侧墙壁/边缘
@onready var raycast_right: RayCast2D = $RayCast2DRight  # 检测右侧墙壁/边缘
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 每帧调用
func _process(delta: float) -> void:
	# 如果史莱姆碰到墙壁或到达边缘，则改变方向
	check_direction()
	
	# 根据当前方向移动史莱姆
	move(delta)

# 根据射线检测结果检查史莱姆是否需要改变方向
func check_direction() -> void:
	if raycast_right.is_colliding():
		# 右侧碰到物体，向左转
		direction = -1
		animated_sprite_2d.flip_h = true
	elif raycast_left.is_colliding():
		# 左侧碰到物体，向右转
		direction = 1
		animated_sprite_2d.flip_h = false

# 根据当前方向和速度移动史莱姆
func move(delta: float) -> void:
	position.x += patrol_speed * delta * direction
