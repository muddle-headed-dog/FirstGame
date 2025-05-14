extends Area2D

class_name Coin

# 节点引用
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 当金币被玩家触碰时调用此函数
func _on_body_entered(body) -> void:
	# 检查碰撞的物体是否为玩家
	if body is Player:
		# 播放拾取动画（应该会处理金币消失效果）
		animation_player.play("pick_up")
		
		# 注意：在这里可以添加计分、音效或其他游戏机制
		# 例如：增加玩家得分、播放收集音效等
