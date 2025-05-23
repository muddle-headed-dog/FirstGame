# 这是一个 Godot 编辑器插件脚本，用于在编辑器中显示和管理节点类别的树形结构。
# 它扩展了 `VBoxContainer` 类，并提供了搜索、分类和拖放节点的功能。
@tool
class_name ClassTree
extends VBoxContainer

# 变量声明
var root: TreeItem # 树的根节点项
var editor_interface: EditorInterface # 对编辑器接口的引用
var search_bar: LineEdit # 搜索栏控件
var tree: Tree # 用于显示节点的树形控件
var full_node_list: Array = [] # 完整的节点类列表
# 存储各个根项的折叠状态
var root_items_collapsed_state = {
	"Favorite": true, # 收藏节点分类
	"Recent": true, # 最近使用的节点
	"2D Nodes": true, # 2D节点分类
	"Control": true, # 控制节点分类
	"All Nodes": true, # 所有节点分类
}
var is_search_active = false # 是否处于搜索模式

# 收藏节点列表，初始默认值
var favorite_nodes = [
	"Node2D", "Sprite2D", "AnimatedSprite2D", "CollisionShape2D",
	"Area2D", "CharacterBody2D", "Camera2D", "TileMap", "Button", "Label"
]

# 最近使用的节点，最多保存10个
var recent_nodes = []
const MAX_RECENT_NODES = 10
const CONFIG_PATH = "user://drag_n_drop_nodes.cfg"

# 定义常用节点列表，按照需要显示的顺序排列
var control_nodes = [
	"Control", "Button", "Label", "Panel", "TextEdit", "LineEdit",
	"ColorRect", "TextureRect", "VBoxContainer", "HBoxContainer",
	"GridContainer", "OptionButton", "CheckBox", "ItemList"
]

# 当前右键菜单
var current_popup: PopupMenu = null
var current_node_name: String = ""

# 初始化函数，设置控件和连接信号
func _init(_editor_interface: EditorInterface) -> void:
	editor_interface = _editor_interface
	name = "节点" # 设置面板名称
	
	# 加载保存的配置
	load_config()

	# 创建水平布局存放搜索栏和按钮
	var top_bar = HBoxContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(top_bar)

	# 创建搜索栏
	search_bar = LineEdit.new()
	search_bar.placeholder_text = "搜索节点..." # 设置占位文本
	search_bar.clear_button_enabled = true # 启用清除按钮
	search_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(search_bar)
	search_bar.text_changed.connect(self._on_search_text_changed) # 连接文本变化信号
	
	# 创建收藏按钮
	var fav_button = Button.new()
	fav_button.text = "收藏"
	fav_button.tooltip_text = "将选中的节点添加到收藏夹或从收藏夹移除"
	top_bar.add_child(fav_button)
	fav_button.pressed.connect(self._on_favorite_button_pressed)

	# 创建树形控件
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL # 垂直方向填满空间
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL # 水平方向填满空间
	tree.set_drag_forwarding(_get_drag_data_fw, Callable(), Callable()) # 设置拖拽转发
	add_child(tree)

	# 连接树形控件的信号
	tree.item_activated.connect(self._on_item_activated) # 项被激活时的信号
	tree.item_collapsed.connect(self._on_item_collapsed) # 项被折叠时的信号
	
	# 仍然保留右键菜单代码，使用多种方法尝试解决问题
	tree.item_mouse_selected.connect(self._on_item_mouse_selected)
	tree.button_clicked.connect(self._on_tree_button_clicked)

	# 生成节点列表和类树
	generate_full_node_list()
	generate_class_tree()

# 从配置文件加载收藏节点和最近使用节点
func load_config() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	
	if err == OK:
		if config.has_section_key("favorites", "nodes"):
			favorite_nodes = config.get_value("favorites", "nodes")
		if config.has_section_key("recent", "nodes"):
			recent_nodes = config.get_value("recent", "nodes")
	
	# 确保收藏列表不为空（如果用户清空了配置文件）
	if favorite_nodes.is_empty():
		favorite_nodes = [
			"Node2D", "Sprite2D", "AnimatedSprite2D", "CollisionShape2D",
			"Area2D", "CharacterBody2D", "Camera2D", "TileMap", "Button", "Label"
		]

