extends Panel

# 预加载UI管理器类
const UiManager = preload("res://bag_system/scripts/ui_manger.gd")

@onready var btn_bag: TextureButton = $p_menu/btn_bag
var ui_manager: UiManager

func _ready():
	btn_bag.button_down.connect(_on_btn_bag_pressed)
	btn_bag.button_up.connect(_on_btn_bag_released)
	
	# 获取UI管理器引用
	await get_tree().process_frame
	find_ui_manager()

# 查找UI管理器
func find_ui_manager():
	var root = get_tree().root
	for node in root.get_children():
		if node is UiManager:
			ui_manager = node
			print("找到UI管理器")
			return
	
	print("未找到UI管理器")

func _on_btn_bag_pressed():
	btn_bag.modulate = Color("#7c7c7c")
	print("btn_bag pressed")

func _on_btn_bag_released():
	btn_bag.modulate = Color.WHITE
	print("btn_bag released")
	
	# 通过UI管理器打开背包
	if ui_manager:
		ui_manager.toggle_panel("bag")
	else:
		print("错误：未找到UI管理器，无法打开背包")