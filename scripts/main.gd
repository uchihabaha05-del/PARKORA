extends Node3D

const STARTING_COINS := 5000
const BUILD_COSTS := {"carousel": 1200, "ferris": 2400, "tree": 100, "path": 25, "food": 650, "drink": 500, "toilet": 450, "rest": 350}
const RIDE_TICKET_PRICE := 35
const ENTRY_TICKET_PRICE := 10
const MAX_VISITORS := 14
const VISITOR_SPAWN_SECONDS := 3.5

var coins := STARTING_COINS
var selected_build := ""
var camera_pivot: Node3D
var camera: Camera3D
var coins_label: Label
var visitors_label: Label
var hint_label: Label
var build_buttons: Dictionary = {}
var touch_dragged := false
var visitors: Array[Dictionary] = []
var rides: Array[Dictionary] = []
var shops: Array[Dictionary] = []
var facilities: Array[Dictionary] = []
var path_cells: Dictionary = {}
var spawn_timer := 1.0
var total_visitors := 0
var total_income := 0
var total_expenses := 0
var admission_income := 0
var ride_income := 0
var service_income := 0
var staff_expenses := 0
var facility_expenses := 0
var ride_maintenance_expenses := 0
var period_income := 0
var period_expenses := 0
var reporting_timer := 60.0
var objective_index := 0
var objective_label: Label
var land_expansions := 0
var land_button: Button
var land_label: Label
var maintenance_timer := 10.0
var save_timer := 15.0
var built_objects: Array[Dictionary] = []
var park_rating := 50.0
var economy_label: Label
var selected_ride_index := -1
var ride_panel: PanelContainer
var ride_info_label: Label
var ride_upgrade_button: Button
var ride_price_label: Label
var ride_condition_label: Label
var ride_repair_button: Button
var staff_label: Label
var hire_cleaner_button: Button
var hire_mechanic_button: Button
var cleaners := 0
var mechanics := 0
var cleanliness := 100.0
var litter_nodes: Array[Node3D] = []
var cleaning_timer := 4.0
var last_saved_unix := 0
var offline_notice := ""
var offline_earnings := 0
var offline_costs := 0

var grass_material: StandardMaterial3D
var path_material: StandardMaterial3D
var wood_material: StandardMaterial3D
var leaf_material: StandardMaterial3D
var red_material: StandardMaterial3D
var yellow_material: StandardMaterial3D
var blue_material: StandardMaterial3D
var cream_material: StandardMaterial3D
var green_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var shirt_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_create_materials()
	_create_environment()
	_create_ground()
	_create_entrance()
	_create_starter_decoration()
	_load_game()
	_create_camera()
	_create_ui()
	_update_hud()
	if offline_notice != "":
		_set_hint(offline_notice)
	else:
		_set_hint("Построй аттракцион, чтобы привлечь посетителей и зарабатывать монеты")


func _process(delta: float) -> void:
	_update_visitors(delta)
	_animate_rides(delta)
	_update_economy(delta)
	_update_reporting_period(delta)
	_update_objectives()
	save_timer -= delta
	if save_timer <= 0.0:
		save_timer = 15.0
		_save_game()
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = _visitor_spawn_interval()
		_spawn_visitor()


func _create_materials() -> void:
	grass_material = _material(Color("#79c96b"))
	path_material = _material(Color("#e9d7ad"))
	wood_material = _material(Color("#9b603b"))
	leaf_material = _material(Color("#36a96b"))
	red_material = _material(Color("#f05b63"))
	yellow_material = _material(Color("#ffd45c"))
	blue_material = _material(Color("#59b9e8"))
	cream_material = _material(Color("#fff0cf"))
	green_material = _material(Color("#55b86a"))
	skin_material = _material(Color("#f2bd91"))
	shirt_materials = [
		_material(Color("#f06b68")),
		_material(Color("#5a9fe8")),
		_material(Color("#f2c94c")),
		_material(Color("#a77be8")),
		_material(Color("#54b99a"))
	]


func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.9
	return result


func _create_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#328ac5")
	sky_material.sky_horizon_color = Color("#b9e3f5")
	sky_material.ground_bottom_color = Color("#536b49")
	sky_material.ground_horizon_color = Color("#b9d7a5")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8e9ff")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)


func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100.0, 100.0)
	ground.mesh = plane
	ground.material_override = grass_material
	ground.position.y = -0.12
	add_child(ground)

	for x in range(-2, 3):
		for z in range(5, 9):
			var tile_position := Vector3(float(x) * 2.0, 0.015, float(z) * 2.0)
			_add_box(tile_position, Vector3(1.95, 0.08, 1.95), path_material)
			_register_path(tile_position)


func _create_entrance() -> void:
	_add_box(Vector3(0, 2.2, 17.0), Vector3(12.0, 0.55, 0.65), red_material)
	_add_box(Vector3(-5.5, 1.1, 17.0), Vector3(0.65, 2.2, 0.65), cream_material)
	_add_box(Vector3(5.5, 1.1, 17.0), Vector3(0.65, 2.2, 0.65), cream_material)
	_add_box(Vector3(0, 2.65, 17.0), Vector3(3.8, 0.55, 0.7), yellow_material)
	_add_box(Vector3(0, 0.12, 11.0), Vector3(3.0, 0.18, 12.0), path_material)
	for z in range(5, 18, 2):
		_register_path(Vector3(0, 0, float(z)))


func _create_starter_decoration() -> void:
	for i in range(10):
		var x := -18.0 + float(i) * 4.0
		_create_tree(Vector3(x, 0.0, -15.0))
		_create_tree(Vector3(x, 0.0, 21.0))
	for i in range(5):
		_create_tree(Vector3(-21.0, 0.0, -10.0 + float(i) * 7.0))
		_create_tree(Vector3(21.0, 0.0, -10.0 + float(i) * 7.0))


func _create_camera() -> void:
	camera_pivot = Node3D.new()
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 23.0, 31.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.fov = 52.0
	camera.current = true
	camera_pivot.add_child(camera)


func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	coins_label = Label.new()
	coins_label.position = Vector2(24, 18)
	coins_label.add_theme_font_size_override("font_size", 30)
	coins_label.add_theme_color_override("font_color", Color.WHITE)
	coins_label.add_theme_color_override("font_shadow_color", Color("#263c35"))
	coins_label.add_theme_constant_override("shadow_offset_x", 2)
	coins_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(coins_label)

	visitors_label = Label.new()
	visitors_label.position = Vector2(24, 58)
	visitors_label.add_theme_font_size_override("font_size", 19)
	visitors_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(visitors_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24, 88)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(hint_label)

	economy_label = Label.new()
	economy_label.position = Vector2(24, 116)
	economy_label.add_theme_font_size_override("font_size", 15)
	economy_label.add_theme_color_override("font_color", Color("#fff0cf"))
	root.add_child(economy_label)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -470
	panel.offset_right = 470
	panel.offset_top = -108
	panel.offset_bottom = -14
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.19, 0.9)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	_add_build_button(row, "Карусель\n🪙 1 200", "carousel")
	_add_build_button(row, "Колесо 🔒\n🪙 2 400", "ferris")
	_add_build_button(row, "Дерево\n🪙 100", "tree")
	_add_build_button(row, "Дорожка\n🪙 25", "path")
	_add_build_button(row, "Еда 🍔\n🪙 650", "food")
	_add_build_button(row, "Напитки 🥤\n🪙 500", "drink")
	_add_build_button(row, "Туалет 🚻\n🪙 450", "toilet")
	_add_build_button(row, "Отдых 🪑\n🪙 350", "rest")
	_add_clear_button(row)
	_create_ride_management_panel(root)
	_create_staff_panel(root)
	_create_objective_panel(root)
	_create_land_panel(root)


func _create_staff_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 190)
	panel.custom_minimum_size = Vector2(290, 146)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.13, 0.17, 0.9)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	staff_label = Label.new()
	staff_label.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(staff_label)
	hire_cleaner_button = Button.new()
	hire_cleaner_button.text = "Нанять уборщика  •  🪙 300"
	hire_cleaner_button.custom_minimum_size = Vector2(0, 34)
	hire_cleaner_button.pressed.connect(_hire_cleaner)
	column.add_child(hire_cleaner_button)
	hire_mechanic_button = Button.new()
	hire_mechanic_button.text = "Нанять механика  •  🪙 500"
	hire_mechanic_button.custom_minimum_size = Vector2(0, 34)
	hire_mechanic_button.pressed.connect(_hire_mechanic)
	column.add_child(hire_mechanic_button)