# 保存配置到文件
func save_config() -> void:
	var config = ConfigFile.new()
	config.set_value("favorites", "nodes", favorite_nodes)
	config.set_value("recent", "nodes", recent_nodes)
	config.save(CONFIG_PATH)

# 添加节点到最近使用列表
func add_to_recent(node_name: String) -> void:
	# 如果已经在列表中，先移除
	if node_name in recent_nodes:
		recent_nodes.erase(node_name)
	
	# 添加到列表开头
	recent_nodes.push_front(node_name)
	
	# 保持列表长度不超过最大限制
	while recent_nodes.size() > MAX_RECENT_NODES:
		recent_nodes.pop_back()
	
	# 保存配置
	save_config()
	
	# 更新树形视图
	generate_class_tree()

# 添加或移除收藏节点
func toggle_favorite(node_name: String) -> void:
	if node_name in favorite_nodes:
		favorite_nodes.erase(node_name)
	else:
		favorite_nodes.append(node_name)
	
	# 保存配置
	save_config()
	
	# 更新树形视图
	generate_class_tree()

# 生成完整的节点类列表
func generate_full_node_list() -> void:
	full_node_list.clear() # 清空列表
	var node_classes = ClassDB.get_inheriters_from_class("Node") # 获取所有继承自Node的类
	node_classes.append("Node") # 添加Node基类

	for _class_name in node_classes:
		# 跳过MissingNode和含有Editor的类
		if _class_name == "MissingNode" or "Editor" in _class_name:
			continue
		# 跳过不能实例化或禁用的类
		if not ClassDB.can_instantiate(_class_name) or not ClassDB.is_class_enabled(_class_name):
			continue
		# 跳过3D节点
		if "3D" in _class_name:
			continue
		full_node_list.append(_class_name) # 添加到列表

	# 排序列表并确保Node在首位
	full_node_list.sort()
	if "Node" in full_node_list:
		full_node_list.erase("Node")
		full_node_list.insert(0, "Node")

# 生成并显示类树
func generate_class_tree() -> void:
	tree.clear() # 清空树
	var editor_theme: Theme = editor_interface.get_editor_theme() # 获取编辑器主题
	var search_text = search_bar.text.strip_edges().to_lower() # 获取搜索文本并转小写
	is_search_active = search_text != "" # 检查是否处于搜索状态

	# 创建根节点
	root = tree.create_item()
	root.set_text(0, "节点") # 设置文本
	root.set_icon(0, editor_theme.get_icon("Sprite2D", "EditorIcons")) # 设置图标
	root.set_disable_folding(true) # 禁用折叠

	# 定义节点分类 - 移除3D节点分类
	var categories = {
		"Favorite": {"nodes": favorite_nodes, "icon": "Favorites"}, # 收藏节点
		"Recent": {"nodes": recent_nodes, "icon": "History"}, # 最近使用节点
		"2D Nodes": {"nodes": [], "icon": "Node2D"}, # 2D节点
		"Control": {"nodes": [], "icon": "Control"}, # 控制节点
		"All Nodes": {"nodes": full_node_list, "icon": "Node"} # 所有节点(已过滤掉3D节点)
	}

	# 将节点分配到相应的分类
	for node_name in full_node_list:
		if "2D" in node_name and not node_name in favorite_nodes:
			categories["2D Nodes"].nodes.append(node_name) # 添加到2D节点分类
		elif node_name.begins_with("Control") or ClassDB.is_parent_class(node_name, "Control"):
			if not node_name in favorite_nodes and not node_name in control_nodes:
				categories["Control"].nodes.append(node_name) # 添加到Control节点分类
	
	# 添加预定义的Control节点
	for node_name in control_nodes:
		if not node_name in favorite_nodes and node_name in full_node_list:
			categories["Control"].nodes.append(node_name)

	# 创建分类项
	for category in categories:
		var parent = tree.create_item(root) # 创建分类项
		parent.set_text(0, category) # 设置分类名称
		# 使用适当的图标
		var icon_name = categories[category].icon
		if not editor_theme.has_icon(icon_name, "EditorIcons"):
			if category == "Favorite":
				icon_name = "Favorites"
			elif category == "Recent":
				icon_name = "History"
			else:
				icon_name = "Node"
		parent.set_icon(0, editor_theme.get_icon(icon_name, "EditorIcons")) # 设置分类图标
		
		# 搜索时展开分类，否则使用保存的折叠状态
		if is_search_active:
			parent.set_collapsed(false) # 展开分类
		else:
			parent.set_collapsed(root_items_collapsed_state.get(category, true))

		# 创建节点项
		for node_name in categories[category].nodes:
			# 如果搜索激活，则只显示匹配的节点
			if is_search_active and node_name.to_lower().find(search_text) == -1:
				continue
			create_tree_item(parent, node_name, editor_theme) # 创建节点项

