# 这是一个 Godot 编辑器插件脚本，用于在编辑器中添加拖放节点的功能。
# 它扩展了 `EditorPlugin` 类，这是所有 Godot 编辑器插件的基础类。
@tool
extends EditorPlugin

# 定义一个变量 `class_tree`，用于存储类树的实例。
var class_tree
# 预加载 `class_tree.gd` 脚本，并将其赋值给常量 `ClassTree`。
const ClassTree = preload("./class_tree.gd")

# 当插件被加载到编辑器时调用的函数。
func _enter_tree() -> void:
	# 设置编辑器节点。
	_setup_editor_nodes()
	
	# 创建 `ClassTree` 的实例，并将其添加到编辑器的左侧停靠栏。
	class_tree = ClassTree.new(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_LEFT_UL, class_tree)

# 当插件从编辑器卸载时调用的函数。
func _exit_tree() -> void:
	# 从停靠栏移除 `class_tree` 控件，并释放其资源。
	remove_control_from_docks(class_tree)
	class_tree.queue_free()

# 设置编辑器节点的函数。
func _setup_editor_nodes() -> void:
	# 获取编辑器的基控件。
	var base = get_editor_interface().get_base_control()
	# 查找所有类型为 `SceneTreeEditor` 的子节点。
	var results = base.find_children("*", "SceneTreeEditor", true, false)
	# 如果找到结果，将第一个结果存储为引擎的元数据。
	if not results.is_empty():
		Engine.set_meta("SceneTreeEditor", results[0])
	# 将编辑器的根节点存储为引擎的元数据。
	Engine.set_meta("EditorNode", get_window().get_child(0, true))