func _create_objective_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 350)
	panel.custom_minimum_size = Vector2(290, 88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.13, 0.17, 0.9)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	objective_label = Label.new()
	objective_label.add_theme_color_override("font_color", Color.WHITE)
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(objective_label)
	_update_objective_text()


func _update_objective_text() -> void:
	var objective_text := ""
	var reward := 0
	match objective_index:
		0:
			objective_text = "Прими первых 5 посетителей"
			reward = 500
		1:
			objective_text = "Построй второй аттракцион"
			reward = 800
		2:
			objective_text = "Построй 2 объекта обслуживания"
			reward = 600
		3:
			objective_text = "Заработай 1 500 монет общей выручки"
			reward = 1000
		4:
			objective_text = "Найми уборщика или механика"
			reward = 500
		5:
			objective_text = "Доведи рейтинг и чистоту до 70%"
			reward = 1500
		_:
			objective_text = "Все основные цели выполнены! Продолжай развивать парк"
	if objective_index >= 6:
		objective_label.text = "🏆 Цели\n" + objective_text
	else:
		objective_label.text = "🎯 ЦЕЛЬ " + str(objective_index + 1) + "/6\n" + objective_text + "\nНаграда: 🪙 " + _format_number(reward)


func _update_objectives() -> void:
	var completed := false
	var reward := 0
	match objective_index:
		0:
			completed = total_visitors >= 5
			reward = 500
		1:
			completed = rides.size() >= 2
			reward = 800
		2:
			completed = shops.size() + facilities.size() >= 2
			reward = 600
		3:
			completed = total_income >= 1500
			reward = 1000
		4:
			completed = cleaners + mechanics >= 1
			reward = 500
		5:
			completed = park_rating >= 70.0 and cleanliness >= 70.0
			reward = 1500
	if completed and objective_index < 6:
		coins += reward
		objective_index += 1
		_update_objective_text()
		_update_hud()
		_save_game()
		_set_hint("Цель выполнена! Награда: +🪙 " + _format_number(reward))


func _create_land_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 450)
	panel.custom_minimum_size = Vector2(290, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.13, 0.17, 0.9)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	land_label = Label.new()
	land_label.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(land_label)
	land_button = Button.new()
	land_button.custom_minimum_size = Vector2(0, 34)
	land_button.pressed.connect(_buy_land_expansion)
	column.add_child(land_button)
	_update_land_panel()


func _land_expansion_cost() -> int:
	match land_expansions:
		0:
			return 3000
		1:
			return 4500
		2:
			return 6000
	return 0


func _update_land_panel() -> void:
	if land_label == null or land_button == null:
		return
	if land_expansions >= 3:
		land_label.text = "🌳 Вся доступная территория открыта"
		land_button.text = "Все участки куплены"
		land_button.disabled = true
	else:
		var cost := _land_expansion_cost()
		var names := ["Северный участок", "Западный участок", "Восточный участок"]
		land_label.text = "🗺️ Участки: " + str(land_expansions) + "/3"
		land_button.text = "Открыть " + names[land_expansions] + " • 🪙 " + _format_number(cost)
		land_button.disabled = coins < cost


func _buy_land_expansion() -> void:
	if land_expansions >= 3:
		return
	var cost := _land_expansion_cost()
	if coins < cost:
		_set_hint("Не хватает монет для покупки участка")
		return
	coins -= cost
	_create_land_zone(land_expansions)
	land_expansions += 1
	_update_land_panel()
	_update_hud()
	_save_game()
	_set_hint("Новый участок парка открыт! Проложи дорожки к новой территории")


func _create_land_zone(zone_index: int) -> void:
	var min_x := -10.0
	var max_x := 10.0
	var min_z := -26.0
	var max_z := -8.0
	if zone_index == 1:
		min_x = -28.0
		max_x = -10.0
		min_z = -6.0
		max_z = 22.0
	elif zone_index == 2:
		min_x = 10.0
		max_x = 28.0
		min_z = -6.0
		max_z = 22.0
	var width := max_x - min_x
	var depth := max_z - min_z
	var center_x := (min_x + max_x) * 0.5
	var center_z := (min_z + max_z) * 0.5
	_add_box(Vector3(center_x, 0.055, min_z), Vector3(width, 0.12, 0.22), yellow_material)
	_add_box(Vector3(center_x, 0.055, max_z), Vector3(width, 0.12, 0.22), yellow_material)
	_add_box(Vector3(min_x, 0.055, center_z), Vector3(0.22, 0.12, depth), yellow_material)
	_add_box(Vector3(max_x, 0.055, center_z), Vector3(0.22, 0.12, depth), yellow_material)


func _is_position_in_owned_land(position: Vector3) -> bool:
	if position.x >= -10.0 and position.x <= 10.0 and position.z >= -8.0 and position.z <= 22.0:
		return true
	for zone_index in range(land_expansions):
		if zone_index == 0 and position.x >= -10.0 and position.x <= 10.0 and position.z >= -26.0 and position.z <= -8.0:
			return true
		if zone_index == 1 and position.x >= -28.0 and position.x <= -10.0 and position.z >= -6.0 and position.z <= 22.0:
			return true
		if zone_index == 2 and position.x >= 10.0 and position.x <= 28.0 and position.z >= -6.0 and position.z <= 22.0:
			return true
	return false


func _hire_cleaner() -> void:
	if coins < 300:
		_set_hint("Не хватает 300 монет для найма уборщика")
		return
	coins -= 300
	cleaners += 1
	_update_hud()
	_save_game()
	_set_hint("Нанят уборщик! Зарплата: 8 монет каждые 10 секунд")


func _hire_mechanic() -> void:
	if coins < 500:
		_set_hint("Не хватает 500 монет для найма механика")
		return
	coins -= 500
	mechanics += 1
	_update_hud()
	_save_game()
	_set_hint("Нанят механик! Он обслуживает изношенные аттракционы. Зарплата: 12 монет каждые 10 секунд")


func _spawn_litter(near_position: Vector3) -> void:
	if litter_nodes.size() >= 60:
		return
	var offset := Vector3(randf_range(-4.0, 4.0), 0.12, randf_range(-4.0, 4.0))
	_create_litter(near_position + offset)
	cleanliness = maxf(0.0, cleanliness - 1.2)
	_update_hud()


func _create_litter(position: Vector3) -> void:
	var litter := Node3D.new()
	litter.position = position
	add_child(litter)
	var piece := _add_box_local(litter, Vector3.ZERO, Vector3(0.28, 0.12, 0.22), yellow_material)
	piece.rotation.y = randf_range(0.0, TAU)
	litter_nodes.append(litter)


func _update_cleanliness(interval: float) -> void:
	cleaning_timer -= interval
	if cleaning_timer > 0.0:
		return
	cleaning_timer = 4.0
	if cleaners > 0 and not litter_nodes.is_empty():
		var amount := mini(cleaners, litter_nodes.size())
		for i in range(amount):
			var litter := litter_nodes.pop_front()
			if is_instance_valid(litter):
				litter.queue_free()
			cleanliness = minf(100.0, cleanliness + 2.5)
	elif litter_nodes.size() > 0:
		cleanliness = maxf(0.0, cleanliness - 0.5)
	if cleanliness < 35.0:
		park_rating = maxf(0.0, park_rating - 0.4)
	elif cleanliness > 80.0:
		park_rating = minf(100.0, park_rating + 0.15)