# 创建树项
func create_tree_item(parent: TreeItem, node_name: String, theme: Theme) -> void:
	var class_item = tree.create_item(parent) # 创建树项
	var class_icon = theme.get_icon("Node", "EditorIcons") # 默认使用Node图标
	if theme.has_icon(node_name, "EditorIcons"):
		class_icon = theme.get_icon(node_name, "EditorIcons") # 使用特定节点图标
	class_item.set_text(0, node_name) # 设置节点名称
	class_item.set_icon(0, class_icon) # 设置节点图标
	class_item.set_selectable(0, ClassDB.can_instantiate(node_name)) # 设置是否可选
	class_item.set_meta("node_name", node_name) # 设置元数据
	
	# 如果是收藏夹中的节点，添加一个星标指示
	if node_name in favorite_nodes and parent.get_text(0) != "Favorite":
		class_item.set_suffix(0, " ★")

# 添加此函数，处理收藏按钮点击
func _on_favorite_button_pressed() -> void:
	var item = tree.get_selected()
	if not item or item.get_parent() == root:
		# 没有选中项或选中的是分类项
		return
		
	var node_name = item.get_text(0)
	toggle_favorite(node_name)

# 修改右键菜单弹出函数，使用右键按钮值2
func _on_item_mouse_selected(position: Vector2, mouse_button_index: int) -> void:
	# 调试信息
	# 使用正确的右键值2
	if mouse_button_index != 2: # 右键是2
		return
		
	var item = tree.get_selected()
	if not item:
		return
		
	
	# 忽略分类项
	if item.get_parent() == root:
		return
	
	# 获取节点名称    
	var node_name = item.get_text(0)
	current_node_name = node_name
	
	# 如果有之前的弹出菜单，先清理
	if is_instance_valid(current_popup):
		current_popup.queue_free()
	
	# 创建右键菜单
	current_popup = PopupMenu.new()
	
	if node_name in favorite_nodes:
		current_popup.add_item("从收藏中移除", 1)
	else:
		current_popup.add_item("添加到收藏", 1)
	
	# 获取点击位置的全局坐标
	var global_click_pos = tree.get_screen_position() + position
	
	# 添加到控件树，但使用编辑器的根窗口
	get_tree().get_root().add_child(current_popup)
	
	# 设置菜单位置为鼠标点击位置
	current_popup.position = global_click_pos
	
	# 连接信号
	if current_popup.id_pressed.is_connected(_on_popup_menu_id_pressed):
		current_popup.id_pressed.disconnect(_on_popup_menu_id_pressed)
	current_popup.id_pressed.connect(_on_popup_menu_id_pressed)
	
	if current_popup.visibility_changed.is_connected(_on_popup_hidden):
		current_popup.visibility_changed.disconnect(_on_popup_hidden)
	current_popup.visibility_changed.connect(_on_popup_hidden)
	
	# 显示菜单
	current_popup.popup()

# 当弹出菜单隐藏时清理
func _on_popup_hidden() -> void:
	if is_instance_valid(current_popup) and not current_popup.visible:
		current_popup.queue_free()
		current_popup = null

# 处理右键菜单选项
func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # 添加到场景
			var item = tree.get_selected()
			if item:
				_create_node(item)
		1: # 切换收藏状态
			toggle_favorite(current_node_name)

