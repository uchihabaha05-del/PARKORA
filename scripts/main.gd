extends Node3D

const STARTING_CASH := 5000
const COSTS := {"carousel": 1200, "tree": 100, "path": 25}

var cash := STARTING_CASH
var selected_build := ""
var camera_pivot: Node3D
var camera: Camera3D
var cash_label: Label
var hint_label: Label
var build_buttons: Dictionary = {}
var touch_dragged := false

var grass_material: StandardMaterial3D
var path_material: StandardMaterial3D
var wood_material: StandardMaterial3D
var leaf_material: StandardMaterial3D
var red_material: StandardMaterial3D
var yellow_material: StandardMaterial3D
var blue_material: StandardMaterial3D
var cream_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_create_environment()
	_create_ground()
	_create_entrance()
	_create_starter_decoration()
	_create_camera()
	_create_ui()
	_update_cash()
	_set_hint("Выбери объект внизу, затем коснись земли, чтобы построить")


func _create_materials() -> void:
	grass_material = _material(Color("#79c96b"))
	path_material = _material(Color("#e9d7ad"))
	wood_material = _material(Color("#9b603b"))
	leaf_material = _material(Color("#36a96b"))
	red_material = _material(Color("#f05b63"))
	yellow_material = _material(Color("#ffd45c"))
	blue_material = _material(Color("#59b9e8"))
	cream_material = _material(Color("#fff0cf"))


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

	# A simple entrance plaza gives the empty park a clear starting point.
	for x in range(-2, 3):
		for z in range(5, 9):
			_add_box(Vector3(float(x) * 2.0, 0.015, float(z) * 2.0), Vector3(1.95, 0.08, 1.95), path_material)


func _create_entrance() -> void:
	_add_box(Vector3(0, 2.2, 17.0), Vector3(12.0, 0.55, 0.65), red_material)
	_add_box(Vector3(-5.5, 1.1, 17.0), Vector3(0.65, 2.2, 0.65), cream_material)
	_add_box(Vector3(5.5, 1.1, 17.0), Vector3(0.65, 2.2, 0.65), cream_material)
	_add_box(Vector3(0, 2.65, 17.0), Vector3(3.8, 0.55, 0.7), yellow_material)


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
	camera_pivot.position = Vector3.ZERO
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 23.0, 31.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
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

	cash_label = Label.new()
	cash_label.position = Vector2(24, 20)
	cash_label.add_theme_font_size_override("font_size", 30)
	cash_label.add_theme_color_override("font_color", Color("#ffffff"))
	cash_label.add_theme_color_override("font_shadow_color", Color("#263c35"))
	cash_label.add_theme_constant_override("shadow_offset_x", 2)
	cash_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(cash_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24, 62)
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", Color("#ffffff"))
	root.add_child(hint_label)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -104
	panel.offset_bottom = -18
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.19, 0.88)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	_add_build_button(row, "Карусель\n$1200", "carousel")
	_add_build_button(row, "Дерево\n$100", "tree")
	_add_build_button(row, "Дорожка\n$25", "path")
	_add_clear_button(row)


func _add_build_button(parent: HBoxContainer, caption: String, build_type: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(132, 68)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_select_build.bind(build_type))
	parent.add_child(button)
	build_buttons[build_type] = button


func _add_clear_button(parent: HBoxContainer) -> void:
	var button := Button.new()
	button.text = "Отмена"
	button.custom_minimum_size = Vector2(100, 68)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_select_build.bind(""))
	parent.add_child(button)


func _select_build(build_type: String) -> void:
	selected_build = build_type
	if selected_build == "":
		_set_hint("Режим строительства выключен. Перетаскивай экран для вращения камеры")
	else:
		_set_hint("Строительство: " + _build_name(build_type) + ". Коснись свободного места")
	for key in build_buttons:
		var button: Button = build_buttons[key]
		button.modulate = Color("#ffe28a") if key == selected_build else Color.WHITE


func _build_name(build_type: String) -> String:
	match build_type:
		"carousel":
			return "Карусель"
		"tree":
			return "Дерево"
		"path":
			return "Дорожка"
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
	if selected_build == "":
		return
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
	_place_selected(Vector3(snappedf(hit.x, 2.0), 0.0, snappedf(hit.z, 2.0)))


func _place_selected(position: Vector3) -> void:
	var cost: int = COSTS.get(selected_build, 0)
	if cash < cost:
		_set_hint("Недостаточно денег для строительства")
		return
	match selected_build:
		"carousel":
			_create_carousel(position)
		"tree":
			_create_tree(position)
		"path":
			_add_box(position + Vector3(0, 0.04, 0), Vector3(2.0, 0.12, 2.0), path_material)
	cash -= cost
	_update_cash()
	_set_hint(_build_name(selected_build) + " построено! Остаток: $" + str(cash))


func _create_tree(position: Vector3) -> void:
	_add_cylinder(position + Vector3(0, 1.0, 0), 0.28, 2.0, wood_material)
	_add_sphere(position + Vector3(0, 2.5, 0), 1.25, leaf_material)
	_add_sphere(position + Vector3(0.75, 2.25, 0.1), 0.75, leaf_material)


func _create_carousel(position: Vector3) -> void:
	_add_cylinder(position + Vector3(0, 0.25, 0), 3.4, 0.5, cream_material)
	_add_cylinder(position + Vector3(0, 2.0, 0), 0.22, 3.2, red_material)
	_add_cylinder(position + Vector3(0, 3.65, 0), 3.0, 0.35, yellow_material)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var seat_position := position + Vector3(cos(angle) * 2.25, 1.45, sin(angle) * 2.25)
		var seat_color: StandardMaterial3D = red_material if i % 2 == 0 else blue_material
		_add_box(seat_position, Vector3(0.8, 0.8, 0.8), seat_color)
		_add_cylinder(position + Vector3(cos(angle) * 2.25, 2.45, sin(angle) * 2.25), 0.07, 2.0, cream_material)


func _add_box(position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	add_child(instance)
	return instance


func _add_cylinder(position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	add_child(instance)
	return instance


func _add_sphere(position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	add_child(instance)
	return instance


func _update_cash() -> void:
	if cash_label != null:
		cash_label.text = "PARKORA   $" + str(cash)


func _set_hint(message: String) -> void:
	if hint_label != null:
		hint_label.text = message