func _create_ride_management_panel(root: Control) -> void:
	ride_panel = PanelContainer.new()
	ride_panel.anchor_left = 1.0
	ride_panel.anchor_right = 1.0
	ride_panel.anchor_top = 0.0
	ride_panel.anchor_bottom = 0.0
	ride_panel.offset_left = -292
	ride_panel.offset_right = -18
	ride_panel.offset_top = 18
	ride_panel.offset_bottom = 270
	ride_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.13, 0.17, 0.94)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	ride_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(ride_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	ride_panel.add_child(column)
	ride_info_label = Label.new()
	ride_info_label.add_theme_font_size_override("font_size", 15)
	ride_info_label.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(ride_info_label)
	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 6)
	column.add_child(price_row)
	var lower_button := Button.new()
	lower_button.text = "− Цена"
	lower_button.custom_minimum_size = Vector2(82, 36)
	lower_button.pressed.connect(_change_ride_price.bind(-5))
	price_row.add_child(lower_button)
	ride_price_label = Label.new()
	ride_price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ride_price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ride_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ride_price_label.add_theme_color_override("font_color", Color("#ffe28a"))
	price_row.add_child(ride_price_label)
	var raise_button := Button.new()
	raise_button.text = "+ Цена"
	raise_button.custom_minimum_size = Vector2(82, 36)
	raise_button.pressed.connect(_change_ride_price.bind(5))
	price_row.add_child(raise_button)
	ride_upgrade_button = Button.new()
	ride_upgrade_button.text = "Улучшить"
	ride_upgrade_button.custom_minimum_size = Vector2(0, 38)
	ride_upgrade_button.pressed.connect(_upgrade_selected_ride)
	column.add_child(ride_upgrade_button)
	ride_condition_label = Label.new()
	ride_condition_label.add_theme_font_size_override("font_size", 13)
	ride_condition_label.add_theme_color_override("font_color", Color("#cde7d2"))
	column.add_child(ride_condition_label)
	ride_repair_button = Button.new()
	ride_repair_button.custom_minimum_size = Vector2(0, 34)
	ride_repair_button.pressed.connect(_repair_selected_ride)
	column.add_child(ride_repair_button)
	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(0, 32)
	close_button.pressed.connect(_close_ride_panel)
	column.add_child(close_button)


func _select_ride_at_position(world_position: Vector3) -> void:
	var nearest := -1
	var nearest_distance := 5.0
	for i in range(rides.size()):
		var ride_position: Vector3 = rides[i]["position"]
		var distance := Vector2(world_position.x, world_position.z).distance_to(Vector2(ride_position.x, ride_position.z))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = i
	if nearest >= 0:
		selected_ride_index = nearest
		ride_panel.visible = true
		_update_ride_panel()
		_set_hint("Аттракцион выбран. Настраивай цену и улучшения")
	else:
		_close_ride_panel()


func _close_ride_panel() -> void:
	selected_ride_index = -1
	if ride_panel != null:
		ride_panel.visible = false


func _update_ride_panel() -> void:
	if selected_ride_index < 0 or selected_ride_index >= rides.size():
		_close_ride_panel()
		return
	var ride: Dictionary = rides[selected_ride_index]
	var ride_name := "Карусель" if ride["kind"] == "carousel" else "Колесо обозрения"
	var level := int(ride.get("level", 1))
	var capacity := int(ride.get("queue_capacity", 6))
	var duration := float(ride.get("ride_duration", 4.0))
	var price := int(ride.get("ticket_price", RIDE_TICKET_PRICE))
	var condition := float(ride.get("condition", 100.0))
	var revenue := int(ride.get("ride_revenue", 0))
	var served := int(ride.get("served", 0))
	var operating_status := "ОТКРЫТ" if condition >= 25.0 else "ЗАКРЫТ — требуется ремонт"
	ride_info_label.text = ride_name + "  •  Ур. " + str(level) + "  •  " + operating_status + "\nОчередь: " + str(capacity) + " мест   •   Катание: " + str(snappedf(duration, 0.1)) + " сек.\nКлиентов: " + str(served) + "   •   Выручка: 🪙 " + _format_number(revenue)
	ride_price_label.text = "🪙 " + str(price)
	ride_condition_label.text = "Состояние: " + str(roundi(condition)) + "%"
	ride_condition_label.add_theme_color_override("font_color", Color("#83d69a") if condition >= 60.0 else Color("#ffb56b") if condition >= 25.0 else Color("#ff7777"))
	var repair_cost := 250 + level * 150
	ride_repair_button.text = "Обслужить  •  🪙 " + _format_number(repair_cost)
	ride_repair_button.disabled = condition >= 99.9 or coins < repair_cost
	if level >= 3:
		ride_upgrade_button.text = "Максимальный уровень"
		ride_upgrade_button.disabled = true
	else:
		var upgrade_cost := level * 1000
		ride_upgrade_button.text = "Улучшить  •  🪙 " + _format_number(upgrade_cost)
		ride_upgrade_button.disabled = coins < upgrade_cost


func _change_ride_price(amount: int) -> void:
	if selected_ride_index < 0 or selected_ride_index >= rides.size():
		return
	var ride: Dictionary = rides[selected_ride_index]
	ride["ticket_price"] = clampi(int(ride.get("ticket_price", RIDE_TICKET_PRICE)) + amount, 5, 200)
	rides[selected_ride_index] = ride
	_sync_ride_save(selected_ride_index)
	_update_ride_panel()
	_save_game()


func _upgrade_selected_ride() -> void:
	if selected_ride_index < 0 or selected_ride_index >= rides.size():
		return
	var ride: Dictionary = rides[selected_ride_index]
	var level := int(ride.get("level", 1))
	if level >= 3:
		return
	var cost := level * 1000
	if coins < cost:
		_set_hint("Недостаточно монет для улучшения")
		return
	coins -= cost
	ride["level"] = level + 1
	ride["queue_capacity"] = int(ride.get("queue_capacity", 6)) + 2
	ride["ride_duration"] = maxf(2.0, float(ride.get("ride_duration", 4.0)) * 0.9)
	rides[selected_ride_index] = ride
	_sync_ride_save(selected_ride_index)
	_update_hud()
	_update_ride_panel()
	_save_game()
	_set_hint("Аттракцион улучшен до уровня " + str(level + 1))


func _repair_selected_ride() -> void:
	if selected_ride_index < 0 or selected_ride_index >= rides.size():
		return
	var ride: Dictionary = rides[selected_ride_index]
	var level := int(ride.get("level", 1))
	var cost := 250 + level * 150
	if float(ride.get("condition", 100.0)) >= 99.9 or coins < cost:
		return
	coins -= cost
	ride["condition"] = 100.0
	rides[selected_ride_index] = ride
	_sync_ride_save(selected_ride_index)
	_update_hud()
	_update_ride_panel()
	_save_game()
	_set_hint("Аттракцион отремонтирован. Состояние восстановлено до 100%")


func _sync_ride_save(ride_index: int) -> void:
	if ride_index < 0 or ride_index >= rides.size():
		return
	var ride: Dictionary = rides[ride_index]
	var position: Vector3 = ride["position"]
	for i in range(built_objects.size()):
		var saved: Dictionary = built_objects[i]
		if saved.get("type", "") == ride["kind"] and saved.get("position", Vector3.ZERO).distance_to(position) < 0.1:
			saved["level"] = int(ride.get("level", 1))
			saved["ticket_price"] = int(ride.get("ticket_price", RIDE_TICKET_PRICE))
			saved["queue_capacity"] = int(ride.get("queue_capacity", 6))
			saved["ride_duration"] = float(ride.get("ride_duration", 4.0))
			saved["condition"] = float(ride.get("condition", 100.0))
			saved["ride_revenue"] = int(ride.get("ride_revenue", 0))
			saved["served"] = int(ride.get("served", 0))
			built_objects[i] = saved
			return


func _add_build_button(parent: HBoxContainer, caption: String, build_type: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(96, 72)
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(_select_build.bind(build_type))
	parent.add_child(button)
	build_buttons[build_type] = button


func _add_clear_button(parent: HBoxContainer) -> void:
	var button := Button.new()
	button.text = "Отмена"
	button.custom_minimum_size = Vector2(70, 72)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_select_build.bind(""))
	parent.add_child(button)


func _select_build(build_type: String) -> void:
	selected_build = build_type
	if selected_build == "":
		_set_hint("Строительство выключено. Перетаскивай экран для вращения камеры")
	else:
		_set_hint("Выбрано: " + _build_name(build_type) + ". Коснись свободного места")
	for key in build_buttons:
		var button: Button = build_buttons[key]
		button.modulate = Color("#ffe28a") if key == selected_build else Color.WHITE