# 搜索文本变化时的回调
func _on_search_text_changed(new_text: String) -> void:
	generate_class_tree() # 重新生成类树以反映搜索结果

# 项被激活（双击）时的回调
func _on_item_activated() -> void:
	var item = tree.get_selected() # 获取选中的项
	if item == null:
		return
	_create_node(item) # 创建节点

# 创建节点实例并添加到场景
func _create_node(item: TreeItem) -> void:
	var node_type = item.get_text(0) # 获取节点类型
	var node: Node = ClassDB.instantiate(node_type) # 实例化节点
	if node == null:
		return
		
	# 添加到最近使用的节点
	add_to_recent(node_type)
	
	var scene_root = editor_interface.get_edited_scene_root() # 获取当前编辑场景的根节点
	
	# 如果没有根节点，将此节点设置为根节点
	if not is_instance_valid(scene_root):
		var tree_editor = Engine.get_meta("SceneTreeEditor", null) # 获取场景树编辑器
		var editor_node = Engine.get_meta("EditorNode", null) # 获取编辑器节点
		if not is_instance_valid(tree_editor) or not is_instance_valid(editor_node):
			node.free() # 避免内存泄漏
			return
		editor_node.call("set_edited_scene", node) # 设置为编辑场景
		tree_editor.call("update_tree") # 更新树
		return
	
	# 将节点添加到现有场景
	scene_root.add_child(node, true) # 添加为子节点
	node.owner = scene_root # 设置所有者为场景根节点

# 项折叠状态变化时的回调
func _on_item_collapsed(item: TreeItem) -> void:
	var item_text = item.get_text(0)
	if item_text in root_items_collapsed_state:
		root_items_collapsed_state[item_text] = item.is_collapsed()

# 处理拖放数据
func _get_drag_data_fw(position: Vector2) -> Variant:
	var current_scene = editor_interface.get_edited_scene_root()
	if not is_instance_valid(current_scene):
		return null
	
	var item := tree.get_item_at_position(position)
	if not item:
		return null
	
	var _class_name = item.get_text(0)
	if _class_name.is_empty() or not ClassDB.can_instantiate(_class_name):
		return null
	
	# 添加到最近使用
	add_to_recent(_class_name)
	
	# 创建节点实例
	var instance: Node = ClassDB.instantiate(_class_name) as Node
	current_scene.add_child(instance, true)
	instance.owner = current_scene
	editor_interface.get_selection().clear()
	editor_interface.get_selection().add_node(instance)
	
	# 创建拖放预览
	var editor_theme = editor_interface.get_editor_theme()
	var class_icon = editor_theme.get_icon("Node", "EditorIcons")
	if editor_theme.has_icon(_class_name, "EditorIcons"):
		class_icon = editor_theme.get_icon(_class_name, "EditorIcons")
	
	var hb := HBoxContainer.new()
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2i(16, 16)
	tr.texture = class_icon
	hb.add_child(tr)
	var label := Label.new()
	label.text = _class_name
	hb.add_child(label)
	set_drag_preview(hb)
	return {"type": "nodes", "nodes": [instance.get_path()]}

# 修改按钮点击处理函数
func _on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != 1: # 改为1，而不是2
		return
		
	# 忽略分类项
	if item.get_parent() == root:
		return
	
	var node_name = item.get_text(0)
	current_node_name = node_name
	
	# 如果有之前的弹出菜单，先清理
	if is_instance_valid(current_popup):
		current_popup.queue_free()
	
	# 创建右键菜单
	current_popup = PopupMenu.new()
	current_popup.add_item("添加到场景", 0)
	
	if node_name in favorite_nodes:
		current_popup.add_item("从收藏中移除", 1)
	else:
		current_popup.add_item("添加到收藏", 1)
	
	# 将弹出菜单添加到场景树
	get_tree().root.add_child(current_popup)
	
	# 尝试方法2：使用鼠标全局位置并使用不同的父节点
	var global_pos = get_viewport().get_mouse_position()
	current_popup.position = global_pos
	
	# 连接信号
	current_popup.id_pressed.connect(_on_popup_menu_id_pressed)
	current_popup.visibility_changed.connect(_on_popup_hidden)
	
	# 显示菜单
	current_popup.popup()
