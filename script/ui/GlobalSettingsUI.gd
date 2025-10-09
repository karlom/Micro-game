extends CanvasLayer

# GlobalSettingsUI - 游戏设置界面管理
# 现在使用SettingsManager统一管理所有设置

# 当前设置（从SettingsManager获取）
var current_settings = {}

@onready var settings_ui = $SettingsUI
@onready var api_type_option = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/APITypeContainer/APITypeOption
@onready var model_option = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/ModelContainer/ModelOption
@onready var api_key_input = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/APIKeyContainer/APIKeyInput
@onready var ai_label_checkbox = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/AILabelContainer/AILabelCheckBox
@onready var save_button = $SettingsUI/NinePatchRect/VBoxContainer/ButtonContainer/SaveButton
@onready var cancel_button = $SettingsUI/NinePatchRect/VBoxContainer/ButtonContainer/CancelButton
@onready var map_button = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/MapButton
@onready var main_menu_button = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/MainMenuButton
@onready var quit_button = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/QuitButton

func _ready():
	hide_settings()
	
	# 初始化API类型选项
	for type in SettingsManager.api_types:
		api_type_option.add_item(type)
	
	# 连接设置管理器
	SettingsManager.settings_changed.connect(_on_settings_changed)
	current_settings = SettingsManager.get_settings()
	update_ui()
	print("[GlobalSettingsUI] 已连接设置管理器")
	
	# 连接信号
	api_type_option.item_selected.connect(_on_api_type_selected)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	map_button.pressed.connect(_on_map_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 设置为单例，确保在场景转换时不被销毁
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if settings_ui.visible:
			hide_settings()
		else:
			show_settings()

# 设置变化回调
func _on_settings_changed(new_settings: Dictionary):
	current_settings = new_settings.duplicate()
	update_ui()
	print("[GlobalSettingsUI] 设置已更新，UI已刷新")

# 更新UI显示
func update_ui():
	# 设置API类型
	var api_index = SettingsManager.api_types.find(current_settings.api_type)
	if api_index >= 0:
		api_type_option.selected = api_index
	
	# 更新模型选项
	model_option.clear()
	var models = SettingsManager.get_models_for_api(current_settings.api_type)
	for model in models:
		model_option.add_item(model)
	
	# 选择当前模型
	var model_index = models.find(current_settings.model)
	if model_index >= 0:
		model_option.select(model_index)
	
	# 设置API Key
	api_key_input.text = current_settings.api_key
	
	# 设置AI标签显示复选框
	ai_label_checkbox.button_pressed = current_settings.get("show_ai_model_label", true)
	
	# 根据API类型显示/隐藏API Key输入框
	api_key_input.get_parent().visible = current_settings.api_type != "Ollama"

# API类型选择回调
func _on_api_type_selected(index):
	current_settings.api_type = SettingsManager.api_types[index]
	# 重置模型选择
	var models = SettingsManager.get_models_for_api(current_settings.api_type)
	current_settings.model = models[0]
	update_ui()

# 保存按钮回调
func _on_save_pressed():
	current_settings.model = model_option.get_item_text(model_option.selected)
	if current_settings.api_type != "Ollama":
		current_settings.api_key = api_key_input.text
	
	# 保存AI标签显示设置
	current_settings.show_ai_model_label = ai_label_checkbox.button_pressed
	
	# 通过SettingsManager更新设置
	SettingsManager.update_settings(current_settings)
	hide_settings()
	print("[GlobalSettingsUI] 设置已保存并通知所有组件")

# 取消按钮回调
func _on_cancel_pressed():
	current_settings = SettingsManager.get_settings()
	update_ui()
	hide_settings()

# 地图按钮回调
func _on_map_pressed():
	hide_settings()
	get_tree().change_scene_to_file("res://scene/MapSelection.tscn")

# 主菜单按钮回调
func _on_main_menu_pressed():
	hide_settings()
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")

# 退出按钮回调
func _on_quit_pressed():
	get_tree().quit()

# 显示设置界面
func show_settings():
	settings_ui.visible = true

# 隐藏设置界面
func hide_settings():
	settings_ui.visible = false

# 检查设置UI是否可见
func is_settings_visible() -> bool:
	return settings_ui.visible