func _build_name(build_type: String) -> String:
	match build_type:
		"carousel":
			return "Карусель"
		"ferris":
			return "Колесо обозрения"
		"tree":
			return "Дерево"
		"path":
			return "Дорожка"
		"food":
			return "Киоск еды"
		"drink":
			return "Киоск напитков"
		"toilet":
			return "Туалет"
		"rest":
			return "Зона отдыха"
	return "Объект"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		touch_dragged = true
		camera_pivot.rotate_y(-event.relative.x * 0.005)
		camera.position.y = clampf(camera.position.y + event.relative.y * 0.035, 12.0, 38.0)
	elif event is InputEventMagnifyGesture:
		_zoom_camera(1.0 / event.factor)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(0.88)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_try_place(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_dragged = false
		elif not touch_dragged:
			_try_place(event.position)


func _zoom_camera(factor: float) -> void:
	camera.position *= factor
	camera.position.y = clampf(camera.position.y, 12.0, 38.0)
	camera.position.z = clampf(camera.position.z, 16.0, 48.0)


func _try_place(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.001:
		return
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return
	var hit := origin + direction * distance
	if absf(hit.x) > 45.0 or absf(hit.z) > 45.0:
		return
	if selected_build == "":
		_select_ride_at_position(hit)
		return
	_place_selected(Vector3(snappedf(hit.x, 2.0), 0.0, snappedf(hit.z, 2.0)))


func _place_selected(position: Vector3) -> void:
	var cost: int = BUILD_COSTS.get(selected_build, 0)
	if not _is_position_in_owned_land(position):
		_set_hint("Эта территория закрыта. Сначала купи новый участок")
		return
	if coins < cost:
		_set_hint("Не хватает монет для строительства")
		return
	if selected_build in ["carousel", "ferris", "food", "drink", "toilet", "rest"]:
		if _find_path(Vector3(0, 0, 13), position + Vector3(0, 0, 2.0)).is_empty():
			_set_hint("Подведи дорожку к объекту — посетители должны иметь к нему доступ")
			return
	match selected_build:
		"carousel":
			_create_carousel(position)
		"ferris":
			_create_ferris_wheel(position)
		"tree":
			_create_tree(position)
		"path":
			_add_box(position + Vector3(0, 0.04, 0), Vector3(2.0, 0.12, 2.0), path_material)
			_register_path(position)
		"food", "drink":
			_create_shop(selected_build, position)
		"toilet", "rest":
			_create_facility(selected_build, position)
	coins -= cost
	var saved_ride := {"type": selected_build, "position": position}
	if selected_build in ["carousel", "ferris"] and not rides.is_empty():
		var new_ride: Dictionary = rides[rides.size() - 1]
		saved_ride["level"] = int(new_ride.get("level", 1))
		saved_ride["ticket_price"] = int(new_ride.get("ticket_price", RIDE_TICKET_PRICE))
		saved_ride["queue_capacity"] = int(new_ride.get("queue_capacity", 6))
		saved_ride["ride_duration"] = float(new_ride.get("ride_duration", 4.0))
		saved_ride["condition"] = float(new_ride.get("condition", 100.0))
		saved_ride["ride_revenue"] = int(new_ride.get("ride_revenue", 0))
		saved_ride["served"] = int(new_ride.get("served", 0))
	built_objects.append(saved_ride)
	_save_game()
	_update_hud()
	_set_hint(_build_name(selected_build) + " построено! 🪙 " + str(coins))


func _create_shop(shop_type: String, position: Vector3) -> void:
	var kiosk := Node3D.new()
	kiosk.position = position
	add_child(kiosk)
	var counter_material: StandardMaterial3D = red_material if shop_type == "food" else blue_material
	_add_box_local(kiosk, Vector3(0, 0.8, 0), Vector3(2.2, 1.6, 1.8), counter_material)
	_add_box_local(kiosk, Vector3(0, 1.75, 0), Vector3(2.5, 0.18, 2.1), cream_material)
	_add_box_local(kiosk, Vector3(0, 2.35, 0), Vector3(2.6, 0.18, 2.2), yellow_material)
	_add_box_local(kiosk, Vector3(0, 2.05, -0.85), Vector3(2.5, 0.55, 0.12), green_material if shop_type == "food" else blue_material)
	shops.append({"kind": shop_type, "position": position, "timer": 5.0, "served": 0})

func _create_facility(facility_type: String, position: Vector3) -> void:
	var building := Node3D.new()
	building.position = position
	add_child(building)
	if facility_type == "toilet":
		_add_box_local(building, Vector3(0, 1.0, 0), Vector3(2.5, 2.0, 2.2), cream_material)
		_add_box_local(building, Vector3(0, 2.1, 0), Vector3(2.7, 0.22, 2.4), blue_material)
		_add_box_local(building, Vector3(0, 1.25, -1.12), Vector3(0.9, 0.85, 0.08), blue_material)
		_add_box_local(building, Vector3(0, 2.65, 0), Vector3(0.7, 0.35, 0.15), yellow_material)
	else:
		_add_box_local(building, Vector3(0, 0.35, 0), Vector3(3.0, 0.35, 1.6), wood_material)
		_add_box_local(building, Vector3(-1.15, 0.85, 0), Vector3(0.18, 0.8, 1.6), wood_material)
		_add_box_local(building, Vector3(1.15, 0.85, 0), Vector3(0.18, 0.8, 1.6), wood_material)
		_add_box_local(building, Vector3(0, 1.65, 0), Vector3(3.2, 0.18, 1.9), green_material)
		for i in range(3):
			_add_cylinder_local(building, Vector3(-0.8 + float(i) * 0.8, 0.9, 0), 0.08, 1.0, wood_material)
	facilities.append({"kind": facility_type, "position": position, "served": 0})


func _create_tree(position: Vector3) -> void:
	_add_cylinder(position + Vector3(0, 1.0, 0), 0.28, 2.0, wood_material)
	_add_sphere(position + Vector3(0, 2.5, 0), 1.25, leaf_material)
	_add_sphere(position + Vector3(0.75, 2.25, 0.1), 0.75, leaf_material)


func _create_carousel(position: Vector3) -> void:
	var ride := Node3D.new()
	ride.position = position
	add_child(ride)
	_add_cylinder_local(ride, Vector3(0, 0.25, 0), 3.4, 0.5, cream_material)
	_add_cylinder_local(ride, Vector3(0, 2.0, 0), 0.22, 3.2, red_material)
	_add_cylinder_local(ride, Vector3(0, 3.65, 0), 3.0, 0.35, yellow_material)
	var spinning := Node3D.new()
	spinning.position.y = 2.0
	ride.add_child(spinning)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var seat_position := Vector3(cos(angle) * 2.25, -0.55, sin(angle) * 2.25)
		var seat_color: StandardMaterial3D = red_material if i % 2 == 0 else blue_material
		_add_box_local(spinning, seat_position, Vector3(0.8, 0.8, 0.8), seat_color)
		_add_cylinder_local(spinning, Vector3(cos(angle) * 2.25, 0.45, sin(angle) * 2.25), 0.07, 2.0, cream_material)
	rides.append({"kind": "carousel", "position": position, "node": spinning, "timer": 0.0, "queue": [], "busy": false, "queue_capacity": 6, "level": 1, "ticket_price": RIDE_TICKET_PRICE, "ride_duration": 4.0, "condition": 100.0, "ride_revenue": 0, "served": 0})


func _create_ferris_wheel(position: Vector3) -> void:
	var ride := Node3D.new()
	ride.position = position
	add_child(ride)
	_add_box_local(ride, Vector3(-2.3, 2.1, 0), Vector3(0.35, 4.2, 0.45), blue_material)
	_add_box_local(ride, Vector3(2.3, 2.1, 0), Vector3(0.35, 4.2, 0.45), blue_material)
	var wheel := Node3D.new()
	wheel.position = Vector3(0, 4.1, 0)
	ride.add_child(wheel)
	_add_torus_local(wheel, Vector3.ZERO, 3.0, 0.16, yellow_material)
	_add_cylinder_local(wheel, Vector3.ZERO, 0.35, 0.45, red_material)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var spoke := _add_box_local(wheel, Vector3(cos(angle) * 1.5, sin(angle) * 1.5, 0), Vector3(3.0, 0.09, 0.12), cream_material)
		spoke.rotation.z = angle
		var gondola := _add_box_local(wheel, Vector3(cos(angle) * 3.0, sin(angle) * 3.0, 0), Vector3(0.65, 0.55, 0.55), red_material if i % 2 == 0 else blue_material)
		gondola.rotation.z = angle
	rides.append({"kind": "ferris", "position": position, "node": wheel, "timer": 0.0, "queue": [], "busy": false, "queue_capacity": 6, "level": 1, "ticket_price": RIDE_TICKET_PRICE, "ride_duration": 7.0, "condition": 100.0, "ride_revenue": 0, "served": 0})


func _animate_rides(delta: float) -> void:
	for ride in rides:
		var node: Node3D = ride["node"]
		if is_instance_valid(node):
			if ride["kind"] == "carousel":
				node.rotate_y(delta * 0.75)
			else:
				node.rotate_z(delta * 0.22)




func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load("user://parkora_save.cfg") != OK:
		return
	coins = int(config.get_value("park", "coins", STARTING_COINS))
	total_visitors = int(config.get_value("park", "total_visitors", 0))
	total_income = int(config.get_value("park", "total_income", 0))
	total_expenses = int(config.get_value("park", "total_expenses", 0))
	admission_income = int(config.get_value("economy", "admission_income", 0))
	ride_income = int(config.get_value("economy", "ride_income", 0))
	service_income = int(config.get_value("economy", "service_income", 0))
	staff_expenses = int(config.get_value("economy", "staff_expenses", 0))
	facility_expenses = int(config.get_value("economy", "facility_expenses", 0))
	ride_maintenance_expenses = int(config.get_value("economy", "ride_maintenance_expenses", 0))
	period_income = int(config.get_value("economy", "period_income", 0))
	period_expenses = int(config.get_value("economy", "period_expenses", 0))
	reporting_timer = float(config.get_value("economy", "reporting_timer", 60.0))
	objective_index = clampi(int(config.get_value("economy", "objective_index", 0)), 0, 6)
	last_saved_unix = int(config.get_value("park", "last_saved_unix", 0))
	land_expansions = clampi(int(config.get_value("park", "land_expansions", 0)), 0, 3)
	for zone_index in range(land_expansions):
		_create_land_zone(zone_index)
	park_rating = float(config.get_value("park", "park_rating", 50.0))
	cleaners = int(config.get_value("park", "cleaners", 0))
	mechanics = int(config.get_value("park", "mechanics", 0))
	cleanliness = float(config.get_value("park", "cleanliness", 100.0))
	var saved_litter: Array = config.get_value("park", "litter_positions", [])
	for litter_position in saved_litter:
		if litter_position is Vector3:
			_create_litter(litter_position)
	var saved_objects: Array = config.get_value("park", "built_objects", [])
	for saved_object in saved_objects:
		if not saved_object is Dictionary:
			continue
		var object_type := str(saved_object.get("type", ""))
		var object_position: Vector3 = saved_object.get("position", Vector3.ZERO)
		match object_type:
			"carousel":
				_create_carousel(object_position)
			"ferris":
				_create_ferris_wheel(object_position)
			"tree":
				_create_tree(object_position)
			"path":
				_add_box(object_position + Vector3(0, 0.04, 0), Vector3(2.0, 0.12, 2.0), path_material)
				_register_path(object_position)
			"food", "drink":
				_create_shop(object_type, object_position)
			"toilet", "rest":
				_create_facility(object_type, object_position)
		if object_type in ["carousel", "ferris"] and not rides.is_empty():
			var restored_ride: Dictionary = rides[rides.size() - 1]
			restored_ride["level"] = int(saved_object.get("level", 1))
			restored_ride["ticket_price"] = int(saved_object.get("ticket_price", RIDE_TICKET_PRICE))
			restored_ride["queue_capacity"] = int(saved_object.get("queue_capacity", 6))
			restored_ride["ride_duration"] = float(saved_object.get("ride_duration", restored_ride.get("ride_duration", 4.0)))
			restored_ride["condition"] = float(saved_object.get("condition", 100.0))
			restored_ride["ride_revenue"] = int(saved_object.get("ride_revenue", 0))
			restored_ride["served"] = int(saved_object.get("served", 0))
			rides[rides.size() - 1] = restored_ride
		built_objects.append(saved_object.duplicate(true))
	var now_unix := int(Time.get_unix_time_from_system())
	if last_saved_unix > 0:
		_apply_offline_progress(now_unix - last_saved_unix)
	last_saved_unix = now_unix


func _apply_offline_progress(raw_elapsed_seconds: int) -> void:
	var elapsed := clampi(raw_elapsed_seconds, 0, 28800)
	if elapsed < 60:
		return
	var open_ride_indices: Array[int] = []
	var condition_total := 0.0
	var ticket_total := 0.0
	for i in range(rides.size()):
		var ride: Dictionary = rides[i]
		var condition := float(ride.get("condition", 100.0))
		if condition >= 25.0:
			open_ride_indices.append(i)
			condition_total += condition
			ticket_total += float(ride.get("ticket_price", RIDE_TICKET_PRICE))
	var has_open_rides := not open_ride_indices.is_empty()
	var average_condition := condition_total / float(open_ride_indices.size()) if has_open_rides else 0.0
	var average_ticket := ticket_total / float(open_ride_indices.size()) if has_open_rides else 0.0
	var demand_factor := clampf(0.45 + park_rating / 200.0, 0.45, 0.95)
	var cleanliness_factor := lerpf(0.25, 1.0, cleanliness / 100.0)
	var condition_factor := lerpf(0.35, 1.0, average_condition / 100.0)
	var visitors_per_hour := int(minf(120.0, float(open_ride_indices.size()) * 28.0) * demand_factor * cleanliness_factor * condition_factor) if has_open_rides else 0
	var estimated_visitors := int(float(visitors_per_hour) * float(elapsed) / 3600.0)
	var admission_gain := estimated_visitors * ENTRY_TICKET_PRICE
	var ride_gain := int(round(float(estimated_visitors) * average_ticket))
	var service_customers := int(float(estimated_visitors) * 0.25)
	var service_gain := service_customers * 13
	var gross_income := admission_gain + ride_gain + service_gain
	var staff_per_tick := cleaners * 8 + mechanics * 12
	var facility_per_tick := shops.size() + facilities.size() * 2
	var ride_per_tick := 0
	for ride in rides:
		ride_per_tick += 2 + int(ride.get("level", 1))
	var upkeep_per_tick := staff_per_tick + facility_per_tick + ride_per_tick
	var upkeep_ticks := int(elapsed / 10)
	var gross_expenses := upkeep_per_tick * upkeep_ticks
	var starting_cash := coins
	coins = maxi(0, starting_cash + gross_income - gross_expenses)
	total_visitors += estimated_visitors
	total_income += gross_income
	total_expenses += gross_expenses
	admission_income += admission_gain
	ride_income += ride_gain
	service_income += service_gain
	staff_expenses += staff_per_tick * upkeep_ticks
	facility_expenses += facility_per_tick * upkeep_ticks
	ride_maintenance_expenses += ride_per_tick * upkeep_ticks
	var guests_per_ride := int(ceil(float(estimated_visitors) / float(open_ride_indices.size()))) if has_open_rides else 0
	for ride_index in open_ride_indices:
		var ride: Dictionary = rides[ride_index]
		var served := int(round(float(estimated_visitors) / float(open_ride_indices.size())))
		var ride_price := int(ride.get("ticket_price", RIDE_TICKET_PRICE))
		ride["served"] = int(ride.get("served", 0)) + served
		ride["ride_revenue"] = int(ride.get("ride_revenue", 0)) + served * ride_price
		var wear := float(guests_per_ride) * 1.5
		var mechanic_repair := float(mechanics) * 2.5 * float(upkeep_ticks)
		ride["condition"] = clampf(float(ride.get("condition", 100.0)) - wear + mechanic_repair, 0.0, 100.0)
		rides[ride_index] = ride
		_sync_ride_save(ride_index)
	var litter_created := estimated_visitors
	var litter_cleaned := mini(litter_created, cleaners * upkeep_ticks)
	cleanliness = clampf(cleanliness + float(litter_cleaned) * 2.5 - float(litter_created - litter_cleaned) * 1.2, 0.0, 100.0)
	if gross_expenses > starting_cash + gross_income:
		var unpaid_cost := gross_expenses - (starting_cash + gross_income)
		park_rating = maxf(0.0, park_rating - minf(15.0, float(unpaid_cost) / 500.0))
	offline_earnings = gross_income
	offline_costs = gross_expenses
	var net_result := gross_income - gross_expenses
	var hours_text := "%.1f" % (float(elapsed) / 3600.0)
	if has_open_rides:
		offline_notice = "Парк работал офлайн " + hours_text + " ч. Доход +" + _format_number(gross_income) + " • расходы −" + _format_number(gross_expenses) + " • итог " + ("+" if net_result >= 0 else "−") + _format_number(absi(net_result)) + " монет"
	else:
		offline_notice = "Парк был закрыт " + hours_text + " ч. Дохода не было; содержание обошлось в " + _format_number(gross_expenses) + " монет"
	_update_hud()


func _save_game() -> void:
	var config := ConfigFile.new()
	last_saved_unix = int(Time.get_unix_time_from_system())
	config.set_value("park", "last_saved_unix", last_saved_unix)
	config.set_value("park", "coins", coins)
	config.set_value("park", "total_visitors", total_visitors)
	config.set_value("park", "total_income", total_income)
	config.set_value("park", "total_expenses", total_expenses)
	config.set_value("park", "land_expansions", land_expansions)
	config.set_value("economy", "admission_income", admission_income)
	config.set_value("economy", "ride_income", ride_income)
	config.set_value("economy", "service_income", service_income)
	config.set_value("economy", "staff_expenses", staff_expenses)
	config.set_value("economy", "facility_expenses", facility_expenses)
	config.set_value("economy", "ride_maintenance_expenses", ride_maintenance_expenses)
	config.set_value("economy", "period_income", period_income)
	config.set_value("economy", "period_expenses", period_expenses)
	config.set_value("economy", "reporting_timer", reporting_timer)
	config.set_value("economy", "objective_index", objective_index)
	config.set_value("park", "park_rating", park_rating)
	config.set_value("park", "cleaners", cleaners)
	config.set_value("park", "mechanics", mechanics)
	config.set_value("park", "cleanliness", cleanliness)
	var litter_positions: Array[Vector3] = []
	for litter in litter_nodes:
		if is_instance_valid(litter):
			litter_positions.append(litter.position)
	config.set_value("park", "litter_positions", litter_positions)
	config.set_value("park", "built_objects", built_objects)
	var error := config.save("user://parkora_save.cfg")
	if error != OK:
		push_warning("PARKORA: не удалось сохранить прогресс")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()


func _update_economy(delta: float) -> void:
	maintenance_timer -= delta
	if maintenance_timer > 0.0:
		return
	maintenance_timer = 10.0
	var staff_cost := cleaners * 8 + mechanics * 12
	var facility_cost := shops.size() + facilities.size() * 2
	var ride_cost := 0
	for ride in rides:
		ride_cost += 2 + int(ride.get("level", 1))
	var upkeep := staff_cost + facility_cost + ride_cost
	staff_expenses += staff_cost
	facility_expenses += facility_cost
	ride_maintenance_expenses += ride_cost
	period_expenses += upkeep
	if upkeep <= 0:
		return
	total_expenses += upkeep
	if coins >= upkeep:
		coins -= upkeep
		_set_hint("Обслуживание аттракционов: −🪙 " + str(upkeep))
	else:
		coins = 0
		park_rating = maxf(0.0, park_rating - 1.0)
		_set_hint("Не хватает монет на обслуживание! Рейтинг парка снижается")
	_update_cleanliness(10.0)
	_update_ride_maintenance()
	_update_hud()


func _update_reporting_period(delta: float) -> void:
	reporting_timer -= delta
	if reporting_timer > 0.0:
		return
	while reporting_timer <= 0.0:
		reporting_timer += 60.0
		period_income = 0
		period_expenses = 0
	_update_hud()


func _update_ride_maintenance() -> void:
	if mechanics <= 0:
		return
	var repaired_count := 0
	for i in range(rides.size()):
		var ride: Dictionary = rides[i]
		var condition := float(ride.get("condition", 100.0))
		if condition >= 99.9:
			continue
		var repair_amount := minf(100.0 - condition, float(mechanics) * 2.5)
		ride["condition"] = condition + repair_amount
		rides[i] = ride
		_sync_ride_save(i)
		repaired_count += 1
	if repaired_count > 0:
		_set_hint("Механики обслужили аттракционы: восстановление состояния")


func _visitor_spawn_interval() -> float:
	var reputation_factor := park_rating / 100.0
	var cleanliness_factor := cleanliness / 100.0
	return lerpf(7.0, 2.5, reputation_factor * cleanliness_factor)


func _spawn_visitor() -> void:
	if visitors.size() >= MAX_VISITORS or rides.is_empty():
		return
	var willingness_to_pay := randi_range(25, 65)
	var target_index := _find_best_ride(willingness_to_pay)
	if target_index < 0:
		return
	var person := Node3D.new()
	person.position = Vector3(randf_range(-0.7, 0.7), 0, 13.0)
	add_child(person)
	var shirt: StandardMaterial3D = shirt_materials[randi() % shirt_materials.size()]
	_add_capsule_local(person, Vector3(0, 0.85, 0), 0.28, 1.1, shirt)
	_add_sphere_local(person, Vector3(0, 1.65, 0), 0.25, skin_material)
	var queue: Array = rides[target_index]["queue"]
	queue.append(person.get_instance_id())
	rides[target_index]["queue"] = queue
	var target := _queue_position(target_index, queue.size() - 1)
	var route := _find_path(person.position, target)
	if route.is_empty():
		queue.pop_back()
		rides[target_index]["queue"] = queue
		person.queue_free()
		return
	visitors.append({"node": person, "person_id": person.get_instance_id(), "target": target, "route": route, "route_index": 0, "route_queue_index": queue.size() - 1, "patience": 45.0, "state": "walking", "wait": 0.0, "ride_index": target_index, "hunger": randf_range(15.0, 35.0), "thirst": randf_range(20.0, 40.0), "hygiene": randf_range(25.0, 45.0), "rest": randf_range(25.0, 45.0), "shop_index": -1, "facility_index": -1, "service_done": false, "willingness_to_pay": willingness_to_pay})
	coins += ENTRY_TICKET_PRICE
	total_visitors += 1
	total_income += ENTRY_TICKET_PRICE
	admission_income += ENTRY_TICKET_PRICE
	period_income += ENTRY_TICKET_PRICE
	_update_hud()
	_set_hint("Новый посетитель вошёл в парк: +🪙 " + str(ENTRY_TICKET_PRICE))


func _register_path(position: Vector3) -> void:
	var cell := Vector2i(roundi(position.x / 2.0), roundi(position.z / 2.0))
	path_cells[cell] = true


func _find_nearest_path_cell(position: Vector3, max_distance: float = 6.0) -> Vector2i:
	var best_cell := Vector2i(99999, 99999)
	var best_distance := max_distance
	for cell_variant in path_cells.keys():
		var cell: Vector2i = cell_variant
		var world_position := Vector3(float(cell.x) * 2.0, 0, float(cell.y) * 2.0)
		var distance := Vector2(position.x, position.z).distance_to(Vector2(world_position.x, world_position.z))
		if distance <= best_distance:
			best_distance = distance
			best_cell = cell
	return best_cell


func _find_path(start_position: Vector3, goal_position: Vector3) -> Array:
	var start_cell := _find_nearest_path_cell(start_position)
	var goal_cell := _find_nearest_path_cell(goal_position, 3.0)
	var result: Array = []
	if start_cell.x == 99999 or goal_cell.x == 99999:
		return result
	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {start_cell: Vector2i(99999, 99999)}
	var found := false
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal_cell:
			found = true
			break
		for direction in directions:
			var next_cell := current + direction
			if not path_cells.has(next_cell) or came_from.has(next_cell):
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)
	if not found:
		return result
	var reversed_path: Array[Vector2i] = []
	var cursor := goal_cell
	while cursor != Vector2i(99999, 99999):
		reversed_path.append(cursor)
		cursor = came_from[cursor]
	reversed_path.reverse()
	for cell in reversed_path:
		result.append(Vector3(float(cell.x) * 2.0, 0, float(cell.y) * 2.0))
	result.append(goal_position)
	return result


func _find_best_ride(willingness_to_pay: int) -> int:
	var best_index := -1
	var best_load := INF
	for i in range(rides.size()):
		var queue: Array = rides[i]["queue"]
		var capacity: int = int(rides[i].get("queue_capacity", 6))
		if queue.size() >= capacity:
			continue
		if int(rides[i].get("ticket_price", RIDE_TICKET_PRICE)) > willingness_to_pay:
			continue
		if float(rides[i].get("condition", 100.0)) < 25.0:
			continue
		if _find_path(Vector3(0, 0, 13), _queue_position(i, 0)).is_empty():
			continue
		var price := float(rides[i].get("ticket_price", RIDE_TICKET_PRICE))
		var load := float(queue.size()) + price * 0.015
		if rides[i]["busy"]:
			load += 0.5
		if load < best_load:
			best_load = load
			best_index = i
	return best_index


func _queue_position(ride_index: int, queue_index: int) -> Vector3:
	var ride_position: Vector3 = rides[ride_index]["position"]
	return ride_position + Vector3(0, 0, 4.0 + float(queue_index) * 1.15)


func _find_visitor_queue_index(ride_index: int, person_id: int) -> int:
	var queue: Array = rides[ride_index]["queue"]
	return queue.find(person_id)


func _remove_visitor_from_queue(ride_index: int, person_id: int) -> void:
	if ride_index < 0 or ride_index >= rides.size():
		return
	var queue: Array = rides[ride_index]["queue"]
	var index := queue.find(person_id)
	if index >= 0:
		queue.remove_at(index)
		rides[ride_index]["queue"] = queue


func _update_visitors(delta: float) -> void:
	for i in range(visitors.size() - 1, -1, -1):
		var visitor: Dictionary = visitors[i]
		var person: Node3D = visitor["node"]
		var ride_index: int = visitor["ride_index"]
		if not is_instance_valid(person):
			if ride_index >= 0 and ride_index < rides.size():
				_remove_visitor_from_queue(ride_index, visitor["person_id"])
				if visitor["state"] == "riding":
					rides[ride_index]["busy"] = false
			visitors.remove_at(i)
			continue
		if ride_index < 0 or ride_index >= rides.size():
			continue
		visitor["hunger"] = minf(100.0, float(visitor.get("hunger", 0.0)) + delta * 0.22)
		visitor["thirst"] = minf(100.0, float(visitor.get("thirst", 0.0)) + delta * 0.3)
		visitor["hygiene"] = minf(100.0, float(visitor.get("hygiene", 0.0)) + delta * 0.22)
		visitor["rest"] = minf(100.0, float(visitor.get("rest", 0.0)) + delta * 0.18)
		var person_id: int = visitor["person_id"]
		var queue_index := _find_visitor_queue_index(ride_index, person_id)
		if visitor["state"] == "walking":
			if queue_index < 0:
				continue
			if visitor["route_queue_index"] != queue_index:
				visitor["route"] = _find_path(person.position, _queue_position(ride_index, queue_index))
				visitor["route_index"] = 0
				visitor["route_queue_index"] = queue_index
			var route: Array = visitor["route"]
			if route.is_empty():
				continue
			var waypoint: Vector3 = route[visitor["route_index"]]
			var direction: Vector3 = waypoint - person.position
			direction.y = 0.0
			if direction.length() < 0.3:
				visitor["route_index"] += 1
				if visitor["route_index"] >= route.size():
					visitor["state"] = "queued"
			else:
				person.position += direction.normalized() * delta * 2.2
				person.look_at(Vector3(waypoint.x, person.position.y, waypoint.z), Vector3.UP)
		elif visitor["state"] == "queued":
			if queue_index < 0:
				continue
			visitor["patience"] -= delta
			if visitor["patience"] <= 0.0:
				_remove_visitor_from_queue(ride_index, person_id)
				visitor["state"] = "leaving"
				visitor["target"] = Vector3(0, 0, 16.0)
				visitor["route"] = _find_path(person.position, visitor["target"])
				visitor["route_index"] = 0
				park_rating = maxf(0.0, park_rating - 4.0)
				_update_hud()
				_set_hint("Посетитель не дождался очереди. Рейтинг парка снизился")
				continue
			var target := _queue_position(ride_index, queue_index)
			var direction: Vector3 = target - person.position
			direction.y = 0.0
			if direction.length() > 0.18:
				person.position += direction.normalized() * delta * 2.0
				person.look_at(Vector3(target.x, person.position.y, target.z), Vector3.UP)
			if queue_index == 0 and not rides[ride_index]["busy"] and direction.length() < 0.6:
				rides[ride_index]["busy"] = true
				visitor["state"] = "riding"
				var effective_duration := float(rides[ride_index].get("ride_duration", 4.0))
				if float(rides[ride_index].get("condition", 100.0)) < 50.0:
					effective_duration *= 1.25
				visitor["wait"] = effective_duration
				person.position = rides[ride_index]["position"] + Vector3(0, 0.2, 0)
				_set_hint("Аттракцион начал обслуживать посетителя")
		elif visitor["state"] == "riding":
			visitor["wait"] -= delta
			if visitor["wait"] <= 0.0:
				_remove_visitor_from_queue(ride_index, person_id)
				rides[ride_index]["busy"] = false
				var ride_price := int(rides[ride_index].get("ticket_price", RIDE_TICKET_PRICE))
				coins += ride_price
				total_income += ride_price
				ride_income += ride_price
				period_income += ride_price
				rides[ride_index]["ride_revenue"] = int(rides[ride_index].get("ride_revenue", 0)) + ride_price
				rides[ride_index]["served"] = int(rides[ride_index].get("served", 0)) + 1
				rides[ride_index]["condition"] = maxf(0.0, float(rides[ride_index].get("condition", 100.0)) - 1.5)
				_sync_ride_save(ride_index)
				_spawn_litter(rides[ride_index]["position"])
				park_rating = minf(100.0, park_rating + 1.5)
				_update_hud()
				_set_hint("Катание завершено! +🪙 " + str(ride_price))
				_send_visitor_to_service(visitor, person)
		elif visitor["state"] == "walking_to_shop":
			var shop_route: Array = visitor["route"]
			if shop_route.is_empty():
				_send_visitor_to_exit(visitor, person)
				continue
			var shop_waypoint: Vector3 = shop_route[visitor["route_index"]]
			var shop_direction: Vector3 = shop_waypoint - person.position
			shop_direction.y = 0.0
			if shop_direction.length() < 0.3:
				visitor["route_index"] += 1
				if visitor["route_index"] >= shop_route.size():
					visitor["state"] = "shopping"
					visitor["wait"] = 3.0
			else:
				person.position += shop_direction.normalized() * delta * 2.2
				person.look_at(Vector3(shop_waypoint.x, person.position.y, shop_waypoint.z), Vector3.UP)
		elif visitor["state"] == "shopping":
			visitor["wait"] -= delta
			if visitor["wait"] <= 0.0:
				var shop_index: int = visitor["shop_index"]
				if shop_index >= 0 and shop_index < shops.size():
					var shop_kind: String = shops[shop_index]["kind"]
					var sale_price := 18 if shop_kind == "food" else 12
					coins += sale_price
					total_income += sale_price
					service_income += sale_price
					period_income += sale_price
					shops[shop_index]["served"] += 1
					if shop_kind == "food":
						visitor["hunger"] = 0.0
					else:
						visitor["thirst"] = 0.0
					park_rating = minf(100.0, park_rating + 1.0)
					_update_hud()
					_set_hint(("Посетитель купил еду" if shop_kind == "food" else "Посетитель купил напиток") + ": +🪙 " + str(sale_price))
				visitor["service_done"] = true
				_send_visitor_to_exit(visitor, person)
		elif visitor["state"] == "walking_to_facility":
			var facility_route: Array = visitor["route"]
			if facility_route.is_empty():
				_send_visitor_to_exit(visitor, person)
				continue
			var facility_waypoint: Vector3 = facility_route[visitor["route_index"]]
			var facility_direction: Vector3 = facility_waypoint - person.position
			facility_direction.y = 0.0
			if facility_direction.length() < 0.3:
				visitor["route_index"] += 1
				if visitor["route_index"] >= facility_route.size():
					visitor["state"] = "using_facility"
					visitor["wait"] = 4.0
			else:
				person.position += facility_direction.normalized() * delta * 2.2
				person.look_at(Vector3(facility_waypoint.x, person.position.y, facility_waypoint.z), Vector3.UP)
		elif visitor["state"] == "using_facility":
			visitor["wait"] -= delta
			if visitor["wait"] <= 0.0:
				var facility_index: int = int(visitor.get("facility_index", -1))
				if facility_index >= 0 and facility_index < facilities.size():
					var facility_kind: String = facilities[facility_index]["kind"]
					var service_price := 8 if facility_kind == "toilet" else 6
					coins += service_price
					total_income += service_price
					service_income += service_price
					period_income += service_price
					facilities[facility_index]["served"] = int(facilities[facility_index].get("served", 0)) + 1
					if facility_kind == "toilet":
						visitor["hygiene"] = 0.0
					else:
						visitor["rest"] = 0.0
					park_rating = minf(100.0, park_rating + 1.0)
					_update_hud()
					_set_hint(("Посетитель воспользовался туалетом" if facility_kind == "toilet" else "Посетитель отдохнул") + ": +🪙 " + str(service_price))
				visitor["service_done"] = true
				_send_visitor_to_exit(visitor, person)
		elif visitor["state"] == "leaving":
			var exit_route: Array = visitor["route"]
			if exit_route.is_empty():
				person.queue_free()
				visitors.remove_at(i)
				_update_hud()
				continue
			var exit_waypoint: Vector3 = exit_route[visitor["route_index"]]
			var exit_direction: Vector3 = exit_waypoint - person.position
			exit_direction.y = 0.0
			if exit_direction.length() < 0.3:
				visitor["route_index"] += 1
				if visitor["route_index"] >= exit_route.size():
					person.queue_free()
					visitors.remove_at(i)
					_update_hud()
			else:
				person.position += exit_direction.normalized() * delta * 2.4
				person.look_at(Vector3(exit_waypoint.x, person.position.y, exit_waypoint.z), Vector3.UP)


func _send_visitor_to_service(visitor: Dictionary, person: Node3D) -> void:
	if bool(visitor.get("service_done", false)):
		_send_visitor_to_exit(visitor, person)
		return
	var best_kind := ""
	var best_index := -1
	var best_route: Array = []
	var best_score := 25.0
	for shop_index in range(shops.size()):
		var shop_kind: String = shops[shop_index]["kind"]
		var need_level := float(visitor.get("hunger", 0.0)) if shop_kind == "food" else float(visitor.get("thirst", 0.0))
		var price := 18 if shop_kind == "food" else 12
		if need_level < 30.0 or price > int(visitor.get("willingness_to_pay", 35)):
			continue
		var shop_position: Vector3 = shops[shop_index]["position"]
		var candidate_route := _find_path(person.position, shop_position + Vector3(0, 0, 2.0))
		if candidate_route.is_empty():
			continue
		var score := need_level - person.position.distance_to(shop_position) * 0.5
		if score > best_score:
			best_score = score
			best_kind = shop_kind
			best_index = shop_index
			best_route = candidate_route
	for facility_index in range(facilities.size()):
		var facility_kind: String = facilities[facility_index]["kind"]
		var facility_need_level := float(visitor.get("hygiene", 0.0)) if facility_kind == "toilet" else float(visitor.get("rest", 0.0))
		var facility_price := 8 if facility_kind == "toilet" else 6
		if facility_need_level < 30.0 or facility_price > int(visitor.get("willingness_to_pay", 35)):
			continue
		var facility_position: Vector3 = facilities[facility_index]["position"]
		var facility_candidate_route := _find_path(person.position, facility_position + Vector3(0, 0, 2.0))
		if facility_candidate_route.is_empty():
			continue
		var facility_score := facility_need_level - person.position.distance_to(facility_position) * 0.5
		if facility_score > best_score:
			best_score = facility_score
			best_kind = facility_kind
			best_index = facility_index
			best_route = facility_candidate_route
	if best_index < 0:
		_send_visitor_to_exit(visitor, person)
		return
	visitor["route"] = best_route
	visitor["route_index"] = 0
	if best_kind in ["food", "drink"]:
		visitor["shop_index"] = best_index
		visitor["state"] = "walking_to_shop"
		_set_hint("Посетитель направился в " + ("киоск еды" if best_kind == "food" else "киоск напитков"))
	else:
		visitor["facility_index"] = best_index
		visitor["state"] = "walking_to_facility"
		_set_hint("Посетитель направился " + ("в туалет" if best_kind == "toilet" else "в зону отдыха"))


func _send_visitor_to_exit(visitor: Dictionary, person: Node3D) -> void:
	visitor["state"] = "leaving"
	visitor["target"] = Vector3(0, 0, 16.0)
	visitor["route"] = _find_path(person.position, visitor["target"])
	visitor["route_index"] = 0


func _add_box(position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	add_child(instance)
	return instance


func _add_box_local(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_cylinder_local(parent: Node3D, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_cylinder(position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	return _add_cylinder_local(self, position, radius, height, material)


func _add_sphere(position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	return _add_sphere_local(self, position, radius, material)


func _add_sphere_local(parent: Node3D, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_capsule_local(parent: Node3D, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_torus_local(parent: Node3D, position: Vector3, radius: float, tube_radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube_radius
	mesh.outer_radius = radius + tube_radius
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _update_hud() -> void:
	if build_buttons.has("ferris"):
		var ferris_button: Button = build_buttons["ferris"]
		ferris_button.disabled = total_visitors < 8
		ferris_button.text = "Колесо 🔒\n🪙 2 400" if total_visitors < 8 else "Колесо\n🪙 2 400"
	if coins_label != null:
		coins_label.text = "PARKORA   🪙 " + _format_number(coins)
	if visitors_label != null:
		visitors_label.text = "👥 " + str(visitors.size()) + " / " + str(MAX_VISITORS) + "    Всего: " + str(total_visitors) + "    ⭐ " + str(roundi(park_rating)) + "    🧹 " + str(roundi(cleanliness)) + "%"
	if ride_panel != null and ride_panel.visible:
		_update_ride_panel()
	if staff_label != null:
		staff_label.text = "🧹 Уборщики: " + str(cleaners) + "   🔧 Механики: " + str(mechanics) + "\nМусор: " + str(litter_nodes.size()) + "   🚻 " + str(_count_facilities("toilet")) + "   🪑 " + str(_count_facilities("rest"))
	if hire_cleaner_button != null:
		hire_cleaner_button.disabled = coins < 300
	_update_land_panel()
	if hire_mechanic_button != null:
		hire_mechanic_button.disabled = coins < 500
	if economy_label != null:
		var lifetime_profit := total_income - total_expenses
		var period_profit := period_income - period_expenses
		economy_label.text = "Доход: вход " + _format_number(admission_income) + " | аттракционы " + _format_number(ride_income) + " | услуги " + _format_number(service_income) + "\nРасходы: персонал " + _format_number(staff_expenses) + " | объекты " + _format_number(facility_expenses) + " | аттракционы " + _format_number(ride_maintenance_expenses) + "\nЗа минуту: доход +" + _format_number(period_income) + " / расход −" + _format_number(period_expenses) + " / итог " + ("+" if period_profit >= 0 else "−") + _format_number(absi(period_profit)) + "   Всего: " + ("+" if lifetime_profit >= 0 else "−") + _format_number(absi(lifetime_profit))


func _count_facilities(kind: String) -> int:
	var count := 0
	for facility in facilities:
		if facility.get("kind", "") == kind:
			count += 1
	return count


func _total_queued_visitors() -> int:
	var total := 0
	for ride in rides:
		var queue: Array = ride["queue"]
		total += queue.size()
	return total


func _format_number(value: int) -> String:
	var raw := str(value)
	var output := ""
	for i in range(raw.length()):
		output += raw[i]
		var remaining := raw.length() - i - 1
		if remaining > 0 and remaining % 3 == 0:
			output += " "
	return output


func _set_hint(message: String) -> void:
	if hint_label != null:
		hint_label.text = message
