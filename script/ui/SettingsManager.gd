# SettingsManager.gd - 设置管理器单例
# 统一管理游戏设置，使用信号机制实现解耦

extends Node

# 设置变化信号
signal settings_changed(new_settings)

# 设置文件路径
const CONFIG_FILE = "user://settings.cfg"
const CHARACTER_AI_CONFIG_FILE = "user://character_ai_settings.cfg"

# 当前设置（默认AI设置）
var current_settings = {
	"api_type": "Ollama",
	"model": "qwen2.5:1.5b",
	"api_key": "",
	"show_ai_model_label": true
}

# 角色独立AI设置
var character_ai_settings = {}

# 可用的API类型和模型（通过APIConfig统一管理）
var api_types: Array[String] = []
var _api_config_loaded: bool = false

func _ready():
	_load_api_config()
	load_settings()
	print("[SettingsManager] 设置管理器已初始化")

# 加载API配置
func _load_api_config():
	if not _api_config_loaded:
		api_types = APIConfig.get_api_types()
		_api_config_loaded = true

# 获取当前设置
func get_settings() -> Dictionary:
	return current_settings.duplicate()

# 更新设置并通知所有监听者
func update_settings(new_settings: Dictionary):
	current_settings = new_settings.duplicate()
	save_settings()
	settings_changed.emit(current_settings.duplicate())
	print("[SettingsManager] 设置已更新并通知所有监听者")

# 获取指定API类型的模型列表
func get_models_for_api(api_type: String) -> Array:
	_load_api_config()
	return APIConfig.get_models_for_api(api_type)

# 获取可用模型列表（为了兼容性）
func get_available_models(api_type: String) -> Array:
	return get_models_for_api(api_type)

# 保存设置到文件
func save_settings():
	var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_settings))
		file.close()
		print("[SettingsManager] 设置已保存到文件")
	else:
		print("[SettingsManager错误] 无法打开配置文件进行写入：", CONFIG_FILE)
	
	# 保存角色AI设置
	save_character_ai_settings()

# 从文件加载设置
func load_settings():
	if FileAccess.file_exists(CONFIG_FILE):
		var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			if content.strip_edges() != "":
				var data = JSON.parse_string(content)
				if data:
					current_settings = data
					print("[SettingsManager] 设置已从文件加载")
				else:
					print("[SettingsManager错误] JSON解析失败，使用默认设置")
			else:
				print("[SettingsManager警告] 配置文件为空，使用默认设置")
		else:
			print("[SettingsManager错误] 无法打开配置文件进行读取：", CONFIG_FILE)
	else:
		print("[SettingsManager] 配置文件不存在，使用默认设置")
	
	# 加载角色AI设置
	load_character_ai_settings()

# 获取角色AI设置（优先使用角色独立设置，没有则返回默认设置）
func get_character_ai_settings(character_name: String) -> Dictionary:
	if character_ai_settings.has(character_name):
		return character_ai_settings[character_name].duplicate()
	else:
		return current_settings.duplicate()

# 设置角色AI配置
func set_character_ai_settings(character_name: String, settings: Dictionary):
	character_ai_settings[character_name] = settings.duplicate()
	save_character_ai_settings()
	settings_changed.emit(current_settings.duplicate())
	print("[SettingsManager] 角色 ", character_name, " 的AI设置已更新")

# 删除角色AI设置（恢复使用默认设置）
func remove_character_ai_settings(character_name: String):
	if character_ai_settings.has(character_name):
		character_ai_settings.erase(character_name)
		save_character_ai_settings()
		settings_changed.emit(current_settings.duplicate())
		print("[SettingsManager] 角色 ", character_name, " 已恢复使用默认AI设置")

# 检查角色是否有独立AI设置
func has_character_ai_settings(character_name: String) -> bool:
	return character_ai_settings.has(character_name)

# 获取所有有独立AI设置的角色列表
func get_characters_with_ai_settings() -> Array:
	return character_ai_settings.keys()

# 保存角色AI设置到文件
func save_character_ai_settings():
	var file = FileAccess.open(CHARACTER_AI_CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(character_ai_settings))
		file.close()
		print("[SettingsManager] 角色AI设置已保存到文件")
	else:
		print("[SettingsManager错误] 无法打开角色AI配置文件进行写入：", CHARACTER_AI_CONFIG_FILE)

# 从文件加载角色AI设置
func load_character_ai_settings():
	if FileAccess.file_exists(CHARACTER_AI_CONFIG_FILE):
		var file = FileAccess.open(CHARACTER_AI_CONFIG_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			if content.strip_edges() != "":
				var data = JSON.parse_string(content)
				if data:
					character_ai_settings = data
					print("[SettingsManager] 角色AI设置已从文件加载")
				else:
					print("[SettingsManager错误] 角色AI设置JSON解析失败")
			else:
				print("[SettingsManager警告] 角色AI配置文件为空")
		else:
			print("[SettingsManager错误] 无法打开角色AI配置文件进行读取：", CHARACTER_AI_CONFIG_FILE)
	else:
		print("[SettingsManager] 角色AI配置文件不存在，使用空配置")
