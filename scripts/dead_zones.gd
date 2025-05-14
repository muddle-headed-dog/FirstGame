extends Area2D

class_name DeadZones

# 节点引用
@onready var timer: Timer = $Timer

# 当物体进入死亡区域时调用此函数
func _on_body_entered(body: Node2D) -> void:
	# 检查进入的物体是否为玩家
	if body is Player:
		# 禁用GUI输入，防止玩家在死亡动画期间控制角色
		get_tree().root.gui_disable_input = false
		
		# 播放死亡动画
		body.get_node("AnimatedSprite2D").play("die")
		
		# 减慢时间流逝，产生戏剧效果
		Engine.time_scale = 0.5
		
		# 启动计时器，在动画播放后重置场景
		timer.start()

# 当计时器超时时调用此函数
func _on_timer_timeout() -> void:
	# 将时间流逝恢复正常
	Engine.time_scale = 1
	
	# 重新加载当前场景以重新开始关卡
	get_tree().reload_current_scene()
	
