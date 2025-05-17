extends CanvasLayer
class_name ui_manger

# 面板路径映射字典
var panel_paths: Dictionary = {
    "bag": "res://bag_system/scene/bag_panel.tscn",
    "main": "res://bag_system/scene/main_panel.tscn"
}

# 已加载的面板缓存
var loaded_panels: Dictionary = {}

# 当前显示的面板
var current_panel: String = ""

@onready var panel_container: PanelContainer = $Control/SceneMargin/PanelContainer

func _ready():
    # 预加载主界面
    load_panel("main")
    show_panel("main")

# 加载面板
func load_panel(panel_name: String) -> bool:
    # 如果面板已加载，则不重复加载
    if loaded_panels.has(panel_name):
        return true
    
    # 检查面板路径是否存在
    if not panel_paths.has(panel_name):
        printerr("面板 %s 未定义路径!" % panel_name)
        return false
    
    # 加载面板场景
    var panel_scene = load(panel_paths[panel_name])
    if panel_scene == null:
        printerr("无法加载面板: %s" % panel_paths[panel_name])
        return false
    
    # 实例化面板
    var panel_instance = panel_scene.instantiate()
    if panel_instance == null:
        printerr("无法实例化面板: %s" % panel_name)
        return false
    
    # 添加到缓存
    loaded_panels[panel_name] = panel_instance
    
    # 添加到容器但设为不可见
    panel_container.add_child(panel_instance)
    panel_instance.visible = false
    
    print("面板 %s 加载成功" % panel_name)
    return true

# 显示面板
func show_panel(panel_name: String) -> bool:
    # 如果面板未加载，先加载
    if not loaded_panels.has(panel_name):
        if not load_panel(panel_name):
            return false
    
    # 如果有当前面板，先隐藏
    if current_panel != "" and current_panel != panel_name:
        hide_panel(current_panel)
    
    # 显示目标面板
    loaded_panels[panel_name].visible = true
    current_panel = panel_name
    
    print("显示面板: %s" % panel_name)
    return true

# 隐藏面板
func hide_panel(panel_name: String) -> bool:
    # 检查面板是否已加载
    if not loaded_panels.has(panel_name):
        printerr("尝试隐藏未加载的面板: %s" % panel_name)
        return false
    
    # 隐藏面板
    loaded_panels[panel_name].visible = false
    
    # 如果是当前面板，清除当前面板引用
    if current_panel == panel_name:
        current_panel = ""
    
    print("隐藏面板: %s" % panel_name)
    return true

# 切换面板
func toggle_panel(panel_name: String) -> bool:
    # 检查面板是否已加载
    if loaded_panels.has(panel_name) and loaded_panels[panel_name].visible:
        return hide_panel(panel_name)
    else:
        return show_panel(panel_name)

# 卸载面板
func unload_panel(panel_name: String) -> bool:
    # 检查面板是否已加载
    if not loaded_panels.has(panel_name):
        return false
    
    # 如果面板正在显示，先隐藏
    if current_panel == panel_name:
        hide_panel(panel_name)
    
    # 从树中移除并释放资源
    var panel = loaded_panels[panel_name]
    panel_container.remove_child(panel)
    panel.queue_free()
    
    # 从缓存中移除
    loaded_panels.erase(panel_name)
    
    print("卸载面板: %s" % panel_name)
    return true

# 获取面板引用
func get_panel(panel_name: String):
    if loaded_panels.has(panel_name):
        return loaded_panels[panel_name]
    return null
